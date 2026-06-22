import 'package:drift/drift.dart';

import 'cached_user.dart';

/// Permission tokens the cached user holds — many rows per user.
///
/// `userId` references [CachedUser.id] with **`ON DELETE CASCADE`**, so a
/// `deleteUser(id)` automatically wipes the permissions row-set in the
/// same SQL statement. Foreign-key enforcement is enabled by the
/// `PRAGMA foreign_keys = ON` set in `AppDatabase.beforeOpen` (Slice
/// 0.3.1).
///
/// Composite primary key on `(userId, permission)` makes "does this user
/// have permission X?" lookups a single-row index probe, and prevents
/// accidental duplicates if a sync rewrites the same row twice.
@DataClassName('UserPermissionRow')
class UserPermissions extends Table {
  TextColumn get userId => text().references(
        CachedUser,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Opaque permission token — e.g. `'finance.invoice.create'`,
  /// `'admin'`. Treated as a stable string, not parsed locally.
  TextColumn get permission => text()();

  @override
  Set<Column<Object>> get primaryKey => {userId, permission};
}
