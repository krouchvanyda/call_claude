import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import 'tables/biometric_settings.dart';

part 'biometric_settings_dao.g.dart';

/// Drift-backed reader/writer for the per-user `biometric_on` preference.
///
/// This is the **only** auth-feature surface that touches the
/// `biometric_settings` table. The route guard (Slice 9.3.3-ish — App
/// PIN lock / biometric re-auth on resume) and the Settings page
/// (Module 9 Phase 9.1) both go through this DAO; nothing else needs
/// to know.
///
/// **Storage rule reminder**: the bool flag lives here in drift; the
/// crypto material stays in the OS-managed keychain via `local_auth`.
/// We never see or store actual keys.
@DriftAccessor(tables: [BiometricSettings])
class BiometricSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$BiometricSettingsDaoMixin {
  BiometricSettingsDao(super.db);

  /// Returns `true` only when the user has explicitly opted in. Missing
  /// row (never enrolled) is treated as `false`.
  Future<bool> isEnabledFor(String userId) async {
    final row = await (select(biometricSettings)
          ..where((r) => r.userId.equals(userId)))
        .getSingleOrNull();
    return row?.enabled ?? false;
  }

  /// Reactive variant for the Settings switch.
  Stream<bool> watchEnabledFor(String userId) {
    return (select(biometricSettings)
          ..where((r) => r.userId.equals(userId)))
        .watchSingleOrNull()
        .map((r) => r?.enabled ?? false);
  }

  /// Toggles the preference, capturing the moment of opt-in for audit
  /// purposes. Setting `enabled: false` clears `enrolledAt`.
  Future<void> setEnabledFor(
    String userId, {
    required bool enabled,
    DateTime? enrolledAt,
  }) async {
    await into(biometricSettings).insert(
      BiometricSettingsCompanion.insert(
        userId: userId,
        enabled: Value(enabled),
        enrolledAt: Value(enabled ? (enrolledAt ?? DateTime.now()) : null),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Removes the preference row for [userId]. The FK CASCADE in
  /// `cached_user` already covers full sign-out; this method exists
  /// for explicit "forget my biometric pref" flows.
  Future<int> deleteFor(String userId) =>
      (delete(biometricSettings)..where((r) => r.userId.equals(userId))).go();
}
