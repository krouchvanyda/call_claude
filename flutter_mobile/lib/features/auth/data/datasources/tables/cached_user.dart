import 'package:drift/drift.dart';

/// Cached identity of the signed-in user — drives offline RBAC + the
/// "who am I?" splash probe.
///
/// **Strict-rule reminder**: profile + permissions live here in drift;
/// access/refresh tokens never do — those are in `flutter_secure_storage`
/// only. Anything stored here is non-secret metadata.
@DataClassName('CachedUserRow')
class CachedUser extends Table {
  /// Server-assigned user id. Used as FK target by `user_permissions`.
  TextColumn get id => text()();

  TextColumn get email => text()();
  TextColumn get displayName => text()();

  /// When this row was last refreshed from the server. Lets the splash
  /// probe pick the most recently signed-in user when the device has
  /// multi-account history.
  DateTimeColumn get cachedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
