import 'package:drift/drift.dart';

/// Drift table for the offline item master (Slice 5.3.1 — spec:
/// "Download item master to local drift DB"). Mirrors
/// [`InventoryItem`] 1:1; the DAO does the enum ↔ string round-trip
/// at the boundary so the table stores the canonical lower-case name.
@DataClassName('CachedInventoryItemRow')
class CachedInventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text()();
  TextColumn get name => text()();
  TextColumn get warehouseCode => text()();
  TextColumn get locationCode => text()();
  RealColumn get onHandQty => real()();
  RealColumn get reorderPoint => real()();
  TextColumn get unitCost => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
