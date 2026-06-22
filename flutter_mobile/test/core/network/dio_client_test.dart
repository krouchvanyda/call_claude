import 'package:dio/dio.dart';
import 'package:erp_mobile/core/di/app_env.dart';
import 'package:erp_mobile/core/network/dio_client.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:test/test.dart';

const _customEnv = AppEnv(
  apiBaseUrl: 'https://staging.example.com/api/v1',
  connectTimeoutMs: 5000,
  receiveTimeoutMs: 7000,
  enableNetworkLogging: false,
);

void main() {
  group('buildDio — base options', () {
    final dio = buildDio(_customEnv);

    test('applies the env baseUrl verbatim', () {
      expect(dio.options.baseUrl, _customEnv.apiBaseUrl);
    });

    test('maps timeout integers to Duration values', () {
      expect(
        dio.options.connectTimeout,
        Duration(milliseconds: _customEnv.connectTimeoutMs),
      );
      expect(
        dio.options.receiveTimeout,
        Duration(milliseconds: _customEnv.receiveTimeoutMs),
      );
      expect(
        dio.options.sendTimeout,
        Duration(milliseconds: _customEnv.connectTimeoutMs),
      );
    });

    test('sets JSON Accept and Content-Type headers', () {
      expect(dio.options.headers[HttpHeaders.accept], 'application/json');
      expect(
        dio.options.headers[HttpHeaders.contentType],
        'application/json; charset=utf-8',
      );
    });

    test('expects responses as parsed JSON', () {
      expect(dio.options.responseType, ResponseType.json);
    });

    test('uses default status policy (only 2xx resolves; rest throw)', () {
      final validate = dio.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(204), isTrue);
      expect(validate(299), isTrue);
      // 4xx + 5xx throw DioException — the auth interceptor handles 401,
      // the error interceptor (0.2.3) maps everything else.
      expect(validate(400), isFalse);
      expect(validate(401), isFalse);
      expect(validate(404), isFalse);
      expect(validate(500), isFalse);
      expect(validate(503), isFalse);
    });

    test('caps redirects at 5', () {
      expect(dio.options.followRedirects, isTrue);
      expect(dio.options.maxRedirects, 5);
    });
  });

  group('buildDio — interceptor wiring', () {
    test('omits the pretty logger when env logging is disabled', () {
      final dio = buildDio(_customEnv);
      expect(
        dio.interceptors.whereType<PrettyDioLogger>(),
        isEmpty,
        reason: 'logger should be off for production-like envs',
      );
    });

    test('attaches the pretty logger when env logging is enabled', () {
      final dio = buildDio(const AppEnv(
        apiBaseUrl: 'https://x',
        connectTimeoutMs: 1000,
        receiveTimeoutMs: 1000,
        enableNetworkLogging: true,
      ));
      expect(dio.interceptors.whereType<PrettyDioLogger>(), hasLength(1));
    });
  });
}
