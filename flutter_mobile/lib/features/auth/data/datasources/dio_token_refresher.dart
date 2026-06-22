import 'package:dio/dio.dart';

import '../../../../core/error/crash_reporter.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/network/auth_tokens.dart';
import '../../../../core/network/token_refresher.dart';
import '../../../../core/utils/logger/app_logger.dart';
import 'cached_user_dao.dart';

/// Production [TokenRefresher] — replaces `UnimplementedTokenRefresher`.
///
/// Hits the auth server's refresh endpoint with the stored refresh token,
/// parses the response, and returns a new [AuthTokens] pair. The
/// `AuthInterceptor` (Slice 0.2.2) calls this from inside its 401-driven
/// refresh window.
///
/// **`user_id` context** (per CLAUDE.md Slice 1.1.3): every refresh
/// looks up the currently-cached user and threads their id through the
/// log + crash-report context so observability dashboards can attribute
/// the rotation to a specific session. The id is **not** sent to the
/// server — the refresh token alone is sufficient identification.
///
/// **Safety**:
/// - The request carries `AuthInterceptor.skipAuthKey: true`, so the
///   interceptor doesn't attach the about-to-expire access token to the
///   refresh call and doesn't recursively refresh on a 401 to this
///   endpoint.
/// - Any exception (DioException, FormatException, anything else)
///   propagates up to the auth interceptor, which treats it as a refresh
///   failure: tokens cleared, session invalidated, user bounced to /login.
class DioTokenRefresher implements TokenRefresher {
  DioTokenRefresher({
    required Dio dio,
    required CachedUserDao cachedUserDao,
    required AppLogger logger,
    required CrashReporter crashReporter,
  })  : _dio = dio,
        _cache = cachedUserDao,
        _logger = logger.child('auth.refresh'),
        _crash = crashReporter;

  /// Refresh endpoint path. Resolved against `dio.options.baseUrl`.
  static const String endpointPath = '/auth/refresh';

  // Body key: tell the server which refresh token to rotate.
  static const String _bodyRefreshToken = 'refresh_token';
  // Response keys (snake_case — common REST/OAuth convention).
  static const String _respAccessToken = 'access_token';
  static const String _respRefreshToken = 'refresh_token';
  static const String _respExpiresAt = 'expires_at';

  final Dio _dio;
  final CachedUserDao _cache;
  final AppLogger _logger;
  final CrashReporter _crash;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final logContext = await _buildContext();
    _logger.info('starting refresh', context: logContext);

    try {
      final response = await _dio.post<dynamic>(
        endpointPath,
        data: <String, String>{_bodyRefreshToken: refreshToken},
        options: Options(
          // Skip the AuthInterceptor's request-side header attachment AND
          // its error-side recursive-refresh dance. The refresh token in
          // the body is the auth.
          extra: const <String, dynamic>{AuthInterceptor.skipAuthKey: true},
        ),
      );

      final tokens = _parseResponse(response.data);
      _logger.info('refresh succeeded', context: logContext);
      return tokens;
    } on DioException catch (e, stack) {
      _crash.report(
        e,
        stack,
        severity: CrashSeverity.warning,
        description: 'auth.refresh transport failed',
        context: logContext,
      );
      rethrow;
    } on FormatException catch (e, stack) {
      _crash.report(
        e,
        stack,
        severity: CrashSeverity.warning,
        description: 'auth.refresh malformed response',
        context: logContext,
      );
      rethrow;
    }
  }

  Future<Map<String, Object?>> _buildContext() async {
    // Look up the cached user for log/crash context. The miss case is
    // expected on first install (no row yet) — emit the call without an
    // id rather than blocking the refresh on it.
    final user = await _cache.getCurrentUser();
    return {
      if (user != null) 'user_id': user.id,
    };
  }

  AuthTokens _parseResponse(dynamic data) {
    if (data is! Map) {
      throw FormatException(
        'refresh response is not a JSON object: ${data.runtimeType}',
      );
    }
    final access = data[_respAccessToken];
    final refresh = data[_respRefreshToken];
    if (access is! String || access.isEmpty) {
      throw const FormatException(
        'refresh response missing or non-string "access_token"',
      );
    }
    if (refresh is! String || refresh.isEmpty) {
      throw const FormatException(
        'refresh response missing or non-string "refresh_token"',
      );
    }
    final expiresRaw = data[_respExpiresAt];
    final expiresAt =
        expiresRaw is String ? DateTime.tryParse(expiresRaw) : null;
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: expiresAt,
    );
  }
}
