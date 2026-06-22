import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/database/cache_freshness_dao.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late CacheFreshnessDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 12, 9, 0, 0);
    // Construct directly so we can inject a deterministic clock — the
    // production wiring goes through `db.cacheFreshnessDao` (DateTime.now).
    dao = CacheFreshnessDao(db, clock: () => fakeNow);
  });

  tearDown(() => db.close());

  group('markFresh + isFresh', () {
    test('an unmarked key is never fresh', () async {
      expect(await dao.isFresh('orders.list'), isFalse);
    });

    test('a freshly marked key is fresh', () async {
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 5));
      expect(await dao.isFresh('orders.list'), isTrue);
    });

    test('isFresh stays true while still inside the TTL window', () async {
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 5));

      fakeNow = fakeNow.add(const Duration(minutes: 4, seconds: 59));
      expect(await dao.isFresh('orders.list'), isTrue);
    });

    test('isFresh flips to false once the TTL has elapsed', () async {
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 5));

      fakeNow = fakeNow.add(const Duration(minutes: 5, seconds: 1));
      expect(await dao.isFresh('orders.list'), isFalse);
    });

    test('re-marking a key resets the freshness timer', () async {
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 5));

      // Drift past the original TTL window, then re-mark.
      fakeNow = fakeNow.add(const Duration(minutes: 10));
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 5));

      expect(await dao.isFresh('orders.list'), isTrue);

      // Single-row contract — only the latest mark is stored.
      expect(await dao.count(), 1);
    });

    test('TTLs are independent per key', () async {
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 1));
      await dao.markFresh('customers.list', ttl: const Duration(hours: 1));

      fakeNow = fakeNow.add(const Duration(minutes: 2));
      expect(await dao.isFresh('orders.list'), isFalse);
      expect(await dao.isFresh('customers.list'), isTrue);
    });

    test('zero or negative TTLs are rejected (use invalidate instead)',
        () async {
      expect(
        () => dao.markFresh('x', ttl: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => dao.markFresh('x', ttl: const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });
  });

  group('lastFetched', () {
    test('returns null for an unmarked key', () async {
      expect(await dao.lastFetched('never'), isNull);
    });

    test('returns the timestamp passed via the injected clock', () async {
      await dao.markFresh('orders.list', ttl: const Duration(minutes: 5));
      final stored = await dao.lastFetched('orders.list');
      expect(stored, isNotNull);
      // Stored as Unix seconds → may lose sub-second precision.
      expect(
        stored!.millisecondsSinceEpoch ~/ 1000,
        fakeNow.millisecondsSinceEpoch ~/ 1000,
      );
    });
  });

  group('invalidate', () {
    test('removes a single entry and returns 1', () async {
      await dao.markFresh('a', ttl: const Duration(minutes: 5));
      await dao.markFresh('b', ttl: const Duration(minutes: 5));

      expect(await dao.invalidate('a'), 1);
      expect(await dao.isFresh('a'), isFalse);
      expect(await dao.isFresh('b'), isTrue);
    });

    test('returns 0 when the key was never marked', () async {
      expect(await dao.invalidate('phantom'), 0);
    });
  });

  group('purgeExpired', () {
    test('removes only entries whose TTL has elapsed', () async {
      await dao.markFresh('short', ttl: const Duration(minutes: 1));
      await dao.markFresh('long',  ttl: const Duration(hours: 1));

      // Drift past the short TTL but not the long one.
      fakeNow = fakeNow.add(const Duration(minutes: 5));

      final removed = await dao.purgeExpired();
      expect(removed, 1);
      expect(await dao.isFresh('short'), isFalse);
      expect(await dao.isFresh('long'), isTrue);
      expect(await dao.count(), 1);
    });

    test('is a no-op when nothing has expired', () async {
      await dao.markFresh('a', ttl: const Duration(hours: 1));

      final removed = await dao.purgeExpired();
      expect(removed, 0);
      expect(await dao.count(), 1);
    });

    test('drops every row when everything has expired', () async {
      await dao.markFresh('a', ttl: const Duration(seconds: 30));
      await dao.markFresh('b', ttl: const Duration(seconds: 30));

      fakeNow = fakeNow.add(const Duration(minutes: 2));
      expect(await dao.purgeExpired(), 2);
      expect(await dao.count(), 0);
    });
  });
}
