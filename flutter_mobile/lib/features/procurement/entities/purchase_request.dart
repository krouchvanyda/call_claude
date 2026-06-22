/// Lifecycle states of a purchase request (Slice 4.1.1).
///
/// Workflow: `draft → submitted → approved → converted` (happy path).
/// `rejected` is terminal. `converted` means a PO has been generated
/// (Slice 4.2.2) — the PR is closed but kept for audit.
enum PurchaseRequestStatus { draft, submitted, approved, rejected, converted }

/// Sort axes for the PR list (Slice 4.1.1).
enum PurchaseRequestSort { createdDesc, createdAsc, totalDesc, numberAsc }

/// Header record for a PR. Line items are owned by [PurchaseRequest]
/// because the list view needs the count and the form view needs the
/// itemised body — splitting them would force a second roundtrip on
/// every detail open.
class PurchaseRequest {
  const PurchaseRequest({
    required this.id,
    required this.number,
    required this.requesterName,
    required this.costCenter,
    required this.approverName,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.lineItems,
    this.justification,
  });

  final String id;
  final String number;
  final String requesterName;
  final String costCenter;
  final String approverName;
  final DateTime createdAt;
  final PurchaseRequestStatus status;

  /// Pre-formatted to keep entities locale-stable (e.g. `r'$1,234.56'`).
  final String totalAmount;

  final List<PurchaseRequestLine> lineItems;

  /// Optional free-text rationale entered on the form.
  final String? justification;

  PurchaseRequest copyWith({
    String? id,
    String? number,
    String? requesterName,
    String? costCenter,
    String? approverName,
    DateTime? createdAt,
    PurchaseRequestStatus? status,
    String? totalAmount,
    List<PurchaseRequestLine>? lineItems,
    String? justification,
  }) {
    return PurchaseRequest(
      id: id ?? this.id,
      number: number ?? this.number,
      requesterName: requesterName ?? this.requesterName,
      costCenter: costCenter ?? this.costCenter,
      approverName: approverName ?? this.approverName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      lineItems: lineItems ?? this.lineItems,
      justification: justification ?? this.justification,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseRequest &&
          other.id == id &&
          other.number == number &&
          other.requesterName == requesterName &&
          other.costCenter == costCenter &&
          other.approverName == approverName &&
          other.createdAt == createdAt &&
          other.status == status &&
          other.totalAmount == totalAmount &&
          other.justification == justification &&
          _listEquals(other.lineItems, lineItems);

  @override
  int get hashCode => Object.hash(
        id,
        number,
        requesterName,
        costCenter,
        approverName,
        createdAt,
        status,
        totalAmount,
        justification,
        Object.hashAll(lineItems),
      );
}

class PurchaseRequestLine {
  const PurchaseRequestLine({
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
      other is PurchaseRequestLine &&
          other.id == id &&
          other.description == description &&
          other.sku == sku &&
          other.quantity == quantity &&
          other.unitPrice == unitPrice &&
          other.lineTotal == lineTotal;

  @override
  int get hashCode => Object.hash(
        id,
        description,
        sku,
        quantity,
        unitPrice,
        lineTotal,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
