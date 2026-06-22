/// Goods receipt — a record of a partial or complete physical
/// arrival against a PO line (Slice 4.2.3). Multiple receipts can
/// accumulate against a single PO until it's fully received.
class GoodsReceipt {
  const GoodsReceipt({
    required this.id,
    required this.purchaseOrderId,
    required this.receivedAt,
    required this.receivedBy,
    required this.lines,
    this.note,
  });

  final String id;
  final String purchaseOrderId;
  final DateTime receivedAt;
  final String receivedBy;
  final List<GoodsReceiptLine> lines;
  final String? note;
}

class GoodsReceiptLine {
  const GoodsReceiptLine({
    required this.purchaseOrderLineId,
    required this.quantity,
  });
  final String purchaseOrderLineId;
  final num quantity;
}
