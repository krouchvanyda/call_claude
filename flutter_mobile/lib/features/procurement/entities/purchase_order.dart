/// Lifecycle states of a purchase order (Slice 4.2.1).
///
/// Workflow: `open → partially_received → fully_received → closed`.
/// `cancelled` is terminal and reachable from `open` only.
enum PurchaseOrderStatus { open, partiallyReceived, fullyReceived, closed, cancelled }

/// Header + lines for a PO. The list view shows headers; the detail
/// view shows lines + receipt history (Slice 4.2.3 goods receipts).
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.number,
    required this.vendorId,
    required this.vendorName,
    required this.createdAt,
    required this.expectedAt,
    required this.status,
    required this.totalAmount,
    required this.lineItems,
    this.sourcePurchaseRequestId,
  });

  final String id;
  final String number;
  final String vendorId;
  final String vendorName;
  final DateTime createdAt;
  final DateTime expectedAt;
  final PurchaseOrderStatus status;
  final String totalAmount;
  final List<PurchaseOrderLine> lineItems;

  /// Set when the PO was created via PR→PO conversion (Slice 4.2.2).
  /// Lets the detail page link back to the originating PR for audit.
  final String? sourcePurchaseRequestId;

  PurchaseOrder copyWith({
    String? id,
    String? number,
    String? vendorId,
    String? vendorName,
    DateTime? createdAt,
    DateTime? expectedAt,
    PurchaseOrderStatus? status,
    String? totalAmount,
    List<PurchaseOrderLine>? lineItems,
    String? sourcePurchaseRequestId,
  }) =>
      PurchaseOrder(
        id: id ?? this.id,
        number: number ?? this.number,
        vendorId: vendorId ?? this.vendorId,
        vendorName: vendorName ?? this.vendorName,
        createdAt: createdAt ?? this.createdAt,
        expectedAt: expectedAt ?? this.expectedAt,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        lineItems: lineItems ?? this.lineItems,
        sourcePurchaseRequestId:
            sourcePurchaseRequestId ?? this.sourcePurchaseRequestId,
      );
}

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.description,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.unitPrice,
    required this.lineTotal,
    this.sku,
  });

  final String id;
  final String description;
  final String? sku;
  final num orderedQuantity;
  final num receivedQuantity;
  final String unitPrice;
  final String lineTotal;

  num get outstandingQuantity =>
      (orderedQuantity - receivedQuantity).clamp(0, orderedQuantity);

  PurchaseOrderLine copyWith({
    String? id,
    String? description,
    String? sku,
    num? orderedQuantity,
    num? receivedQuantity,
    String? unitPrice,
    String? lineTotal,
  }) =>
      PurchaseOrderLine(
        id: id ?? this.id,
        description: description ?? this.description,
        sku: sku ?? this.sku,
        orderedQuantity: orderedQuantity ?? this.orderedQuantity,
        receivedQuantity: receivedQuantity ?? this.receivedQuantity,
        unitPrice: unitPrice ?? this.unitPrice,
        lineTotal: lineTotal ?? this.lineTotal,
      );
}
