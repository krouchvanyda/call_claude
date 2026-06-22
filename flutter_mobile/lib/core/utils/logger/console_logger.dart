import 'package:logger/logger.dart' as pkg;

import 'app_logger.dart';
import 'log_level.dart';

/// Production [AppLogger] backed by the `logger` package.
///
/// Format: `<tag-prefixed message> [k1=v1 k2=v2 …]`. Trailing context block
/// is omitted when the merged context is empty so console output stays
/// scannable for the common case.
class ConsoleLogger extends AppLogger {
  ConsoleLogger({pkg.Logger? logger})
      : _logger = logger ?? pkg.Logger(printer: pkg.PrettyPrinter(methodCount: 0));

  final pkg.Logger _logger;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    final formatted = _format(message, context);
    switch (level) {
      case LogLevel.trace:
        _logger.t(formatted, error: error, stackTrace: stackTrace);
      case LogLevel.debug:
        _logger.d(formatted, error: error, stackTrace: stackTrace);
      case LogLevel.info:
        _logger.i(formatted, error: error, stackTrace: stackTrace);
      case LogLevel.warning:
        _logger.w(formatted, error: error, stackTrace: stackTrace);
      case LogLevel.error:
        _logger.e(formatted, error: error, stackTrace: stackTrace);
      case LogLevel.fatal:
        _logger.f(formatted, error: error, stackTrace: stackTrace);
    }
  }

  static String _format(String message, Map<String, Object?>? context) {
    if (context == null || context.isEmpty) return message;
    final parts =
        context.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return '$message [$parts]';
  }
}
