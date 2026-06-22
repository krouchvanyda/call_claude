import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';

import 'biometric_service.dart';

/// `local_auth`-backed [BiometricService].
///
/// The only file in the codebase that imports `package:local_auth`. It
/// translates the platform's three-state "supported / canCheck /
/// enrolled" handshake into a single boolean and maps the auth result
/// (or `PlatformException`) into the coarse [BiometricUnlockResult]
/// enum the rest of the app understands.
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      // Sequence: device must support biometrics in hardware AND the OS
      // must currently be willing to check (not locked out / disabled
      // by policy) AND the user must have enrolled at least one method.
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<BiometricUnlockResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Disable PIN/passcode fallback — we want a *biometric* gate.
          // The PIN-lock screen (Slice 9.3.3) is a separate flow with
          // its own UI.
          biometricOnly: true,
          // Keep the prompt alive across app backgrounding so the user
          // can switch to a password manager and return.
          stickyAuth: true,
        ),
      );
      return ok
          ? BiometricUnlockResult.succeeded
          : BiometricUnlockResult.cancelled;
    } on PlatformException {
      // Hardware lockout, no enrolment, etc. — caller falls back to PIN.
      return BiometricUnlockResult.unavailable;
    }
  }
}
