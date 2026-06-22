/// Lifecycle/availability for an item (Slice 5.1.1).
enum InventoryItemStatus { active, discontinued, blocked }

/// Sort axes for the catalog list (Slice 5.1.1).
enum InventoryItemSort { nameAsc, skuAsc, onHandAsc, onHandDesc }

/// One stock-keeping unit in a specific [warehouseCode] + [locationCode]
/// bin. Items with the same `sku` but different locations are separate
/// rows here — the list view groups them by warehouse via the filter.
///
/// **Pure data**: no Flutter, no drift. Pre-formatted [unitCost] keeps
/// the entity locale-stable (same rule as `Invoice.totalAmount`).
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.warehouseCode,
    required this.locationCode,
    required this.onHandQty,
    required this.reorderPoint,
    required this.unitCost,
    required this.status,
    this.barcode,
  });

  final String id;
  final String sku;
  final String name;
  final String warehouseCode;
  final String locationCode;
  final num onHandQty;

  /// Threshold below which the low-stock alert (Slice 5.1.3) fires.
  final num reorderPoint;

  /// Pre-formatted (e.g. `r'$12.50'`).
  final String unitCost;

  /// Optional barcode / QR payload — populated for scannable items.
  final String? barcode;

  final InventoryItemStatus status;

  /// `true` when on-hand has dropped to or below the reorder point.
  bool get isLowStock => onHandQty <= reorderPoint;

  InventoryItem copyWith({
    String? id,
    String? sku,
    String? name,
    String? warehouseCode,
    String? locationCode,
    num? onHandQty,
    num? reorderPoint,
    String? unitCost,
    String? barcode,
    InventoryItemStatus? status,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        name: name ?? this.name,
        warehouseCode: warehouseCode ?? this.warehouseCode,
        locationCode: locationCode ?? this.locationCode,
        onHandQty: onHandQty ?? this.onHandQty,
        reorderPoint: reorderPoint ?? this.reorderPoint,
        unitCost: unitCost ?? this.unitCost,
        barcode: barcode ?? this.barcode,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          other.id == id &&
          other.sku == sku &&
          other.name == name &&
          other.warehouseCode == warehouseCode &&
          other.locationCode == locationCode &&
          other.onHandQty == onHandQty &&
          other.reorderPoint == reorderPoint &&
          other.unitCost == unitCost &&
          other.barcode == barcode &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        id,
        sku,
        name,
        warehouseCode,
        locationCode,
        onHandQty,
        reorderPoint,
        unitCost,
        barcode,
        status,
      );
}
