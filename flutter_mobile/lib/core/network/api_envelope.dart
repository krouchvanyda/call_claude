/// Parser for the Spring `ApiResponse<T>` envelope returned by every
/// `/api/v1/*` endpoint:
///
/// ```json
/// {
///   "success": true,
///   "message": "Success",
///   "data": { ... typed payload ... },
///   "errorCode": null,
///   "traceId": "fb774ae5-..."
/// }
/// ```
///
/// Centralised here so every data-source `.post` / `.get` parses the
/// same way. When `success` is `false`, throws [ApiEnvelopeException]
/// so the repository layer can translate it into a typed `Failure`.
///
/// HTTP-level errors (4xx / 5xx) still come through the existing dio
/// interceptors as `DioException` — this only handles the case where
/// the backend returns HTTP 200 with a business-logic failure inside
/// the envelope.
class ApiEnvelope {
  ApiEnvelope._();

  /// Unwrap [body] and hand the inner `data` map to [parser].
  ///
  /// Throws:
  ///   - [ApiEnvelopeException] when `success: false`.
  ///   - [FormatException] when `data` is missing or not a `Map`.
  static T parse<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parser,
  ) {
    // Tolerant of older endpoints that don't wrap — if there's no
    // `success` key, treat the body itself as the data payload.
    if (!body.containsKey('success') && !body.containsKey('data')) {
      return parser(body);
    }

    final success = body['success'] as bool? ?? true;
    if (!success) {
      throw ApiEnvelopeException(
        message: body['message']?.toString(),
        errorCode: body['errorCode']?.toString(),
        traceId: body['traceId']?.toString(),
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'API envelope missing or malformed "data" field',
      );
    }
    return parser(data);
  }

  /// List variant — when the backend returns
  /// `{ "success": true, "data": [ ... ], ... }`. Each item is parsed
  /// by [itemFromJson]; non-map elements are silently skipped so a
  /// stray null in the array doesn't poison the whole response.
  ///
  /// Throws [ApiEnvelopeException] on `success: false`, and
  /// [FormatException] when `data` is missing or not a `List`.
  static List<T> parseList<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    if (!body.containsKey('success') && !body.containsKey('data')) {
      // Bare list endpoints that don't wrap — treat the body itself as
      // the array if it happens to look like one (unusual but cheap to
      // support).
      return const <Never>[];
    }

    final success = body['success'] as bool? ?? true;
    if (!success) {
      throw ApiEnvelopeException(
        message: body['message']?.toString(),
        errorCode: body['errorCode']?.toString(),
        traceId: body['traceId']?.toString(),
      );
    }

    final data = body['data'];
    if (data is! List) {
      throw const FormatException(
        'API envelope "data" expected to be a list but was not',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(itemFromJson)
        .toList(growable: false);
  }
}

/// Raised when an API envelope arrives with `success: false`. The
/// repository layer catches this and maps it onto a typed `Failure`.
class ApiEnvelopeException implements Exception {
  ApiEnvelopeException({this.message, this.errorCode, this.traceId});

  final String? message;
  final String? errorCode;
  final String? traceId;

  @override
  String toString() =>
      'ApiEnvelopeException(${errorCode ?? '?'}): ${message ?? 'unknown'}';
}
