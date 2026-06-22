import 'package:erp_mobile/core/utils/logger/app_logger.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';

/// Captured log entry — exposed publicly so tests can pattern-match fields.
class RecordedLog {
  RecordedLog({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    Map<String, Object?>? context,
  }) : context = Map<String, Object?>.unmodifiable(context ?? const {});

  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?> context;

  @override
  String toString() => 'RecordedLog($level, "$message", '
      'error=$error, context=$context)';
}

/// In-memory [AppLogger] for tests.
///
/// Drop into any slice's tests when you want to assert that a piece of code
/// logged a specific message / level / context — `expect(logger.records, ...)`.
class RecordingLogger extends AppLogger {
  RecordingLogger();

  final List<RecordedLog> records = [];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    records.add(RecordedLog(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    ));
  }

  /// Filter helpers for assertions.
  Iterable<RecordedLog> at(LogLevel level) =>
      records.where((r) => r.level == level);

  RecordedLog? get last => records.isEmpty ? null : records.last;

  void clear() => records.clear();
}
