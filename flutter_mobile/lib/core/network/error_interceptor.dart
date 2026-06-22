import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Translates raw [DioException]s into typed [Failure]s and stuffs the
/// result into `DioException.error` so repositories can pluck it out
/// without re-doing the classification.
///
/// Order matters: this interceptor must be added **after** the auth
/// interceptor so 401s only reach here once the silent-refresh attempt
/// has already failed.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = mapDioExceptionToFailure(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }
}

/// Pure mapping function — used by both the interceptor itself and by the
/// repository-side `failureFromDioException` helper. Kept as a top-level
/// function so tests can exercise the mapping without constructing the
/// full interceptor + handler harness.
Failure mapDioExceptionToFailure(DioException err) {
  switch (err.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return Failure.timeout(message: err.message);

    case DioExceptionType.cancel:
      return const Failure.cancelled();

    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return Failure.network(message: err.message);

    case DioExceptionType.badResponse:
      return _failureForStatus(err.response, err.message);

    case DioExceptionType.unknown:
      // Network-layer exceptions (SocketException, HandshakeException…) get
      // wrapped as DioExceptionType.unknown when no type was inferred.
      if (_looksLikeOfflineError(err)) {
        return Failure.network(message: err.message);
      }
      return Failure.unknown(message: err.message ?? err.error?.toString());
  }
}

Failure _failureForStatus(Response<dynamic>? response, String? rawMessage) {
  final status = response?.statusCode;
  final message = _extractMessage(response) ?? rawMessage;

  return switch (status) {
    401 => Failure.unauthorized(message: message),
    403 => Failure.forbidden(message: message),
    404 => Failure.notFound(message: message),
    409 => Failure.conflict(message: message),
    400 || 422 => Failure.validation(
        fieldErrors: _extractFieldErrors(response),
        message: message,
      ),
    429 => Failure.rateLimited(
        retryAfter: _extractRetryAfter(response),
        message: message,
      ),
    final int s when s >= 500 && s < 600 =>
      Failure.server(statusCode: s, message: message),
    _ => Failure.unknown(message: message),
  };
}

bool _looksLikeOfflineError(DioException err) {
  final blob = '${err.error ?? ''} ${err.message ?? ''}'.toLowerCase();
  return blob.contains('socketexception') ||
      blob.contains('handshakeexception') ||
      blob.contains('failed host lookup') ||
      blob.contains('connection refused') ||
      blob.contains('network is unreachable');
}

/// Try a few well-known body shapes for a human-readable error message.
String? _extractMessage(Response<dynamic>? response) {
  final data = response?.data;
  if (data is Map) {
    for (final key in const ['message', 'error', 'detail', 'title']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
  } else if (data is String && data.isNotEmpty) {
    return data;
  }
  return null;
}

/// Recognises the two most common validation-error envelopes:
/// Laravel-style `{ "errors": { "field": ["msg", ...] } }` and
/// JSON:API-style `{ "errors": [{ "source": { "pointer": "/data/attributes/field" }, "detail": "msg" }] }`.
Map<String, List<String>> _extractFieldErrors(Response<dynamic>? response) {
  final data = response?.data;
  if (data is! Map) return const {};

  final errors = data['errors'];
  if (errors is Map) {
    final result = <String, List<String>>{};
    errors.forEach((key, value) {
      if (key is! String) return;
      if (value is List) {
        result[key] = value.whereType<String>().toList(growable: false);
      } else if (value is String) {
        result[key] = [value];
      }
    });
    return result;
  }

  if (errors is List) {
    final result = <String, List<String>>{};
    for (final entry in errors) {
      if (entry is! Map) continue;
      final pointer = (entry['source'] as Map?)?['pointer'];
      final detail = entry['detail'];
      if (pointer is String && detail is String) {
        final field = pointer.split('/').lastWhere(
              (segment) => segment.isNotEmpty,
              orElse: () => pointer,
            );
        result.putIfAbsent(field, () => []).add(detail);
      }
    }
    return result;
  }

  return const {};
}

/// Reads `Retry-After` (seconds-only form per RFC 9110) from a 429 response.
Duration? _extractRetryAfter(Response<dynamic>? response) {
  final raw = response?.headers.value('retry-after');
  if (raw == null) return null;
  final seconds = int.tryParse(raw.trim());
  return seconds == null ? null : Duration(seconds: seconds);
}
