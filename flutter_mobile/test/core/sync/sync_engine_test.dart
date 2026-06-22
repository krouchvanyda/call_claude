import 'dart:async';

import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/database/sync_queue_dao.dart';
import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/core/network/connectivity_checker.dart';
import 'package:erp_mobile/core/sync/backoff_strategy.dart';
import 'package:erp_mobile/core/sync/sync_engine.dart';
import 'package:erp_mobile/core/sync/sync_event.dart';
import 'package:erp_mobile/core/sync/sync_op_executor.dart';
import 'package:erp_mobile/core/sync/sync_op_status.dart';
import 'package:erp_mobile/core/sync/sync_op_type.dart';
import 'package:test/test.dart';

// ── Test doubles ────────────────────────────────────────────────────
class _FakeExecutor implements SyncOpExecutor {
  _FakeExecutor(this._respond);

  /// Maps op id → behaviour. Default (missing entry): success.
  final Future<void> Function(String id) _respond;

  final received = <String>[];

  @override
  Future<void> execute(SyncQueueRow op) async {
    received.add(op.id);
    return _respond(op.id);
  }
}

class _FakeConnectivity implements ConnectivityChecker {
  _FakeConnectivity({bool initial = true}) : _online = initial;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  void emit(bool value) {
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  Future<void> dispose() => _controller.close();
}

// ── Helpers ─────────────────────────────────────────────────────────
Future<String> _enqueue(SyncQueueDao dao, {String entityId = 'a'}) =>
    dao.enqueue(
      entityType: 'invoice',
      entityId: entityId,
      operation: SyncOpType.create,
      payloadJson: '{"x":1}',
      endpointMethod: 'POST',
      endpointPath: '/api/v1/invoices',
    );

void main() {
  late AppDatabase db;
  late SyncQueueDao queue;
  late _FakeConnectivity connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = SyncQueueDao(db);
    connectivity = _FakeConnectivity();
  });

  tearDown(() async {
    await connectivity.dispose();
    await db.close();
  });

  group('triggerSync — empty queue', () {
    test('emits drainStarted then drainCompleted(0,0)', () async {
      final engine = SyncEngine(
        queue: queue,
        executor: _FakeExecutor((_) async {}),
        connectivity: connectivity,
      );
      addTearDown(engine.dispose);

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.triggerSync();
      // Broadcast streams deliver via microtasks — let the listener catch up.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, hasLength(2));
      expect(events.first, isA<SyncEventDrainStarted>());
      expect(
        events.last,
        const SyncEvent.drainCompleted(processed: 0, failed: 0),
      );
    });
  });

  group('triggerSync — single op success', () {
    test('executor receives the op, row is removed, success event fires',
        () async {
      final id = await _enqueue(queue);
      final executor = _FakeExecutor((_) async {});
      final engine = SyncEngine(
        queue: queue,
        executor: executor,
        connectivity: connectivity,
      );
      addTearDown(engine.dispose);

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.triggerSync();
      // Broadcast streams deliver via microtasks — let the listener catch up.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(executor.received, [id]);
      expect(await queue.findAll(), isEmpty,
          reason: 'success deletes the row');
      expect(events, contains(SyncEvent.opSucceeded(id: id)));
      expect(events.last,
          const SyncEvent.drainCompleted(processed: 1, failed: 0));
    });
  });

  group('triggerSync — transient failure', () {
    test('flips back to pending with backoff scheduled and willRetry=true',
        () async {
      final id = await _enqueue(queue);
      final engine = SyncEngine(
        queue: queue,
        executor: _FakeExecutor((_) async => throw const NetworkFailure()),
        connectivity: connectivity,
        backoff: const ExponentialBackoff(base: Duration(seconds: 1)),
      );
      addTearDown(engine.dispose);

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.triggerSync();
      // Broadcast streams deliver via microtasks — let the listener catch up.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final row = (await queue.findAll()).single;
      expect(row.status, SyncOpStatus.pending);
      expect(row.attempts, 1);
      expect(row.lastError, contains('Failure.network'));
      expect(row.nextAttemptAt, isNotNull);

      final failEvent = events.whereType<SyncEventOpFailed>().single;
      expect(failEvent.id, id);
      expect(failEvent.willRetry, isTrue);
      expect(events.last,
          const SyncEvent.drainCompleted(processed: 0, failed: 0));
    });

    test('RateLimitFailure backoff honours retryAfter when present',
        () async {
      final id = await _enqueue(queue);
      final engine = SyncEngine(
        queue: queue,
        executor: _FakeExecutor((_) async => throw const RateLimitFailure(
              retryAfter: Duration(seconds: 90),
            )),
        connectivity: connectivity,
        // Generous default would dwarf 90s — proves the override path.
        backoff: const ExponentialBackoff(base: Duration(seconds: 1)),
      );
      addTearDown(engine.dispose);

      await engine.triggerSync();

      final row = (await queue.findAll()).single;
      // Created at ~now in setUp; verify the gap between createdAt and
      // nextAttemptAt is ~90s.
      final delaySeconds = row.nextAttemptAt!.millisecondsSinceEpoch ~/ 1000 -
          row.createdAt.millisecondsSinceEpoch ~/ 1000;
      expect(delaySeconds, greaterThanOrEqualTo(89));
      expect(delaySeconds, lessThanOrEqualTo(91));
      expect(id, isNotEmpty); // sanity touch on the captured id
    });
  });

  group('triggerSync — permanent failure', () {
    test('marks dead-letter, willRetry=false, row remains in failed status',
        () async {
      final id = await _enqueue(queue);
      final engine = SyncEngine(
        queue: queue,
        executor: _FakeExecutor((_) async => throw const ValidationFailure()),
        connectivity: connectivity,
      );
      addTearDown(engine.dispose);

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.triggerSync();
      // Broadcast streams deliver via microtasks — let the listener catch up.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final row = (await queue.findAll()).single;
      expect(row.id, id);
      expect(row.status, SyncOpStatus.failed);
      expect(row.lastError, contains('Failure.validation'));

      final failEvent = events.whereType<SyncEventOpFailed>().single;
      expect(failEvent.willRetry, isFalse);
      expect(events.last,
          const SyncEvent.drainCompleted(processed: 0, failed: 1));
    });
  });

  group('triggerSync — max attempts', () {
    test('after maxAttempts transient failures, op is dead-lettered',
        () async {
      final id = await _enqueue(queue);
      // Pre-bake the row so attempts is right at the cap minus one.
      await queue.markInFlight(id);
      await queue.markFailed(id, error: 'previous');
      await queue.markFailed(id, error: 'previous');
      // Two failures + the upcoming third = 3. Use maxAttempts: 3.

      final engine = SyncEngine(
        queue: queue,
        executor: _FakeExecutor((_) async => throw const NetworkFailure()),
        connectivity: connectivity,
        maxAttempts: 3,
      );
      addTearDown(engine.dispose);

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.triggerSync();
      // Broadcast streams deliver via microtasks — let the listener catch up.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final row = (await queue.findAll()).single;
      expect(row.status, SyncOpStatus.failed,
          reason: 'budget exhausted → dead-letter');
      expect(events.whereType<SyncEventOpFailed>().single.willRetry, isFalse);
    });
  });

  group('concurrent triggerSync', () {
    test('three simultaneous triggers fold into one drain', () async {
      var executions = 0;
      final executor = _FakeExecutor((_) async {
        executions++;
      });
      await _enqueue(queue, entityId: 'a');
      await _enqueue(queue, entityId: 'b');
      await _enqueue(queue, entityId: 'c');

      final engine = SyncEngine(
        queue: queue,
        executor: executor,
        connectivity: connectivity,
      );
      addTearDown(engine.dispose);

      // Three calls to triggerSync, no awaits between them.
      final futures = <Future<void>>[
        engine.triggerSync(),
        engine.triggerSync(),
        engine.triggerSync(),
      ];
      await Future.wait(futures);

      expect(executions, 3,
          reason: 'each op runs exactly once across the three triggers');
      expect(await queue.findAll(), isEmpty);
    });
  });

  group('start() — connectivity-driven', () {
    test('online emission triggers a drain that processes pending ops',
        () async {
      final id = await _enqueue(queue);
      final executor = _FakeExecutor((_) async {});

      final engine = SyncEngine(
        queue: queue,
        executor: executor,
        connectivity: connectivity,
      )..start();
      addTearDown(engine.dispose);

      // Wait until the engine settles after the connectivity event.
      final completed = engine.events
          .firstWhere((e) => e is SyncEventDrainCompleted);
      connectivity.emit(true);
      await completed;

      expect(executor.received, [id]);
      expect(await queue.findAll(), isEmpty);
    });

    test('offline emissions do not trigger drains', () async {
      final executor = _FakeExecutor((_) async {});
      final engine = SyncEngine(
        queue: queue,
        executor: executor,
        connectivity: connectivity,
      )..start();
      addTearDown(engine.dispose);

      await _enqueue(queue);
      connectivity.emit(false);
      // Allow microtasks to drain.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(executor.received, isEmpty);
      expect(await queue.findAll(), hasLength(1));
    });

    test('start() is idempotent — second call is a no-op', () async {
      final engine = SyncEngine(
        queue: queue,
        executor: _FakeExecutor((_) async {}),
        connectivity: connectivity,
      )
        ..start()
        ..start();
      addTearDown(engine.dispose);

      // If both subscriptions fired we'd see two drains for one online emit;
      // a single completion event proves we attached only once.
      var completions = 0;
      final sub = engine.events.listen((e) {
        if (e is SyncEventDrainCompleted) completions++;
      });

      connectivity.emit(true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await sub.cancel();

      expect(completions, 1);
    });
  });
}
