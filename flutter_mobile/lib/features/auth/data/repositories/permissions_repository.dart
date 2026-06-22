import '../../entities/permission.dart';
import '../datasources/cached_user_dao.dart';

/// Drift-backed per-user permission cache.
///
/// Maps `String ↔ Permission` at the boundary so the storage layer
/// stays string-keyed (matches what `user_permissions` already holds)
/// while the rest of the codebase works with the typed [Permission]
/// surface.
///
/// Wraps the raw `String`-keyed `user_permissions` table (Slice 1.1.2b)
/// in a typed [Permission] surface. The route guard (1.3.2) and the
/// `PermissionGuard` widget (1.3.3) are the primary consumers; the
/// auth feature's own refresh path uses [cachePermissions] when the
/// server returns a fresh role set.
class PermissionsRepository {
  PermissionsRepository({required CachedUserDao cachedUserDao})
      : _dao = cachedUserDao;

  final CachedUserDao _dao;

  /// Snapshot of the [userId]'s held permissions. Empty set when no
  /// row is cached yet (treat as "no privileges").
  Future<Set<Permission>> getPermissions(String userId) async {
    final raw = await _dao.getPermissions(userId);
    return raw.map(Permission.parse).toSet();
  }

  /// Reactive variant — emits a fresh set whenever any
  /// `user_permissions` row for [userId] changes.
  Stream<Set<Permission>> watchPermissions(String userId) {
    return _dao
        .watchPermissionsFor(userId)
        .map((raw) => raw.map(Permission.parse).toSet());
  }

  /// Atomically replaces the cached permissions for [userId]. Intended
  /// for the post-sign-in / post-RBAC-refresh path: server hands back
  /// the authoritative list, we replace ours wholesale.
  Future<void> cachePermissions(
    String userId,
    Set<Permission> permissions,
  ) {
    return _dao.replacePermissions(
      userId,
      permissions.map((p) => p.token).toSet(),
    );
  }

  /// Convenience predicate for ad-hoc checks. Honours the wildcard
  /// semantics from [Permission.grants].
  Future<bool> hasPermission(String userId, Permission required) async {
    final held = await getPermissions(userId);
    return held.grant(required);
  }
}
