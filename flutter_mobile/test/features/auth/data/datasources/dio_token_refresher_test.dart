import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/error/logging_crash_reporter.dart';
import 'package:erp_mobile/core/network/auth_interceptor.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:erp_mobile/features/auth/data/datasources/cached_user_dao.dart';
import 'package:erp_mobile/features/auth/data/datasources/dio_token_refresher.dart';
import 'package:erp_mobile/features/auth/entities/user.dart';
import 'package:test/test.dart';

import '../../../../_support/recording_logger.dart';

// ── Test transport ──────────────────────────────────────────────────
/// Captures every outbound request and replies with a scripted body /
/// status code per call.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({this.statusCode = 200, this.body = const {}});
  int statusCode;
  Map<String, dynamic> body;
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

Map<String, dynamic> _decodeBody(List<int> bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

// ── Fixture builders ────────────────────────────────────────────────
({
  DioTokenRefresher refresher,
  Dio dio,
  _ScriptedAdapter adapter,
  RecordingLogger logger,
  AppDatabase db,
  CachedUserDao cache,
}) _build({
  int status = 200,
  Map<String, dynamic> body = const {
    'access_token': 'new-access',
    'refresh_token': 'new-refresh',
    'expires_at': '2026-05-12T11:00:00.000Z',
  },
}) {
  final adapter = _ScriptedAdapter(statusCode: status, body: body);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
  final db = AppDatabase(NativeDatabase.memory());
  final cache = db.cachedUserDao;
  final logger = RecordingLogger();
  final refresher = DioTokenRefresher(
    dio: dio,
    cachedUserDao: cache,
    logger: logger,
    crashReporter: LoggingCrashReporter(logger),
  );
  return (
    refresher: refresher,
    dio: dio,
    adapter: adapter,
    logger: logger,
    db: db,
    cache: cache,
  );
}

void main() {
  group('DioTokenRefresher — success path', () {
    test('POSTs the refresh token and returns parsed AuthTokens', () async {
      final fx = _build();
      addTearDown(fx.db.close);

      final tokens = await fx.refresher.refresh('the-refresh-token');

      expect(tokens.accessToken, 'new-access');
      expect(tokens.refreshToken, 'new-refresh');
      expect(tokens.accessExpiresAt, DateTime.utc(2026, 5, 12, 11));

      // One call against /auth/refresh with the refresh_token in the body.
      expect(fx.adapter.received, hasLength(1));
      final req = fx.adapter.received.single;
      expect(req.method, 'POST');
      expect(req.path, '/auth/refresh');
      final reqBody = _decodeBody(fx.adapter.requestBodies.single);
      expect(reqBody, {'refresh_token': 'the-refresh-token'});
    });

    test('attaches the skipAuthKey extra so AuthInterceptor stays out',
        () async {
      final fx = _build();
      addTearDown(fx.db.close);

      await fx.refresher.refresh('rt');

      final extra = fx.adapter.received.single.extra;
      expect(extra[AuthInterceptor.skipAuthKey], isTrue);
    });

    test('accessExpiresAt is null when the response omits expires_at',
        () async {
      final fx = _build(body: const {
        'access_token': 'a',
        'refresh_token': 'r',
      });
      addTearDown(fx.db.close);

      final tokens = await fx.refresher.refresh('rt');
      expect(tokens.accessExpiresAt, isNull);
    });
  });

  group('DioTokenRefresher — observability (user_id context)', () {
    test('attaches user_id from drift to the start + success log entries',
        () async {
      final fx = _build();
      addTearDown(fx.db.close);

      // Pre-cache a signed-in user — the refresher should pick it up.
      await fx.cache.cacheUser(const User(
        id: 'u-42',
        email: 'a@b.co',
        displayName: 'Alice',
      ));

      await fx.refresher.refresh('rt');

      // Two info events: "starting refresh" and "refresh succeeded".
      final infos = fx.logger.at(LogLevel.info).toList();
      expect(infos, hasLength(2));
      for (final entry in infos) {
        expect(entry.context['user_id'], 'u-42',
            reason: '$entry should carry the cached user id');
        // Child logger prefixes with [auth.refresh].
        expect(entry.message, startsWith('[auth.refresh]'));
      }
    });

    test('omits user_id when no user is cached (first install)', () async {
      final fx = _build();
      addTearDown(fx.db.close);

      await fx.refresher.refresh('rt');

      final infos = fx.logger.at(LogLevel.info).toList();
      expect(infos, isNotEmpty);
      for (final entry in infos) {
        expect(entry.context.containsKey('user_id'), isFalse);
      }
    });
  });

  group('DioTokenRefresher — failure paths', () {
    test('5xx → DioException rethrown + logged at warning severity',
        () async {
      final fx = _build(status: 500, body: const {'error': 'oops'});
      addTearDown(fx.db.close);

      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<DioException>()),
      );
      // CrashReporter (LoggingCrashReporter) fires at warning level for
      // the transport failure.
      final warnings = fx.logger.at(LogLevel.warning).toList();
      expect(warnings, hasLength(1));
      expect(warnings.single.message,
          contains('auth.refresh transport failed'));
    });

    test('401 from refresh endpoint propagates without recursive refresh',
        () async {
      final fx = _build(status: 401, body: const {'error': 'expired'});
      addTearDown(fx.db.close);

      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<DioException>()),
      );
      // skipAuthKey on the request means the AuthInterceptor (not even
      // attached here) wouldn't try to refresh again — but the contract
      // is also that *we* don't loop. Single attempt.
      expect(fx.adapter.received, hasLength(1));
    });

    test('malformed response (not JSON object) → FormatException + warning',
        () async {
      final fx = _build();
      addTearDown(fx.db.close);
      // Swap the adapter for one that returns a JSON array — the
      // refresher expects a Map and rejects this shape.
      fx.dio.httpClientAdapter = _RawBytesAdapter(
        statusCode: 200,
        bytes: utf8.encode('[1,2,3]'),
      );

      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<FormatException>()),
      );
      final warnings = fx.logger.at(LogLevel.warning).toList();
      expect(warnings, hasLength(1));
      expect(warnings.single.message,
          contains('auth.refresh malformed response'));
    });

    test('missing access_token → FormatException', () async {
      final fx = _build(body: const {'refresh_token': 'r'});
      addTearDown(fx.db.close);
      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing refresh_token → FormatException', () async {
      final fx = _build(body: const {'access_token': 'a'});
      addTearDown(fx.db.close);
      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<FormatException>()),
      );
    });

    test('non-string access_token → FormatException', () async {
      final fx = _build(body: const {
        'access_token': 42,
        'refresh_token': 'r',
      });
      addTearDown(fx.db.close);
      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<FormatException>()),
      );
    });

    test('failure log carries user_id when one is cached', () async {
      final fx = _build(status: 503);
      addTearDown(fx.db.close);

      await fx.cache.cacheUser(const User(
        id: 'u-9',
        email: 'a@b.co',
        displayName: 'A',
      ));

      await expectLater(
        () => fx.refresher.refresh('rt'),
        throwsA(isA<DioException>()),
      );
      final warning = fx.logger.at(LogLevel.warning).single;
      expect(warning.context['user_id'], 'u-9');
    });
  });
}

// ── Helper for the malformed-body case ──────────────────────────────
class _RawBytesAdapter implements HttpClientAdapter {
  _RawBytesAdapter({required this.statusCode, required this.bytes});
  final int statusCode;
  final List<int> bytes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      bytes,
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
