import 'package:drift/drift.dart';

import 'cached_user.dart';

/// Per-user biometric-unlock preference — drives whether the app
/// requires Face ID / Touch ID / fingerprint on cold start, on resume
/// after timeout, or before sensitive flows.
///
/// **Storage rule** (CLAUDE.md Slice 1.2.3): only the *boolean* preference
/// is persisted here in drift. The biometric crypto material itself
/// (LAContext on iOS, BiometricPrompt key handles on Android) lives in
/// the OS-managed keychain and is never seen by Dart code — `local_auth`
/// is a thin platform-channel wrapper over those native APIs.
///
/// Single row per cached user. `userId` references [CachedUser.id] with
/// `ON DELETE CASCADE`, so signing out (which wipes `cached_user`) wipes
/// the preference too — a fresh sign-in starts with biometrics off
/// until the user opts in again.
@DataClassName('BiometricSettingRow')
class BiometricSettings extends Table {
  TextColumn get userId => text().references(
        CachedUser,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// `true` once the user has explicitly opted in (typically via the
  /// Settings screen — Module 9). Defaults to `false` so cold installs
  /// don't surprise users with a biometric prompt before they've
  /// granted the permission.
  BoolColumn get enabled =>
      boolean().withDefault(const Constant(false))();

  /// When the user opted in, captured for audit / "biometrics enrolled
  /// 3 days ago" UX. Null when disabled.
  DateTimeColumn get enrolledAt => dateTime().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}
