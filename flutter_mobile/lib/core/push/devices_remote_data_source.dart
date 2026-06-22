import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import '../network/api_envelope.dart';

/// REST surface for the device-token registry.
///
/// Routes (Section 1 of [`docs/FCM_BACKGROUND_CALLS_PLAN.md`]):
/// - `POST   /api/v1/me/devices`              — upsert this device's FCM
///   token for the authenticated user (idempotent on `deviceId`).
/// - `DELETE /api/v1/me/devices/{deviceId}`   — drop the row so the
///   backend stops pushing here. Called on logout.
///
/// The injected [Dio] already carries `AuthInterceptor`, so every call
/// rides the same `Authorization: Bearer …` + refresh path as every
/// other authenticated endpoint.
abstract class DevicesRemoteDataSource {
  /// Upsert the device row. Mobile-supplied [deviceId] is the upsert
  /// key — the backend overwrites the FCM token + platform + app
  /// version on collision.
  Future<void> register({
    required String deviceId,
    required String fcmToken,
    String? appVersion,
  });

  /// Revoke this device server-side. Best-effort: returns normally on
  /// 404 (already deleted) so the logout cleanup never blocks.
  Future<void> unregister({required String deviceId});
}

class DioDevicesRemoteDataSource implements DevicesRemoteDataSource {
  DioDevicesRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const String _basePath = '/me/devices';

  @override
  Future<void> register({
    required String deviceId,
    required String fcmToken,
    String? appVersion,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _basePath,
      data: <String, dynamic>{
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': _platformWireValue,
        if (appVersion != null) 'appVersion': appVersion,
      },
    );
    // We don't read the body — backend returns `{success, data: { deviceId }}`
    // and the deviceId we sent IS the canonical one. ApiEnvelope.parse is
    // still called so a `success: false` response throws and the caller
    // can log it.
    ApiEnvelope.parse<void>(res.data ?? const {}, (_) {});
  }

  @override
  Future<void> unregister({required String deviceId}) async {
    try {
      await _dio.delete<Map<String, dynamic>>('$_basePath/$deviceId');
    } on DioException catch (e) {
      // 404 = already revoked (e.g. logout pressed twice, or backend
      // already pruned after token rotation). Treat as success — the
      // caller's intent is "make sure this device is gone server-side".
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  /// Matches the backend's `platform` enum (typically `android` / `ios`).
  /// We don't ship for desktop/web yet — if we ever do, extend the
  /// backend's enum first, then add a branch here.
  static String get _platformWireValue {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
