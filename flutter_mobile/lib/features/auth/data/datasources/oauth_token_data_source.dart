import 'package:dio/dio.dart';

import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/network/auth_tokens.dart';

/// OAuth `/token` surface — exchanges an authorization code for tokens.
///
/// Slice 1.2.2 only ships the `authorization_code` grant since that's
/// the one PKCE proofs. The refresh-token grant lives in
/// `DioTokenRefresher` (Slice 1.1.3); other grant types (`password`,
/// `client_credentials`) aren't part of this app's flow.
abstract class OAuthTokenDataSource {
  /// Trades [code] (received via the OAuth redirect) plus the original
  /// PKCE [codeVerifier] for an [AuthTokens] pair.
  ///
  /// Throws [DioException] on transport / 4xx / 5xx, [FormatException]
  /// on a response shape we can't parse.
  Future<AuthTokens> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  });
}

/// `dio`-backed implementation. Uses a dedicated [Dio] (no
/// auth/error interceptors) — same pattern as `DioTokenRefresher` and
/// `DioAuthRemoteDataSource`. The exchange is body-authenticated by the
/// PKCE proof; no Bearer header is needed, and an interceptor refresh
/// dance during sign-in would be incoherent.
class DioOAuthTokenDataSource implements OAuthTokenDataSource {
  DioOAuthTokenDataSource({required Dio dio}) : _dio = dio;

  /// Path resolved against `dio.options.baseUrl`. Standard OAuth 2.0
  /// metadata convention; configurable later if a vendor uses a
  /// non-standard endpoint.
  static const String tokenPath = '/oauth/token';

  // Body keys.
  static const String _grantType = 'authorization_code';
  static const String _bodyGrant = 'grant_type';
  static const String _bodyCode = 'code';
  static const String _bodyVerifier = 'code_verifier';
  static const String _bodyRedirectUri = 'redirect_uri';
  static const String _bodyClientId = 'client_id';

  // Response keys.
  static const String _respAccessToken = 'access_token';
  static const String _respRefreshToken = 'refresh_token';
  static const String _respExpiresIn = 'expires_in';

  final Dio _dio;

  @override
  Future<AuthTokens> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  }) async {
    final response = await _dio.post<dynamic>(
      tokenPath,
      data: <String, String>{
        _bodyGrant: _grantType,
        _bodyCode: code,
        _bodyVerifier: codeVerifier,
        _bodyRedirectUri: redirectUri,
        _bodyClientId: clientId,
      },
      options: Options(
        // RFC 6749 §4.1.3 mandates form-encoded for the token endpoint.
        contentType: Headers.formUrlEncodedContentType,
        // Keep the AuthInterceptor out — there's no token to attach
        // (this *is* the request that produces the first token), and a
        // 401 here mustn't trigger a recursive refresh.
        extra: const <String, dynamic>{AuthInterceptor.skipAuthKey: true},
      ),
    );
    return _parseTokens(response.data);
  }

  AuthTokens _parseTokens(dynamic data) {
    if (data is! Map) {
      throw FormatException(
        'OAuth token response is not a JSON object: ${data.runtimeType}',
      );
    }
    final access = data[_respAccessToken];
    final refresh = data[_respRefreshToken];
    if (access is! String || access.isEmpty) {
      throw const FormatException(
        'OAuth token response missing or non-string "access_token"',
      );
    }
    if (refresh is! String || refresh.isEmpty) {
      throw const FormatException(
        'OAuth token response missing or non-string "refresh_token"',
      );
    }

    DateTime? expiresAt;
    final expiresIn = data[_respExpiresIn];
    if (expiresIn is num) {
      expiresAt = DateTime.now().add(Duration(seconds: expiresIn.toInt()));
    }

    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: expiresAt,
    );
  }
}
