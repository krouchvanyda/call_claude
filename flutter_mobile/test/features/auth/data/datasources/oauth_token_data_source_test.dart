import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:erp_mobile/core/network/auth_interceptor.dart';
import 'package:erp_mobile/features/auth/data/datasources/oauth_token_data_source.dart';
import 'package:test/test.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, dynamic> body = const {};
  final List<RequestOptions> received = [];
  final List<List<int>> requestBodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    if (requestStream != null) {
      final chunks = <int>[];
      await for (final c in requestStream) {
        chunks.addAll(c);
      }
      requestBodies.add(chunks);
    } else {
      requestBodies.add(const []);
    }
    final raw = utf8.encode(jsonEncode(body));
    return ResponseBody.fromBytes(
      raw,
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({DioOAuthTokenDataSource source, _ScriptedAdapter adapter}) _build() {
  final adapter = _ScriptedAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
  return (source: DioOAuthTokenDataSource(dio: dio), adapter: adapter);
}

Map<String, String> _decodeFormBody(List<int> bytes) {
  final raw = utf8.decode(bytes);
  return Map.fromEntries(raw.split('&').map((p) {
    final parts = p.split('=');
    return MapEntry(
      Uri.decodeQueryComponent(parts[0]),
      Uri.decodeQueryComponent(parts[1]),
    );
  }));
}

void main() {
  group('DioOAuthTokenDataSource.exchangeAuthorizationCode — happy path', () {
    test('POSTs form-encoded body with all RFC 6749 + 7636 fields', () async {
      final fx = _build();
      fx.adapter.body = const {
        'access_token': 'at-1',
        'refresh_token': 'rt-1',
        'expires_in': 3600,
      };

      await fx.source.exchangeAuthorizationCode(
        code: 'authcode-xyz',
        codeVerifier: 'verifier-abc',
        redirectUri: 'erpmobile://oauth/callback',
        clientId: 'erp-mobile-dev',
      );

      expect(fx.adapter.received, hasLength(1));
      final req = fx.adapter.received.single;
      expect(req.method, 'POST');
      expect(req.path, DioOAuthTokenDataSource.tokenPath);
      expect(req.contentType, Headers.formUrlEncodedContentType);

      final body = _decodeFormBody(fx.adapter.requestBodies.single);
      expect(body, {
        'grant_type': 'authorization_code',
        'code': 'authcode-xyz',
        'code_verifier': 'verifier-abc',
        'redirect_uri': 'erpmobile://oauth/callback',
        'client_id': 'erp-mobile-dev',
      });
    });

    test('attaches skipAuthKey so AuthInterceptor stays out', () async {
      final fx = _build();
      fx.adapter.body = const {
        'access_token': 'a',
        'refresh_token': 'r',
      };
      await fx.source.exchangeAuthorizationCode(
        code: 'c',
        codeVerifier: 'v',
        redirectUri: 'r',
        clientId: 'c',
      );
      expect(
        fx.adapter.received.single.extra[AuthInterceptor.skipAuthKey],
        isTrue,
      );
    });

    test('parses access_token + refresh_token + expires_in into AuthTokens',
        () async {
      final fx = _build();
      fx.adapter.body = const {
        'access_token': 'access-A',
        'refresh_token': 'refresh-A',
        'expires_in': 1800,
      };

      final before = DateTime.now();
      final tokens = await fx.source.exchangeAuthorizationCode(
        code: 'c',
        codeVerifier: 'v',
        redirectUri: 'r',
        clientId: 'c',
      );
      final after = DateTime.now();

      expect(tokens.accessToken, 'access-A');
      expect(tokens.refreshToken, 'refresh-A');
      // Timestamp comes from `DateTime.now() + expires_in` — assert it's
      // inside the realistic window the test took to execute.
      expect(
        tokens.accessExpiresAt!.isAfter(
              before.add(const Duration(seconds: 1799)),
            ) &&
            tokens.accessExpiresAt!.isBefore(
              after.add(const Duration(seconds: 1801)),
            ),
        isTrue,
        reason:
            'expiresAt ${tokens.accessExpiresAt} not in expected window',
      );
    });

    test('omits accessExpiresAt when expires_in is missing', () async {
      final fx = _build();
      fx.adapter.body = const {
        'access_token': 'a',
        'refresh_token': 'r',
      };
      final tokens = await fx.source.exchangeAuthorizationCode(
        code: 'c',
        codeVerifier: 'v',
        redirectUri: 'r',
        clientId: 'c',
      );
      expect(tokens.accessExpiresAt, isNull);
    });
  });

  group('DioOAuthTokenDataSource — failure paths', () {
    test('5xx response throws DioException', () async {
      final fx = _build();
      fx.adapter.statusCode = 503;
      await expectLater(
        () => fx.source.exchangeAuthorizationCode(
          code: 'c',
          codeVerifier: 'v',
          redirectUri: 'r',
          clientId: 'c',
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('400 invalid_grant throws DioException', () async {
      final fx = _build();
      fx.adapter.statusCode = 400;
      fx.adapter.body = const {'error': 'invalid_grant'};
      await expectLater(
        () => fx.source.exchangeAuthorizationCode(
          code: 'c',
          codeVerifier: 'v',
          redirectUri: 'r',
          clientId: 'c',
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('missing access_token in 200 body throws FormatException', () async {
      final fx = _build();
      fx.adapter.body = const {'refresh_token': 'r'};
      await expectLater(
        () => fx.source.exchangeAuthorizationCode(
          code: 'c',
          codeVerifier: 'v',
          redirectUri: 'r',
          clientId: 'c',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing refresh_token throws FormatException', () async {
      final fx = _build();
      fx.adapter.body = const {'access_token': 'a'};
      await expectLater(
        () => fx.source.exchangeAuthorizationCode(
          code: 'c',
          codeVerifier: 'v',
          redirectUri: 'r',
          clientId: 'c',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('non-string token field throws FormatException', () async {
      final fx = _build();
      fx.adapter.body = const {'access_token': 42, 'refresh_token': 'r'};
      await expectLater(
        () => fx.source.exchangeAuthorizationCode(
          code: 'c',
          codeVerifier: 'v',
          redirectUri: 'r',
          clientId: 'c',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
