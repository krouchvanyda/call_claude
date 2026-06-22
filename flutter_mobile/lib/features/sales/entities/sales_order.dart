import 'sales_quotation.dart' show SalesLineItem;

/// Workflow state for a sales order's *fulfillment* (Slice 6.2.3).
///
/// Decoupled from the approval workflow used on invoices: by the time
/// a sales order exists, the customer has already accepted; what
/// happens next is operational — pack, ship, deliver.
enum SalesOrderStatus { pending, packing, shipped, delivered, cancelled }

/// Sales order header + lines (Slice 6.2.1 / 6.2.2 / 6.2.3).
class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.lineItems,
    this.sourceQuotationId,
    this.shippedAt,
    this.deliveredAt,
    this.trackingReference,
  });

  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final SalesOrderStatus status;
  final String totalAmount;
  final List<SalesLineItem> lineItems;

  /// Set when the order was produced via [`convertQuotationToOrder`]
  /// (Slice 6.2.2). Lets the detail page link back to the quotation.
  final String? sourceQuotationId;

  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? trackingReference;

  SalesOrder copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    DateTime? createdAt,
    SalesOrderStatus? status,
    String? totalAmount,
    List<SalesLineItem>? lineItems,
    String? sourceQuotationId,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? trackingReference,
  }) =>
      SalesOrder(
        id: id ?? this.id,
        number: number ?? this.number,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        lineItems: lineItems ?? this.lineItems,
        sourceQuotationId: sourceQuotationId ?? this.sourceQuotationId,
        shippedAt: shippedAt ?? this.shippedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        trackingReference: trackingReference ?? this.trackingReference,
      );
}
