import 'package:bloc/bloc.dart';

/// Inputs to [RejectReasonFormBloc] (Slice 3.2.4).
sealed class RejectReasonFormEvent {
  const RejectReasonFormEvent();
}

class RejectReasonChanged extends RejectReasonFormEvent {
  const RejectReasonChanged(this.value);
  final String value;
}

class RejectReasonSubmitted extends RejectReasonFormEvent {
  const RejectReasonSubmitted();
}

/// Single-field form state. `error` is the i18n key (resolved at the
/// widget layer) — keeps the bloc Flutter-free per the project's
/// "no BuildContext inside BLoC" guardrail.
class RejectReasonFormState {
  const RejectReasonFormState({
    this.reason = '',
    this.error,
    this.attemptedSubmit = false,
  });

  final String reason;
  final String? error;

  /// Flips `true` after the first submit attempt so the field starts
  /// validating only after the user has tried to submit (matches
  /// `AutovalidateMode.onUserInteraction` semantics in pure Dart).
  final bool attemptedSubmit;

  bool get isValid => error == null && reason.trim().isNotEmpty;

  RejectReasonFormState copyWith({
    String? reason,
    Object? error = _sentinel,
    bool? attemptedSubmit,
  }) {
    return RejectReasonFormState(
      reason: reason ?? this.reason,
      error:
          identical(error, _sentinel) ? this.error : error as String?,
      attemptedSubmit: attemptedSubmit ?? this.attemptedSubmit,
    );
  }

  static const _sentinel = Object();
}

/// FormBLoC for the reject reason input (Slice 3.2.4).
///
/// **Why a bloc for one field**: the spec calls for `FormBLoC` so the
/// rule lives outside the widget. The win is double-checking — the
/// domain UseCase enforces non-empty as defence in depth — but the
/// form-level error is what the user sees inline as they type.
class RejectReasonFormBloc
    extends Bloc<RejectReasonFormEvent, RejectReasonFormState> {
  RejectReasonFormBloc() : super(const RejectReasonFormState()) {
    on<RejectReasonChanged>((e, emit) {
      emit(state.copyWith(
        reason: e.value,
        error: state.attemptedSubmit ? _validate(e.value) : null,
      ));
    });
    on<RejectReasonSubmitted>((e, emit) {
      emit(state.copyWith(
        attemptedSubmit: true,
        error: _validate(state.reason),
      ));
    });
  }

  /// Returns the i18n key for the message, or `null` when valid.
  static String? _validate(String value) {
    return value.trim().isEmpty ? 'required' : null;
  }
}
