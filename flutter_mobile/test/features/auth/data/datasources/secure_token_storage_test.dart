import 'dart:convert';

import 'package:erp_mobile/core/network/auth_tokens.dart';
import 'package:erp_mobile/features/auth/data/datasources/secure_token_storage.dart';
import 'package:test/test.dart';

import '../../../../_support/in_memory_secret_store.dart';

void main() {
  late InMemorySecretStore secrets;
  late SecureTokenStorage storage;

  setUp(() {
    secrets = InMemorySecretStore();
    storage = SecureTokenStorage(secrets);
  });

  group('SecureTokenStorage — initial state', () {
    test('read on empty store returns null', () async {
      expect(await storage.read(), isNull);
    });

    test('clear on empty store does not throw', () async {
      await storage.clear();
      expect(await storage.read(), isNull);
    });
  });

  group('SecureTokenStorage — round-trip', () {
    test('writes and reads back access + refresh tokens', () async {
      const tokens = AuthTokens(
        accessToken: 'access-A',
        refreshToken: 'refresh-A',
      );
      await storage.write(tokens);

      final read = await storage.read();
      expect(read?.accessToken, 'access-A');
      expect(read?.refreshToken, 'refresh-A');
      expect(read?.accessExpiresAt, isNull);
    });

    test('preserves accessExpiresAt across the JSON boundary', () async {
      final expires = DateTime.utc(2026, 5, 12, 10);
      final tokens = AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
        accessExpiresAt: expires,
      );

      await storage.write(tokens);

      final read = await storage.read();
      expect(read?.accessExpiresAt, expires);
    });

    test('overwrite replaces the previously-stored tokens', () async {
      await storage.write(const AuthTokens(
        accessToken: 'old-a',
        refreshToken: 'old-r',
      ));
      await storage.write(const AuthTokens(
        accessToken: 'new-a',
        refreshToken: 'new-r',
      ));

      final read = await storage.read();
      expect(read?.accessToken, 'new-a');
      expect(read?.refreshToken, 'new-r');
      expect(secrets.keyCount, 1, reason: 'still a single key — not duplicated');
    });
  });

  group('SecureTokenStorage — clear', () {
    test('clear removes the persisted blob and read returns null', () async {
      await storage.write(const AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
      ));
      await storage.clear();
      expect(await storage.read(), isNull);
      expect(secrets.keyCount, 0);
    });

    test('clear targets the auth.tokens.v1 key only', () async {
      // Drop another secret in to prove clear() doesn't nuke unrelated keys.
      await secrets.write('unrelated.secret', 'keep-me');

      await storage.write(const AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
      ));
      await storage.clear();

      expect(secrets.peek('unrelated.secret'), 'keep-me');
    });
  });

  group('SecureTokenStorage — defensive reads', () {
    test('garbled JSON returns null instead of throwing', () async {
      // Pre-existing crash-prone behaviour: a corrupt blob would crash
      // boot. Storage swallows and reports "no tokens" so the auth flow
      // recovers via a full sign-in.
      secrets.corrupt('auth.tokens.v1', 'not json {{{');
      expect(await storage.read(), isNull);
    });

    test('valid JSON of the wrong shape returns null', () async {
      secrets.corrupt('auth.tokens.v1', jsonEncode({'unrelated': 'value'}));
      expect(await storage.read(), isNull);
    });

    test('missing accessToken / refreshToken returns null', () async {
      secrets.corrupt(
        'auth.tokens.v1',
        jsonEncode({'accessToken': 'a'}), // no refreshToken
      );
      expect(await storage.read(), isNull);
    });

    test('non-string accessToken returns null', () async {
      secrets.corrupt(
        'auth.tokens.v1',
        jsonEncode({'accessToken': 42, 'refreshToken': 'r'}),
      );
      expect(await storage.read(), isNull);
    });

    test('unparseable accessExpiresAt is dropped (tokens still load)',
        () async {
      secrets.corrupt(
        'auth.tokens.v1',
        jsonEncode({
          'accessToken': 'a',
          'refreshToken': 'r',
          'accessExpiresAt': 'not-a-date',
        }),
      );

      final read = await storage.read();
      expect(read?.accessToken, 'a');
      expect(read?.refreshToken, 'r');
      expect(read?.accessExpiresAt, isNull);
    });

    test('empty stored value is treated as no tokens', () async {
      await secrets.write('auth.tokens.v1', '');
      expect(await storage.read(), isNull);
    });
  });

  group('SecureTokenStorage — schema versioning', () {
    test('uses the v1-suffixed key (verifies the on-disk format contract)',
        () async {
      await storage.write(const AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
      ));
      // The exact key matters: bumping the storage format means rotating
      // this suffix so old blobs are ignored on upgrade rather than
      // mis-parsed.
      expect(secrets.peek('auth.tokens.v1'), isNotNull);
      expect(secrets.peek('auth.tokens'), isNull);
    });
  });
}
