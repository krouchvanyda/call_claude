import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:erp_mobile/features/auth/data/datasources/pkce_generator.dart';
import 'package:test/test.dart';

void main() {
  group('PkceGenerator — verifier shape (RFC 7636 §4.1)', () {
    final generator = PkceGenerator();

    test('default verifier length is 64 characters', () {
      expect(generator.generate().verifier, hasLength(64));
    });

    test('honours a custom verifier length', () {
      expect(PkceGenerator(verifierLength: 43).generate().verifier,
          hasLength(43));
      expect(PkceGenerator(verifierLength: 128).generate().verifier,
          hasLength(128));
    });

    test('rejects verifier lengths outside the RFC range', () {
      expect(() => PkceGenerator(verifierLength: 42), throwsArgumentError);
      expect(() => PkceGenerator(verifierLength: 129), throwsArgumentError);
      expect(() => PkceGenerator(verifierLength: 0), throwsArgumentError);
    });

    test('verifier uses only the unreserved-character alphabet', () {
      // Run a handful of generations to lower the false-pass odds.
      for (var i = 0; i < 10; i++) {
        final v = generator.generate().verifier;
        for (final ch in v.split('')) {
          expect(
            PkceGenerator.unreservedAlphabet.contains(ch),
            isTrue,
            reason: 'character "$ch" not in unreserved alphabet',
          );
        }
      }
    });

    test('two consecutive verifiers are different (entropy sanity)', () {
      final a = generator.generate().verifier;
      final b = generator.generate().verifier;
      expect(a, isNot(b));
    });
  });

  group('PkceGenerator — challenge derivation (RFC 7636 §4.2 S256)', () {
    test('challenge is BASE64URL(SHA-256(verifier)) with no padding', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';

      // Reference value from RFC 7636 Appendix B (the canonical test vector).
      const expectedChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

      expect(PkceGenerator.deriveChallenge(verifier), expectedChallenge);
    });

    test('derive is deterministic for a given verifier', () {
      const v = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
      expect(PkceGenerator.deriveChallenge(v),
          PkceGenerator.deriveChallenge(v));
    });

    test('challenge has no `=` padding', () {
      final v = PkceGenerator().generate();
      expect(v.challenge, isNot(contains('=')));
    });

    test("manually re-deriving from a generated verifier reproduces "
        'the challenge (round-trip)', () {
      final pair = PkceGenerator().generate();
      final manualHash = sha256.convert(utf8.encode(pair.verifier)).bytes;
      final manualChallenge = base64UrlEncode(manualHash).replaceAll('=', '');
      expect(pair.challenge, manualChallenge);
    });

    test('default method is "S256"', () {
      expect(PkceGenerator().generate().method, 'S256');
    });
  });

  group('PkceGenerator — state nonce', () {
    final generator = PkceGenerator();

    test('produces a non-empty token', () {
      expect(generator.generateStateNonce(), isNotEmpty);
    });

    test('two consecutive nonces differ', () {
      expect(generator.generateStateNonce(),
          isNot(generator.generateStateNonce()));
    });

    test('nonce has no `=` padding', () {
      expect(generator.generateStateNonce(), isNot(contains('=')));
    });
  });

  group('PkceGenerator — deterministic via injected RNG', () {
    test('two generators with the same seed produce the same verifier', () {
      // `Random.secure()` ignores seeds; a vanilla `Random(seed)` is
      // deterministic and lets the test pin the output.
      final a = PkceGenerator(random: Random(42)).generate();
      final b = PkceGenerator(random: Random(42)).generate();
      expect(a.verifier, b.verifier);
      expect(a.challenge, b.challenge);
    });
  });
}
