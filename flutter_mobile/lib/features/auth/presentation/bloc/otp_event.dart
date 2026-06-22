import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_event.freezed.dart';

/// Inputs to [OtpBloc].
@freezed
sealed class OtpEvent with _$OtpEvent {
  /// User edited the digits. Empty string is valid (clears the field).
  const factory OtpEvent.codeChanged(String code) = OtpCodeChanged;

  /// User tapped "Verify". The bloc validates length, then calls the
  /// use case.
  const factory OtpEvent.submitted() = OtpSubmitted;

  /// Reset the page back to its initial state (e.g. after popping back
  /// from a "resend" flow — placeholder for future slice).
  const factory OtpEvent.cleared() = OtpCleared;
}
