import 'package:drift/drift.dart';

import 'app_database.dart';

/// Common surface every drift DAO inherits.
///
/// Subclasses still own their typed query methods — the base class only
/// captures operations that genuinely don't vary between tables (count,
/// list/watch all, bulk upsert, drain). This keeps each DAO short and
/// audit-friendly.
///
/// Usage:
/// ```dart
/// @DriftAccessor(tables: [Customers])
/// class CustomerDao extends BaseDao<Customers, CustomerRow>
///     with _$CustomerDaoMixin {
///   CustomerDao(super.db);
///
///   @override
///   TableInfo<Customers, CustomerRow> get table => customers;
///
///   // ...feature-specific queries here
/// }
/// ```
abstract class BaseDao<TBL extends Table, R>
    extends DatabaseAccessor<AppDatabase> {
  BaseDao(super.db);

  /// Concrete table reference — supplied by the subclass so the generic
  /// helpers can build typed queries.
  TableInfo<TBL, R> get table;

  // ── Reads ────────────────────────────────────────────────────
  Future<List<R>> findAll() => select(table).get();

  /// Reactive variant of [findAll]. Drift propagates change events
  /// automatically when any write touches [table].
  Stream<List<R>> watchAll() => select(table).watch();

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM "${table.actualTableName}"',
      readsFrom: {table},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<bool> exists() async => (await count()) > 0;

  // ── Writes ───────────────────────────────────────────────────
  /// Upsert a batch of rows in a single statement — significantly faster
  /// than calling `insertOnConflictUpdate` in a loop.
  Future<void> bulkInsertOrReplace(Iterable<Insertable<R>> rows) =>
      batch((b) => b.insertAll(
            table,
            rows.toList(growable: false),
            mode: InsertMode.insertOrReplace,
          ));

  /// Wipe every row. Used when a sync replays the entire collection
  /// from the server and the local mirror needs to start fresh.
  Future<int> deleteAll() => delete(table).go();
}
