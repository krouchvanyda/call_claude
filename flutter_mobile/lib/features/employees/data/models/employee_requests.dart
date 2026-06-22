/// `PATCH /api/v1/employees/{id}` body — mirrors the Spring record
/// `UpdateEmployeeRequest`. All fields optional; only set ones are
/// serialised so the backend's partial-update semantics decide what
/// to touch.
///
/// Field names follow the convention established by `UserDto` +
/// `UpdateUserRequest` — Spring's Jackson is configured for camelCase
/// throughout the ERP, so `fullName` / `dateOfBirth` etc. all match
/// what the controller expects without an `@JsonAlias`.
///
/// Dates use ISO-8601 (`yyyy-MM-dd`) which `LocalDate.parse` accepts
/// straight off the wire.
class UpdateEmployeeRequest {
  const UpdateEmployeeRequest({
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.department,
    this.positionTitle,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? department;
  final String? positionTitle;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    void putString(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        json[key] = value.trim();
      }
    }

    putString('fullName', fullName);
    // Field name notes — all confirmed against Spring's
    // `UpdateEmployeeRequest` record:
    //   - `workEmail`        (not `email`)
    //   - `phone`            (not `workPhone`)
    //   - `position`         (not `positionTitle` / `jobTitle`)
    //   - `emergencyContact` (single string for the name)
    //   - `emergencyPhone`   (single string for the phone)
    // Earlier sends under `emergencyContactName`/`emergencyContactPhone`
    // were silently dropped by Jackson because the record had no
    // setters with those names.
    putString('workEmail', email);
    putString('phone', phone);
    putString('address', address);
    putString('department', department);
    putString('position', positionTitle);
    putString('emergencyContact', emergencyContactName);
    putString('emergencyPhone', emergencyContactPhone);
    if (dateOfBirth != null) {
      // ISO `yyyy-MM-dd`; no time component (Spring `LocalDate`).
      final d = dateOfBirth!;
      json['dateOfBirth'] =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }
    return json;
  }
}
