import 'package:drift/drift.dart';

import 'app_database.dart';
import 'base_dao.dart';
import 'tables/app_metadata.dart';

part 'app_metadata_dao.g.dart';

/// DAO for the cross-cutting [AppMetadata] key-value table.
///
/// Demonstrates the [BaseDao] pattern: inherits the generic CRUD primitives
/// and adds the two domain-specific helpers any caller actually wants
/// (`get(key)` / `put(key, value)`).
@DriftAccessor(tables: [AppMetadata])
class AppMetadataDao extends BaseDao<AppMetadata, AppMetadataRow>
    with _$AppMetadataDaoMixin {
  AppMetadataDao(super.db);

  @override
  TableInfo<AppMetadata, AppMetadataRow> get table => appMetadata;

  /// Returns the stored value, or `null` if the key was never written.
  Future<String?> getValue(String key) async {
    final row = await (select(appMetadata)..where((r) => r.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Reactive variant of [getValue] — emits the latest stored value (or
  /// `null` if the row is absent) whenever the key is written.
  Stream<String?> watchValue(String key) =>
      (select(appMetadata)..where((r) => r.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  /// Insert-or-replace upsert, refreshing `updatedAt` on every write.
  Future<void> putValue(String key, String value) async {
    await into(appMetadata).insert(
      AppMetadataCompanion.insert(key: key, value: value),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Removes the row for [key]. No-op if the key doesn't exist.
  Future<int> remove(String key) =>
      (delete(appMetadata)..where((r) => r.key.equals(key))).go();
}
