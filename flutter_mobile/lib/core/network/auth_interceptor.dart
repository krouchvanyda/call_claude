import 'dart:async';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'auth_tokens.dart';
import 'dio_client.dart' show HttpHeaders;
import 'session_signal.dart';
import 'token_refresher.dart';
import 'token_storage.dart';

/// Attaches the bearer access token to every outgoing request and silently
/// refreshes it once on 401, retrying the original request transparently.
///
/// Built on top of [QueuedInterceptor] so concurrent requests pile up behind
/// the in-flight refresh instead of spawning a thundering herd of refresh
/// calls. An additional `_inFlight` [Completer] guards the rare case where
/// the queue still re-enters the refresh path.
///
/// **Opting out of auth attachment** for endpoints that mustn't carry the
/// token (login, refresh, token revocation) is done by setting the
/// [skipAuthKey] extra on the request:
///
/// ```dart
/// dio.post('/auth/login', data: ..., options: Options(extra: {
///   AuthInterceptor.skipAuthKey: true,
/// }));
/// ```
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required TokenRefresher tokenRefresher,
    required SessionSignal sessionSignal,
  })  : _tokenStorage = tokenStorage,
        _tokenRefresher = tokenRefresher,
        _sessionSignal = sessionSignal;

  /// Set to `true` on a [RequestOptions.extra] to skip header attachment AND
  /// the 401-refresh dance for that single call.
  static const String skipAuthKey = 'authInterceptor.skipAuth';

  final TokenStorage _tokenStorage;
  final TokenRefresher _tokenRefresher;
  final SessionSignal _sessionSignal;

  /// The [Dio] this interceptor is attached to — used to retry the original
  /// request after a successful refresh. Set by the DI wiring immediately
  /// after construction.
  late Dio dio;

  Completer<AuthTokens>? _inFlightRefresh;

  // ── Request side ─────────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isOptedOut(options)) return handler.next(options);

    final tokens = await _tokenStorage.read();
    if (tokens != null) {
      options.headers[HttpHeaders.authorization] =
          'Bearer ${tokens.accessToken}';
    }
    return handler.next(options);
  }

  // ── Error side ───────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldAttemptRefresh(err)) return handler.next(err);

    final stored = await _tokenStorage.read();
    if (stored == null) {
      await _sessionSignal.invalidate();
      return handler.next(err);
    }

    // Fast path: another request in this burst already refreshed the
    // tokens. The failed request was sent with the *previous* access
    // token; just retry it with the current one — no refresh needed.
    final usedAuthHeader =
        err.requestOptions.headers[HttpHeaders.authorization];
    final currentAuthHeader = 'Bearer ${stored.accessToken}';
    if (usedAuthHeader != null && usedAuthHeader != currentAuthHeader) {
      try {
        final retried = await _retry(err.requestOptions, stored);
        return handler.resolve(retried);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }

    final AuthTokens fresh;
    try {
      fresh = await _refreshOnce(stored.refreshToken);
    } catch (_) {
      await _tokenStorage.clear();
      await _sessionSignal.invalidate();
      return handler.next(err);
    }

    await _tokenStorage.write(fresh);

    try {
      final retried = await _retry(err.requestOptions, fresh);
      return handler.resolve(retried);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────
  /// Visible for unit tests so the branch logic can be asserted without
  /// constructing a full interceptor + handler harness.
  @visibleForTesting
  static bool shouldAttemptRefresh(DioException err) =>
      _shouldAttemptRefresh(err);

  static bool _shouldAttemptRefresh(DioException err) {
    if (err.response?.statusCode != 401) return false;
    if (_isOptedOut(err.requestOptions)) return false;
    return true;
  }

  static bool _isOptedOut(RequestOptions options) =>
      options.extra[skipAuthKey] == true;

  /// Coalesces concurrent refresh attempts into a single network call.
  Future<AuthTokens> _refreshOnce(String refreshToken) {
    final inflight = _inFlightRefresh;
    if (inflight != null) return inflight.future;

    final completer = Completer<AuthTokens>();
    _inFlightRefresh = completer;

    Future<void>(() async {
      try {
        final tokens = await _tokenRefresher.refresh(refreshToken);
        completer.complete(tokens);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _inFlightRefresh = null;
      }
    });

    return completer.future;
  }

  Future<Response<dynamic>> _retry(
    RequestOptions original,
    AuthTokens fresh,
  ) {
    final retryOptions = Options(
      method: original.method,
      headers: <String, dynamic>{
        ...original.headers,
        HttpHeaders.authorization: 'Bearer ${fresh.accessToken}',
      },
      contentType: original.contentType,
      responseType: original.responseType,
      sendTimeout: original.sendTimeout,
      receiveTimeout: original.receiveTimeout,
      followRedirects: original.followRedirects,
      maxRedirects: original.maxRedirects,
      validateStatus: original.validateStatus,
      // Mark the retry so a second 401 propagates instead of looping.
      extra: <String, dynamic>{
        ...original.extra,
        skipAuthKey: true,
      },
    );

    return dio.request<dynamic>(
      original.path,
      data: original.data,
      queryParameters: original.queryParameters,
      cancelToken: original.cancelToken,
      options: retryOptions,
    );
  }
}
