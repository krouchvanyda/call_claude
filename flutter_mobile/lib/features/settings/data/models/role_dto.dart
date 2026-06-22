/// Wire-format role payload returned by `/api/v1/roles*` endpoints.
///
/// Mirrors the Spring `RoleDto` record. `id` arrives as a number (Long
/// on the JVM) and is toString'd into a Dart `String` to keep parity
/// with every other id in the app's domain layer.
///
/// `isSystem` is optional on the wire — the Spring record may or may
/// not expose it depending on whether system roles are read-only on
/// the server side. Defaults to `false` when missing.
class RoleDto {
  const RoleDto({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.permissionTokens = const <String>[],
    this.isSystem = false,
  });

  final String id;

  /// Machine-readable canonical identifier — e.g. `SUPER_ADMIN`. This
  /// is what RBAC checks should compare against. Stable across locales
  /// (the human-friendly [name] gets translated; [code] never does).
  final String code;

  /// Human-readable display name — e.g. `Super Admin`. Use in UI only.
  final String name;
  final String description;

  /// Permission tokens granted to this role. Backend ships them as a
  /// plain string list (e.g. `["user:write", "role:read"]`) — the
  /// canonical separator is `:`, not `.`.
  final List<String> permissionTokens;
  final bool isSystem;

  factory RoleDto.fromJson(Map<String, dynamic> json) {
    // Backend sends `permissions: ["user:write", …]` on this endpoint.
    // Older drafts used `permissionTokens` — accept either for safety.
    final permsRaw = json['permissions'] ??
        json['permissionTokens'] ??
        const <dynamic>[];
    return RoleDto(
      id: (json['id'] ?? '').toString(),
      // `code` may be missing on older payloads — fall back to `name`
      // so the dropdown still works during the upgrade window.
      code: (json['code'] ?? json['name'] ?? '').toString(),
      name: (json['name'] ?? json['code'] ?? '').toString(),
      description: (json['description'] ?? '') as String,
      permissionTokens: (permsRaw is List ? permsRaw : const <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false),
      isSystem: (json['isSystem'] ?? json['system'] ?? false) as bool,
    );
  }
}

/// Wire-format permission descriptor — used by the role editor to render
/// the list of grantable scopes alongside an optional human-readable
/// group label and description.
///
/// Mirrors the Spring `PermissionDto`. The exact backend field names
/// aren't documented; tolerant of `token` / `name` / `scope` for the
/// canonical id and `group` / `category` for the grouping label.
class PermissionDto {
  const PermissionDto({
    required this.token,
    this.group,
    this.description,
  });

  final String token;
  final String? group;
  final String? description;

  factory PermissionDto.fromJson(Map<String, dynamic> json) {
    return PermissionDto(
      token: (json['token'] ?? json['name'] ?? json['scope'] ?? '').toString(),
      group: (json['group'] ?? json['category']) as String?,
      description: json['description'] as String?,
    );
  }
}
