/// Client-side mirror of the backend `Permissions` constants
/// (`com.company.erp.core.security.Permissions`).
///
/// The Spring controllers gate their endpoints with
/// `@PreAuthorize("hasAuthority('" + Permissions.X + "')")` — the
/// strings here MUST match the server-side values byte-for-byte or
/// `currentUser.permissions.contains(...)` will silently miss.
///
/// Keep this file in sync with the Java side. If the backend ever
/// flips its naming convention (e.g. `ROLE_WRITE` → `role.write`),
/// fix it here in one place rather than every call site.
///
/// **Note on values** — the actual string is the part the JWT carries
/// in `permissions[]`. Looking at the API.md and seed migration V3,
/// the convention is dotted lowercase (e.g. `role.read`). If your
/// `Permissions.java` uses a different format (`ROLE_WRITE` constant
/// → value `"ROLE_WRITE"`), update the string literals below.
abstract final class AppPermissions {
  // ── Roles ─────────────────────────────────────────────────────
  static const String roleRead = 'role.read';
  static const String roleWrite = 'role.write';

  // ── Users ─────────────────────────────────────────────────────
  static const String userRead = 'user.read';
  static const String userWrite = 'user.write';

  // ── Chat ──────────────────────────────────────────────────────
  static const String chatRead = 'chat.read';
  static const String chatWrite = 'chat.write';

  // ── Roles (codes from V3 seed) ────────────────────────────────
  /// Backend seed: V3 ships SUPER_ADMIN / ADMIN / STAFF / CUSTOMER.
  /// Role-management screens treat SUPER_ADMIN as the only role
  /// allowed to assign permissions or change other users' roles —
  /// regular ADMIN can read but not write.
  static const String superAdminRoleCode = 'SUPER_ADMIN';
}

/// Returns `true` when [roles] contains the super-admin role code.
///
/// Tolerant of common naming variants the backend might ship:
///   - `SUPER_ADMIN`  (V3 seed canonical, per API.md)
///   - `Super Admin`  (the actual `roles.name` value the team's
///                     `WHERE name = 'Super Admin'` SQL targets)
///   - `super_admin`  (lowercase)
///   - `SUPERADMIN`   (no separator)
///   - `ROLE_SUPER_ADMIN` (Spring Security `ROLE_` prefix convention)
///
/// Normalisation: trim → uppercase → strip non-alphanumerics → also
/// accept a `ROLE_` prefix. So all the variants above collapse to
/// `SUPERADMIN` after normalisation and match the same constant.
bool isSuperAdmin(Iterable<String> roles) {
  final target = AppPermissions.superAdminRoleCode.replaceAll('_', '');
  for (final r in roles) {
    var normalized = r.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalized.startsWith('ROLE')) {
      normalized = normalized.substring(4);
    }
    if (normalized == target) return true;
  }
  return false;
}

/// Convenience: returns `true` when [granted] contains [required] or
/// any wildcard that subsumes it (e.g. `role.*` covers `role.read`).
///
/// The backend may issue grants at either fine-grained (`role.read`)
/// or wildcard (`role.*` / `admin`) granularity. Centralising the
/// match here so widget-level gates don't reimplement the logic.
bool hasPermission(Iterable<String> granted, String required) {
  if (granted.contains(required)) return true;
  if (granted.contains('admin')) return true;

  // Wildcard match — e.g. `role.write` is satisfied by `role.*`.
  final dotIndex = required.indexOf('.');
  if (dotIndex > 0) {
    final wildcard = '${required.substring(0, dotIndex)}.*';
    if (granted.contains(wildcard)) return true;
  }
  return false;
}
