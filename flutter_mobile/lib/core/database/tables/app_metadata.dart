import 'package:drift/drift.dart';

/// Key-value scratch space for app-level metadata: last-sync timestamps per
/// entity type, schema migration markers, lightweight feature flags cached
/// from the server, and similar housekeeping.
///
/// Slice 0.3.3's TTL-cache helper writes here too. Feature-specific data
/// belongs in its own typed table inside the relevant feature module.
@DataClassName('AppMetadataRow')
class AppMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
