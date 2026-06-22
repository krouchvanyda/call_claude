import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../entities/inventory_item.dart';
import '../../entities/stock_movement.dart';
import 'tables/cached_inventory_items.dart';
import 'tables/cached_stock_movements.dart';

part 'items_dao.g.dart';

/// Drift DAO for the offline inventory cache (Slice 5.3.1).
///
/// Owns both `cached_inventory_items` (master) and
/// `cached_stock_movements` (ledger). The cascade on the FK means a
/// header wipe drops history — we still delete in the explicit order
/// to keep the code readable.
@DriftAccessor(tables: [CachedInventoryItems, CachedStockMovements])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  // ── Items ────────────────────────────────────────────────────

  Future<void> upsertItems(Iterable<InventoryItem> items) {
    return batch((b) {
      for (final i in items) {
        b.insert(
          cachedInventoryItems,
          _itemToCompanion(i),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<InventoryItem>> getAllItems() async {
    final rows = await (select(cachedInventoryItems)
          ..orderBy([(r) => OrderingTerm.asc(r.name)]))
        .get();
    return rows.map(_itemFromRow).toList(growable: false);
  }

  Stream<List<InventoryItem>> watchAllItems() {
    return (select(cachedInventoryItems)
          ..orderBy([(r) => OrderingTerm.asc(r.name)]))
        .watch()
        .map((rows) => rows.map(_itemFromRow).toList(growable: false));
  }

  Future<InventoryItem?> findItemById(String id) async {
    final row = await (select(cachedInventoryItems)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _itemFromRow(row);
  }

  Future<InventoryItem?> findItemByBarcode(String barcode) async {
    final row = await (select(cachedInventoryItems)
          ..where((r) => r.barcode.equals(barcode)))
        .getSingleOrNull();
    return row == null ? null : _itemFromRow(row);
  }

  Future<List<String>> distinctWarehouses() async {
    final c = cachedInventoryItems.warehouseCode;
    final query = selectOnly(cachedInventoryItems, distinct: true)
      ..addColumns([c])
      ..orderBy([OrderingTerm.asc(c)]);
    final rows = await query.get();
    return rows.map((r) => r.read(c)!).toList(growable: false);
  }

  Future<int> countItems() async {
    final c = countAll();
    final query = selectOnly(cachedInventoryItems)..addColumns([c]);
    return (await query.map((r) => r.read(c) ?? 0).getSingle());
  }

  Future<InventoryItem> setOnHand(String itemId, num newQty) async {
    final updated = await (update(cachedInventoryItems)
          ..where((r) => r.id.equals(itemId)))
        .write(CachedInventoryItemsCompanion(onHandQty: Value(newQty.toDouble())));
    if (updated == 0) {
      throw StateError('Item "$itemId" not found');
    }
    return (await findItemById(itemId))!;
  }

  // ── Movements ───────────────────────────────────────────────

  Future<StockMovement> appendMovement(StockMovement m) async {
    await into(cachedStockMovements).insert(_movementToCompanion(m));
    return m;
  }

  Future<List<StockMovement>> movementsForItem(String itemId) async {
    final rows = await (select(cachedStockMovements)
          ..where((r) => r.itemId.equals(itemId))
          ..orderBy([(r) => OrderingTerm.desc(r.postedAt)]))
        .get();
    return rows.map(_movementFromRow).toList(growable: false);
  }

  Stream<List<StockMovement>> watchMovementsForItem(String itemId) {
    final query = select(cachedStockMovements)
      ..where((r) => r.itemId.equals(itemId))
      ..orderBy([(r) => OrderingTerm.desc(r.postedAt)]);
    return query.watch().map(
          (rows) => rows.map(_movementFromRow).toList(growable: false),
        );
  }

  Future<void> wipeAll() async {
    await delete(cachedStockMovements).go();
    await delete(cachedInventoryItems).go();
  }

  // ── Mapping ────────────────────────────────────────────────────

  static CachedInventoryItemsCompanion _itemToCompanion(InventoryItem i) {
    return CachedInventoryItemsCompanion(
      id: Value(i.id),
      sku: Value(i.sku),
      name: Value(i.name),
      warehouseCode: Value(i.warehouseCode),
      locationCode: Value(i.locationCode),
      onHandQty: Value(i.onHandQty.toDouble()),
      reorderPoint: Value(i.reorderPoint.toDouble()),
      unitCost: Value(i.unitCost),
      barcode: Value(i.barcode),
      status: Value(i.status.name),
    );
  }

  static InventoryItem _itemFromRow(CachedInventoryItemRow r) {
    return InventoryItem(
      id: r.id,
      sku: r.sku,
      name: r.name,
      warehouseCode: r.warehouseCode,
      locationCode: r.locationCode,
      onHandQty: r.onHandQty,
      reorderPoint: r.reorderPoint,
      unitCost: r.unitCost,
      barcode: r.barcode,
      status: _statusFromString(r.status),
    );
  }

  static InventoryItemStatus _statusFromString(String raw) {
    for (final s in InventoryItemStatus.values) {
      if (s.name == raw) return s;
    }
    return InventoryItemStatus.active;
  }

  static CachedStockMovementsCompanion _movementToCompanion(StockMovement m) {
    return CachedStockMovementsCompanion(
      id: Value(m.id),
      itemId: Value(m.itemId),
      postedAt: Value(m.postedAt),
      type: Value(m.type.name),
      quantity: Value(m.quantity.toDouble()),
      runningQty: Value(m.runningQty.toDouble()),
      reference: Value(m.reference),
      note: Value(m.note),
    );
  }

  static StockMovement _movementFromRow(CachedStockMovementRow r) {
    return StockMovement(
      id: r.id,
      itemId: r.itemId,
      postedAt: r.postedAt,
      type: _typeFromString(r.type),
      quantity: r.quantity,
      runningQty: r.runningQty,
      reference: r.reference,
      note: r.note,
    );
  }

  static StockMovementType _typeFromString(String raw) {
    for (final t in StockMovementType.values) {
      if (t.name == raw) return t;
    }
    return StockMovementType.adjustment;
  }
}
