import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:erp_mobile/features/notifications/domain/entities/notification.dart';
import 'package:erp_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:erp_mobile/features/notifications/presentation/bloc/notification_inbox_bloc.dart';
import 'package:erp_mobile/features/notifications/presentation/bloc/notification_inbox_event.dart';
import 'package:erp_mobile/features/notifications/presentation/bloc/notification_inbox_state.dart';
import 'package:test/test.dart';

/// In-memory fake — captures writes and pumps the watch stream by hand
/// so tests control the timing precisely.
class _FakeRepo implements NotificationsRepository {
  final _ctrl = StreamController<List<AppNotification>>.broadcast();
  final markedRead = <String>[];
  int markAllReadCalls = 0;
  final dismissed = <String>[];

  /// Push a snapshot to subscribers.
  void emit(List<AppNotification> snapshot) => _ctrl.add(snapshot);

  /// Push an error to subscribers.
  void emitError(Object e) => _ctrl.addError(e);

  @override
  Stream<List<AppNotification>> watchInbox() => _ctrl.stream;

  @override
  Future<List<AppNotification>> getInbox() async => const [];

  @override
  Stream<int> watchUnreadCount() => const Stream.empty();

  @override
  Future<void> upsert(AppNotification notification) async {}

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCalls++;
  }

  @override
  Future<void> dismiss(String id) async {
    dismissed.add(id);
  }

  @override
  Future<void> wipeAll() async {}

  Future<void> close() => _ctrl.close();
}

AppNotification _n(String id, {DateTime? readAt}) => AppNotification(
      id: id,
      title: 't-$id',
      body: 'b-$id',
      category: 'system',
      receivedAt: DateTime.utc(2026, 1, 1),
      readAt: readAt,
    );

void main() {
  late _FakeRepo repo;

  setUp(() => repo = _FakeRepo());
  tearDown(() => repo.close());

  group('NotificationInboxBloc', () {
    test('initial state is Initial (no subscription before Started)', () {
      final bloc = NotificationInboxBloc(repository: repo);
      expect(bloc.state, const NotificationInboxState.initial());
    });

    blocTest<NotificationInboxBloc, NotificationInboxState>(
      'Started → Loading then Loaded on first snapshot; unreadCount derived',
      build: () => NotificationInboxBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const NotificationInboxEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([
          _n('a'),
          _n('b', readAt: DateTime.utc(2026, 1, 2)),
          _n('c'),
        ]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const NotificationInboxState.loading(),
        isA<NotificationInboxLoaded>()
            .having((s) => s.notifications.length, 'count', 3)
            .having((s) => s.unreadCount, 'unread', 2),
      ],
    );

    blocTest<NotificationInboxBloc, NotificationInboxState>(
      'Started is idempotent — second Started does not double-subscribe',
      build: () => NotificationInboxBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const NotificationInboxEvent.started());
        bloc.add(const NotificationInboxEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([_n('a')]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const NotificationInboxState.loading(),
        isA<NotificationInboxLoaded>()
            .having((s) => s.notifications, 'list', hasLength(1)),
      ],
    );

    blocTest<NotificationInboxBloc, NotificationInboxState>(
      'MarkedRead delegates to the repo (no direct emit; relies on '
      'subsequent watch tick)',
      build: () => NotificationInboxBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const NotificationInboxEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([_n('a'), _n('b')]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationInboxEvent.markedRead('a'));
        await Future<void>.delayed(Duration.zero);
        // Repo would now write & re-emit; simulate the new snapshot.
        repo.emit([_n('a', readAt: DateTime.utc(2026, 5, 1)), _n('b')]);
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        expect(repo.markedRead, ['a']);
      },
      expect: () => [
        const NotificationInboxState.loading(),
        isA<NotificationInboxLoaded>()
            .having((s) => s.unreadCount, 'unread before', 2),
        isA<NotificationInboxLoaded>()
            .having((s) => s.unreadCount, 'unread after', 1),
      ],
    );

    blocTest<NotificationInboxBloc, NotificationInboxState>(
      'MarkedAllRead delegates once to the repo',
      build: () => NotificationInboxBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const NotificationInboxEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([_n('a'), _n('b'), _n('c')]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationInboxEvent.markedAllRead());
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) => expect(repo.markAllReadCalls, 1),
    );

    blocTest<NotificationInboxBloc, NotificationInboxState>(
      'Dismissed delegates to the repo',
      build: () => NotificationInboxBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const NotificationInboxEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([_n('a')]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationInboxEvent.dismissed('a'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) => expect(repo.dismissed, ['a']),
    );

    blocTest<NotificationInboxBloc, NotificationInboxState>(
      'watch error → Failure (typed state, not unhandled exception)',
      build: () => NotificationInboxBloc(repository: repo),
      act: (bloc) async {
        bloc.add(const NotificationInboxEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emitError(StateError('drift exploded'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const NotificationInboxState.loading(),
        isA<NotificationInboxFailure>()
            .having((s) => s.message, 'message', contains('drift exploded')),
      ],
    );
  });
}
