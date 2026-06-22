import 'package:erp_mobile/core/error/crash_reporter.dart';
import 'package:erp_mobile/core/error/logging_crash_reporter.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:test/test.dart';

import '../../_support/recording_logger.dart';

void main() {
  group('LoggingCrashReporter', () {
    late RecordingLogger logger;
    late LoggingCrashReporter reporter;

    setUp(() {
      logger = RecordingLogger();
      reporter = LoggingCrashReporter(logger);
    });

    test('default severity (error) logs at LogLevel.error', () {
      final stack = StackTrace.fromString('synthetic');
      reporter.report(StateError('boom'), stack);

      final record = logger.last!;
      expect(record.level, LogLevel.error);
      expect(record.error, isA<StateError>());
      expect(record.stackTrace, stack);
    });

    test('warning severity → LogLevel.warning', () {
      reporter.report('hiccup', null, severity: CrashSeverity.warning);
      expect(logger.last!.level, LogLevel.warning);
    });

    test('fatal severity → LogLevel.fatal', () {
      reporter.report('catastrophe', null, severity: CrashSeverity.fatal);
      expect(logger.last!.level, LogLevel.fatal);
    });

    test('description is forwarded as the log message', () {
      reporter.report(
        ArgumentError('x'),
        null,
        description: 'auth.signIn',
      );
      expect(logger.last!.message, 'auth.signIn');
    });

    test('falls back to error.toString() when no description supplied', () {
      reporter.report(ArgumentError('bad input'), null);
      expect(logger.last!.message, contains('bad input'));
    });

    test('context map is forwarded to the logger', () {
      reporter.report(
        Exception('x'),
        null,
        context: {'route': '/orders', 'user_id': 42},
      );
      expect(logger.last!.context, {'route': '/orders', 'user_id': 42});
    });

    test('error + stackTrace are forwarded to the logger', () {
      final stack = StackTrace.fromString('synthetic-stack');
      final err = StateError('boom');
      reporter.report(err, stack);

      final record = logger.last!;
      expect(identical(record.error, err), isTrue);
      expect(record.stackTrace, stack);
    });
  });
}
