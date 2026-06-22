import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:erp_mobile/core/network/auth_interceptor.dart';
import 'package:erp_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
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

void main() {
  group('DioAuthRemoteDataSource.revokeRefreshToken', () {
    late _ScriptedAdapter adapter;
    late Dio dio;
    late DioAuthRemoteDataSource source;

    setUp(() {
      adapter = _ScriptedAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      source = DioAuthRemoteDataSource(dio: dio);
    });

    test('POSTs the refresh token to the revoke endpoint', () async {
      await source.revokeRefreshToken(
        accessToken: 'at-abc',
        refreshToken: 'rt-xyz',
      );

      expect(adapter.received, hasLength(1));
      final req = adapter.received.single;
      expect(req.method, 'POST');
      expect(req.path, DioAuthRemoteDataSource.revokePath);

      final body = jsonDecode(utf8.decode(adapter.requestBodies.single))
          as Map<String, dynamic>;
      // Spring Boot record fields → camelCase JSON.
      expect(body, {'refreshToken': 'rt-xyz'});
    });

    test('sets skipAuthKey so the auth interceptor stays out', () async {
      await source.revokeRefreshToken(
        accessToken: 'at-abc',
        refreshToken: 'rt-xyz',
      );
      expect(
        adapter.received.single.extra[AuthInterceptor.skipAuthKey],
        isTrue,
      );
    });

    test('attaches the Bearer header so Spring Security accepts the logout',
        () async {
      await source.revokeRefreshToken(
        accessToken: 'at-abc',
        refreshToken: 'rt-xyz',
      );
      // Spring's `/auth/logout` is gated by Spring Security — without
      // `Authorization: Bearer …` the server returns 401. The header is
      // attached manually because skipAuthKey is still set (to avoid the
      // refresh-on-401 loop), so the interceptor isn't doing it for us.
      expect(
        adapter.received.single.headers['Authorization'],
        'Bearer at-abc',
      );
    });

    test('propagates DioException on 5xx', () async {
      adapter.statusCode = 503;
      await expectLater(
        () => source.revokeRefreshToken(
          accessToken: 'at-abc',
          refreshToken: 'rt-xyz',
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('propagates DioException on 401 (expired token)', () async {
      adapter.statusCode = 401;
      await expectLater(
        () => source.revokeRefreshToken(
          accessToken: 'at-abc',
          refreshToken: 'rt-xyz',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
