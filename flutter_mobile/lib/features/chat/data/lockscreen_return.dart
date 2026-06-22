import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the native `MainActivity` so a call that was answered OVER
/// the lock screen drops back to the lock screen when it ends — instead of
/// leaving the app sitting unlocked on the dashboard.
///
/// The decision lives natively: `MainActivity` only acts when it actually
/// launched over a LOCKED keyguard for the call and the device is still
/// locked at end-time. So this is safe to call from every call-end path —
/// a call started from inside the unlocked app is a no-op.
class LockScreenReturn {
  const LockScreenReturn._();

  static const MethodChannel _channel = MethodChannel('erp/lockscreen');

  /// Ask native to return to the lock screen if this session was shown
  /// over a locked keyguard for the call. Best-effort and fire-and-forget
  /// — swallows the platform exception on iOS / when no Activity is
  /// attached (the channel simply isn't registered there).
  static Future<void> returnToLockScreenIfShownOver() async {
    try {
      await _channel.invokeMethod<bool>('returnToLockScreenIfShownOver');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LockScreenReturn] channel call ignored: $e');
      }
    }
  }
}
