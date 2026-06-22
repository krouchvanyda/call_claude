import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/customers_repository.dart';
import '../../entities/customer.dart';
import 'customer_list_event.dart';
import 'customer_list_state.dart';

/// Bloc for the customer list (Slice 6.1.1). Same shape as
/// `InvoiceListBloc` / `ItemsListBloc`: events route inputs; the
/// pure [`applyCustomerQuery`] does the work.
class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  CustomerListBloc({required CustomersRepository repository})
      : _repository = repository,
        super(const CustomerListState()) {
    on<CustomerListStarted>(_onStarted);
    on<CustomerListSearchChanged>(_onSearchChanged);
    on<CustomerListStatusToggled>(_onStatusToggled);
    on<CustomerListSegmentToggled>(_onSegmentToggled);
    on<CustomerListSortChanged>(_onSortChanged);
    on<CustomerListFeedUpdated>(_onFeedUpdated);
    on<CustomerListFeedFailed>(_onFeedFailed);
  }

  final CustomersRepository _repository;
  StreamSubscription<List<Customer>>? _sub;

  Future<void> _onStarted(
    CustomerListStarted event,
    Emitter<CustomerListState> emit,
  ) async {
    if (_sub != null) return;
    _sub = _repository.watchAll().listen(
          (list) => add(CustomerListFeedUpdated(list)),
          onError: (Object e) =>
              add(CustomerListFeedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    CustomerListFeedUpdated event,
    Emitter<CustomerListState> emit,
  ) {
    emit(_recompute(state.copyWith(
      source: event.all,
      isLoading: false,
      errorMessage: null,
    )));
  }

  void _onFeedFailed(
    CustomerListFeedFailed event,
    Emitter<CustomerListState> emit,
  ) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  void _onSearchChanged(
    CustomerListSearchChanged event,
    Emitter<CustomerListState> emit,
  ) {
    emit(_recompute(state.copyWith(searchQuery: event.query)));
  }

  void _onStatusToggled(
    CustomerListStatusToggled event,
    Emitter<CustomerListState> emit,
  ) {
    final next = Set<CustomerStatus>.of(state.statusFilter);
    if (!next.remove(event.status)) next.add(event.status);
    emit(_recompute(state.copyWith(statusFilter: next)));
  }

  void _onSegmentToggled(
    CustomerListSegmentToggled event,
    Emitter<CustomerListState> emit,
  ) {
    final next = Set<CustomerSegment>.of(state.segmentFilter);
    if (!next.remove(event.segment)) next.add(event.segment);
    emit(_recompute(state.copyWith(segmentFilter: next)));
  }

  void _onSortChanged(
    CustomerListSortChanged event,
    Emitter<CustomerListState> emit,
  ) {
    emit(_recompute(state.copyWith(sort: event.sort)));
  }

  CustomerListState _recompute(CustomerListState s) {
    return s.copyWith(
      visible: applyCustomerQuery(
        s.source,
        statusFilter: s.statusFilter,
        segmentFilter: s.segmentFilter,
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
