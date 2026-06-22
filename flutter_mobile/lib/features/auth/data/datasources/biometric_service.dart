/// Outcome of a single biometric prompt — coarse enough that the UI
/// only needs three branches (allow, fall back to PIN, show "set up
/// biometrics first" hint).
enum BiometricUnlockResult {
  /// User authenticated successfully.
  succeeded,

  /// User explicitly cancelled the prompt (Cancel button, swipe-down,
  /// or the OS-controlled "Use password" fallback).
  cancelled,

  /// Biometric unlock isn't currently usable on this device — hardware
  /// missing, no enrolment, locked out after too many failures, or the
  /// platform threw a `PlatformException` we couldn't classify.
  unavailable,
}

/// Cross-cutting biometric surface used by the auth feature.
///
/// **Flutter-free interface** so the use case + tests stay in pure
/// Dart. The production binding ([LocalAuthBiometricService]) wraps
/// `local_auth` and is the only file in the codebase that imports it.
///
/// **Storage rule** (CLAUDE.md Slice 1.2.3): no method here ever writes
/// or reads cryptographic material. The OS keychain (iOS Keychain via
/// LAContext, Android KeyStore via BiometricPrompt) owns all keys; this
/// interface just asks the OS to authenticate the human in front of the
/// screen.
abstract class BiometricService {
  /// `true` when the device has biometric hardware AND at least one
  /// fingerprint / face / iris is enrolled AND the OS isn't currently
  /// locking it out (e.g. after too many failed attempts).
  ///
  /// Cheap to call — should be invoked before showing a "Use Face ID"
  /// option in the UI so the option only renders when usable.
  Future<bool> isAvailable();

  /// Prompt the user. [reason] becomes the iOS Touch ID / Face ID
  /// dialog body and the Android BiometricPrompt subtitle.
  Future<BiometricUnlockResult> authenticate({required String reason});
}
