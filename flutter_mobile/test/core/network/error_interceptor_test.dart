import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/core/error/failure_from_dio.dart';
import 'package:erp_mobile/core/network/error_interceptor.dart';
import 'package:test/test.dart';

DioException _badResponse({
  required int status,
  Object? body,
  Map<String, List<String>>? headers,
}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: req,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers ?? const {}),
    ),
  );
}

DioException _typed(DioExceptionType type, {String? message, Object? error}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: type,
    message: message,
    error: error,
  );
}

void main() {
  group('mapDioExceptionToFailure — transport failures', () {
    test('connectionTimeout → TimeoutFailure', () {
      expect(
        mapDioExceptionToFailure(_typed(DioExceptionType.connectionTimeout)),
        isA<TimeoutFailure>(),
      );
    });

    test('sendTimeout / receiveTimeout → TimeoutFailure', () {
      expect(
        mapDioExceptionToFailure(_typed(DioExceptionType.sendTimeout)),
        isA<TimeoutFailure>(),
      );
      expect(
        mapDioExceptionToFailure(_typed(DioExceptionType.receiveTimeout)),
        isA<TimeoutFailure>(),
      );
    });

    test('cancel → CancelledFailure', () {
      expect(
        mapDioExceptionToFailure(_typed(DioExceptionType.cancel)),
        isA<CancelledFailure>(),
      );
    });

    test('connectionError / badCertificate → NetworkFailure', () {
      expect(
        mapDioExceptionToFailure(_typed(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
      expect(
        mapDioExceptionToFailure(_typed(DioExceptionType.badCertificate)),
        isA<NetworkFailure>(),
      );
    });

    test('unknown with offline-looking error → NetworkFailure', () {
      expect(
        mapDioExceptionToFailure(_typed(
          DioExceptionType.unknown,
          error: 'SocketException: Failed host lookup',
        )),
        isA<NetworkFailure>(),
      );
    });

    test('unknown with no clue → UnknownFailure', () {
      expect(
        mapDioExceptionToFailure(_typed(
          DioExceptionType.unknown,
          message: 'something weird',
        )),
        isA<UnknownFailure>(),
      );
    });
  });

  group('mapDioExceptionToFailure — status code routing', () {
    test('401 → UnauthorizedFailure', () {
      expect(
        mapDioExceptionToFailure(_badResponse(status: 401)),
        isA<UnauthorizedFailure>(),
      );
    });

    test('403 → ForbiddenFailure', () {
      expect(
        mapDioExceptionToFailure(_badResponse(status: 403)),
        isA<ForbiddenFailure>(),
      );
    });

    test('404 → NotFoundFailure', () {
      expect(
        mapDioExceptionToFailure(_badResponse(status: 404)),
        isA<NotFoundFailure>(),
      );
    });

    test('409 → ConflictFailure', () {
      expect(
        mapDioExceptionToFailure(_badResponse(status: 409)),
        isA<ConflictFailure>(),
      );
    });

    test('500 / 502 / 503 → ServerFailure carrying the status', () {
      for (final s in [500, 502, 503, 599]) {
        final f = mapDioExceptionToFailure(_badResponse(status: s));
        expect(f, isA<ServerFailure>(),
            reason: 'status $s should be ServerFailure');
        expect((f as ServerFailure).statusCode, s);
      }
    });

    test('418 (oddball 4xx) → UnknownFailure', () {
      expect(
        mapDioExceptionToFailure(_badResponse(status: 418)),
        isA<UnknownFailure>(),
      );
    });
  });

  group('mapDioExceptionToFailure — validation parsing', () {
    test('Laravel-style errors map → ValidationFailure.fieldErrors', () {
      final failure = mapDioExceptionToFailure(_badResponse(
        status: 422,
        body: {
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['must be valid'],
            'password': ['too short', 'missing digit'],
          },
        },
      )) as ValidationFailure;

      expect(failure.message, 'The given data was invalid.');
      expect(failure.fieldErrors['email'], ['must be valid']);
      expect(failure.fieldErrors['password'], ['too short', 'missing digit']);
    });

    test('JSON:API-style errors map → ValidationFailure.fieldErrors', () {
      final failure = mapDioExceptionToFailure(_badResponse(
        status: 400,
        body: {
          'errors': [
            {
              'source': {'pointer': '/data/attributes/email'},
              'detail': 'must be valid',
            },
            {
              'source': {'pointer': '/data/attributes/password'},
              'detail': 'too short',
            },
            {
              'source': {'pointer': '/data/attributes/password'},
              'detail': 'missing digit',
            },
          ],
        },
      )) as ValidationFailure;

      expect(failure.fieldErrors['email'], ['must be valid']);
      expect(failure.fieldErrors['password'], ['too short', 'missing digit']);
    });

    test('400 with no recognisable shape → empty fieldErrors', () {
      final failure = mapDioExceptionToFailure(
        _badResponse(status: 400, body: 'plain text body'),
      ) as ValidationFailure;
      expect(failure.fieldErrors, isEmpty);
      expect(failure.message, 'plain text body');
    });
  });

  group('mapDioExceptionToFailure — rate limiting', () {
    test('429 with Retry-After seconds → RateLimitFailure with Duration', () {
      final failure = mapDioExceptionToFailure(_badResponse(
        status: 429,
        headers: {'retry-after': ['30']},
      )) as RateLimitFailure;
      expect(failure.retryAfter, const Duration(seconds: 30));
    });

    test('429 without Retry-After → RateLimitFailure, retryAfter null', () {
      final failure = mapDioExceptionToFailure(_badResponse(status: 429))
          as RateLimitFailure;
      expect(failure.retryAfter, isNull);
    });
  });

  group('failureFromDioException', () {
    test('returns the Failure already stuffed by ErrorInterceptor', () {
      const stuffed = NetworkFailure(message: 'pre-mapped');
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
        error: stuffed,
      );
      expect(failureFromDioException(e), same(stuffed));
    });

    test('falls back to mapping when interceptor was bypassed', () {
      final e = _typed(DioExceptionType.connectionTimeout);
      expect(failureFromDioException(e), isA<TimeoutFailure>());
    });
  });

  group('ErrorInterceptor end-to-end', () {
    test('stuffs the mapped Failure into the thrown DioException.error',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _CannedStatusAdapter(503)
        ..interceptors.add(const ErrorInterceptor());

      try {
        await dio.get<dynamic>('/anything');
        fail('expected DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ServerFailure>());
        expect((e.error! as ServerFailure).statusCode, 503);
      }
    });

    test('non-error responses pass through untouched', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _CannedStatusAdapter(200)
        ..interceptors.add(const ErrorInterceptor());

      final res = await dio.get<dynamic>('/anything');
      expect(res.statusCode, 200);
    });
  });
}

class _CannedStatusAdapter implements HttpClientAdapter {
  _CannedStatusAdapter(this.status);
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      Uint8List.fromList(const [123, 125]), // "{}"
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
