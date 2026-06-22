import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../entities/pkce_challenge.dart';

/// Pure Dart generator of PKCE proof material (RFC 7636 §4.1 + §4.2).
///
/// Uses [Random.secure] by default — cryptographically strong on every
/// supported platform. Tests can inject a deterministic [Random] to
/// pin the verifier output.
class PkceGenerator {
  PkceGenerator({
    Random? random,
    int verifierLength = 64,
  })  : _random = random ?? Random.secure(),
        _verifierLength = verifierLength {
    if (verifierLength < 43 || verifierLength > 128) {
      throw ArgumentError.value(
        verifierLength,
        'verifierLength',
        'RFC 7636 §4.1 requires 43-128 characters',
      );
    }
  }

  /// Unreserved-character alphabet from RFC 3986 §2.3 — the only
  /// characters permitted in a PKCE verifier per RFC 7636 §4.1.
  static const String unreservedAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  final Random _random;
  final int _verifierLength;

  /// Generate a fresh `(verifier, challenge)` pair. Idempotency is **not**
  /// a guarantee — a new verifier rolls every call.
  PkceChallenge generate() {
    final verifier = _generateVerifier();
    final challenge = deriveChallenge(verifier);
    return PkceChallenge(verifier: verifier, challenge: challenge);
  }

  /// Cryptographically random nonce for the OAuth `state` parameter
  /// (CSRF guard). 16 bytes → ~22 base64url chars after padding strip.
  String generateStateNonce() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return _base64UrlNoPad(bytes);
  }

  String _generateVerifier() {
    final buf = StringBuffer();
    for (var i = 0; i < _verifierLength; i++) {
      buf.write(unreservedAlphabet[_random.nextInt(unreservedAlphabet.length)]);
    }
    return buf.toString();
  }

  /// Public so tests (and any future need to verify externally-issued
  /// challenges) can re-derive without instantiating a generator.
  static String deriveChallenge(String verifier) {
    final hash = sha256.convert(utf8.encode(verifier));
    return _base64UrlNoPad(hash.bytes);
  }

  static String _base64UrlNoPad(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');
}
