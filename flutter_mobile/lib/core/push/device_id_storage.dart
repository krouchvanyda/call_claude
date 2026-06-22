import '../../features/auth/data/datasources/secret_store.dart';
import '../utils/uuid_generator.dart';

/// Stable per-install device identifier used as the primary key for
/// the backend's `devices` table (`POST /me/devices` /
/// `DELETE /me/devices/{deviceId}`).
///
/// Why a separate id and not just the FCM token:
/// - FCM tokens rotate (post-restore, after data wipe, every few months
///   at FCM's discretion). The backend keyed on token would have to
///   garbage-collect orphan rows; keying on a stable id means a
///   rotation is just an `UPDATE … SET fcm_token = ?`.
/// - Multiple installs of the same user on the same device (rare, but
///   happens with work profiles / shared phones) should produce
///   distinct rows.
///
/// Lives in `flutter_secure_storage` for the same reason the push
/// token does — it's not strictly auth-equivalent, but it ties a
/// user's identity to a physical device and we want it wiped on a
/// full app reinstall (which clears the keychain on iOS and the
/// Android Keystore-backed slot too).
abstract class DeviceIdStorage {
  /// Returns the existing device id, minting + persisting a fresh
  /// UUIDv4 the first time it's called. Idempotent — every subsequent
  /// call returns the same value for the lifetime of the install.
  Future<String> readOrCreate();

  /// Returns the stored id without minting one. Used by the unregister
  /// flow so we don't accidentally create an id just to delete it.
  Future<String?> readIfExists();

  /// Wipe on app reset / logout-with-revoke-device.
  Future<void> clear();
}

class SecretStoreDeviceIdStorage implements DeviceIdStorage {
  const SecretStoreDeviceIdStorage({required SecretStore secrets})
      : _secrets = secrets;

  final SecretStore _secrets;

  static const _key = 'push.device_id';

  @override
  Future<String> readOrCreate() async {
    final existing = await _secrets.read(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = newUuid();
    await _secrets.write(_key, fresh);
    return fresh;
  }

  @override
  Future<String?> readIfExists() => _secrets.read(_key);

  @override
  Future<void> clear() => _secrets.delete(_key);
}
