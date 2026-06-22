import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/usecases/federated_search.dart';
import 'global_search_event.dart';
import 'global_search_state.dart';

/// Bloc behind the global search bar (Slice 2.1.3).
///
/// **Debounced + restartable**: typing fast doesn't fire one query per
/// keystroke; the latest query wins. Implemented via an rxdart event
/// transformer:
/// 1. `debounceTime(300ms)` — wait for the user to pause
/// 2. `switchMap` — cancel any in-flight previous query when a newer
///    one arrives (subscriptions to the older mapper future are dropped)
class GlobalSearchBloc extends Bloc<GlobalSearchEvent, GlobalSearchState> {
  GlobalSearchBloc({required FederatedSearchUseCase federatedSearch})
      : _federatedSearch = federatedSearch,
        super(const GlobalSearchState.idle()) {
    on<GlobalSearchQueryChanged>(
      _onQueryChanged,
      transformer: _debouncedRestartable(),
    );
    on<GlobalSearchCleared>(_onCleared);
  }

  final FederatedSearchUseCase _federatedSearch;

  /// Internal: visible-for-testing knob is unnecessary because the
  /// bloc test fakes the use case and pumps events directly — the
  /// debounce window only matters for live keystrokes.
  static const Duration _debounce = Duration(milliseconds: 300);

  Future<void> _onQueryChanged(
    GlobalSearchQueryChanged event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const GlobalSearchState.idle());
      return;
    }
    emit(GlobalSearchState.loading(query));
    try {
      final groups = await _federatedSearch.call(query);
      emit(GlobalSearchState.success(query: query, groups: groups));
    } catch (e) {
      emit(GlobalSearchState.failure(query: query, message: e.toString()));
    }
  }

  void _onCleared(GlobalSearchCleared event, Emitter<GlobalSearchState> emit) {
    emit(const GlobalSearchState.idle());
  }

  /// `debounceTime` collapses bursts of keystrokes into the latest;
  /// `switchMap` then cancels any prior in-flight handler so only the
  /// final query's emit() reaches the state.
  static EventTransformer<GlobalSearchQueryChanged> _debouncedRestartable() {
    return (events, mapper) =>
        events.debounceTime(_debounce).switchMap(mapper);
  }
}
