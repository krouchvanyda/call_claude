import 'dart:async';

import '../database/app_database.dart' show SyncQueueRow;
import '../database/sync_queue_dao.dart';
import '../error/failure.dart';
import '../network/connectivity_checker.dart';
import 'backoff_strategy.dart';
import 'retry_policy.dart';
import 'sync_event.dart';
import 'sync_op_executor.dart';

/// Drains the [SyncQueueDao] against the server, with retry/backoff,
/// per-failure routing, and an auto-trigger on connectivity restore.
///
/// Designed to be the *only* path that processes queued mutations — any
/// caller (BLoC, debug UI, test) goes through [triggerSync]. Concurrent
/// triggers fold into a single in-flight drain so the queue is never
/// processed by two workers at once.
class SyncEngine {
  SyncEngine({
    required SyncQueueDao queue,
    required SyncOpExecutor executor,
    required ConnectivityChecker connectivity,
    BackoffStrategy backoff = const ExponentialBackoff(),
    RetryPolicy retryPolicy = const DefaultRetryPolicy(),
    int maxAttempts = 10,
    int maxDrainIterations = 50,
  })  : _queue = queue,
        _executor = executor,
        _connectivity = connectivity,
        _backoff = backoff,
        _retryPolicy = retryPolicy,
        _maxAttempts = maxAttempts,
        _maxDrainIterations = maxDrainIterations;

  final SyncQueueDao _queue;
  final SyncOpExecutor _executor;
  final ConnectivityChecker _connectivity;
  final BackoffStrategy _backoff;
  final RetryPolicy _retryPolicy;
  final int _maxAttempts;
  final int _maxDrainIterations;

  final StreamController<SyncEvent> _eventsController =
      StreamController<SyncEvent>.broadcast();

  StreamSubscription<bool>? _connectivitySub;
  Future<void>? _inFlightDrain;
  var _started = false;

  /// Granular progress events. Cold consumers won't miss anything emitted
  /// while subscribed; events fired before `listen()` are not replayed.
  Stream<SyncEvent> get events => _eventsController.stream;

  /// Begin listening to connectivity transitions. Subsequent online emissions
  /// kick off a drain. Idempotent — calling twice does nothing.
  void start() {
    if (_started) return;
    _started = true;
    _connectivitySub = _connectivity.onlineChanges.listen((online) {
      if (online) {
        unawaited(triggerSync());
      }
    });
  }

  /// Run a drain pass. Concurrent calls collapse to the same in-flight
  /// future, so it's safe to call from anywhere without locking.
  Future<void> triggerSync() {
    return _inFlightDrain ??=
        _drain().whenComplete(() => _inFlightDrain = null);
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _started = false;
    await _eventsController.close();
  }

  // ── internals ────────────────────────────────────────────────
  Future<void> _drain() async {
    _eventsController.add(const SyncEvent.drainStarted());
    var processed = 0;
    var failed = 0;

    for (var iteration = 0; iteration < _maxDrainIterations; iteration++) {
      final batch = await _queue.pendingReady();
      if (batch.isEmpty) {
        _eventsController.add(SyncEvent.drainCompleted(
          processed: processed,
          failed: failed,
        ));
        return;
      }

      for (final op in batch) {
        final claimed = await _queue.markInFlight(op.id);
        if (!claimed) continue;

        try {
          await _executor.execute(op);
          await _queue.markCompleted(op.id);
          processed++;
          _eventsController.add(SyncEvent.opSucceeded(id: op.id));
        } on Failure catch (failure) {
          final willRetry = await _handleFailure(op, failure);
          if (!willRetry) failed++;
          _eventsController.add(SyncEvent.opFailed(
            id: op.id,
            failure: failure,
            willRetry: willRetry,
          ));
        } catch (e) {
          // Non-typed exception bubbled past the executor — treat as
          // transient and let the retry budget decide.
          final failure = Failure.unknown(message: e.toString());
          final willRetry = await _handleFailure(op, failure);
          if (!willRetry) failed++;
          _eventsController.add(SyncEvent.opFailed(
            id: op.id,
            failure: failure,
            willRetry: willRetry,
          ));
        }
      }
    }

    _eventsController.add(SyncEvent.drainAborted(
      reason: 'maxDrainIterations ($_maxDrainIterations) exceeded',
    ));
  }

  /// Decides whether [op] gets requeued or written off. Returns true when
  /// the op was flipped back to pending with a backoff scheduled.
  Future<bool> _handleFailure(SyncQueueRow op, Failure failure) async {
    final attemptsAfter = op.attempts + 1;
    final decision = _retryPolicy.decide(failure);
    final budgetExhausted = attemptsAfter >= _maxAttempts;
    final willRetry = decision == RetryDecision.retry && !budgetExhausted;

    if (willRetry) {
      final backoff = failure is RateLimitFailure && failure.retryAfter != null
          ? failure.retryAfter!
          : _backoff.delayFor(attemptsAfter);
      await _queue.markFailed(
        op.id,
        error: failure.toString(),
        backoff: backoff,
      );
    } else {
      await _queue.markDeadLetter(op.id, error: failure.toString());
    }
    return willRetry;
  }
}
