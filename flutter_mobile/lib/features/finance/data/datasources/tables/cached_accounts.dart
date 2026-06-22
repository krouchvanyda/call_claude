import 'package:drift/drift.dart';

/// Drift table for the offline chart-of-accounts cache (Slice 3.1.3).
///
/// Mirrors the [`Account`] domain entity 1:1 — the DAO does the
/// `enum AccountType` ↔ string round-trip at the boundary so the
/// table itself stores the canonical lower-case name.
@DataClassName('CachedAccountRow')
class CachedAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get formattedBalance => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
