import '../../features/auth/data/datasources/secret_store.dart';

/// Secure persistence for the device push token (Slice 2.3.2).
///
/// **Storage rule** (CLAUDE.md, [[feedback_secure_storage_for_tokens]]):
/// the FCM device token is auth-equivalent material — anyone with it can
/// impersonate the device for push delivery. It lives in
/// `flutter_secure_storage` only, never in drift / sqlite /
/// `shared_preferences` / `app_metadata`. The interface here is
/// abstract so unit tests can fake without dragging the platform
/// keychain in.
abstract class PushTokenStorage {
  /// Returns the stored token, or `null` when nothing has been
  /// persisted yet (fresh install / post-wipe / permission denied).
  Future<String?> readToken();

  /// Idempotent write — overwrites any previous value.
  Future<void> saveToken(String token);

  /// Tombstone-free delete. Called on sign-out so the next user on
  /// the same device doesn't inherit the previous identity's token.
  Future<void> clear();
}

/// Concrete impl: layers on top of the existing [SecretStore]
/// abstraction (which already owns the `flutter_secure_storage`
/// binding). Adding a token-specific class — rather than scattering
/// `read('push_token')` calls across the codebase — keeps the storage
/// key in one auditable place.
class SecretStorePushTokenStorage implements PushTokenStorage {
  const SecretStorePushTokenStorage({required SecretStore secrets})
      : _secrets = secrets;

  final SecretStore _secrets;

  /// Storage key. Lives next to the implementation so a key rename
  /// is a single edit + a one-shot migration helper if we ever need
  /// to move existing tokens.
  static const _key = 'push.device_token';

  @override
  Future<String?> readToken() => _secrets.read(_key);

  @override
  Future<void> saveToken(String token) => _secrets.write(_key, token);

  @override
  Future<void> clear() => _secrets.delete(_key);
}
