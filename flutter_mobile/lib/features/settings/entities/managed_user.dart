/// Slice 9.2.1 — admin-managed user record.
enum ManagedUserStatus { active, invited, suspended }

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.name,
    required this.status,
    required this.roleIds,
    required this.createdAt,
    this.lastSeenAt,
  });

  final String id;
  final String email;
  final String name;
  final ManagedUserStatus status;
  final List<String> roleIds;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  ManagedUser copyWith({
    String? id,
    String? email,
    String? name,
    ManagedUserStatus? status,
    List<String>? roleIds,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) =>
      ManagedUser(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        status: status ?? this.status,
        roleIds: roleIds ?? this.roleIds,
        createdAt: createdAt ?? this.createdAt,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ManagedUser) return false;
    if (other.id != id ||
        other.email != email ||
        other.name != name ||
        other.status != status ||
        other.createdAt != createdAt ||
        other.lastSeenAt != lastSeenAt) {
      return false;
    }
    if (other.roleIds.length != roleIds.length) return false;
    for (var i = 0; i < roleIds.length; i++) {
      if (other.roleIds[i] != roleIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        email,
        name,
        status,
        Object.hashAll(roleIds),
        createdAt,
        lastSeenAt,
      );
}

/// Slice 9.2.2 — role with its permission scopes.
///
/// `isSystem` flags built-in roles ("admin", "viewer") that the editor
/// must not allow editing/deleting — those are seeded by the API and
/// changing them would create configuration drift.
class Role {
  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionTokens,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final String description;
  final List<String> permissionTokens;
  final bool isSystem;

  Role copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? permissionTokens,
    bool? isSystem,
  }) =>
      Role(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        permissionTokens: permissionTokens ?? this.permissionTokens,
        isSystem: isSystem ?? this.isSystem,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Role) return false;
    if (other.id != id ||
        other.name != name ||
        other.description != description ||
        other.isSystem != isSystem) {
      return false;
    }
    if (other.permissionTokens.length != permissionTokens.length) {
      return false;
    }
    for (var i = 0; i < permissionTokens.length; i++) {
      if (other.permissionTokens[i] != permissionTokens[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        Object.hashAll(permissionTokens),
        isSystem,
      );
}
