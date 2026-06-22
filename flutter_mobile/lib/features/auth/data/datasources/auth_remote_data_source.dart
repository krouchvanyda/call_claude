import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/network/dio_client.dart' show HttpHeaders;
import '../models/auth_requests.dart';
import '../models/auth_response.dart';

/// Auth-server data source surface.
///
/// Mirrors the Spring `AuthController` at `/api/v1/auth/*`:
///   - `POST /login`    → returns [AuthResponse]
///   - `POST /register` → returns [AuthResponse]
///   - `POST /refresh`  → returns [AuthResponse]
///   - `POST /logout`   → server-revokes the refresh token (best-effort)
///
/// All four endpoints skip the [AuthInterceptor] — login/register run
/// before the user has a token, refresh/revoke must not loop on a 401.
abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(LoginRequest body);
  Future<AuthResponse> register(RegisterRequest body);
  Future<AuthResponse> refresh(RefreshRequest body);

  /// Best-effort server-side invalidation of [refreshToken] — call this
  /// from the sign-out path. May throw on transport / 4xx / 5xx; callers
  /// must treat any failure as a hint to *still* clean up locally so the
  /// user doesn't get stuck signed in when the server is unreachable.
  ///
  /// [accessToken] is required because the Spring `/auth/logout` endpoint
  /// is gated by Spring Security — it identifies *who* is logging out so
  /// the server can revoke the matching refresh-token row. Attached
  /// manually to the request header; the [AuthInterceptor] is still
  /// skipped so a 401 from a stale access token doesn't trigger a
  /// refresh-then-revoke loop on the way out.
  Future<void> revokeRefreshToken({
    required String accessToken,
    required String refreshToken,
  });
}

/// `dio`-backed implementation. Uses a dedicated [Dio] (no auth /
/// error-mapping interceptors) so the call doesn't race the [AuthInterceptor]
/// during sign-out: a stale access token must not trigger a refresh while
/// the user is on their way out, and a 401 here must not loop.
///
/// Paths are resolved relative to `dio.options.baseUrl`, which the
/// environment seed (e.g. `Local dev`) sets to
/// `http://localhost:8080/api/v1`.
class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  DioAuthRemoteDataSource({required Dio dio}) : _dio = dio;

  // ── Endpoint paths (relative to baseUrl `…/api/v1`) ──────────
  static const String loginPath = '/auth/login';
  static const String registerPath = '/auth/register';
  static const String refreshPath = '/auth/refresh';
  static const String revokePath = '/auth/logout';

  final Dio _dio;

  /// `Options` for endpoints that must NOT trigger the auth interceptor:
  /// login/register run pre-authentication, refresh/revoke must not loop
  /// on a 401 of their own.
  static final Options _skipAuthOptions = Options(
    extra: const <String, dynamic>{AuthInterceptor.skipAuthKey: true},
  );

  @override
  Future<AuthResponse> login(LoginRequest body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      loginPath,
      data: body.toJson(),
      options: _skipAuthOptions,
    );
    return ApiEnvelope.parse(res.data!, AuthResponse.fromJson);
  }

  @override
  Future<AuthResponse> register(RegisterRequest body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      registerPath,
      data: body.toJson(),
      options: _skipAuthOptions,
    );
    return ApiEnvelope.parse(res.data!, AuthResponse.fromJson);
  }

  @override
  Future<AuthResponse> refresh(RefreshRequest body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      refreshPath,
      data: body.toJson(),
      options: _skipAuthOptions,
    );
    return ApiEnvelope.parse(res.data!, AuthResponse.fromJson);
  }

  @override
  Future<void> revokeRefreshToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _dio.post<dynamic>(
      revokePath,
      data: LogoutRequest(refreshToken: refreshToken).toJson(),
      // Manually attach the Bearer header — the interceptor is still
      // skipped so a 401 here cannot trigger the refresh loop. Spring
      // Security gates `/auth/logout` so this header is required.
      options: Options(
        headers: <String, dynamic>{
          HttpHeaders.authorization: 'Bearer $accessToken',
        },
        extra: const <String, dynamic>{AuthInterceptor.skipAuthKey: true},
      ),
    );
  }
}
