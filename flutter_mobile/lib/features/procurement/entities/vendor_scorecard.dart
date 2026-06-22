/// Raw stats fed into [computeVendorScorecard] (Slice 4.3.3).
class VendorPerformanceStats {
  const VendorPerformanceStats({
    required this.totalDeliveries,
    required this.onTimeDeliveries,
    required this.totalUnitsReceived,
    required this.defectiveUnits,
    required this.totalSpend,
    required this.openDisputes,
  });

  final int totalDeliveries;
  final int onTimeDeliveries;
  final int totalUnitsReceived;
  final int defectiveUnits;

  /// Pre-formatted spend (e.g. `r'$48,200.00'`); kept opaque so the
  /// scorecard isn't tempted to do currency math.
  final String totalSpend;
  final int openDisputes;
}

/// Visual grade bucket (Slice 4.3.3) — derived from the composite score.
enum VendorGrade { a, b, c, d }

/// Output of [computeVendorScorecard]. All percentages are 0.0..100.0.
class VendorScorecard {
  const VendorScorecard({
    required this.onTimeRatePct,
    required this.defectRatePct,
    required this.compositeScore,
    required this.grade,
    required this.totalSpend,
    required this.openDisputes,
  });

  final double onTimeRatePct;
  final double defectRatePct;

  /// Composite 0..100, weighted: 60% on-time + 40% defect-free, with a
  /// flat penalty per open dispute (capped at -20).
  final double compositeScore;
  final VendorGrade grade;
  final String totalSpend;
  final int openDisputes;
}
