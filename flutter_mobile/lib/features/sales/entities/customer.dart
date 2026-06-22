/// Onboarding/lifecycle status (Slice 6.1.1).
enum CustomerStatus { prospect, active, onHold, churned }

/// Coarse segmentation — drives the "top customers" widget grouping
/// (Slice 6.3.2) without us inventing CRM segmentation theory.
enum CustomerSegment { smb, midMarket, enterprise }

/// Sort axes for the customer list (Slice 6.1.1).
enum CustomerSort { nameAsc, lifetimeValueDesc, recentlyAdded }

/// Master record for a customer / account.
///
/// **Pure data**: no Flutter, no drift. [lifetimeValue] is
/// pre-formatted so the entity stays locale-stable — analytics
/// computations consume the raw rollup data via the activity ledger,
/// not this string.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.billingAddress,
    required this.segment,
    required this.status,
    required this.onboardedAt,
    required this.lifetimeValue,
    this.industry,
    this.notes,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String billingAddress;
  final CustomerSegment segment;
  final CustomerStatus status;
  final DateTime onboardedAt;

  /// Pre-formatted (e.g. `r'$48,200.00'`).
  final String lifetimeValue;

  final String? industry;
  final String? notes;

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? billingAddress,
    CustomerSegment? segment,
    CustomerStatus? status,
    DateTime? onboardedAt,
    String? lifetimeValue,
    String? industry,
    String? notes,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        billingAddress: billingAddress ?? this.billingAddress,
        segment: segment ?? this.segment,
        status: status ?? this.status,
        onboardedAt: onboardedAt ?? this.onboardedAt,
        lifetimeValue: lifetimeValue ?? this.lifetimeValue,
        industry: industry ?? this.industry,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.phone == phone &&
          other.billingAddress == billingAddress &&
          other.segment == segment &&
          other.status == status &&
          other.onboardedAt == onboardedAt &&
          other.lifetimeValue == lifetimeValue &&
          other.industry == industry &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        email,
        phone,
        billingAddress,
        segment,
        status,
        onboardedAt,
        lifetimeValue,
        industry,
        notes,
      );
}
