import 'package:flutter/foundation.dart';

import '../utils/logger/app_logger.dart';
import 'device_id_storage.dart';
import 'devices_remote_data_source.dart';
import 'push_notification_service.dart';
import 'push_token_storage.dart';

/// Front-of-house for the device registration handshake.
///
/// One call site per lifecycle event — none of them need to know how
/// the pieces fit together:
///   - login / register-account  → [register]
///   - FCM token rotation         → [register] (idempotent)
///   - logout                     → [unregister]
///
/// Pulls together:
///   - [PushNotificationService] — current FCM token (may be null if
///     Play Services / network are flaky)
///   - [PushTokenStorage]        — local secure cache (so we don't
///     re-POST if nothing changed since last successful registration)
///   - [DeviceIdStorage]         — the stable upsert key
///   - [DevicesRemoteDataSource] — actual HTTP
class DeviceRegistrar {
  DeviceRegistrar({
    required DevicesRemoteDataSource remote,
    required PushNotificationService push,
    required PushTokenStorage tokenStorage,
    required DeviceIdStorage deviceIdStorage,
    required AppLogger logger,
  })  : _remote = remote,
        _push = push,
        _tokenStorage = tokenStorage,
        _deviceIdStorage = deviceIdStorage,
        _logger = logger;

  final DevicesRemoteDataSource _remote;
  final PushNotificationService _push;
  final PushTokenStorage _tokenStorage;
  final DeviceIdStorage _deviceIdStorage;
  final AppLogger _logger;

  /// Upsert this device's FCM token server-side.
  ///
  /// Safe to call repeatedly — the backend keys on `deviceId`, so a
  /// re-register with the same token is a no-op on the server. We
  /// still issue the call (rather than short-circuiting locally) on
  /// every login so a backend-side row that got pruned (e.g. inactive
  /// device GC) is re-created.
  ///
  /// Failures are swallowed: a missing device row only means we
  /// won't receive call.invite pushes — it must not block sign-in
  /// or block FCM token rotation from completing.
  Future<void> register({String? overrideToken}) async {
    try {
      final token = overrideToken ?? await _push.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔥 DeviceRegistrar.register skipped: no FCM token');
        }
        return;
      }
      final deviceId = await _deviceIdStorage.readOrCreate();
      await _remote.register(deviceId: deviceId, fcmToken: token);
      await _tokenStorage.saveToken(token);
      _logger.info(
          'DeviceRegistrar.register OK · deviceId=$deviceId · token.len=${token.length}');
      if (kDebugMode) {
        debugPrint('🔥 DeviceRegistrar.register OK · deviceId=$deviceId');
      }
    } catch (e, s) {
      _logger.warn('DeviceRegistrar.register failed',
          error: e, stackTrace: s);
      if (kDebugMode) {
        debugPrint('🔥 DeviceRegistrar.register failed → $e');
      }
    }
  }

  /// Revoke this device server-side and wipe the local secure-storage
  /// copies. Idempotent (404 on the DELETE is treated as success).
  ///
  /// Call BEFORE `tokenStorage.clear()` in the auth sign-out flow so
  /// the access token is still around for the DELETE to authenticate.
  Future<void> unregister() async {
    try {
      final deviceId = await _deviceIdStorage.readIfExists();
      if (deviceId != null) {
        await _remote.unregister(deviceId: deviceId);
        _logger.info('DeviceRegistrar.unregister OK · deviceId=$deviceId');
      }
    } catch (e, s) {
      _logger.warn('DeviceRegistrar.unregister failed',
          error: e, stackTrace: s);
    } finally {
      // Local wipe is unconditional — even if the server-side delete
      // failed (network down, token already expired), we don't want
      // a stale device id sitting in storage. Next login will mint a
      // fresh one and the orphaned server row will eventually be
      // pruned by the backend's inactive-device GC.
      await _tokenStorage.clear();
      await _deviceIdStorage.clear();
    }
  }
}
