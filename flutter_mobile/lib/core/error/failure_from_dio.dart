import 'package:dio/dio.dart';

import '../network/error_interceptor.dart';
import 'failure.dart';

/// Repository-side helper.
///
/// The error interceptor stuffs the mapped [Failure] into
/// `DioException.error`. If, for some reason, the interceptor wasn't on the
/// chain (raw `Dio` instance in a test, etc.), we fall back to the same
/// pure mapping so callers always receive a typed [Failure].
///
/// Usage:
/// ```dart
/// try {
///   final res = await dio.get('/orders');
///   return ok(parse(res.data));
/// } on DioException catch (e) {
///   return err(failureFromDioException(e));
/// }
/// ```
Failure failureFromDioException(DioException e) {
  final stuffed = e.error;
  if (stuffed is Failure) return stuffed;
  return mapDioExceptionToFailure(e);
}
