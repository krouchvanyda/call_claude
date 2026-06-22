/// `POST /api/v1/roles` body.
///
/// Mirrors the Spring record:
/// ```java
/// public record CreateRoleRequest(
///     @NotBlank @Size(max=64)  String code,
///     @NotBlank @Size(max=128) String name,
///     @Size(max=255) String description,
///     Set<String> permissions
/// ) {}
/// ```
///
/// `code` and `name` are required (`@NotBlank`); `description` is
/// optional. `permissions` is a set of permission codes — Spring
/// dedups; we ship a list and let the backend convert.
class CreateRoleRequest {
  const CreateRoleRequest({
    required this.code,
    required this.name,
    this.description,
    this.permissions = const <String>[],
  });

  /// Machine identifier — e.g. `SUPER_ADMIN`. Max 64 chars per backend.
  final String code;
  final String name;
  final String? description;

  /// Permission codes — e.g. `["user:read", "role:write"]`.
  final List<String> permissions;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'code': code,
      'name': name,
      'permissions': permissions,
    };
    if (description != null && description!.trim().isNotEmpty) {
      json['description'] = description!.trim();
    }
    return json;
  }
}

/// `PATCH /api/v1/roles/{id}` body.
///
/// Mirrors the Spring record:
/// ```java
/// public record UpdateRoleRequest(
///     @Size(max=128) String name,
///     @Size(max=255) String description,
///     Set<String> permissions   // null = leave untouched
/// ) {}
/// ```
///
/// Every field optional — only fields the caller actually wants to
/// change are sent. The `code` is immutable on the backend (no
/// corresponding field on the DTO) and cannot be edited after create.
class UpdateRoleRequest {
  const UpdateRoleRequest({
    this.name,
    this.description,
    this.permissions,
  });

  final String? name;
  final String? description;

  /// Permission codes — replaces the role's full permission set.
  /// `null` leaves them untouched; empty list strips everything.
  final List<String>? permissions;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null && name!.trim().isNotEmpty) {
      json['name'] = name!.trim();
    }
    if (description != null) {
      // Empty string is a legitimate "clear description" signal — only
      // skip when truly null.
      json['description'] = description!.trim();
    }
    if (permissions != null) {
      json['permissions'] = permissions;
    }
    return json;
  }
}
