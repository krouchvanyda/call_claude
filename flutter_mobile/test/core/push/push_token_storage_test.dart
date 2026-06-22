import 'package:erp_mobile/core/push/push_token_storage.dart';
import 'package:erp_mobile/features/auth/data/datasources/secret_store.dart';
import 'package:test/test.dart';

class _FakeSecretStore implements SecretStore {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }
}

void main() {
  group('SecretStorePushTokenStorage', () {
    test('readToken returns null on a fresh install', () async {
      final storage =
          SecretStorePushTokenStorage(secrets: _FakeSecretStore());
      expect(await storage.readToken(), isNull);
    });

    test('saveToken round-trips through readToken', () async {
      final storage =
          SecretStorePushTokenStorage(secrets: _FakeSecretStore());
      await storage.saveToken('fcm-token-abc');
      expect(await storage.readToken(), 'fcm-token-abc');
    });

    test('saveToken overwrites in place (no accumulation)', () async {
      final storage =
          SecretStorePushTokenStorage(secrets: _FakeSecretStore());
      await storage.saveToken('first');
      await storage.saveToken('second');
      expect(await storage.readToken(), 'second');
    });

    test('clear removes the token (sign-out path)', () async {
      final storage =
          SecretStorePushTokenStorage(secrets: _FakeSecretStore());
      await storage.saveToken('to-be-cleared');
      await storage.clear();
      expect(await storage.readToken(), isNull);
    });

    test(
        'storage key is namespaced — does not collide with other secrets '
        'in the same SecretStore',
        () async {
      final secrets = _FakeSecretStore();
      // Pretend an auth slice wrote a token under a different key.
      await secrets.write('auth.access_token', 'jwt-xyz');
      final pushStorage =
          SecretStorePushTokenStorage(secrets: secrets);
      await pushStorage.saveToken('fcm-abc');

      // Both must coexist.
      expect(await secrets.read('auth.access_token'), 'jwt-xyz');
      expect(await pushStorage.readToken(), 'fcm-abc');
    });
  });
}
