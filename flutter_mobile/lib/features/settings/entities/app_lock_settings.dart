/// Slice 9.3.3 — app PIN + biometric re-auth on resume.
///
/// **Storage boundary** — only `pinEnabled` / `biometricEnabled` /
/// `autoLockMinutes` live in drift. The PIN itself never touches drift
/// — it's hashed and held in `flutter_secure_storage` so wiping the
/// drift cache (logout, app data clear) doesn't invalidate the lock.
class AppLockSettings {
  const AppLockSettings({
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.autoLockMinutes,
  });

  final bool pinEnabled;
  final bool biometricEnabled;

  /// 0 = lock immediately on resume; positive values are the grace
  /// window after backgrounding. Capped at 60 by the validator.
  final int autoLockMinutes;

  AppLockSettings copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    int? autoLockMinutes,
  }) =>
      AppLockSettings(
        pinEnabled: pinEnabled ?? this.pinEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLockSettings &&
          other.pinEnabled == pinEnabled &&
          other.biometricEnabled == biometricEnabled &&
          other.autoLockMinutes == autoLockMinutes;

  @override
  int get hashCode =>
      Object.hash(pinEnabled, biometricEnabled, autoLockMinutes);

  static const initial = AppLockSettings(
    pinEnabled: false,
    biometricEnabled: false,
    autoLockMinutes: 5,
  );
}
