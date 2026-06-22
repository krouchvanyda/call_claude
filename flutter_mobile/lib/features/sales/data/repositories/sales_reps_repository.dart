import '../../entities/activity_event.dart';
import '../../entities/sales_rep.dart';
import '../sales_seed.dart';

/// Slice 6.3.3 — sales rep master list.
class SalesRepsRepository {
  SalesRepsRepository();

  static final List<SalesRep> _seed = List<SalesRep>.of(SalesSeed.reps);

  Future<List<SalesRep>> getAll() async => List.unmodifiable(_seed);

  Future<SalesRep?> findById(String id) async {
    for (final r in _seed) {
      if (r.id == id) return r;
    }
    return null;
  }
}

/// One row on the leaderboard (Slice 6.3.3).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rep,
    required this.revenue,
    required this.formattedRevenue,
    required this.targetAmount,
    required this.attainmentPct,
    required this.dealsClosed,
    required this.rank,
  });

  final SalesRep rep;

  /// Raw revenue (sum of attributed `order`/`payment` events).
  final num revenue;

  /// Pre-formatted version of [revenue] for display.
  final String formattedRevenue;

  /// The rep's [`SalesRep.targetAmount`] pass-through.
  final String targetAmount;

  /// 0.0..(unbounded) — `revenue / target * 100`. Capped at `0` for a
  /// zero/missing target so the UI can render a flat 0% bar instead
  /// of `NaN`.
  final double attainmentPct;

  final int dealsClosed;

  /// 1-based rank — entries are returned pre-ranked, but having this
  /// on the row lets the UI render the rank without a separate
  /// `indexOf` lookup.
  final int rank;
}

/// Computes the leaderboard from the activity feed (Slice 6.3.3).
///
/// **Source of truth**: the activity ledger keyed by `actor`. Each
/// `order` event contributes its `amount` to the matching rep's
/// revenue and counts as a closed deal. `payment` events are
/// **not** double-counted (they're a follow-on of the order they
/// reference). Other event types are ignored.
///
/// **Attribution gap**: an order's `actor` may not match a rep id in
/// the master list — the function still surfaces a result for the
/// missing rep by falling back to the actor string as both id and
/// label (so the dashboard doesn't silently swallow revenue). The
/// fallback row carries an empty target string.
List<LeaderboardEntry> salesRepLeaderboard(
  Iterable<ActivityEvent> activities, {
  required Iterable<SalesRep> reps,
  int? limit,
}) {
  final repsByName = <String, SalesRep>{
    for (final r in reps) r.name: r,
  };

  final revenueByActor = <String, num>{};
  final dealsByActor = <String, int>{};

  for (final a in activities) {
    if (a.type != ActivityEventType.order) continue;
    final amount = _parse(a.amount);
    revenueByActor[a.actor] = (revenueByActor[a.actor] ?? 0) + amount;
    dealsByActor[a.actor] = (dealsByActor[a.actor] ?? 0) + 1;
  }

  // Make sure reps with no orders still appear (zero revenue).
  for (final r in reps) {
    revenueByActor.putIfAbsent(r.name, () => 0);
    dealsByActor.putIfAbsent(r.name, () => 0);
  }

  final entries = revenueByActor.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final ranked = <LeaderboardEntry>[];
  for (var i = 0; i < entries.length; i++) {
    final actor = entries[i].key;
    final revenue = entries[i].value;
    final rep = repsByName[actor] ??
        SalesRep(id: actor, name: actor, targetAmount: '');
    final targetRaw = _parse(rep.targetAmount);
    final attainment =
        targetRaw <= 0 ? 0.0 : (revenue / targetRaw * 100.0).toDouble();
    ranked.add(LeaderboardEntry(
      rep: rep,
      revenue: revenue,
      formattedRevenue: _format(revenue),
      targetAmount: rep.targetAmount,
      attainmentPct: attainment,
      dealsClosed: dealsByActor[actor] ?? 0,
      rank: i + 1,
    ));
  }
  if (limit == null) return ranked;
  return ranked.take(limit).toList();
}

num _parse(String? formatted) {
  if (formatted == null) return 0;
  final cleaned = formatted.replaceAll(RegExp(r'[^0-9.\-]'), '');
  return num.tryParse(cleaned) ?? 0;
}

String _format(num n) {
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
