import 'dart:convert';

import 'package:dio/dio.dart';

import '../database/app_database.dart' show SyncQueueRow;
import '../error/failure.dart';
import '../error/failure_from_dio.dart';

/// Replays a single queued mutation against the server.
///
/// The engine talks to the executor instead of to `Dio` directly so tests
/// can script success/failure without spinning up a mock adapter, and so
/// future variants (e.g. a batch executor that ships several ops in one
/// request) plug in cleanly.
///
/// Contract: throw a [Failure] on any kind of failure. Returning normally
/// means the server accepted the mutation.
abstract class SyncOpExecutor {
  Future<void> execute(SyncQueueRow op);
}

/// Production implementation backed by the shared [Dio] instance.
///
/// Attaches the row's `idempotencyKey` as a request header so the server
/// can dedupe retries. Surfaces the typed [Failure] that the error
/// interceptor stuffed into the thrown [DioException].
class DioSyncOpExecutor implements SyncOpExecutor {
  DioSyncOpExecutor(this._dio);

  final Dio _dio;

  @override
  Future<void> execute(SyncQueueRow op) async {
    final dynamic data = op.payloadJson.isEmpty
        ? null
        : jsonDecode(op.payloadJson);

    try {
      await _dio.request<dynamic>(
        op.endpointPath,
        data: data,
        options: Options(
          method: op.endpointMethod,
          headers: {'Idempotency-Key': op.idempotencyKey},
        ),
      );
    } on DioException catch (e) {
      Error.throwWithStackTrace(failureFromDioException(e), e.stackTrace);
    }
  }
}
