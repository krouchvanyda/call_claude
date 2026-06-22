import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/failure.dart';

part 'sync_event.freezed.dart';

/// Granular progress events emitted by the sync engine.
///
/// Slice 0.4.4's `SyncBloc` will fold these into coarser UI states
/// (`idle` / `syncing` / `error`). Tests and diagnostics consume them
/// directly.
@freezed
sealed class SyncEvent with _$SyncEvent {
  /// A drain pass has begun — the engine claimed the in-flight latch and
  /// is iterating the ready queue.
  const factory SyncEvent.drainStarted() = SyncEventDrainStarted;

  /// A single op was accepted by the server and removed from the queue.
  const factory SyncEvent.opSucceeded({required String id}) =
      SyncEventOpSucceeded;

  /// A single op failed. `willRetry` reflects whether the engine has
  /// flipped it back to pending (true) or written it off as a dead letter
  /// (false).
  const factory SyncEvent.opFailed({
    required String id,
    required Failure failure,
    required bool willRetry,
  }) = SyncEventOpFailed;

  /// The drain finished normally with these tallies.
  const factory SyncEvent.drainCompleted({
    required int processed,
    required int failed,
  }) = SyncEventDrainCompleted;

  /// The drain stopped early because of an internal safety guard (e.g.
  /// the max-iterations cap).
  const factory SyncEvent.drainAborted({required String reason}) =
      SyncEventDrainAborted;
}
