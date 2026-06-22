import 'package:freezed_annotation/freezed_annotation.dart';

import 'sync_event.dart';

part 'sync_bloc_event.freezed.dart';

/// Inputs to [SyncBloc].
///
/// Three flavours:
/// - **`triggerRequested`** — UI/usecase asking for an immediate drain.
/// - **`engineEventReceived`** — internal forwarder from
///   `SyncEngine.events` so all state mutation goes through `on<>` handlers
///   (and stays unit-testable via `bloc_test`).
/// - **`pendingCountChanged`** — internal forwarder from
///   `SyncQueueDao.watchPendingCount()` for the badge.
@freezed
sealed class SyncBlocEvent with _$SyncBlocEvent {
  /// User / use-case asked for a manual drain.
  const factory SyncBlocEvent.triggerRequested() = SyncTriggerRequested;

  /// Forwarded from `SyncEngine.events`.
  const factory SyncBlocEvent.engineEventReceived(SyncEvent event) =
      SyncEngineEventReceived;

  /// Forwarded from `SyncQueueDao.watchPendingCount()`.
  const factory SyncBlocEvent.pendingCountChanged(int count) =
      SyncPendingCountChanged;
}
