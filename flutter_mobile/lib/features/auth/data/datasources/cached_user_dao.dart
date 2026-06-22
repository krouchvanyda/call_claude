import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../entities/user.dart';
import 'tables/cached_user.dart';
import 'tables/user_permissions.dart';

part 'cached_user_dao.g.dart';

/// Drift-backed cache for the signed-in [User] and their permission set.
///
/// Roles round-trip through the `user_permissions` table; the DAO returns
/// a typed domain [User] so callers in the repository / use-case layer
/// never see drift row classes.
///
/// **Storage rule** (CLAUDE.md → Module 1 Phase 1.1): profile + permissions
/// live here in drift; access/refresh tokens never do.
@DriftAccessor(tables: [CachedUser, UserPermissions])
class CachedUserDao extends DatabaseAccessor<AppDatabase>
    with _$CachedUserDaoMixin {
  CachedUserDao(super.db);

  // ── Writes ───────────────────────────────────────────────────
  /// Replaces the cached profile **and** the permission set atomically.
  ///
  /// Permissions are wiped + reinserted (rather than merged) so removed
  /// roles disappear immediately when the server downgrades a user.
  Future<void> cacheUser(User user) {
    return transaction(() async {
      await into(cachedUser).insert(
        CachedUserCompanion.insert(
          id: user.id,
          email: user.email,
          displayName: user.displayName,
        ),
        mode: InsertMode.insertOrReplace,
      );

      await (delete(userPermissions)
            ..where((r) => r.userId.equals(user.id)))
          .go();

      if (user.roles.isNotEmpty) {
        await batch((b) => b.insertAll(
              userPermissions,
              user.roles
                  .map((p) => UserPermissionsCompanion.insert(
                        userId: user.id,
                        permission: p,
                      ))
                  .toList(),
            ));
      }
    });
  }

  /// Deletes the user; CASCADE wipes their permissions in the same
  /// statement.
  Future<int> deleteUser(String userId) =>
      (delete(cachedUser)..where((r) => r.id.equals(userId))).go();

  /// Removes every permission row for [userId] without touching the
  /// profile. Useful when a server roundtrip refreshes the role set but
  /// leaves the identity intact (e.g. RBAC sync in Slice 1.3.x).
  Future<int> deletePermissions(String userId) =>
      (delete(userPermissions)..where((r) => r.userId.equals(userId))).go();

  /// Atomically replaces the permission set for [userId] — wipes the
  /// existing rows then bulk-inserts the new ones in a single
  /// transaction. Used by the RBAC refresh path (Slice 1.3.1) so a
  /// server-side downgrade can't leave a "ghost" admin permission
  /// behind.
  Future<void> replacePermissions(
    String userId,
    Set<String> permissions,
  ) {
    return transaction(() async {
      await (delete(userPermissions)..where((r) => r.userId.equals(userId)))
          .go();
      if (permissions.isNotEmpty) {
        await batch((b) => b.insertAll(
              userPermissions,
              permissions
                  .map((p) => UserPermissionsCompanion.insert(
                        userId: userId,
                        permission: p,
                      ))
                  .toList(growable: false),
            ));
      }
    });
  }

  /// Reactive variant of [getPermissions]. Subscribers receive a fresh
  /// `Set<String>` whenever the user's permission rows change — drives
  /// the route guard (Slice 1.3.2) and `PermissionGuard` widget (1.3.3)
  /// rebuilds.
  Stream<Set<String>> watchPermissionsFor(String userId) {
    return (select(userPermissions)
          ..where((r) => r.userId.equals(userId)))
        .watch()
        .map((rows) => rows.map((r) => r.permission).toSet());
  }

  /// Drops every cached user and every permission row. Called on logout
  /// (Slice 1.1.4) so a subsequent sign-in starts from a clean slate.
  Future<void> wipeAll() {
    return transaction(() async {
      // Order matters even with CASCADE — wipe children first so the
      // parent delete doesn't re-check FKs against stale rows.
      await delete(userPermissions).go();
      await delete(cachedUser).go();
    });
  }

  // ── Reads ────────────────────────────────────────────────────
  /// Returns the [User] for [userId] (including their permission set),
  /// or `null` when no row is cached.
  Future<User?> getUser(String userId) async {
    final row = await (select(cachedUser)..where((r) => r.id.equals(userId)))
        .getSingleOrNull();
    if (row == null) return null;
    final perms = await getPermissions(userId);
    return User(
      id: row.id,
      email: row.email,
      displayName: row.displayName,
      roles: perms,
    );
  }

  /// Returns the most-recently-cached user — the splash probe uses this to
  /// answer "who was last signed in on this device?".
  Future<User?> getCurrentUser() async {
    final row = await (select(cachedUser)
          ..orderBy([(r) => OrderingTerm.desc(r.cachedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return getUser(row.id);
  }

  /// Reactive variant for the AuthBloc / dashboard avatar to subscribe to.
  Stream<User?> watchCurrentUser() {
    final query = select(cachedUser)
      ..orderBy([(r) => OrderingTerm.desc(r.cachedAt)])
      ..limit(1);
    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final perms = await getPermissions(row.id);
      return User(
        id: row.id,
        email: row.email,
        displayName: row.displayName,
        roles: perms,
      );
    });
  }

  Future<Set<String>> getPermissions(String userId) async {
    final rows =
        await (select(userPermissions)..where((r) => r.userId.equals(userId)))
            .get();
    return rows.map((r) => r.permission).toSet();
  }

  /// Single-row indexed probe — used by the permission-aware route guard
  /// (Slice 1.3.2) and `PermissionGuard` widget (1.3.3) to avoid loading
  /// the full role set on every check.
  Future<bool> hasPermission(String userId, String permission) async {
    final row = await (select(userPermissions)
          ..where((r) =>
              r.userId.equals(userId) & r.permission.equals(permission))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
