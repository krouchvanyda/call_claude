import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/core/sync/sync_bloc.dart';
import 'package:erp_mobile/core/sync/sync_bloc_event.dart';
import 'package:erp_mobile/core/sync/sync_event.dart';
import 'package:erp_mobile/core/sync/sync_state.dart';
import 'package:erp_mobile/core/sync/sync_status.dart';
import 'package:test/test.dart';

// ── Fixtures ────────────────────────────────────────────────────────
final _fixedClock = DateTime.utc(2026, 5, 12, 9, 0, 0);

// Each test gets fresh controllers + a fresh trigger spy.
late StreamController<SyncEvent> engineEvents;
late StreamController<int> pendingCounts;
late int triggerCount;

SyncBloc _build() {
  triggerCount = 0;
  engineEvents = StreamController<SyncEvent>.broadcast();
  pendingCounts = StreamController<int>.broadcast();
  return SyncBloc(
    triggerSync: () async {
      triggerCount++;
    },
    engineEvents: engineEvents.stream,
    pendingCounts: pendingCounts.stream,
    clock: () => _fixedClock,
  );
}

Future<void> _close() async {
  await engineEvents.close();
  await pendingCounts.close();
}

void main() {
  group('SyncBloc — initial state', () {
    test('starts idle with pendingCount 0 and no error', () {
      final bloc = _build();
      addTearDown(() async {
        await bloc.close();
        await _close();
      });

      expect(bloc.state.status, SyncStatus.idle);
      expect(bloc.state.pendingCount, 0);
      expect(bloc.state.lastSucceededAt, isNull);
      expect(bloc.state.lastError, isNull);
      expect(bloc.state.isIdle, isTrue);
      expect(bloc.state.hasError, isFalse);
      expect(bloc.state.hasPendingWork, isFalse);
    });
  });

  group('SyncBloc — manual trigger', () {
    blocTest<SyncBloc, SyncState>(
      'triggerRequested calls the injected triggerSync exactly once',
      build: _build,
      act: (bloc) => bloc.add(const SyncBlocEvent.triggerRequested()),
      verify: (_) => expect(triggerCount, 1),
      tearDown: _close,
    );
  });

  group('SyncBloc — engine event folding', () {
    blocTest<SyncBloc, SyncState>(
      'drainStarted → status: syncing, lastError cleared',
      build: _build,
      seed: () => const SyncState(
        status: SyncStatus.error,
        lastError: NetworkFailure(message: 'previous failure'),
      ),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(SyncEvent.drainStarted()),
      ),
      expect: () => [
        const SyncState(status: SyncStatus.syncing),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'opSucceeded mid-drain does not change state',
      build: _build,
      seed: () => const SyncState(status: SyncStatus.syncing),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(
          SyncEvent.opSucceeded(id: 'x'),
        ),
      ),
      expect: () => const <SyncState>[],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'opFailed surfaces the failure mid-drain (status unchanged)',
      build: _build,
      seed: () => const SyncState(status: SyncStatus.syncing),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(
          SyncEvent.opFailed(
            id: 'x',
            failure: ServerFailure(statusCode: 503),
            willRetry: true,
          ),
        ),
      ),
      expect: () => [
        const SyncState(
          status: SyncStatus.syncing,
          lastError: ServerFailure(statusCode: 503),
        ),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'drainCompleted with all successes → idle, lastSucceededAt set, '
      'lastError cleared',
      build: _build,
      seed: () => const SyncState(
        status: SyncStatus.syncing,
        lastError: NetworkFailure(),
      ),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(
          SyncEvent.drainCompleted(processed: 3, failed: 0),
        ),
      ),
      expect: () => [
        SyncState(
          lastSucceededAt: _fixedClock,
        ),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'drainCompleted with any failure → status: error, lastError preserved',
      build: _build,
      seed: () => const SyncState(
        status: SyncStatus.syncing,
        lastError: ServerFailure(statusCode: 500),
      ),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(
          SyncEvent.drainCompleted(processed: 1, failed: 2),
        ),
      ),
      expect: () => [
        SyncState(
          status: SyncStatus.error,
          lastSucceededAt: _fixedClock,
          lastError: const ServerFailure(statusCode: 500),
        ),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'drainCompleted with 0 processed leaves lastSucceededAt untouched',
      build: _build,
      seed: () => SyncState(
        status: SyncStatus.syncing,
        lastSucceededAt: _fixedClock.subtract(const Duration(hours: 1)),
      ),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(
          SyncEvent.drainCompleted(processed: 0, failed: 0),
        ),
      ),
      expect: () => [
        SyncState(
          lastSucceededAt: _fixedClock.subtract(const Duration(hours: 1)),
        ),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'drainAborted → status: error, synthetic UnknownFailure carries reason',
      build: _build,
      seed: () => const SyncState(status: SyncStatus.syncing),
      act: (bloc) => bloc.add(
        const SyncBlocEvent.engineEventReceived(
          SyncEvent.drainAborted(reason: 'maxIterations'),
        ),
      ),
      expect: () => [
        const SyncState(
          status: SyncStatus.error,
          lastError: UnknownFailure(message: 'sync aborted: maxIterations'),
        ),
      ],
      tearDown: _close,
    );
  });

  group('SyncBloc — stream subscriptions', () {
    blocTest<SyncBloc, SyncState>(
      'engine event stream feeds engineEventReceived',
      build: _build,
      act: (bloc) async {
        engineEvents.add(const SyncEvent.drainStarted());
        // Yield so the stream listener forwards before the test ends.
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SyncState(status: SyncStatus.syncing),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'pendingCounts stream feeds pendingCountChanged',
      build: _build,
      act: (bloc) async {
        pendingCounts.add(7);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SyncState(pendingCount: 7),
      ],
      tearDown: _close,
    );

    blocTest<SyncBloc, SyncState>(
      'duplicate pending count does not emit (Bloc dedupes by equality)',
      build: _build,
      seed: () => const SyncState(pendingCount: 5),
      act: (bloc) async {
        pendingCounts.add(5);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const <SyncState>[],
      tearDown: _close,
    );
  });

  group('SyncBloc — close()', () {
    test('cancels both stream subscriptions', () async {
      final bloc = _build();

      await bloc.close();

      // After close, neither stream should still have a listener.
      expect(engineEvents.hasListener, isFalse);
      expect(pendingCounts.hasListener, isFalse);

      await _close();
    });
  });
}
