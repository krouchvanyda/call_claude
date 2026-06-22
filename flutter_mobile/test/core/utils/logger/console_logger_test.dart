import 'package:erp_mobile/core/utils/logger/console_logger.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:logger/logger.dart' as pkg;
import 'package:test/test.dart';

/// Captures every log line so we can assert on the formatted output without
/// touching `print()` or stdout.
class _CapturingOutput extends pkg.LogOutput {
  final lines = <String>[];

  @override
  void output(pkg.OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  group('ConsoleLogger', () {
    late _CapturingOutput output;
    late ConsoleLogger logger;

    setUp(() {
      output = _CapturingOutput();
      logger = ConsoleLogger(
        logger: pkg.Logger(
          printer: pkg.SimplePrinter(printTime: false, colors: false),
          output: output,
          level: pkg.Level.trace,
        ),
      );
    });

    test('emits a line that contains the message', () {
      logger.info('hello world');
      expect(output.lines.single, contains('hello world'));
    });

    test('omits the trailing context block when context is empty', () {
      // SimplePrinter prefixes with `[X] ` — assert on the *suffix*
      // (the formatted message itself), not the whole line.
      logger.info('plain');
      expect(output.lines.single.endsWith('plain'), isTrue);
    });

    test('appends [k=v ...] context block when context is non-empty', () {
      logger.info('login', context: {'user_id': 42, 'session': 'abc'});
      expect(output.lines.single, contains('[user_id=42 session=abc]'));
      expect(output.lines.single.endsWith('[user_id=42 session=abc]'), isTrue);
    });

    test('routes each LogLevel to a distinct underlying logger call', () {
      logger.log(LogLevel.trace, 't');
      logger.log(LogLevel.debug, 'd');
      logger.log(LogLevel.info, 'i');
      logger.log(LogLevel.warning, 'w');
      logger.log(LogLevel.error, 'e');
      logger.log(LogLevel.fatal, 'f');

      // One line per level — proves every switch arm dispatched.
      expect(output.lines, hasLength(6));
      // Each line ends with the message verbatim (not swallowed by an
      // empty switch arm or routed to the wrong level).
      expect(output.lines[0].endsWith('t'), isTrue);
      expect(output.lines[1].endsWith('d'), isTrue);
      expect(output.lines[2].endsWith('i'), isTrue);
      expect(output.lines[3].endsWith('w'), isTrue);
      expect(output.lines[4].endsWith('e'), isTrue);
      expect(output.lines[5].endsWith('f'), isTrue);
    });
  });
}
