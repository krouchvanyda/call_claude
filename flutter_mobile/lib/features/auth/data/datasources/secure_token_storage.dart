import 'dart:convert';

import '../../../../core/network/auth_tokens.dart';
import '../../../../core/network/token_storage.dart';
import 'secret_store.dart';

/// `flutter_secure_storage`-backed [TokenStorage].
///
/// Replaces the `InMemoryTokenStorage` stub from Module 0. All three
/// fields (`accessToken`, `refreshToken`, optional `accessExpiresAt`)
/// round-trip through a single JSON blob under one secure-storage key —
/// fewer round-trips, atomic writes from the caller's perspective.
///
/// **Strict-rule reminder**: this is the *only* place tokens are
/// persisted. Drift, sqlite, shared_preferences and the `app_metadata`
/// table never see them.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._secrets);

  final SecretStore _secrets;

  /// Single key holding the serialised [AuthTokens]. Versioned so the
  /// format can evolve without orphan reads on upgrade.
  static const String _key = 'auth.tokens.v1';

  static const String _accessKey = 'accessToken';
  static const String _refreshKey = 'refreshToken';
  static const String _expiresKey = 'accessExpiresAt';

  @override
  Future<AuthTokens?> read() async {
    final raw = await _secrets.read(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final access = decoded[_accessKey];
      final refresh = decoded[_refreshKey];
      if (access is! String || refresh is! String) return null;

      final expiresRaw = decoded[_expiresKey];
      final expiresAt = expiresRaw is String
          ? DateTime.tryParse(expiresRaw)
          : null;

      return AuthTokens(
        accessToken: access,
        refreshToken: refresh,
        accessExpiresAt: expiresAt,
      );
    } on FormatException {
      // Corrupt blob — treat as no-tokens so the auth flow falls back
      // to a full sign-in instead of crashing the boot. The next
      // successful login overwrites the bad value.
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    final payload = <String, dynamic>{
      _accessKey: tokens.accessToken,
      _refreshKey: tokens.refreshToken,
      if (tokens.accessExpiresAt != null)
        _expiresKey: tokens.accessExpiresAt!.toIso8601String(),
    };
    await _secrets.write(_key, jsonEncode(payload));
  }

  @override
  Future<void> clear() => _secrets.delete(_key);
}
