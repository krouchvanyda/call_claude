import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../di/app_env.dart';

/// HTTP header names used across the app.
///
/// Centralised so spelling stays consistent (HTTP headers are case-insensitive
/// but tooling, tests, and grep aren't). Values that vary per request — like
/// `Authorization` — are written by interceptors in later slices.
abstract final class HttpHeaders {
  static const String accept = 'Accept';
  static const String contentType = 'Content-Type';
  static const String acceptLanguage = 'Accept-Language';
  static const String userAgent = 'User-Agent';
  static const String authorization = 'Authorization';
  static const String requestId = 'X-Request-ID';
  static const String clientPlatform = 'X-Client-Platform';
  static const String clientVersion = 'X-Client-Version';
}

/// Builds a configured [Dio] from an [AppEnv].
///
/// Pure factory — no DI lookup, no globals. Lets the function be unit-tested
/// against arbitrary envs and reused inside the `@module` provider. Later
/// slices attach interceptors (auth → 0.2.2, error mapping → 0.2.3) by reading
/// `dio.interceptors.add(...)` after construction; this slice deliberately
/// only sets the **transport-level** defaults.
Dio buildDio(AppEnv env) {
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: Duration(milliseconds: env.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: env.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: env.connectTimeoutMs),
      headers: <String, String>{
        HttpHeaders.accept: 'application/json',
        HttpHeaders.contentType: 'application/json; charset=utf-8',
      },
      responseType: ResponseType.json,
      // Default-status policy: 2xx resolves, everything else throws a
      // DioException. The auth interceptor (0.2.2) intercepts 401s for
      // the silent refresh; the error interceptor (0.2.3) maps the rest
      // into typed Failures.
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  if (env.enableNetworkLogging) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 120,
      ),
    );
  }

  return dio;
}
