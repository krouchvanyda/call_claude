import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/notifications/data/datasources/notifications_dao.dart';
import 'package:erp_mobile/features/notifications/domain/entities/notification.dart';
import 'package:test/test.dart';

AppNotification _n({
  required String id,
  String title = 't',
  String body = 'b',
  String category = 'system',
  String? routeName,
  Map<String, String> pathParameters = const {},
  DateTime? receivedAt,
  DateTime? readAt,
  bool dismissed = false,
}) =>
    AppNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      routeName: routeName,
      pathParameters: pathParameters,
      receivedAt: receivedAt ?? DateTime.utc(2026, 1, 1),
      readAt: readAt,
      dismissed: dismissed,
    );

void main() {
  late AppDatabase db;
  late NotificationsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.notificationsDao;
  });

  tearDown(() => db.close());

  group('upsert + getInbox', () {
    test('round-trips every field, including pathParameters JSON', () async {
      await dao.upsert(_n(
        id: 'n-1',
        title: 'Invoice approved',
        body: 'INV-001 was approved',
        category: 'invoice',
        routeName: 'invoiceDetail',
        pathParameters: {'id': 'INV-001'},
        receivedAt: DateTime.utc(2026, 5, 1, 12),
      ));

      final inbox = await dao.getInbox();
      expect(inbox, hasLength(1));
      final n = inbox.single;
      expect(n.id, 'n-1');
      expect(n.title, 'Invoice approved');
      expect(n.body, 'INV-001 was approved');
      expect(n.category, 'invoice');
      expect(n.routeName, 'invoiceDetail');
      expect(n.pathParameters, {'id': 'INV-001'});
      // Drift round-trips DateTime as Unix-epoch seconds; the read-back
      // value is local-zoned even when written as UTC. Compare via
      // millisecondsSinceEpoch so timezone is irrelevant.
      expect(
        n.receivedAt.millisecondsSinceEpoch,
        DateTime.utc(2026, 5, 1, 12).millisecondsSinceEpoch,
      );
      expect(n.isUnread, isTrue);
      expect(n.dismissed, isFalse);
    });

    test('upsert by id replaces an existing row in place (no duplicate)',
        () async {
      await dao.upsert(_n(id: 'n-1', title: 'A'));
      await dao.upsert(_n(id: 'n-1', title: 'A — updated'));

      final inbox = await dao.getInbox();
      expect(inbox, hasLength(1));
      expect(inbox.single.title, 'A — updated');
    });

    test('newest-first ordering by receivedAt', () async {
      await dao.upsert(_n(
        id: 'old',
        receivedAt: DateTime.utc(2026, 1, 1),
      ));
      await dao.upsert(_n(
        id: 'new',
        receivedAt: DateTime.utc(2026, 5, 1),
      ));
      await dao.upsert(_n(
        id: 'middle',
        receivedAt: DateTime.utc(2026, 3, 1),
      ));

      final inbox = await dao.getInbox();
      expect(inbox.map((n) => n.id), ['new', 'middle', 'old']);
    });

    test('dismissed rows are excluded from getInbox', () async {
      await dao.upsert(_n(id: 'live'));
      await dao.upsert(_n(id: 'gone'));
      await dao.dismiss('gone');

      final inbox = await dao.getInbox();
      expect(inbox.map((n) => n.id), ['live']);
    });

    test('empty pathParameters round-trips as empty map (not null)',
        () async {
      await dao.upsert(_n(id: 'n-1'));
      final n = (await dao.getInbox()).single;
      expect(n.pathParameters, isEmpty);
    });
  });

  group('upsertAll', () {
    test('inserts every row in a single transaction', () async {
      await dao.upsertAll([
        _n(id: 'a'),
        _n(id: 'b'),
        _n(id: 'c'),
      ]);
      expect(await dao.getInbox(), hasLength(3));
    });
  });

  group('markRead', () {
    test('sets readAt to the provided "now"', () async {
      await dao.upsert(_n(id: 'n-1'));
      final affected = await dao.markRead(
        'n-1',
        now: DateTime.utc(2026, 5, 13),
      );
      expect(affected, 1);

      final n = (await dao.getInbox()).single;
      // See round-trips test for the timezone explanation.
      expect(
        n.readAt!.millisecondsSinceEpoch,
        DateTime.utc(2026, 5, 13).millisecondsSinceEpoch,
      );
      expect(n.isUnread, isFalse);
    });

    test('returns 0 for an unknown id (no implicit insert)', () async {
      expect(await dao.markRead('phantom'), 0);
    });
  });

  group('markAllRead', () {
    test('marks every unread, non-dismissed row read', () async {
      await dao.upsert(_n(id: 'a'));
      await dao.upsert(_n(id: 'b'));
      await dao.upsert(_n(id: 'gone'));
      await dao.dismiss('gone');

      final affected = await dao.markAllRead(
        now: DateTime.utc(2026, 5, 13),
      );
      expect(affected, 2,
          reason: 'dismissed rows must NOT be touched by mark-all');

      final inbox = await dao.getInbox();
      expect(inbox.every((n) => !n.isUnread), isTrue);
    });

    test('skips already-read rows (returns count of newly-marked)',
        () async {
      await dao.upsert(_n(id: 'a'));
      await dao.upsert(_n(id: 'b'));
      await dao.markRead('a', now: DateTime.utc(2026, 1, 1));

      final affected = await dao.markAllRead();
      expect(affected, 1);
    });
  });

  group('dismiss', () {
    test('flips dismissed flag and removes from inbox', () async {
      await dao.upsert(_n(id: 'x'));
      final affected = await dao.dismiss('x');
      expect(affected, 1);
      expect(await dao.getInbox(), isEmpty);
    });
  });

  group('watchInbox', () {
    test('emits a fresh snapshot on each write', () async {
      final emitted = <List<AppNotification>>[];
      final sub = dao.watchInbox().listen(emitted.add);

      await pumpEventQueue();
      await dao.upsert(_n(id: 'a', title: 'A'));
      await pumpEventQueue();
      await dao.upsert(_n(id: 'b', title: 'B'));
      await pumpEventQueue();
      await dao.dismiss('a');
      await pumpEventQueue();
      await sub.cancel();

      // Initial empty + at least one snapshot per write.
      expect(emitted.first, isEmpty);
      expect(emitted.last.map((n) => n.id), ['b']);
    });
  });

  group('watchUnreadCount', () {
    test('counts only unread, non-dismissed rows', () async {
      final emitted = <int>[];
      final sub = dao.watchUnreadCount().listen(emitted.add);

      await pumpEventQueue();
      await dao.upsert(_n(id: 'a'));
      await dao.upsert(_n(id: 'b'));
      await pumpEventQueue();
      await dao.markRead('a', now: DateTime.utc(2026, 1, 1));
      await pumpEventQueue();
      await dao.dismiss('b');
      await pumpEventQueue();
      await sub.cancel();

      // Locks the *progression*: 0 → 2 → 1 → 0 (with possible
      // intermediate duplicates absorbed).
      expect(emitted.first, 0);
      expect(emitted, contains(2));
      expect(emitted.last, 0);
    });
  });

  group('wipeAll', () {
    test('deletes every row including dismissed ones', () async {
      await dao.upsert(_n(id: 'a'));
      await dao.upsert(_n(id: 'b'));
      await dao.dismiss('b');

      await dao.wipeAll();

      // Inspect the underlying table directly to confirm tombstones
      // are gone too (getInbox would lie — it filters dismissed).
      final all = await db.select(db.cachedNotifications).get();
      expect(all, isEmpty);
    });
  });
}
