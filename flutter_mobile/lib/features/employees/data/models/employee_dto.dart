/// Wire-format employee payload returned by `/api/v1/employees*`.
///
/// Mirrors the Spring `EmployeeDto` record. Field names are tolerant
/// of common Spring naming variants (e.g. `dateOfBirth` vs `birthdate`,
/// `hireDate` vs `hiredAt`) so a small backend rename doesn't ripple
/// into a crash on the mobile side. Optional fields stay nullable so
/// a partially-populated record (new hire still missing personal info)
/// still parses cleanly.
class EmployeeDto {
  const EmployeeDto({
    required this.id,
    required this.fullName,
    this.code,
    this.email,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.hireDate,
    this.address,
    this.department,
    this.positionTitle,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.lastLoginAt,
  });

  /// Numeric Long on the JVM, stringified here to keep parity with
  /// every other id in the app's domain layer.
  final String id;

  /// Machine-readable employee code (e.g. `EMP-001`). Distinct from
  /// [id] — meant for display + barcode/badge scenarios.
  final String? code;

  final String fullName;
  final String? email;
  final String? phone;

  /// Backend returns either a relative path (`/uploads/employees/3/…`)
  /// or a full URL. The repository layer resolves it against the API
  /// base URL before handing it to the UI.
  final String? avatarUrl;

  final DateTime? dateOfBirth;
  final DateTime? hireDate;
  final String? address;
  final String? department;
  final String? positionTitle;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  /// Last time the linked user account signed in. Comes back as
  /// ISO-8601 UTC (`2026-05-27T07:16:52.994093Z`) and is shown on the
  /// profile's Account Security row.
  final DateTime? lastLoginAt;

  /// Lightweight copy — only fields the data source actually rewrites
  /// post-parse (the avatar URL, currently). Add more parameters when
  /// callers need them; no point listing every field upfront.
  EmployeeDto copyWith({String? avatarUrl}) => EmployeeDto(
        id: id,
        fullName: fullName,
        code: code,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        dateOfBirth: dateOfBirth,
        hireDate: hireDate,
        address: address,
        department: department,
        positionTitle: positionTitle,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        lastLoginAt: lastLoginAt,
      );

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    // First non-empty string across [keys]. Variadic so we can list as
    // many aliases as we need without nested ternaries.
    String? firstString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final t = v.toString();
        if (t.isNotEmpty) return t;
      }
      return null;
    }

    DateTime? firstDate(List<String> keys) {
      final s = firstString(keys);
      if (s == null) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return EmployeeDto(
      id: (json['id'] ?? '').toString(),
      // Backend ships `employeeNo` (confirmed) — left the older
      // `code`/`employeeCode` aliases in place so an unrelated rename
      // upstream doesn't break the page.
      code: firstString(['employeeNo', 'employeeCode', 'code']),
      fullName: firstString(['fullName', 'name', 'displayName']) ?? '',
      // `workEmail` (confirmed) takes priority; fall back to plain
      // `email` for backwards compat.
      email: firstString(['workEmail', 'email', 'personalEmail']),
      phone: firstString(
          ['workPhone', 'phone', 'phoneNumber', 'mobile', 'personalPhone']),
      avatarUrl: firstString(['avatarUrl', 'avatar', 'photoUrl']),
      dateOfBirth: firstDate(['dateOfBirth', 'birthDate', 'birthdate']),
      hireDate: firstDate(['hireDate', 'hiredAt', 'joinDate']),
      address: firstString(['address']),
      department: firstString(['department', 'departmentName']),
      // Backend ships `position` (confirmed); aliases kept so a
      // future rename to `jobTitle`/`positionTitle` wouldn't break.
      positionTitle:
          firstString(['position', 'positionTitle', 'jobTitle', 'title']),
      // Backend uses ONE field `emergencyContact` for the contact's
      // name + `emergencyPhone` for the phone — not the two-part
      // `emergencyContactName`/`emergencyContactPhone` pair we used
      // to send. The naming mismatch is exactly why the values never
      // round-tripped before this commit.
      emergencyContactName:
          firstString(['emergencyContact', 'emergencyContactName', 'emergencyName']),
      emergencyContactPhone:
          firstString(['emergencyPhone', 'emergencyContactPhone']),
      lastLoginAt: firstDate(['lastLoginAt', 'lastSignInAt']),
    );
  }
}
