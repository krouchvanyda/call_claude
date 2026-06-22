import 'dart:async';

import 'package:erp_mobile/core/push/local_push_simulator.dart';
import 'package:erp_mobile/core/push/push_message.dart';
import 'package:erp_mobile/core/push/push_message_router.dart';
import 'package:erp_mobile/core/push/push_token_storage.dart';
import 'package:erp_mobile/core/utils/logger/app_logger.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:erp_mobile/features/notifications/domain/entities/notification.dart';
import 'package:erp_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:test/test.dart';

class _NoopLogger extends AppLogger {
  @override
  void log(LogLevel level, String message,
      {Object? error,
      StackTrace? stackTrace,
      Map<String, Object?>? context}) {}
}

class _RecordingRepo implements NotificationsRepository {
  final upserts = <AppNotification>[];

  @override
  Future<void> upsert(AppNotification notification) async {
    upserts.add(notification);
  }

  @override
  Stream<List<AppNotification>> watchInbox() => const Stream.empty();

  @override
  Future<List<AppNotification>> getInbox() async => const [];

  @override
  Stream<int> watchUnreadCount() => const Stream.empty();

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> dismiss(String id) async {}

  @override
  Future<void> wipeAll() async {}
}

class _FakeTokenStorage implements PushTokenStorage {
  String? saved;
  bool cleared = false;

  @override
  Future<String?> readToken() async => saved;

  @override
  Future<void> saveToken(String token) async {
    saved = token;
  }

  @override
  Future<void> clear() async {
    saved = null;
    cleared = true;
  }
}

void main() {
  group('PushMessageRouter.mapToNotification (pure mapping)', () {
    test('reads category + route + path params from data map convention',
        () {
      final n = PushMessageRouter.mapToNotification(const PushMessage(
        id: 'srv-1',
        title: 'Invoice approved',
        body: 'INV-001 approved',
        data: {
          'category': 'invoice',
          'route': 'invoiceDetail',
          'route.id': 'INV-001',
          'route.tab': 'history',
        },
      ));

      expect(n.id, 'srv-1');
      expect(n.title, 'Invoice approved');
      expect(n.body, 'INV-001 approved');
      expect(n.category, 'invoice');
      expect(n.routeName, 'invoiceDetail');
      expect(n.pathParameters, {'id': 'INV-001', 'tab': 'history'});
    });

    test('missing category defaults to "system"', () {
      final n = PushMessageRouter.mapToNotification(
        const PushMessage(title: 't', body: 'b'),
      );
      expect(n.category, 'system');
      expect(n.routeName, isNull);
      expect(n.pathParameters, isEmpty);
    });

    test('null id triggers a generated UUID (so dedupe still works)', () {
      final a = PushMessageRouter.mapToNotification(
        const PushMessage(title: 't', body: 'b'),
      );
      final b = PushMessageRouter.mapToNotification(
        const PushMessage(title: 't', body: 'b'),
      );
      expect(a.id, isNotEmpty);
      expect(b.id, isNotEmpty);
      expect(a.id, isNot(b.id),
          reason: 'two id-less messages must get distinct UUIDs');
    });

    test('null sentAt falls back to "now" so ordering still works', () {
      final before = DateTime.now().toUtc();
      final n = PushMessageRouter.mapToNotification(
        const PushMessage(title: 't', body: 'b'),
      );
      final after = DateTime.now().toUtc();
      expect(n.receivedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(n.receivedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
    });

    test('empty "route." key (just the prefix) is ignored', () {
      final n = PushMessageRouter.mapToNotification(const PushMessage(
        title: 't',
        body: 'b',
        data: {'route.': 'should-be-ignored'},
      ));
      expect(n.pathParameters, isEmpty);
    });
  });

  group('PushMessageRouter.start / handle', () {
    test(
        'start initialises the service, persists the token, and routes '
        'inbound messages to the repo',
        () async {
      final svc = LocalPushSimulator();
      final repo = _RecordingRepo();
      final tokens = _FakeTokenStorage();
      final router = PushMessageRouter(
        service: svc,
        notifications: repo,
        tokenStorage: tokens,
        logger: _NoopLogger(),
      );

      await router.start();
      expect(tokens.saved, isNotNull,
          reason: 'simulator seeds a synthetic token at init time');

      svc.simulateNow(title: 'Hello', body: 'World');
      await pumpEventQueue();

      expect(repo.upserts, hasLength(1));
      expect(repo.upserts.single.title, 'Hello');
      expect(repo.upserts.single.body, 'World');
    });

    test('start is idempotent — second call does not re-subscribe', () async {
      final svc = LocalPushSimulator();
      final repo = _RecordingRepo();
      final router = PushMessageRouter(
        service: svc,
        notifications: repo,
        tokenStorage: _FakeTokenStorage(),
        logger: _NoopLogger(),
      );

      await router.start();
      await router.start();

      svc.simulateNow(title: 't', body: 'b');
      await pumpEventQueue();

      expect(repo.upserts, hasLength(1),
          reason: 'second start must NOT cause duplicate handling');
    });

    test('handle dedupes by id — same id arriving twice writes once',
        () async {
      final svc = LocalPushSimulator();
      final repo = _RecordingRepo();
      final router = PushMessageRouter(
        service: svc,
        notifications: repo,
        tokenStorage: _FakeTokenStorage(),
        logger: _NoopLogger(),
      );

      await router.start();
      await router.handle(const PushMessage(
        id: 'dup',
        title: 't',
        body: 'b',
      ));
      await router.handle(const PushMessage(
        id: 'dup',
        title: 't (resent)',
        body: 'b',
      ));

      expect(repo.upserts, hasLength(1));
    });

    test('handle treats messages with distinct ids as distinct', () async {
      final svc = LocalPushSimulator();
      final repo = _RecordingRepo();
      final router = PushMessageRouter(
        service: svc,
        notifications: repo,
        tokenStorage: _FakeTokenStorage(),
        logger: _NoopLogger(),
      );

      await router.start();
      await router.handle(const PushMessage(id: 'a', title: 't', body: 'b'));
      await router.handle(const PushMessage(id: 'b', title: 't', body: 'b'));
      expect(repo.upserts, hasLength(2));
    });

    test('token rotation is persisted', () async {
      final svc = LocalPushSimulator();
      final repo = _RecordingRepo();
      final tokens = _FakeTokenStorage();
      final router = PushMessageRouter(
        service: svc,
        notifications: repo,
        tokenStorage: tokens,
        logger: _NoopLogger(),
      );
      await router.start();

      svc.simulateTokenRefresh('rotated-token-xyz');
      await pumpEventQueue();
      expect(tokens.saved, 'rotated-token-xyz');
    });

    test('stop clears the dedupe set so the next session is fresh', () async {
      final svc = LocalPushSimulator();
      final repo = _RecordingRepo();
      final router = PushMessageRouter(
        service: svc,
        notifications: repo,
        tokenStorage: _FakeTokenStorage(),
        logger: _NoopLogger(),
      );

      await router.start();
      await router.handle(const PushMessage(id: 'x', title: 't', body: 'b'));
      expect(repo.upserts, hasLength(1));

      await router.stop();
      await router.start();

      // Same id, but the dedupe set was cleared — must write again.
      await router.handle(const PushMessage(id: 'x', title: 't', body: 'b'));
      expect(repo.upserts, hasLength(2));
    });
  });
}
