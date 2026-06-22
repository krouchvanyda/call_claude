import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/invoices_repository.dart';
import '../../entities/invoice.dart';
import 'invoice_list_event.dart';
import 'invoice_list_state.dart';

/// Bloc for the invoice list (Slice 3.2.1).
///
/// **Single state shape** (see [InvoiceListState] doc) — every event
/// re-derives `visible` from `source` + the toolbar inputs via the
/// pure [`applyInvoiceQuery`] helper. Keeps the business logic
/// trivially testable: the bloc routes events; the helper does the work.
class InvoiceListBloc extends Bloc<InvoiceListEvent, InvoiceListState> {
  InvoiceListBloc({required InvoicesRepository repository})
      : _repository = repository,
        super(const InvoiceListState()) {
    on<InvoiceListStarted>(_onStarted);
    on<InvoiceListSearchChanged>(_onSearchChanged);
    on<InvoiceListStatusToggled>(_onStatusToggled);
    on<InvoiceListSortChanged>(_onSortChanged);
    on<InvoiceListFeedUpdated>(_onFeedUpdated);
    on<InvoiceListFeedFailed>(_onFeedFailed);
  }

  final InvoicesRepository _repository;
  StreamSubscription<List<Invoice>>? _sub;

  Future<void> _onStarted(
    InvoiceListStarted event,
    Emitter<InvoiceListState> emit,
  ) async {
    if (_sub != null) return;
    _sub = _repository.watchAll().listen(
          (list) => add(InvoiceListEvent.feedUpdated(list)),
          onError: (Object e) =>
              add(InvoiceListEvent.feedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    InvoiceListFeedUpdated event,
    Emitter<InvoiceListState> emit,
  ) {
    emit(_recompute(state.copyWith(
      source: event.all,
      isLoading: false,
      errorMessage: null,
    )));
  }

  void _onFeedFailed(
    InvoiceListFeedFailed event,
    Emitter<InvoiceListState> emit,
  ) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  void _onSearchChanged(
    InvoiceListSearchChanged event,
    Emitter<InvoiceListState> emit,
  ) {
    emit(_recompute(state.copyWith(searchQuery: event.query)));
  }

  void _onStatusToggled(
    InvoiceListStatusToggled event,
    Emitter<InvoiceListState> emit,
  ) {
    final next = Set<InvoiceStatus>.of(state.statusFilter);
    if (!next.remove(event.status)) next.add(event.status);
    emit(_recompute(state.copyWith(statusFilter: next)));
  }

  void _onSortChanged(
    InvoiceListSortChanged event,
    Emitter<InvoiceListState> emit,
  ) {
    emit(_recompute(state.copyWith(sort: event.sort)));
  }

  /// Re-runs the pure query pipeline against the current source +
  /// toolbar values. Called from every handler that touches the
  /// inputs.
  InvoiceListState _recompute(InvoiceListState s) {
    return s.copyWith(
      visible: applyInvoiceQuery(
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
