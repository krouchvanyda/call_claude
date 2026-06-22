import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/failure.dart';
import 'sync_status.dart';

part 'sync_state.freezed.dart';

/// UI-facing snapshot the [SyncBloc] holds in its current state.
///
/// Single class (instead of a sealed union per status) because each status
/// carries the same shared fields — `pendingCount`, `lastSucceededAt`,
/// `lastError`. The convenience getters (`isSyncing`, `hasError`) keep
/// widget code readable.
@freezed
class SyncState with _$SyncState {
  const factory SyncState({
    @Default(SyncStatus.idle) SyncStatus status,
    @Default(0) int pendingCount,

    /// When the most recent drain completed with at least one successful op.
    /// Null until the first such drain.
    DateTime? lastSucceededAt,

    /// The last failure surfaced by the engine in the current "attention
    /// window" — populated by `opFailed` / `drainAborted` events and
    /// cleared at the start of a new drain or after a fully-successful one.
    Failure? lastError,
  }) = _SyncState;

  const SyncState._();

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isIdle => status == SyncStatus.idle;
  bool get hasError => status == SyncStatus.error;

  /// True when there are queued operations waiting to be sent.
  bool get hasPendingWork => pendingCount > 0;
}
