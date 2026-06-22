/// `POST /api/v1/users` body — admin creates a new user.
///
/// Mirrors the Spring `CreateUserRequest` record. `roles` defaults to
/// empty so the backend can apply its own default role assignment.
///
/// Field convention (matches the confirmed `UpdateUserRequest`):
///   - JSON key is `roles`, NOT `roleIds`
///   - Values are role **codes** (e.g. `"SUPER_ADMIN"`, `"STAFF"`),
///     NOT numeric primary keys. The backend resolves codes → entities
///     when applying the update.
class CreateUserRequest {
  const CreateUserRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.roles = const <String>[],
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;

  /// Role codes (`SUPER_ADMIN` / `ADMIN` / `STAFF` / `CUSTOMER`).
  /// Serialised as a JSON array; Spring maps it to `Set<String>` and
  /// dedups internally.
  final List<String> roles;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'roles': roles,
      };
}

/// `PATCH /api/v1/users/{id}` body — admin partial update.
///
/// Mirrors the Spring record:
/// ```java
/// public record UpdateUserRequest(
///     String fullName,
///     String phone,
///     String avatarUrl,
///     Boolean enabled,
///     Set<String> roles   // role codes, null = leave untouched
/// ) {}
/// ```
///
/// Every field optional. Null values are omitted from the JSON entirely
/// so the backend's partial-update semantics decide what to touch —
/// matching the contract that `null roles` means "leave roles alone"
/// while an empty list means "strip every role".
class UpdateUserRequest {
  const UpdateUserRequest({
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.enabled,
    this.roles,
  });

  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool? enabled;

  /// Role codes — e.g. `["SUPER_ADMIN"]`. Backend resolves the codes
  /// to entities and writes them as the user's full role set. Empty
  /// list strips every role; `null` (the default) leaves them alone.
  final List<String>? roles;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (fullName != null && fullName!.trim().isNotEmpty) {
      json['fullName'] = fullName!.trim();
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      json['phone'] = phone!.trim();
    }
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      json['avatarUrl'] = avatarUrl!.trim();
    }
    if (enabled != null) {
      json['enabled'] = enabled;
    }
    if (roles != null) {
      json['roles'] = roles;
    }
    return json;
  }
}
