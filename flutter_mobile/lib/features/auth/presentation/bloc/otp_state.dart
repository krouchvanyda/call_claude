import 'package:freezed_annotation/freezed_annotation.dart';

import '../../entities/otp_verification_result.dart';

part 'otp_state.freezed.dart';

/// Lifecycle of an OTP entry attempt.
enum OtpStatus { idle, submitting, success, error }

/// Snapshot of the OTP page held by [OtpBloc].
///
/// Single class (not a sealed union per status) because every status
/// shares the same scalar fields — exhaustive switching happens in the
/// view via [OtpStatus] enum + the optional [rejectionReason] tag.
@freezed
class OtpState with _$OtpState {
  const factory OtpState({
    /// Required length the bloc validates against. Configurable so the
    /// same widget can drive 4-, 6-, or 8-digit codes.
    @Default(6) int length,

    /// The digits the user has typed so far. Held **in memory only** —
    /// never persisted to drift / secure-storage / shared_preferences.
    @Default('') String code,

    @Default(OtpStatus.idle) OtpStatus status,

    /// Populated when [status] is [OtpStatus.error]. Drives the
    /// per-reason localised error copy in the view.
    OtpRejectionReason? rejectionReason,
  }) = _OtpState;

  const OtpState._();

  bool get isCompleteLength => code.length == length;
  bool get isSubmitting => status == OtpStatus.submitting;
  bool get hasError => status == OtpStatus.error;
  bool get hasSucceeded => status == OtpStatus.success;

  /// `true` when the form is ready for submission — exact length and not
  /// already waiting on a previous attempt.
  bool get canSubmit => isCompleteLength && !isSubmitting;
}
