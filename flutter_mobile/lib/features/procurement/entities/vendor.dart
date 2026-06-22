/// Onboarding lifecycle (Slice 4.3.1).
enum VendorStatus { active, onHold, archived }

/// Master record for a vendor / supplier.
class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.taxId,
    required this.email,
    required this.phone,
    required this.address,
    required this.status,
    required this.onboardedAt,
    this.contactPerson,
    this.notes,
  });

  final String id;
  final String name;
  final String taxId;
  final String email;
  final String phone;
  final String address;
  final VendorStatus status;
  final DateTime onboardedAt;
  final String? contactPerson;
  final String? notes;

  Vendor copyWith({
    String? id,
    String? name,
    String? taxId,
    String? email,
    String? phone,
    String? address,
    VendorStatus? status,
    DateTime? onboardedAt,
    String? contactPerson,
    String? notes,
  }) =>
      Vendor(
        id: id ?? this.id,
        name: name ?? this.name,
        taxId: taxId ?? this.taxId,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        status: status ?? this.status,
        onboardedAt: onboardedAt ?? this.onboardedAt,
        contactPerson: contactPerson ?? this.contactPerson,
        notes: notes ?? this.notes,
      );
}
