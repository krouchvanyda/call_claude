/// Platform-encrypted key/value store — the only persistence layer the
/// auth feature touches for secrets (JWT access + refresh tokens, future
/// biometric crypto material, vendor API keys).
///
/// Kept Flutter-free as an interface so [SecureTokenStorage] stays
/// unit-testable. The production binding is
/// `FlutterSecureStorageSecretStore`, which delegates to
/// `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences
/// on Android).
///
/// **Strict-rule reminder**: tokens never live in drift / sqlite /
/// `shared_preferences` / `app_metadata`. Implementations that aren't
/// platform-encrypted have no business existing for this interface.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}
