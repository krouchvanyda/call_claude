import 'package:drift/drift.dart';

import 'cached_inventory_items.dart';

/// Drift table for the offline stock ledger (Slice 5.3.1).
///
/// **Append-only** semantics live in the DAO — no `update` API. The
/// FK cascades on delete so wiping an item also clears its history
/// (sign-out / item retirement path).
@DataClassName('CachedStockMovementRow')
class CachedStockMovements extends Table {
  TextColumn get id => text()();

  TextColumn get itemId =>
      text().references(CachedInventoryItems, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get postedAt => dateTime()();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  RealColumn get runningQty => real()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
