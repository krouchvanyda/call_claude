import 'package:bloc/bloc.dart';

import '../../data/repositories/otp_repository.dart';
import '../../entities/otp_verification_result.dart';
import 'otp_event.dart';
import 'otp_state.dart';

/// Drives the OTP entry page.
///
/// Holds the typed code in [OtpState.code] — **memory only**. The bloc
/// is created fresh per page mount (factory-scoped in DI) so the code
/// is wiped automatically when the user navigates away. Nothing is ever
/// persisted to drift, secure-storage, or `shared_preferences`.
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required OtpRepository otpRepository,
    int length = 6,
  })  : _otpRepository = otpRepository,
        super(OtpState(length: length)) {
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpSubmitted>(_onSubmitted);
    on<OtpCleared>(_onCleared);
  }

  final OtpRepository _otpRepository;

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    // Clamp to the configured length so paste-overflow doesn't bleed
    // through, and clear any previous error so the user sees they're
    // typing a fresh attempt.
    final trimmed = event.code.length > state.length
        ? event.code.substring(0, state.length)
        : event.code;
    emit(state.copyWith(
      code: trimmed,
      status: OtpStatus.idle,
      rejectionReason: null,
    ));
  }

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(
      status: OtpStatus.submitting,
      rejectionReason: null,
    ));

    final result = await _otpRepository.verify(state.code);

    switch (result) {
      case OtpAccepted():
        emit(state.copyWith(status: OtpStatus.success));
      case OtpRejected(:final reason):
        emit(state.copyWith(
          status: OtpStatus.error,
          rejectionReason: reason,
        ));
    }
  }

  void _onCleared(OtpCleared event, Emitter<OtpState> emit) {
    emit(OtpState(length: state.length));
  }
}
