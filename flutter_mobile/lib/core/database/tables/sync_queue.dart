import 'package:drift/drift.dart';

import '../../sync/sync_op_status.dart';
import '../../sync/sync_op_type.dart';
import '../../utils/uuid_generator.dart';

/// Queue of pending mutations awaiting transmission to the server.
///
/// One row per operation. The producer side (repositories) appends rows
/// inside the same drift transaction as the local-DB write so the user's
/// optimistic UI and the queued server intent stay consistent. The consumer
/// side (Slice 0.4.3 sync engine) drains it FIFO when connectivity returns.
///
/// Columns are deliberately wide enough to support the *later* slices —
/// retry/backoff (`attempts`, `nextAttemptAt`, `lastError`), idempotent
/// replay (`idempotencyKey`), and atomic claim (`status` + a single-statement
/// UPDATE) — so we don't have to migrate the table again immediately.
@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  /// Stable id; used as both primary key and audit reference.
  TextColumn get id => text().clientDefault(() => newUuid())();

  /// Domain entity name — e.g. `'invoice'`, `'customer'`. The sync engine
  /// uses it to dispatch to the right serialiser / endpoint.
  TextColumn get entityType => text()();

  /// The id of the affected entity. May be a client-generated UUID before
  /// the server has assigned a permanent id; the id-mapping rewrite is a
  /// future-slice concern.
  TextColumn get entityId => text()();

  TextColumn get operation => textEnum<SyncOpType>()();

  /// JSON body sent to the server, pre-serialised so the queue is opaque
  /// to the sync engine (no per-entity schema knowledge needed here).
  TextColumn get payloadJson => text()();

  /// HTTP verb (`'POST'`, `'PUT'`, `'PATCH'`, `'DELETE'`).
  TextColumn get endpointMethod => text()();

  /// Resolved request path including any path params — already templated.
  TextColumn get endpointPath => text()();

  /// Sent as `Idempotency-Key` request header. Lets the server collapse
  /// duplicate replays into a single side-effect when retries fire.
  TextColumn get idempotencyKey =>
      text().clientDefault(() => newUuid())();

  TextColumn get status => textEnum<SyncOpStatus>()
      .clientDefault(() => SyncOpStatus.pending.name)();

  /// Number of times the op has been attempted *and failed*. Bumped only on
  /// failure; successful ops are deleted instead.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Timestamp of the most recent attempt (success or failure). Null until
  /// the first claim.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Earliest moment a retry should fire — populated by the backoff
  /// strategy in Slice 0.4.3. Null means "ready immediately".
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  /// Last error message as a debugging aid; not consulted for retry
  /// decisions.
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
