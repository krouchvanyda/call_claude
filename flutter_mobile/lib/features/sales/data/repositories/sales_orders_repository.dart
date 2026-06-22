import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/sales_order.dart';
import '../sales_seed.dart';

/// Slice 6.2.1 / 6.2.2 / 6.2.3 — sales orders.
class SalesOrdersRepository {
  SalesOrdersRepository();

  static final List<SalesOrder> _seed =
      List<SalesOrder>.of(SalesSeed.orders);
  static int _idCounter = 100;

  final StreamController<List<SalesOrder>> _changes =
      StreamController<List<SalesOrder>>.broadcast();

  Future<List<SalesOrder>> getAll() async => List.unmodifiable(_seed);

  Stream<List<SalesOrder>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<SalesOrder?> findById(String id) async {
    for (final o in _seed) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Persists a freshly created order (Slice 6.2.2 conversion).
  Future<SalesOrder> create(SalesOrder draft) async {
    _idCounter++;
    final id = 'so-2026-${_idCounter.toString().padLeft(3, '0')}';
    final persisted = draft.copyWith(id: id, number: id.toUpperCase());
    _seed.insert(0, persisted);
    _changes.add(List.unmodifiable(_seed));
    return persisted;
  }

  /// Advances the fulfillment state machine (Slice 6.2.3).
  Future<SalesOrder> setStatus(
    String id,
    SalesOrderStatus next, {
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? trackingReference,
  }) async {
    final idx = _seed.indexWhere((o) => o.id == id);
    if (idx == -1) throw StateError('Order "$id" not found');
    _seed[idx] = _seed[idx].copyWith(
      status: next,
      shippedAt: shippedAt ?? _seed[idx].shippedAt,
      deliveredAt: deliveredAt ?? _seed[idx].deliveredAt,
      trackingReference: trackingReference ?? _seed[idx].trackingReference,
    );
    _changes.add(List.unmodifiable(_seed));
    return _seed[idx];
  }

  /// Pure transition rules for the fulfillment state machine
  /// (Slice 6.2.3).
  ///
  /// **Allowed transitions**:
  /// ```
  /// pending  → packing | cancelled
  /// packing  → shipped | cancelled
  /// shipped  → delivered
  /// delivered → (terminal)
  /// cancelled → (terminal)
  /// ```
  ///
  /// Throws [`ConflictFailure`] for an illegal hop; throws
  /// [`ValidationFailure`] when `next == shipped` is requested without
  /// a `trackingReference` (the warehouse staff needs the reference to
  /// hand to the courier).
  SalesOrder advanceFulfillment(
    SalesOrder current, {
    required SalesOrderStatus to,
    required DateTime now,
    String? trackingReference,
  }) {
    if (!_isLegalTransition(current.status, to)) {
      throw Failure.conflict(
        message:
            'Cannot move ${current.status.name} → ${to.name}',
      );
    }
    if (to == SalesOrderStatus.shipped &&
        (trackingReference == null || trackingReference.trim().isEmpty)) {
      throw const Failure.validation(
        fieldErrors: {
          'trackingReference': ['required'],
        },
      );
    }
    return current.copyWith(
      status: to,
      trackingReference: trackingReference?.trim() ?? current.trackingReference,
      shippedAt: to == SalesOrderStatus.shipped ? now : current.shippedAt,
      deliveredAt:
          to == SalesOrderStatus.delivered ? now : current.deliveredAt,
    );
  }
}

bool _isLegalTransition(SalesOrderStatus from, SalesOrderStatus to) {
  switch (from) {
    case SalesOrderStatus.pending:
      return to == SalesOrderStatus.packing ||
          to == SalesOrderStatus.cancelled;
    case SalesOrderStatus.packing:
      return to == SalesOrderStatus.shipped ||
          to == SalesOrderStatus.cancelled;
    case SalesOrderStatus.shipped:
      return to == SalesOrderStatus.delivered;
    case SalesOrderStatus.delivered:
    case SalesOrderStatus.cancelled:
      return false;
  }
}

/// Bucketing granularity for the revenue chart (Slice 6.3.1).
enum RevenuePeriod { weekly, monthly }

/// One bucket on the chart.
class RevenueBucket {
  const RevenueBucket({required this.start, required this.amount});

  /// First day of the bucket in UTC — week-start (Mon) for [weekly];
  /// 1st of the month for [monthly].
  final DateTime start;

