import 'package:bloc_test/bloc_test.dart';
import 'package:erp_mobile/features/auth/data/repositories/otp_repository.dart';
import 'package:erp_mobile/features/auth/entities/otp_verification_result.dart';
import 'package:erp_mobile/features/auth/presentation/bloc/otp_bloc.dart';
import 'package:erp_mobile/features/auth/presentation/bloc/otp_event.dart';
import 'package:erp_mobile/features/auth/presentation/bloc/otp_state.dart';
import 'package:test/test.dart';

/// Scriptable verifier — the test parameterises what the repository
/// returns without depending on the stub's hardcoded dev code.
class _ScriptedOtpRepository extends OtpRepository {
  _ScriptedOtpRepository(this._respond);
  final Future<OtpVerificationResult> Function(String code) _respond;
  final received = <String>[];

  @override
  Future<OtpVerificationResult> verify(String code) {
    received.add(code);
    return _respond(code);
  }
}

OtpBloc _buildBloc(OtpRepository repo) => OtpBloc(otpRepository: repo);

void main() {
  group('OtpBloc — initial state', () {
    test('starts idle, code empty, length 6 by default', () {
      final bloc = _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.accepted(),
      ));
      addTearDown(bloc.close);

      expect(bloc.state.status, OtpStatus.idle);
      expect(bloc.state.code, '');
      expect(bloc.state.length, 6);
      expect(bloc.state.canSubmit, isFalse);
    });

    test('honours a custom length', () {
      final bloc = OtpBloc(
        otpRepository: _ScriptedOtpRepository(
          (_) async => const OtpVerificationResult.accepted(),
        ),
        length: 4,
      );
      addTearDown(bloc.close);
      expect(bloc.state.length, 4);
    });
  });

  group('OtpBloc — codeChanged', () {
    blocTest<OtpBloc, OtpState>(
      'updates state.code on every keystroke',
      build: () => _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.accepted(),
      )),
      act: (bloc) => bloc
        ..add(const OtpEvent.codeChanged('1'))
        ..add(const OtpEvent.codeChanged('12'))
        ..add(const OtpEvent.codeChanged('123456')),
      expect: () => [
        const OtpState(code: '1'),
        const OtpState(code: '12'),
        const OtpState(code: '123456'),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'clamps overflow to the configured length (paste-overflow guard)',
      build: () => _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.accepted(),
      )),
      act: (bloc) => bloc.add(const OtpEvent.codeChanged('1234567890')),
      expect: () => [
        const OtpState(code: '123456'),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'clears any previous error when the user resumes typing',
      build: () => _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.accepted(),
      )),
      seed: () => const OtpState(
        code: '999999',
        status: OtpStatus.error,
        rejectionReason: OtpRejectionReason.incorrect,
      ),
      act: (bloc) => bloc.add(const OtpEvent.codeChanged('999998')),
      expect: () => [
        const OtpState(code: '999998'),
      ],
    );
  });

  group('OtpBloc — submitted', () {
    blocTest<OtpBloc, OtpState>(
      'happy path: submitting → success',
      build: () => _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.accepted(),
      )),
      seed: () => const OtpState(code: '123456'),
      act: (bloc) => bloc.add(const OtpEvent.submitted()),
      expect: () => [
        const OtpState(code: '123456', status: OtpStatus.submitting),
        const OtpState(code: '123456', status: OtpStatus.success),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'rejected (incorrect): submitting → error with reason',
      build: () => _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.rejected(
          reason: OtpRejectionReason.incorrect,
        ),
      )),
      seed: () => const OtpState(code: '999999'),
      act: (bloc) => bloc.add(const OtpEvent.submitted()),
      expect: () => [
        const OtpState(code: '999999', status: OtpStatus.submitting),
        const OtpState(
          code: '999999',
          status: OtpStatus.error,
          rejectionReason: OtpRejectionReason.incorrect,
        ),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'rejected (rate-limit): preserves the matching reason',
      build: () => _buildBloc(_ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.rejected(
          reason: OtpRejectionReason.tooManyAttempts,
        ),
      )),
      seed: () => const OtpState(code: '123456'),
      act: (bloc) => bloc.add(const OtpEvent.submitted()),
      expect: () => [
        const OtpState(code: '123456', status: OtpStatus.submitting),
        const OtpState(
          code: '123456',
          status: OtpStatus.error,
          rejectionReason: OtpRejectionReason.tooManyAttempts,
        ),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'short code is ignored (no submit, no state change)',
      build: () {
        final repo = _ScriptedOtpRepository(
          (_) async => fail('verifier must not be called for short code'),
        );
        return _buildBloc(repo);
      },
      seed: () => const OtpState(code: '123'),
      act: (bloc) => bloc.add(const OtpEvent.submitted()),
      expect: () => const <OtpState>[],
    );

    blocTest<OtpBloc, OtpState>(
      're-submit while already submitting is a no-op',
      build: () {
        var calls = 0;
        return _buildBloc(_ScriptedOtpRepository((_) async {
          calls++;
          // Slow enough that the second submit fires before this resolves.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(calls, 1, reason: 'verifier called exactly once');
          return const OtpVerificationResult.accepted();
        }));
      },
      seed: () => const OtpState(code: '123456'),
      act: (bloc) async {
        bloc
          ..add(const OtpEvent.submitted())
          ..add(const OtpEvent.submitted());
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        const OtpState(code: '123456', status: OtpStatus.submitting),
        const OtpState(code: '123456', status: OtpStatus.success),
      ],
    );
  });

  group('OtpBloc — cleared', () {
    blocTest<OtpBloc, OtpState>(
      'resets state to the initial value (preserving length)',
      build: () => OtpBloc(
        otpRepository: _ScriptedOtpRepository(
          (_) async => const OtpVerificationResult.accepted(),
        ),
        length: 8,
      ),
      seed: () => const OtpState(
        length: 8,
        code: '12345678',
        status: OtpStatus.error,
        rejectionReason: OtpRejectionReason.incorrect,
      ),
      act: (bloc) => bloc.add(const OtpEvent.cleared()),
      expect: () => [
        const OtpState(length: 8),
      ],
    );
  });

  group('OtpBloc — memory-only contract', () {
    test('the verifier is the only sink the bloc talks to', () async {
      final repo = _ScriptedOtpRepository(
        (_) async => const OtpVerificationResult.accepted(),
      );
      final bloc = _buildBloc(repo);
      addTearDown(bloc.close);

      bloc
        ..add(const OtpEvent.codeChanged('123456'))
        ..add(const OtpEvent.submitted());

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // The verifier sees the code; nothing else does. Drift / secure
      // storage / shared_preferences aren't in this dependency graph,
      // so there's literally no other place the code could land.
      expect(repo.received, ['123456']);
    });
  });
}
