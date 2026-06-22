import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:erp_mobile/core/network/auth_interceptor.dart';
import 'package:erp_mobile/core/network/auth_tokens.dart';
import 'package:erp_mobile/core/network/dio_client.dart';
import 'package:erp_mobile/core/network/session_signal.dart';
import 'package:erp_mobile/core/network/token_refresher.dart';
import 'package:erp_mobile/core/network/token_storage.dart';
import 'package:test/test.dart';

// ── Test doubles (hand-rolled to avoid dragging mocktail into pure-Dart) ──

class _RecordingSessionSignal implements SessionSignal {
  int invalidateCount = 0;
  @override
  Future<void> invalidate() async => invalidateCount++;
}

class _ScriptedRefresher implements TokenRefresher {
  _ScriptedRefresher(this._respond);
  final Future<AuthTokens> Function(String refreshToken) _respond;
  int callCount = 0;

  @override
  Future<AuthTokens> refresh(String refreshToken) {
    callCount++;
    return _respond(refreshToken);
  }
}

/// Adapter that returns a canned status code per request count.
/// First N calls → 401, every call after → 200 with an empty JSON body.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({required this.failuresBeforeSuccess});
  final int failuresBeforeSuccess;
  int callCount = 0;
  final List<RequestOptions> received = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    received.add(options);
    final status = callCount <= failuresBeforeSuccess ? 401 : 200;
    final body = utf8.encode(jsonEncode({'ok': status == 200}));
    return ResponseBody.fromBytes(
      body,
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _buildTestDio(AuthInterceptor interceptor, _ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://example.test',
    responseType: ResponseType.json,
  ))
    ..httpClientAdapter = adapter
    ..interceptors.add(interceptor);
  interceptor.dio = dio;
  return dio;
}

