import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_verification_result.freezed.dart';

/// Why the server / verifier turned a code down. Enum (not free-form
/// string) so the presentation layer can pick a localised message per
/// case via an exhaustive `switch`.
enum OtpRejectionReason {
  /// Digits didn't match the expected code.
  incorrect,

  /// Code was valid in the past but the validity window has elapsed.
  expired,

  /// Server is throttling further attempts (rate limit / lockout).
  tooManyAttempts,

  /// Transport failure — we couldn't reach the verifier.
  networkError,
}

/// Outcome of a single OTP submission.
///
/// Sealed so callers (the bloc, log handlers) pattern-match exhaustively
/// without falling into a default branch. `accepted` carries no payload
/// for this slice — the real verifier in a future slice will extend the
/// `accepted` variant with the next-step session token / claims.
@freezed
sealed class OtpVerificationResult with _$OtpVerificationResult {
  const factory OtpVerificationResult.accepted() = OtpAccepted;
  const factory OtpVerificationResult.rejected({
    required OtpRejectionReason reason,
  }) = OtpRejected;
}
