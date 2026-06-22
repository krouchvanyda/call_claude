import 'dart:async';

import 'package:bloc/bloc.dart';

import '../error/failure.dart';
import '../utils/clock.dart';
import 'sync_bloc_event.dart';
import 'sync_event.dart';
import 'sync_state.dart';
import 'sync_status.dart';

/// Folds the sync engine's granular [SyncEvent] stream and the queue's
/// pending count into a single coarse [SyncState] the UI can render.
///
/// Architecture: the BLoC takes its inputs as plain `Stream`s and a thunk
/// (instead of holding `SyncEngine` / `SyncQueueDao` references) so it
/// stays Flutter-free, easy to fake in tests, and faithful to the
/// `BLoC → UseCase → Repository → DataSource` rule (the BLoC has no
/// knowledge of drift or dio).
class SyncBloc extends Bloc<SyncBlocEvent, SyncState> {
  SyncBloc({
    required Future<void> Function() triggerSync,
    required Stream<SyncEvent> engineEvents,
    required Stream<int> pendingCounts,
    Clock clock = DateTime.now,
  })  : _triggerSync = triggerSync,
        _clock = clock,
        super(const SyncState()) {
    on<SyncTriggerRequested>(_onTriggerRequested);
    on<SyncEngineEventReceived>(_onEngineEvent);
    on<SyncPendingCountChanged>(_onPendingCountChanged);

    _engineSub = engineEvents.listen(
      (event) => add(SyncBlocEvent.engineEventReceived(event)),
    );
    _pendingSub = pendingCounts.listen(
      (count) => add(SyncBlocEvent.pendingCountChanged(count)),
    );
  }

  final Future<void> Function() _triggerSync;
  final Clock _clock;
  late final StreamSubscription<SyncEvent> _engineSub;
  late final StreamSubscription<int> _pendingSub;

  Future<void> _onTriggerRequested(
    SyncTriggerRequested event,
    Emitter<SyncState> emit,
  ) async {
    // Fire-and-forget — the engine emits progress events that this bloc
    // is already subscribed to, so awaiting here would only block the
    // event handler unnecessarily.
    unawaited(_triggerSync());
  }

  void _onEngineEvent(
    SyncEngineEventReceived wrapper,
    Emitter<SyncState> emit,
  ) {
    final event = wrapper.event;
    switch (event) {
      case SyncEventDrainStarted():
        emit(state.copyWith(
          status: SyncStatus.syncing,
          lastError: null,
        ));
      case SyncEventOpSucceeded():
        // No status change — drain is still in progress; tally lands at
        // drainCompleted.
        break;
      case SyncEventOpFailed(:final failure):
        // Surface the latest failure immediately so a banner can react
        // mid-drain rather than waiting for the whole batch to finish.
        emit(state.copyWith(lastError: failure));
      case SyncEventDrainCompleted(:final processed, :final failed):
        emit(state.copyWith(
          status: failed > 0 ? SyncStatus.error : SyncStatus.idle,
          lastSucceededAt:
              processed > 0 ? _clock() : state.lastSucceededAt,
          // A clean drain (no failures) clears any previous error banner.
          lastError: failed > 0 ? state.lastError : null,
        ));
      case SyncEventDrainAborted(:final reason):
        emit(state.copyWith(
          status: SyncStatus.error,
          lastError: Failure.unknown(message: 'sync aborted: $reason'),
        ));
    }
  }

  void _onPendingCountChanged(
    SyncPendingCountChanged event,
    Emitter<SyncState> emit,
  ) {
    emit(state.copyWith(pendingCount: event.count));
  }

  @override
  Future<void> close() async {
    await _engineSub.cancel();
    await _pendingSub.cancel();
    return super.close();
  }
}
