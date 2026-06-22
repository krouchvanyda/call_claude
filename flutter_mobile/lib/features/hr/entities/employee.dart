/// Employment lifecycle status (Slice 7.1.1).
enum EmploymentStatus { active, onLeave, suspended, terminated }

/// Sort axes for the employee list.
enum EmployeeSort { nameAsc, recentlyHired, departmentAsc }

/// Master record for an employee.
///
/// **Pure data**: no Flutter, no drift. `monthlySalary` is pre-formatted
/// so the entity stays locale-stable — the payslip generator (Phase 7.3)
/// reads raw amounts off `Payslip.lineItems`, not this string.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.position,
    required this.hiredAt,
    required this.status,
    required this.monthlySalary,
    this.managerId,
    this.avatarUrl,
    this.location,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String position;
  final DateTime hiredAt;
  final EmploymentStatus status;

  /// Pre-formatted (e.g. `r'$2,400.00'`).
  final String monthlySalary;

  final String? managerId;
  final String? avatarUrl;
  final String? location;

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    DateTime? hiredAt,
    EmploymentStatus? status,
    String? monthlySalary,
    String? managerId,
    String? avatarUrl,
    String? location,
  }) =>
      Employee(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        department: department ?? this.department,
        position: position ?? this.position,
        hiredAt: hiredAt ?? this.hiredAt,
        status: status ?? this.status,
        monthlySalary: monthlySalary ?? this.monthlySalary,
        managerId: managerId ?? this.managerId,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        location: location ?? this.location,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.phone == phone &&
          other.department == department &&
          other.position == position &&
          other.hiredAt == hiredAt &&
          other.status == status &&
          other.monthlySalary == monthlySalary &&
          other.managerId == managerId &&
          other.avatarUrl == avatarUrl &&
          other.location == location;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        email,
        phone,
        department,
        position,
        hiredAt,
        status,
        monthlySalary,
        managerId,
        avatarUrl,
        location,
      );
}
