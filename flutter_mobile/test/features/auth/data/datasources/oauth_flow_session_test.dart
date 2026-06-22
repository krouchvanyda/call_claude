import 'package:erp_mobile/features/auth/data/datasources/oauth_flow_session.dart';
import 'package:erp_mobile/features/auth/entities/pkce_challenge.dart';
import 'package:test/test.dart';

const _challenge = PkceChallenge(
  verifier: 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
  challenge: 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
);

void main() {
  late OAuthFlowSession session;

  setUp(() => session = OAuthFlowSession());

  group('OAuthFlowSession — initial state', () {
    test('starts inactive with no pending challenge or state', () {
      expect(session.hasActiveFlow, isFalse);
      expect(session.pendingChallenge, isNull);
      expect(session.pendingState, isNull);
    });

    test('consumeVerifier on an empty session returns null', () {
      expect(session.consumeVerifier(state: 'whatever'), isNull);
    });
  });

  group('OAuthFlowSession — happy path', () {
    test('begin → consumeVerifier(matching state) returns the verifier', () {
      session.begin(challenge: _challenge, state: 'csrf-nonce-1');
      expect(session.hasActiveFlow, isTrue);

      final verifier = session.consumeVerifier(state: 'csrf-nonce-1');
      expect(verifier, _challenge.verifier);
    });

    test('successful consumption wipes the session (no replay)', () {
      session.begin(challenge: _challenge, state: 'csrf-1');
      session.consumeVerifier(state: 'csrf-1');

      expect(session.hasActiveFlow, isFalse);
      expect(session.pendingChallenge, isNull);
      // Second consumption with the same nonce gets nothing.
      expect(session.consumeVerifier(state: 'csrf-1'), isNull);
    });
  });

  group('OAuthFlowSession — CSRF guard', () {
    test('mismatched state returns null', () {
      session.begin(challenge: _challenge, state: 'real');
      expect(session.consumeVerifier(state: 'forged'), isNull);
    });

    test('mismatched state ALSO wipes the session (no second-attempt replay)',
        () {
      session.begin(challenge: _challenge, state: 'real');
      session.consumeVerifier(state: 'forged');

      expect(session.hasActiveFlow, isFalse);
      // Even the legitimate caller can't recover now; they must
      // restart the flow. This is the conservative posture.
      expect(session.consumeVerifier(state: 'real'), isNull);
    });
  });

  group('OAuthFlowSession — concurrent flows', () {
    test('begin replaces any in-flight flow silently', () {
      const other = PkceChallenge(
        verifier: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        challenge: 'irrelevant-for-this-test',
      );
      session.begin(challenge: _challenge, state: 'first');
      session.begin(challenge: other, state: 'second');

      // Old state nonce is gone.
      expect(session.consumeVerifier(state: 'first'), isNull);
      // Old verifier never returns either.
    });

    test('after silent replacement, the new flow can complete', () {
      const other = PkceChallenge(
        verifier: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
        challenge: 'irrelevant',
      );
      session.begin(challenge: _challenge, state: 'first');
      session.begin(challenge: other, state: 'second');

      expect(session.consumeVerifier(state: 'second'), other.verifier);
    });
  });

  group('OAuthFlowSession — clear()', () {
    test('clear wipes an active flow', () {
      session.begin(challenge: _challenge, state: 'x');
      session.clear();
      expect(session.hasActiveFlow, isFalse);
      expect(session.consumeVerifier(state: 'x'), isNull);
    });

    test('clear on empty is a no-op', () {
      session.clear();
      expect(session.hasActiveFlow, isFalse);
    });
  });
}
