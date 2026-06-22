import 'package:drift/drift.dart';

import '../utils/clock.dart';
import 'app_database.dart';
import 'base_dao.dart';
import 'tables/cache_freshness.dart';

part 'cache_freshness_dao.g.dart';

/// DAO that tracks per-resource cache freshness on top of the
/// [CacheFreshness] table.
///
/// Repositories use it to decide whether to serve a cached response or
/// refetch:
///
/// ```dart
/// if (await freshness.isFresh('invoices.list')) {
///   return Right(await invoiceDao.findAll());
/// }
/// final remote = await api.fetchInvoices();
/// await invoiceDao.bulkInsertOrReplace(remote);
/// await freshness.markFresh('invoices.list', ttl: const Duration(minutes: 5));
/// return Right(remote);
/// ```
@DriftAccessor(tables: [CacheFreshness])
class CacheFreshnessDao extends BaseDao<CacheFreshness, CacheFreshnessRow>
    with _$CacheFreshnessDaoMixin {
  CacheFreshnessDao(super.db, {Clock? clock}) : _now = clock ?? DateTime.now;

  final Clock _now;

  @override
  TableInfo<CacheFreshness, CacheFreshnessRow> get table => cacheFreshness;

  /// Records that the resource keyed by [cacheKey] was fetched *now* and
  /// remains valid for [ttl]. Idempotent — repeated calls reset the timer.
  Future<void> markFresh(String cacheKey, {required Duration ttl}) async {
    if (ttl.isNegative || ttl == Duration.zero) {
      throw ArgumentError.value(
        ttl,
        'ttl',
        'TTL must be a positive Duration; use invalidate() to drop a key.',
      );
    }
    await into(cacheFreshness).insert(
      CacheFreshnessCompanion.insert(
        cacheKey: cacheKey,
        fetchedAt: Value(_now()),
        ttlSeconds: ttl.inSeconds,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// `true` when the key was marked fresh at some point and the elapsed
  /// time is still within its TTL.
  Future<bool> isFresh(String cacheKey) async {
    final row = await _rowFor(cacheKey);
    if (row == null) return false;
    final expiresAt = row.fetchedAt.add(Duration(seconds: row.ttlSeconds));
    return _now().isBefore(expiresAt);
  }

  /// When was [cacheKey] last refreshed? `null` if it was never seen or has
  /// been invalidated.
  Future<DateTime?> lastFetched(String cacheKey) async =>
      (await _rowFor(cacheKey))?.fetchedAt;

  /// Drop a single cache entry — typically called after a successful write
  /// to force the next read to refetch. No-op if the key is absent.
  Future<int> invalidate(String cacheKey) =>
      (delete(cacheFreshness)..where((r) => r.cacheKey.equals(cacheKey))).go();

  /// Sweep every entry whose TTL has elapsed. Cheap to call periodically
  /// (e.g. on app foreground).
  ///
  /// The filter runs in Dart rather than SQL because drift's DateTime
  /// storage format (ISO text vs. unix epoch) varies with the build options
  /// and we want the purge to stay correct under both. The cache table is
  /// bounded (one row per cacheable resource family — typically tens to
  /// low hundreds of rows) so the round-trip cost is negligible.
  ///
  /// Returns the number of rows removed.
  Future<int> purgeExpired() async {
    final now = _now();
    final allRows = await select(cacheFreshness).get();
    final stale = <String>[];
    for (final r in allRows) {
      final expiresAt = r.fetchedAt.add(Duration(seconds: r.ttlSeconds));
      if (!now.isBefore(expiresAt)) stale.add(r.cacheKey);
    }
    if (stale.isEmpty) return 0;
    return (delete(cacheFreshness)..where((r) => r.cacheKey.isIn(stale)))
        .go();
  }

  Future<CacheFreshnessRow?> _rowFor(String cacheKey) =>
      (select(cacheFreshness)..where((r) => r.cacheKey.equals(cacheKey)))
          .getSingleOrNull();
}
