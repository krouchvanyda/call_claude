import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/purchase_requests_repository.dart';
import '../../entities/purchase_request.dart';
import 'pr_list_event.dart';
import 'pr_list_state.dart';

/// Bloc for the PR list (Slice 4.1.1). Same shape as
/// `InvoiceListBloc`: events route inputs, the pure
/// [`applyPurchaseRequestQuery`] does the work.
class PurchaseRequestListBloc
    extends Bloc<PurchaseRequestListEvent, PurchaseRequestListState> {
  PurchaseRequestListBloc({required PurchaseRequestsRepository repository})
      : _repository = repository,
        super(const PurchaseRequestListState()) {
    on<PurchaseRequestListStarted>(_onStarted);
    on<PurchaseRequestListSearchChanged>(_onSearchChanged);
    on<PurchaseRequestListStatusToggled>(_onStatusToggled);
    on<PurchaseRequestListSortChanged>(_onSortChanged);
    on<PurchaseRequestListFeedUpdated>(_onFeedUpdated);
    on<PurchaseRequestListFeedFailed>(_onFeedFailed);
  }

  final PurchaseRequestsRepository _repository;
  StreamSubscription<List<PurchaseRequest>>? _sub;

  Future<void> _onStarted(
    PurchaseRequestListStarted event,
    Emitter<PurchaseRequestListState> emit,
  ) async {
    if (_sub != null) return;
    _sub = _repository.watchAll().listen(
          (list) => add(PurchaseRequestListFeedUpdated(list)),
          onError: (Object e) =>
              add(PurchaseRequestListFeedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    PurchaseRequestListFeedUpdated event,
    Emitter<PurchaseRequestListState> emit,
  ) {
    emit(_recompute(state.copyWith(
      source: event.all,
      isLoading: false,
      errorMessage: null,
    )));
  }

  void _onFeedFailed(
    PurchaseRequestListFeedFailed event,
    Emitter<PurchaseRequestListState> emit,
  ) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  void _onSearchChanged(
    PurchaseRequestListSearchChanged event,
    Emitter<PurchaseRequestListState> emit,
  ) {
    emit(_recompute(state.copyWith(searchQuery: event.query)));
  }

  void _onStatusToggled(
    PurchaseRequestListStatusToggled event,
    Emitter<PurchaseRequestListState> emit,
  ) {
    final next = Set<PurchaseRequestStatus>.of(state.statusFilter);
    if (!next.remove(event.status)) next.add(event.status);
    emit(_recompute(state.copyWith(statusFilter: next)));
  }

  void _onSortChanged(
    PurchaseRequestListSortChanged event,
    Emitter<PurchaseRequestListState> emit,
  ) {
    emit(_recompute(state.copyWith(sort: event.sort)));
  }

  PurchaseRequestListState _recompute(PurchaseRequestListState s) {
    return s.copyWith(
      visible: applyPurchaseRequestQuery(
        s.source,
        statusFilter: s.statusFilter,
        searchQuery: s.searchQuery,
        sort: s.sort,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
