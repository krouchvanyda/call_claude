import 'package:drift/drift.dart';

import '../sync/sync_op_status.dart';
import '../sync/sync_op_type.dart';
import '../utils/clock.dart';
import 'app_database.dart';
import 'base_dao.dart';
import 'tables/sync_queue.dart';

part 'sync_queue_dao.g.dart';

/// Persistent FIFO queue of pending mutations.
///
/// Producers (repositories) call [enqueue] inside the same drift transaction
/// that performs the optimistic local write. The consumer (sync engine, in
/// Slice 0.4.3) drains via [pendingReady] → [markInFlight] → either
/// [markCompleted] on success or [markFailed] for retry.
///
/// State machine:
/// ```
///   pending ──claim──▶ inFlight ──success──▶ (deleted)
///      ▲                  │
///      └─── failure ──────┘  (with attempts++ and optional backoff)
/// ```
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends BaseDao<SyncQueue, SyncQueueRow>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db, {Clock? clock}) : _now = clock ?? DateTime.now;

  final Clock _now;

  @override
  TableInfo<SyncQueue, SyncQueueRow> get table => syncQueue;

  // ── Producer side ────────────────────────────────────────────
  /// Append a new pending op. Returns the assigned [SyncQueueRow.id].
  Future<String> enqueue({
    required String entityType,
    required String entityId,
    required SyncOpType operation,
    required String payloadJson,
    required String endpointMethod,
    required String endpointPath,
  }) async {
    final inserted = await into(syncQueue).insertReturning(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: payloadJson,
        endpointMethod: endpointMethod,
        endpointPath: endpointPath,
      ),
    );
    return inserted.id;
  }

  // ── Consumer side ────────────────────────────────────────────
  /// All ops that are currently pending **and** eligible to fire now —
  /// i.e. their `nextAttemptAt` is null or in the past. FIFO by `createdAt`.
  Future<List<SyncQueueRow>> pendingReady() {
    final now = _now();
    return (select(syncQueue)
          ..where((r) =>
              r.status.equalsValue(SyncOpStatus.pending) &
              (r.nextAttemptAt.isNull() |
                  r.nextAttemptAt.isSmallerOrEqualValue(now)))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .get();
  }

  /// Atomic claim: flip a pending op to `inFlight` only if the row is still
  /// in `pending`. Returns `true` on a successful claim, `false` when the
  /// row was already taken by another worker (or deleted, or failed-out).
  Future<bool> markInFlight(String id) async {
    final updated = await (update(syncQueue)
          ..where((r) =>
              r.id.equals(id) &
              r.status.equalsValue(SyncOpStatus.pending)))
        .write(SyncQueueCompanion(
      status: const Value(SyncOpStatus.inFlight),
      lastAttemptAt: Value(_now()),
    ));
    return updated == 1;
  }

  /// Successful sync — drop the row.
  Future<int> markCompleted(String id) =>
      (delete(syncQueue)..where((r) => r.id.equals(id))).go();

  /// Permanent failure — flip to terminal `failed` state without scheduling
  /// a retry. The row is kept (rather than deleted like success) so the
  /// dead-letter UI (future slice) can surface what went wrong.
  Future<int> markDeadLetter(String id, {required String error}) {
    final now = _now();
    return (update(syncQueue)..where((r) => r.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value(SyncOpStatus.failed),
        lastError: Value(error),
        lastAttemptAt: Value(now),
      ),
    );
  }

  /// Failure path: bump [SyncQueueRow.attempts], persist the error, schedule
  /// the next attempt (if [backoff] supplied) and flip status back to
  /// `pending` so the row resurfaces in [pendingReady] when the backoff
  /// elapses.
  Future<void> markFailed(
    String id, {
    required String error,
    Duration? backoff,
  }) async {
    final row = await (select(syncQueue)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    final now = _now();
    await (update(syncQueue)..where((r) => r.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value(SyncOpStatus.pending),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
        lastAttemptAt: Value(now),
        nextAttemptAt:
            backoff == null ? const Value(null) : Value(now.add(backoff)),
      ),
    );
  }

  // ── Observation ──────────────────────────────────────────────
  /// Live count of rows still in `pending` status (regardless of
  /// `nextAttemptAt`). Drives the SyncBloc badge in Slice 0.4.4.
  Stream<int> watchPendingCount() {
    final countExpr = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExpr])
      ..where(syncQueue.status.equalsValue(SyncOpStatus.pending));
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }

  Future<int> pendingCount() async {
    final countExpr = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExpr])
      ..where(syncQueue.status.equalsValue(SyncOpStatus.pending));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }
}
