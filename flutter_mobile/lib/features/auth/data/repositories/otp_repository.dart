import '../../entities/otp_verification_result.dart';

/// Verifies a one-time / time-based code.
///
/// Slice 1.2.1 ships a stub that accepts the canonical dev code
/// `123456`; the real backend-bound impl lands in a later MFA slice.
///
/// **Memory-only contract** (per CLAUDE.md Slice 1.2.1): the submitted
/// [code] is consumed inside the call and never stored — no instance
/// fields, no caches. The caller (`OtpBloc`) holds the code in BLoC
/// state for the duration of the page only; nothing is persisted to
/// drift, `shared_preferences`, or secure storage.
class OtpRepository {
  const OtpRepository();

  /// Canonical demo code. Documented as a constant so it surfaces in
  /// l10n hint copy without duplication.
  static const String devCode = '123456';

  /// Submit one OTP attempt.
  ///
  /// The 350 ms artificial latency lets the UI show its "submitting"
  /// spinner — without it, the state transition is invisibly fast.
  /// Accepts a fixed dev code so the OTP page is end-to-end demoable on
  /// the device, and rejects everything else with `incorrect`.
  Future<OtpVerificationResult> verify(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (code == devCode) {
      return const OtpVerificationResult.accepted();
    }
    return const OtpVerificationResult.rejected(
      reason: OtpRejectionReason.incorrect,
    );
  }
}