void main() {
  group('AuthInterceptor.shouldAttemptRefresh', () {
    DioException makeErr({required int? status, Map<String, dynamic>? extra}) {
      final req = RequestOptions(path: '/x', extra: extra ?? {});
      return DioException(
        requestOptions: req,
        response: status == null
            ? null
            : Response(requestOptions: req, statusCode: status),
      );
    }

    test('triggers on 401', () {
      expect(
        AuthInterceptor.shouldAttemptRefresh(makeErr(status: 401)),
        isTrue,
      );
    });

    test('skips on non-401 statuses', () {
      for (final code in [200, 400, 403, 404, 500, 503]) {
        expect(
          AuthInterceptor.shouldAttemptRefresh(makeErr(status: code)),
          isFalse,
          reason: 'status $code must not trigger refresh',
        );
      }
    });

    test('skips when status is missing (network/timeout error)', () {
      expect(
        AuthInterceptor.shouldAttemptRefresh(makeErr(status: null)),
        isFalse,
      );
    });

    test('skips when the request opted out via skipAuthKey', () {
      expect(
        AuthInterceptor.shouldAttemptRefresh(makeErr(
          status: 401,
          extra: {AuthInterceptor.skipAuthKey: true},
        )),
        isFalse,
      );
    });
  });

  group('AuthInterceptor — full request flow', () {
    test('attaches Bearer header from stored token on outgoing request',
        () async {
      final storage = InMemoryTokenStorage()
        ..write(const AuthTokens(
          accessToken: 'access-A',
          refreshToken: 'refresh-A',
        ));
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: _ScriptedRefresher(
          (_) async => throw StateError('refresh should not run'),
        ),
        sessionSignal: _RecordingSessionSignal(),
      );
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 0);
      final dio = _buildTestDio(interceptor, adapter);

      final response = await dio.get<dynamic>('/me');
      expect(response.statusCode, 200);
      expect(adapter.received, hasLength(1));
      expect(
        adapter.received.first.headers[HttpHeaders.authorization],
        'Bearer access-A',
      );
    });

    test('does not attach a header when no token is stored', () async {
      final interceptor = AuthInterceptor(
        tokenStorage: InMemoryTokenStorage(),
        tokenRefresher: _ScriptedRefresher(
          (_) async => throw StateError('refresh should not run'),
        ),
        sessionSignal: _RecordingSessionSignal(),
      );
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 0);
      final dio = _buildTestDio(interceptor, adapter);

      await dio.get<dynamic>('/public');
      expect(
        adapter.received.first.headers.containsKey(HttpHeaders.authorization),
        isFalse,
      );
    });

    test('opt-out via skipAuthKey suppresses header attachment', () async {
      final storage = InMemoryTokenStorage()
        ..write(const AuthTokens(
          accessToken: 'access-A',
          refreshToken: 'refresh-A',
        ));
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: _ScriptedRefresher(
          (_) async => throw StateError('refresh should not run'),
        ),
        sessionSignal: _RecordingSessionSignal(),
      );
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 0);
      final dio = _buildTestDio(interceptor, adapter);

      await dio.post<dynamic>(
        '/auth/login',
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );
      expect(
        adapter.received.first.headers.containsKey(HttpHeaders.authorization),
        isFalse,
      );
    });
  });

  group('AuthInterceptor — 401 refresh & retry', () {
    test('refreshes once, retries the request, returns the retry response',
        () async {
      final storage = InMemoryTokenStorage()
        ..write(const AuthTokens(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ));
      final refresher = _ScriptedRefresher((rt) async {
        expect(rt, 'old-refresh');
        return const AuthTokens(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        );
      });
      final signal = _RecordingSessionSignal();
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: refresher,
        sessionSignal: signal,
      );
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 1);
      final dio = _buildTestDio(interceptor, adapter);

      final response = await dio.get<dynamic>('/orders');

      expect(response.statusCode, 200);
      expect(refresher.callCount, 1, reason: 'exactly one refresh');
      expect(adapter.callCount, 2, reason: 'original + retry');
      expect(signal.invalidateCount, 0, reason: 'session must stay valid');

      // The retry must have carried the new bearer.
      final retryHeaders = adapter.received.last.headers;
      expect(retryHeaders[HttpHeaders.authorization], 'Bearer new-access');

      // Storage is updated to the fresh pair.
      final stored = await storage.read();
      expect(stored?.accessToken, 'new-access');
      expect(stored?.refreshToken, 'new-refresh');
    });

    test('on refresh failure: clears storage and signals invalidation',
        () async {
      final storage = InMemoryTokenStorage()
        ..write(const AuthTokens(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ));
      final refresher = _ScriptedRefresher(
        (_) async => throw StateError('refresh server unreachable'),
      );
      final signal = _RecordingSessionSignal();
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: refresher,
        sessionSignal: signal,
      );
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 1);
      final dio = _buildTestDio(interceptor, adapter);

      await expectLater(
        () => dio.get<dynamic>('/orders'),
        throwsA(isA<DioException>()),
      );
      expect(refresher.callCount, 1);
      expect(adapter.callCount, 1, reason: 'no retry on refresh failure');
      expect(signal.invalidateCount, 1);
      expect(await storage.read(), isNull,
          reason: 'tokens must be cleared on refresh failure');
    });

    test('without stored tokens, a 401 invalidates immediately', () async {
      final storage = InMemoryTokenStorage();
      final refresher = _ScriptedRefresher(
        (_) async => throw StateError('refresh should not run'),
      );
      final signal = _RecordingSessionSignal();
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: refresher,
        sessionSignal: signal,
      );
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 1);
      final dio = _buildTestDio(interceptor, adapter);

      await expectLater(
        () => dio.get<dynamic>('/orders'),
        throwsA(isA<DioException>()),
      );
      expect(refresher.callCount, 0);
      expect(signal.invalidateCount, 1);
    });

    test('coalesces concurrent 401s into a single refresh call', () async {
      final storage = InMemoryTokenStorage()
        ..write(const AuthTokens(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ));
      // Hold the refresh open until we're sure all requests are queued.
      final refreshGate = Completer<void>();
      final refresher = _ScriptedRefresher((_) async {
        await refreshGate.future;
        return const AuthTokens(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        );
      });
      final interceptor = AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: refresher,
        sessionSignal: _RecordingSessionSignal(),
      );
      // Each request: original 401 + retry 200 = 2 adapter calls per request.
      // We fire 3 requests → 6 adapter calls, but only 1 refresh.
      final adapter = _ScriptedAdapter(failuresBeforeSuccess: 3);
      final dio = _buildTestDio(interceptor, adapter);

      final inflight = <Future<Response<dynamic>>>[
        dio.get<dynamic>('/a'),
        dio.get<dynamic>('/b'),
        dio.get<dynamic>('/c'),
      ];

      // Give the queue a moment to pile up behind the refresh.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      refreshGate.complete();

      final responses = await Future.wait(inflight);
      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(refresher.callCount, 1,
          reason: 'concurrent 401s must collapse to a single refresh');
    });
  });
}
