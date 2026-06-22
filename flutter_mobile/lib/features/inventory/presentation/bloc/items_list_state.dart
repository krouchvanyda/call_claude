import '../../entities/inventory_item.dart';

/// One-state shape for the items list (Slice 5.1.1).
class ItemsListState {
  const ItemsListState({
    this.isLoading = true,
    this.errorMessage,
    this.source = const [],
    this.visible = const [],
    this.searchQuery = '',
    this.warehouseFilter = const {},
    this.onlyLowStock = false,
    this.sort = InventoryItemSort.nameAsc,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<InventoryItem> source;
  final List<InventoryItem> visible;
  final String searchQuery;
  final Set<String> warehouseFilter;
  final bool onlyLowStock;
  final InventoryItemSort sort;

  /// Distinct warehouse codes derived from the source feed — drives
  /// the toolbar filter chips.
  Set<String> get availableWarehouses {
    final set = <String>{};
    for (final i in source) {
      set.add(i.warehouseCode);
    }
    return set;
  }

  ItemsListState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<InventoryItem>? source,
    List<InventoryItem>? visible,
    String? searchQuery,
    Set<String>? warehouseFilter,
    bool? onlyLowStock,
    InventoryItemSort? sort,
  }) {
    return ItemsListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      source: source ?? this.source,
      visible: visible ?? this.visible,
      searchQuery: searchQuery ?? this.searchQuery,
      warehouseFilter: warehouseFilter ?? this.warehouseFilter,
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
      sort: sort ?? this.sort,
    );
  }

  static const _sentinel = Object();
}
