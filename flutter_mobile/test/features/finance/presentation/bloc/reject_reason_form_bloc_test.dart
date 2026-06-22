import 'package:erp_mobile/features/finance/presentation/bloc/reject_reason_form_bloc.dart';
import 'package:test/test.dart';

void main() {
  group('RejectReasonFormBloc', () {
    test('initial state is empty + valid:false (no error shown yet)', () {
      final bloc = RejectReasonFormBloc();
      expect(bloc.state.reason, '');
      expect(bloc.state.error, isNull);
      expect(bloc.state.isValid, isFalse);
    });

    test(
        'typing BEFORE first submit attempt does NOT surface the error '
        '(matches onUserInteraction semantics)', () async {
      final bloc = RejectReasonFormBloc();
      bloc.add(const RejectReasonChanged(''));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.error, isNull,
          reason: 'should defer validation until submit');
    });

    test('Submit on empty value flips error="required"', () async {
      final bloc = RejectReasonFormBloc();
      bloc.add(const RejectReasonSubmitted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.error, 'required');
      expect(bloc.state.isValid, isFalse);
    });

    test('After submit, typing re-runs validation live (clears the error)',
        () async {
      final bloc = RejectReasonFormBloc();
      bloc.add(const RejectReasonSubmitted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.error, 'required');

      bloc.add(const RejectReasonChanged('valid reason'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.error, isNull);
      expect(bloc.state.isValid, isTrue);
    });

    test('whitespace-only value still counts as required', () async {
      final bloc = RejectReasonFormBloc();
      bloc.add(const RejectReasonChanged('   '));
      bloc.add(const RejectReasonSubmitted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.error, 'required');
      expect(bloc.state.isValid, isFalse);
    });
  });
}
