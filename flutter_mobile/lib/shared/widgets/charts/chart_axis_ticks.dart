import 'dart:math' as math;

import 'chart_data.dart';

/// Pure-Dart axis-tick computation (Slice 2.2.3) — picks "nice" round
/// numbers for an axis range so the chart's Y-axis labels read as
/// 0/250/500/750/1000 rather than 0/237/473/710/947.
///
/// Algorithm follows Heckbert's "Nice Numbers for Graph Labels"
/// (Graphics Gems, 1990) — bucket the data range into 1, 2, 5, or 10
/// times a power of ten, then aim for roughly the requested tick count.
///
/// **Pure Dart**: split out from any fl_chart wrapper so the rounding
/// rules live in unit tests rather than in widget rendering.
class ChartAxisTicks {
  ChartAxisTicks._({
    required this.min,
    required this.max,
    required this.step,
  });

  final double min;
  final double max;
  final double step;

  /// All tick values from [min] to [max] (inclusive on both ends),
  /// stepping by [step]. The last value may overshoot [max] by less
  /// than [step] / 2 due to rounding — callers should treat the list
  /// as the source of truth and not re-derive from min/max/step.
  List<double> get values {
    final out = <double>[];
    var v = min;
    // Bias by half-step to absorb FP drift on the upper bound.
    while (v <= max + step / 2) {
      out.add(v);
      v += step;
    }
    return out;
  }

  /// How many ticks (inclusive of both endpoints).
  int get tickCount => values.length;

  /// Computes nice ticks covering `[dataMin, dataMax]` with roughly
  /// [targetTicks] divisions.
  ///
  /// - Degenerate ranges (`dataMin == dataMax`) get a tick at the
  ///   value plus a one-step pad on either side so the line / bar
  ///   isn't pinned to the chart's edge.
  /// - Reversed ranges are silently swapped — easier than asking
  ///   every caller to pre-sort.
  static ChartAxisTicks compute({
    required double dataMin,
    required double dataMax,
    int targetTicks = 5,
  }) {
    if (targetTicks < 2) {
      throw ArgumentError.value(
        targetTicks,
        'targetTicks',
        'must be ≥ 2',
      );
    }

    var lo = math.min(dataMin, dataMax);
    var hi = math.max(dataMin, dataMax);

    if (lo == hi) {
      // Degenerate — pad symmetrically around the value so the chart
      // shows a visible band rather than a zero-height range.
      final pad = lo.abs() == 0 ? 1.0 : lo.abs() * 0.1;
      lo -= pad;
      hi += pad;
    }

    final range = _niceNumber(hi - lo, round: false);
    final step = _niceNumber(range / (targetTicks - 1), round: true);
    final niceMin = (lo / step).floor() * step;
    final niceMax = (hi / step).ceil() * step;

    return ChartAxisTicks._(min: niceMin, max: niceMax, step: step);
  }

  /// Convenience for time-series — derives bounds from a series'
  /// y-values. Empty series returns a `[0, 1]` placeholder so the
  /// caller can still render an axis without special-casing.
  static ChartAxisTicks fromSeries(
    Iterable<ChartSeries> seriesIterable, {
    int targetTicks = 5,
  }) {
    double? lo;
    double? hi;
    for (final series in seriesIterable) {
      for (final p in series.points) {
        if (lo == null || p.y < lo) lo = p.y;
        if (hi == null || p.y > hi) hi = p.y;
      }
    }
    if (lo == null || hi == null) {
      return ChartAxisTicks._(min: 0, max: 1, step: 1);
    }
    return compute(dataMin: lo, dataMax: hi, targetTicks: targetTicks);
  }

  /// Heckbert's "nice number" — finds the closest 1×, 2×, 5×, or 10×
  /// power-of-ten to [x]. With [round] = true, picks the closest
  /// nice number; with [round] = false, picks the smallest nice
  /// number ≥ [x] (used for the axis range itself).
  static double _niceNumber(double x, {required bool round}) {
    if (x <= 0) return 1; // Avoid log(0); fall back to a unit step.
    final exp = (math.log(x) / math.ln10).floor();
    final f = x / math.pow(10, exp); // Mantissa in [1, 10).
    double nf;
    if (round) {
      if (f < 1.5) {
        nf = 1;
      } else if (f < 3) {
        nf = 2;
      } else if (f < 7) {
        nf = 5;
      } else {
        nf = 10;
      }
    } else {
      if (f <= 1) {
        nf = 1;
      } else if (f <= 2) {
        nf = 2;
      } else if (f <= 5) {
        nf = 5;
      } else {
        nf = 10;
      }
    }
    return nf * math.pow(10, exp);
  }
}
