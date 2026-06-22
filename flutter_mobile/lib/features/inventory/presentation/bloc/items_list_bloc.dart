import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/items_repository.dart';
import '../../entities/inventory_item.dart';
import 'items_list_event.dart';
import 'items_list_state.dart';

/// Bloc for the inventory items list (Slice 5.1.1). Same shape as
/// the procurement / invoices list blocs: events route inputs; the
/// pure [`applyItemQuery`] does the actual work.
class ItemsListBloc extends Bloc<ItemsListEvent, ItemsListState> {
  ItemsListBloc({required ItemsRepository repository})
      : _repository = repository,
        super(const ItemsListState()) {
    on<ItemsListStarted>(_onStarted);
    on<ItemsListSearchChanged>(_onSearchChanged);
    on<ItemsListWarehouseToggled>(_onWarehouseToggled);
    on<ItemsListLowStockToggled>(_onLowStockToggled);
    on<ItemsListSortChanged>(_onSortChanged);
    on<ItemsListFeedUpdated>(_onFeedUpdated);
    on<ItemsListFeedFailed>(_onFeedFailed);
  }

  final ItemsRepository _repository;
  StreamSubscription<List<InventoryItem>>? _sub;

  Future<void> _onStarted(
    ItemsListStarted event,
    Emitter<ItemsListState> emit,
  ) async {
    if (_sub != null) return;
    _sub = _repository.watchAll().listen(
          (list) => add(ItemsListFeedUpdated(list)),
          onError: (Object e) =>
              add(ItemsListFeedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    ItemsListFeedUpdated event,
    Emitter<ItemsListState> emit,
  ) {
    emit(_recompute(state.copyWith(
      source: event.all,
      isLoading: false,
      errorMessage: null,
    )));
  }

  void _onFeedFailed(
    ItemsListFeedFailed event,
    Emitter<ItemsListState> emit,
  ) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  void _onSearchChanged(
    ItemsListSearchChanged event,
    Emitter<ItemsListState> emit,
  ) {
    emit(_recompute(state.copyWith(searchQuery: event.query)));
  }

  void _onWarehouseToggled(
    ItemsListWarehouseToggled event,
    Emitter<ItemsListState> emit,
  ) {
    final next = Set<String>.of(state.warehouseFilter);
    if (!next.remove(event.warehouseCode)) next.add(event.warehouseCode);
    emit(_recompute(state.copyWith(warehouseFilter: next)));
  }

  void _onLowStockToggled(
    ItemsListLowStockToggled event,
    Emitter<ItemsListState> emit,
  ) {
    emit(_recompute(state.copyWith(onlyLowStock: event.onlyLowStock)));
  }

  void _onSortChanged(
    ItemsListSortChanged event,
    Emitter<ItemsListState> emit,
  ) {
    emit(_recompute(state.copyWith(sort: event.sort)));
  }

  ItemsListState _recompute(ItemsListState s) {
    return s.copyWith(
      visible: applyItemQuery(
        s.source,
        warehouseFilter: s.warehouseFilter,
        onlyLowStock: s.onlyLowStock,
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
