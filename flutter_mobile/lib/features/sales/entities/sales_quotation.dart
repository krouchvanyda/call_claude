/// Lifecycle of a sales quotation (Slice 6.2.1).
enum QuotationStatus { draft, sent, accepted, rejected, expired, converted }

/// One line on a quotation or sales order.
class SalesLineItem {
  const SalesLineItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.sku,
  });

  final String id;
  final String description;
  final String? sku;
  final num quantity;
  final String unitPrice;
  final String lineTotal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesLineItem &&
          other.id == id &&
          other.description == description &&
          other.sku == sku &&
          other.quantity == quantity &&
          other.unitPrice == unitPrice &&
          other.lineTotal == lineTotal;

  @override
  int get hashCode =>
      Object.hash(id, description, sku, quantity, unitPrice, lineTotal);
}

/// Quotation header + lines (Slice 6.2.1).
class SalesQuotation {
  const SalesQuotation({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    required this.validUntil,
    required this.status,
    required this.totalAmount,
    required this.lineItems,
    this.notes,
  });

  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final DateTime validUntil;
  final QuotationStatus status;
  final String totalAmount;
  final List<SalesLineItem> lineItems;
  final String? notes;

  SalesQuotation copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    DateTime? createdAt,
    DateTime? validUntil,
    QuotationStatus? status,
    String? totalAmount,
    List<SalesLineItem>? lineItems,
    String? notes,
  }) =>
      SalesQuotation(
        id: id ?? this.id,
        number: number ?? this.number,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        createdAt: createdAt ?? this.createdAt,
        validUntil: validUntil ?? this.validUntil,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        lineItems: lineItems ?? this.lineItems,
        notes: notes ?? this.notes,
      );
}

/// Sort axes for the quotation list (Slice 6.2.1).
enum QuotationSort { createdDesc, createdAsc, totalDesc, validityAsc }
