import '../../entities/inventory_item.dart';

/// Inputs to [ItemsListBloc] (Slice 5.1.1).
sealed class ItemsListEvent {
  const ItemsListEvent();
}

class ItemsListStarted extends ItemsListEvent {
  const ItemsListStarted();
}

class ItemsListSearchChanged extends ItemsListEvent {
  const ItemsListSearchChanged(this.query);
  final String query;
}

class ItemsListWarehouseToggled extends ItemsListEvent {
  const ItemsListWarehouseToggled(this.warehouseCode);
  final String warehouseCode;
}

class ItemsListLowStockToggled extends ItemsListEvent {
  const ItemsListLowStockToggled(this.onlyLowStock);
  final bool onlyLowStock;
}

class ItemsListSortChanged extends ItemsListEvent {
  const ItemsListSortChanged(this.sort);
  final InventoryItemSort sort;
}

class ItemsListFeedUpdated extends ItemsListEvent {
  const ItemsListFeedUpdated(this.all);
  final List<InventoryItem> all;
}

class ItemsListFeedFailed extends ItemsListEvent {
  const ItemsListFeedFailed(this.message);
  final String message;
}
