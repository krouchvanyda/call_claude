import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Cross-cutting failure type returned by every repository.
///
/// Sealed via `freezed` so callers can pattern-match exhaustively:
///
/// ```dart
/// switch (failure) {
///   case NetworkFailure():       'no internet';
///   case TimeoutFailure():       'slow connection';
///   case ServerFailure(:final statusCode):
///                                'server $statusCode';
///   case UnauthorizedFailure():  'session expired';
///   case ForbiddenFailure():     'not allowed';
///   case NotFoundFailure():      'gone';
///   case ValidationFailure(:final fieldErrors):
///                                'fix ${fieldErrors.keys}';
///   case ConflictFailure():      'merge conflict';
///   case RateLimitFailure(:final retryAfter):
///                                'try again in $retryAfter';
///   case CancelledFailure():     'aborted';
///   case UnknownFailure():       'unexpected';
/// }
/// ```
@freezed
sealed class Failure with _$Failure {
  /// No connectivity / DNS / TLS handshake failure.
  const factory Failure.network({String? message}) = NetworkFailure;

  /// Connect / send / receive timed out before the server responded.
  const factory Failure.timeout({String? message}) = TimeoutFailure;

  /// 5xx — server is unhappy. Include `statusCode` for surfacing in toasts.
  const factory Failure.server({
    int? statusCode,
    String? message,
  }) = ServerFailure;

  /// 401 surfaced *after* the auth interceptor's refresh attempt failed.
  /// Treat as "session ended; route to login."
  const factory Failure.unauthorized({String? message}) = UnauthorizedFailure;

  /// 403 — caller is authenticated but lacks permission.
  const factory Failure.forbidden({String? message}) = ForbiddenFailure;

  /// 404 — resource missing.
  const factory Failure.notFound({String? message}) = NotFoundFailure;

  /// 400 / 422 — request shape was rejected. `fieldErrors` lists the
  /// per-field messages so forms can highlight inputs.
  const factory Failure.validation({
    @Default(<String, List<String>>{}) Map<String, List<String>> fieldErrors,
    String? message,
  }) = ValidationFailure;

  /// 409 — conflicting resource state (optimistic concurrency, etc.).
  const factory Failure.conflict({String? message}) = ConflictFailure;

  /// 429 — caller is being throttled. `retryAfter` is parsed from the
  /// `Retry-After` header when present.
  const factory Failure.rateLimited({
    Duration? retryAfter,
    String? message,
  }) = RateLimitFailure;

  /// Request was cancelled (CancelToken, navigation away, etc.).
  const factory Failure.cancelled() = CancelledFailure;

  /// Catch-all. Always carries a message so logs aren't blind.
  const factory Failure.unknown({String? message}) = UnknownFailure;
}
