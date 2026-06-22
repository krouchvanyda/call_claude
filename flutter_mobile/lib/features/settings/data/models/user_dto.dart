/// Wire-format user payload returned by `/api/v1/users*` endpoints.
///
/// Mirrors the Spring `UserDto` record. Structurally identical to the
/// `UserDto` in `features/auth/data/models/auth_response.dart` —
/// duplicated rather than imported across feature boundaries so the
/// settings module doesn't depend on auth's data layer. If the two
/// shapes ever diverge (e.g. backend adds `lastLoginAt` only to the
/// list view), keep them separate; otherwise consider promoting to
/// `lib/core/models/`.
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.enabled = true,
    this.roles = const <String>[],
    this.permissions = const <String>[],
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool enabled;
  final List<String> roles;
  final List<String> permissions;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    // Roles + permissions can land as either of two shapes:
    //   1. Plain strings — `["SUPER_ADMIN"]` / `["role.read"]`
    //   2. Full DTOs    — `[{id, name, description, …}]`
    // Spring serialises `User.roles` as a `Set<Role>` by default, so the
    // object form is what `/users/me` actually returns. Calling
    // `.toString()` on a Map yields `{id: 1, name: SUPER_ADMIN}` which
    // looks present-but-junk to the super-admin gate. Unwrap the
    // canonical token (`name` → `code` → `token` → `id`) so the gate
    // sees a clean string list regardless of shape.
    List<String> readTokenList(String key) {
      final raw = json[key];
      if (raw is! List) return const <String>[];
      return raw
          .map<String>((e) {
            if (e is String) return e;
            if (e is Map) {
              // Prefer the canonical machine-readable `code` (e.g.
              // `SUPER_ADMIN`) over `name` (e.g. `Super Admin`) — `code`
              // is stable and used everywhere for RBAC checks. Fall
              // through to `token`/`id` if a permission DTO landed in
              // here instead of a role DTO.
              final v = e['code'] ?? e['name'] ?? e['token'] ?? e['id'];
              return (v ?? '').toString();
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    return UserDto(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '') as String,
      fullName: (json['fullName'] ?? json['name'] ?? json['displayName'] ?? '')
          as String,
      phone: json['phone'] as String?,
      enabled: (json['enabled'] ?? true) as bool,
      roles: readTokenList('roles'),
      permissions: readTokenList('permissions'),
    );
  }
}
