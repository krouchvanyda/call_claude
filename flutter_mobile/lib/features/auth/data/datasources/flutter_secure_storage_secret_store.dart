import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secret_store.dart';

/// Production [SecretStore] backed by `flutter_secure_storage`.
///
/// Platform-specific options are pinned to the safe defaults:
///
/// - **Android**: `EncryptedSharedPreferences` (AES-256-GCM via Jetpack
///   Security). Preferred over the legacy `KeyStore`-only path because
///   the latter has historically corrupted on app upgrade.
/// - **iOS / macOS**: Keychain accessibility set to
///   `first_unlock_this_device`. Tokens survive app reinstall on the
///   same device but never sync to iCloud — appropriate for ERP
///   credentials that mustn't leave the device they were issued on.
class FlutterSecureStorageSecretStore implements SecretStore {
  FlutterSecureStorageSecretStore([FlutterSecureStorage? storage])
      : _storage = storage ?? _defaults();

  final FlutterSecureStorage _storage;

  static FlutterSecureStorage _defaults() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
        mOptions: MacOsOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
      );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