  final num amount;
}

/// Pure aggregation (Slice 6.3.1). Sums each [SalesOrder]'s total
/// into the bucket containing its `createdAt`. **Cancelled orders are
/// excluded** — they didn't earn revenue. Buckets are returned in
/// chronological order with no gaps over the full range.
///
/// **Money parsing**: works against the pre-formatted `totalAmount`
/// strings by stripping non-digits before `num.tryParse`. Locale-
/// dependent — the seed is single-currency so this is fine for the
/// demo; when multi-currency lands the entity will carry raw cents.
List<RevenueBucket> revenueByPeriod(
  List<SalesOrder> orders, {
  required RevenuePeriod period,
  required DateTime from,
  required DateTime to,
}) {
  if (!to.isAfter(from)) return const [];

  final keyed = <DateTime, num>{};
  for (final o in orders) {
    if (o.status == SalesOrderStatus.cancelled) continue;
    final ts = o.createdAt;
    if (ts.isBefore(from) || !ts.isBefore(to)) continue;
    final bucket = _bucketFor(ts, period);
    keyed[bucket] = (keyed[bucket] ?? 0) + _parseAmount(o.totalAmount);
  }

  // Fill the whole range so the chart has no gaps.
  final result = <RevenueBucket>[];
  var cursor = _bucketFor(from, period);
  while (cursor.isBefore(to)) {
    result.add(RevenueBucket(
      start: cursor,
      amount: keyed[cursor] ?? 0,
    ));
    cursor = _next(cursor, period);
  }
  return result;
}

DateTime _bucketFor(DateTime ts, RevenuePeriod p) {
  switch (p) {
    case RevenuePeriod.weekly:
      // Snap to Monday in UTC.
      final daysFromMonday = (ts.weekday - DateTime.monday) % 7;
      final monday = DateTime.utc(ts.year, ts.month, ts.day)
          .subtract(Duration(days: daysFromMonday));
      return monday;
    case RevenuePeriod.monthly:
      return DateTime.utc(ts.year, ts.month, 1);
  }
}

DateTime _next(DateTime bucket, RevenuePeriod p) {
  switch (p) {
    case RevenuePeriod.weekly:
      return bucket.add(const Duration(days: 7));
    case RevenuePeriod.monthly:
      final nextMonth = bucket.month == 12 ? 1 : bucket.month + 1;
      final nextYear = bucket.month == 12 ? bucket.year + 1 : bucket.year;
      return DateTime.utc(nextYear, nextMonth, 1);
  }
}

num _parseAmount(String formatted) {
  final cleaned = formatted.replaceAll(RegExp(r'[^0-9.\-]'), '');
  return num.tryParse(cleaned) ?? 0;
}

/// One row on a "top N" ranking (Slice 6.3.2).
class TopRanking<T> {
  const TopRanking({
    required this.key,
    required this.label,
    required this.amount,
    required this.units,
  });

  /// Stable identifier — `customerId`, sku, or rep id.
  final T key;

  /// Display label captured at compute time so the analytics page
  /// doesn't have to refetch the parent entity.
  final String label;

  /// Pre-formatted total revenue (e.g. `r'$48,200.00'`).
  final String amount;

  /// Raw line-item units (orders, qty, deals — depends on the use case).
  final num units;
}

/// **Top customers** by revenue (Slice 6.3.2). Cancelled orders are
/// excluded — they didn't earn revenue.
List<TopRanking<String>> topCustomers(
  List<SalesOrder> orders, {
  int limit = 5,
}) {
  final revenueById = <String, num>{};
  final nameById = <String, String>{};
  final unitsById = <String, int>{};
  for (final o in orders) {
    if (o.status == SalesOrderStatus.cancelled) continue;
    revenueById[o.customerId] =
        (revenueById[o.customerId] ?? 0) + _parseAmount(o.totalAmount);
    nameById[o.customerId] = o.customerName;
    unitsById[o.customerId] = (unitsById[o.customerId] ?? 0) + 1;
  }
  final entries = revenueById.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries.take(limit))
      TopRanking<String>(
        key: e.key,
        label: nameById[e.key] ?? e.key,
        amount: _formatAmount(e.value),
        units: unitsById[e.key] ?? 0,
      ),
  ];
}

/// **Top products** by revenue, keyed by SKU when present, else by
/// description (Slice 6.3.2). Each line contributes its `lineTotal` to
/// the SKU's revenue and its `quantity` to the unit count.
List<TopRanking<String>> topProducts(
  List<SalesOrder> orders, {
  int limit = 5,
}) {
  final revenueByKey = <String, num>{};
  final labelByKey = <String, String>{};
  final unitsByKey = <String, num>{};
  for (final o in orders) {
    if (o.status == SalesOrderStatus.cancelled) continue;
    for (final line in o.lineItems) {
      final key = line.sku ?? line.description;
      revenueByKey[key] =
          (revenueByKey[key] ?? 0) + _parseAmount(line.lineTotal);
      labelByKey[key] = line.sku == null
          ? line.description
          : '${line.sku} — ${line.description}';
      unitsByKey[key] = (unitsByKey[key] ?? 0) + line.quantity;
    }
  }
  final entries = revenueByKey.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries.take(limit))
      TopRanking<String>(
        key: e.key,
        label: labelByKey[e.key] ?? e.key,
        amount: _formatAmount(e.value),
        units: unitsByKey[e.key] ?? 0,
      ),
  ];
}

String _formatAmount(num n) {
  final abs = n.abs().toStringAsFixed(2);
  final parts = abs.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '${n < 0 ? '-' : ''}\$$buf.${parts[1]}';
}
