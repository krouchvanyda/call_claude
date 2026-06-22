/// One line of a cycle count — what the system *expected* on the
/// shelf vs what the counter *actually* found (Slice 5.2.4).
class CycleCountLine {
  const CycleCountLine({
    required this.itemId,
    required this.expectedQty,
    required this.countedQty,
  });

  final String itemId;
  final num expectedQty;
  final num countedQty;

  /// Signed difference. Positive means we found more than expected
  /// (the system was under-recording); negative means shrinkage.
  num get variance => countedQty - expectedQty;
}

/// A cycle count session against a specific location bin / list
/// (Slice 5.2.4).
class CycleCount {
  const CycleCount({
    required this.id,
    required this.warehouseCode,
    required this.locationCode,
    required this.startedAt,
    required this.lines,
    this.completedAt,
    this.note,
  });

  final String id;
  final String warehouseCode;
  final String locationCode;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<CycleCountLine> lines;
  final String? note;

  bool get isCompleted => completedAt != null;
}
