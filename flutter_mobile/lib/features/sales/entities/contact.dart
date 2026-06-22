/// One linked contact on a customer account (Slice 6.1.2).
class CustomerContact {
  const CustomerContact({
    required this.id,
    required this.customerId,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.isPrimary = false,
  });

  final String id;
  final String customerId;
  final String name;
  final String role;
  final String email;
  final String phone;

  /// Exactly one contact per customer is normally marked primary —
  /// the customer list / detail header surfaces this contact's info.
  final bool isPrimary;

  CustomerContact copyWith({
    String? id,
    String? customerId,
    String? name,
    String? role,
    String? email,
    String? phone,
    bool? isPrimary,
  }) =>
      CustomerContact(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        name: name ?? this.name,
        role: role ?? this.role,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerContact &&
          other.id == id &&
          other.customerId == customerId &&
          other.name == name &&
          other.role == role &&
          other.email == email &&
          other.phone == phone &&
          other.isPrimary == isPrimary;

  @override
  int get hashCode =>
      Object.hash(id, customerId, name, role, email, phone, isPrimary);
}
