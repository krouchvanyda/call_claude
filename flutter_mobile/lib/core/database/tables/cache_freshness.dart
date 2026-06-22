import 'package:drift/drift.dart';

/// Tracks when each cacheable resource was last fetched and how long it
/// remains valid.
///
/// One row per *cache key* — typically a stable string the repository owns
/// (e.g. `'invoices.list'`, `'customers.byId.42'`). Storing TTL alongside
/// the timestamp lets repositories choose their own freshness windows
/// without a global config knob.
@DataClassName('CacheFreshnessRow')
class CacheFreshness extends Table {
  TextColumn get cacheKey => text()();
  DateTimeColumn get fetchedAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get ttlSeconds => integer()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}
