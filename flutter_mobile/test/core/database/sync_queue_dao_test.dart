import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/database/sync_queue_dao.dart';
import 'package:erp_mobile/core/sync/sync_op_status.dart';
import 'package:erp_mobile/core/sync/sync_op_type.dart';
import 'package:test/test.dart';

const _entityType = 'invoice';
const _payload = '{"total":100}';
const _method = 'POST';
const _path = '/api/v1/invoices';

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late SyncQueueDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 12, 9, 0, 0);
    dao = SyncQueueDao(db, clock: () => fakeNow);
  });

  tearDown(() => db.close());

  Future<String> enqueueDefault({
    String entityId = 'inv-1',
    SyncOpType op = SyncOpType.create,
  }) =>
      dao.enqueue(
        entityType: _entityType,
        entityId: entityId,
        operation: op,
        payloadJson: _payload,
        endpointMethod: _method,
        endpointPath: _path,
      );

  group('enqueue', () {
    test('returns a non-empty uuid and stores a pending row', () async {
      final id = await enqueueDefault();
      expect(id, isNotEmpty);

      final all = await dao.findAll();
      expect(all, hasLength(1));
      final row = all.single;
      expect(row.id, id);
      expect(row.entityType, _entityType);
      expect(row.entityId, 'inv-1');
      expect(row.operation, SyncOpType.create);
      expect(row.payloadJson, _payload);
      expect(row.endpointMethod, _method);
      expect(row.endpointPath, _path);
      expect(row.status, SyncOpStatus.pending);
      expect(row.attempts, 0);
      expect(row.lastAttemptAt, isNull);
      expect(row.nextAttemptAt, isNull);
      expect(row.lastError, isNull);
      expect(row.idempotencyKey, isNotEmpty);
    });

    test('assigns a distinct idempotency key to every row', () async {
      final id1 = await enqueueDefault(entityId: 'a');
      final id2 = await enqueueDefault(entityId: 'b');

      final rows = await dao.findAll();
      final byId = {for (final r in rows) r.id: r};
      expect(byId[id1]!.idempotencyKey, isNot(byId[id2]!.idempotencyKey));
    });
  });

  group('pendingReady', () {
    test('returns ops in FIFO order by createdAt', () async {
      final a = await enqueueDefault(entityId: 'a');

      // Advance the clock before the next enqueue so createdAt orders them.
      fakeNow = fakeNow.add(const Duration(seconds: 1));
      final b = await enqueueDefault(entityId: 'b');

      fakeNow = fakeNow.add(const Duration(seconds: 1));
      final c = await enqueueDefault(entityId: 'c');

      final ready = await dao.pendingReady();
      expect(ready.map((r) => r.id), [a, b, c]);
    });

    test('hides ops whose nextAttemptAt is in the future', () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);
      await dao.markFailed(
        id,
        error: 'boom',
        backoff: const Duration(minutes: 5),
      );

      // Still inside the backoff window — not ready.
      fakeNow = fakeNow.add(const Duration(minutes: 1));
      expect(await dao.pendingReady(), isEmpty);

      // Backoff elapsed — ready again.
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      final ready = await dao.pendingReady();
      expect(ready.map((r) => r.id), [id]);
    });

    test('only surfaces rows in pending status', () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);
      expect(await dao.pendingReady(), isEmpty);
    });
  });

  group('markInFlight (atomic claim)', () {
    test('the first call wins, the second call returns false', () async {
      final id = await enqueueDefault();
      expect(await dao.markInFlight(id), isTrue);
      expect(await dao.markInFlight(id), isFalse);
    });

    test('claim sets lastAttemptAt to the injected clock', () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);

      final row = (await dao.findAll()).single;
      expect(row.status, SyncOpStatus.inFlight);
      expect(row.lastAttemptAt, isNotNull);
      // Stored as Unix seconds — match by epoch second.
      expect(
        row.lastAttemptAt!.millisecondsSinceEpoch ~/ 1000,
        fakeNow.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('does not bump attempts (those are only bumped on failure)',
        () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);
      final row = (await dao.findAll()).single;
      expect(row.attempts, 0);
    });
  });

  group('markCompleted', () {
    test('removes the row and returns 1', () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);

      expect(await dao.markCompleted(id), 1);
      expect(await dao.findAll(), isEmpty);
    });

    test('returns 0 when the id is absent', () async {
      expect(await dao.markCompleted('phantom'), 0);
    });
  });

  group('markFailed', () {
    test('flips status back to pending, bumps attempts, records error',
        () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);
      await dao.markFailed(id, error: '503 server error');

      final row = (await dao.findAll()).single;
      expect(row.status, SyncOpStatus.pending);
      expect(row.attempts, 1);
      expect(row.lastError, '503 server error');
      expect(row.nextAttemptAt, isNull,
          reason: 'no backoff means immediately retryable');
    });

    test('schedules nextAttemptAt when a backoff is supplied', () async {
      final id = await enqueueDefault();
      await dao.markInFlight(id);
      await dao.markFailed(
        id,
        error: 'rate limited',
        backoff: const Duration(seconds: 30),
      );

      final row = (await dao.findAll()).single;
      expect(row.nextAttemptAt, isNotNull);
      expect(
        row.nextAttemptAt!.millisecondsSinceEpoch ~/ 1000,
        (fakeNow.millisecondsSinceEpoch ~/ 1000) + 30,
      );
    });

    test('multiple failures keep bumping the attempt counter', () async {
      final id = await enqueueDefault();
      for (var i = 0; i < 3; i++) {
        await dao.markInFlight(id);
        await dao.markFailed(id, error: 'try $i');
      }
      final row = (await dao.findAll()).single;
      expect(row.attempts, 3);
      expect(row.lastError, 'try 2');
    });

    test('on missing id, is a no-op (does not throw)', () async {
      await dao.markFailed('phantom', error: 'whatever');
      // Reaching here without an exception is the assertion.
    });
  });

  group('pendingCount + watchPendingCount', () {
    test('reflects only rows currently in pending status', () async {
      expect(await dao.pendingCount(), 0);

      final id = await enqueueDefault();
      expect(await dao.pendingCount(), 1);

      await dao.markInFlight(id);
      expect(await dao.pendingCount(), 0,
          reason: 'in-flight rows are not pending');

      await dao.markFailed(id, error: 'x');
      expect(await dao.pendingCount(), 1,
          reason: 'failure flips back to pending');

      await dao.markInFlight(id);
      await dao.markCompleted(id);
      expect(await dao.pendingCount(), 0);
    });

    test('watchPendingCount emits as the queue evolves', () async {
      final emitted = <int>[];
      final sub = dao.watchPendingCount().listen(emitted.add);

      await pumpEventQueue();
      final a = await enqueueDefault(entityId: 'a');
      await pumpEventQueue();
      final b = await enqueueDefault(entityId: 'b');
      await pumpEventQueue();
      await dao.markInFlight(a);
      await pumpEventQueue();
      await dao.markCompleted(a);
      await pumpEventQueue();
      await dao.markInFlight(b);
      await dao.markCompleted(b);
      await pumpEventQueue();

      await sub.cancel();

      expect(emitted.first, 0);
      expect(emitted, contains(1));
      expect(emitted, contains(2));
      expect(emitted.last, 0);
    });
  });
}
