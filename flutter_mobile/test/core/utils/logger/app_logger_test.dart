import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:test/test.dart';

import '../../../_support/recording_logger.dart';

void main() {
  group('AppLogger — level helpers', () {
    late RecordingLogger logger;

    setUp(() => logger = RecordingLogger());

    test('each helper records the matching LogLevel', () {
      logger
        ..trace('t')
        ..debug('d')
        ..info('i')
        ..warn('w')
        ..error('e')
        ..fatal('f');

      expect(logger.records.map((r) => r.level), [
        LogLevel.trace,
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
        LogLevel.fatal,
      ]);
    });

    test('messages are stored verbatim', () {
      logger.info('user signed in');
      expect(logger.last!.message, 'user signed in');
    });

    test('error/warn/fatal forward error + stackTrace', () {
      final stack = StackTrace.fromString('synthetic');
      logger.error('boom', error: 'oops', stackTrace: stack);
      final record = logger.last!;
      expect(record.error, 'oops');
      expect(record.stackTrace, stack);
    });

    test('context tags are recorded as a frozen map', () {
      logger.info('login', context: {'user_id': 42, 'session': 'abc'});
      final ctx = logger.last!.context;
      expect(ctx, {'user_id': 42, 'session': 'abc'});
      expect(() => ctx['extra'] = 1, throwsUnsupportedError);
    });

    test('at(level) filters records by severity', () {
      logger
        ..info('a')
        ..warn('b')
        ..info('c')
        ..error('d');

      expect(logger.at(LogLevel.info).map((r) => r.message), ['a', 'c']);
      expect(logger.at(LogLevel.warning).map((r) => r.message), ['b']);
      expect(logger.at(LogLevel.error).map((r) => r.message), ['d']);
    });
  });

  group('AppLogger — child composition', () {
    late RecordingLogger root;

    setUp(() => root = RecordingLogger());

    test('child prefixes messages with [tag]', () {
      final auth = root.child('auth');
      auth.info('login succeeded');
      expect(root.last!.message, '[auth] login succeeded');
    });

    test('nested children chain prefixes with /', () {
      final auth = root.child('auth');
      final oauth = auth.child('oauth');
      oauth.info('token refreshed');
      expect(root.last!.message, '[auth/oauth] token refreshed');
    });

    test('default context is attached to every call', () {
      final auth = root.child('auth', defaultContext: {'feature': 'auth'});
      auth.info('login');
      expect(root.last!.context, {'feature': 'auth'});
    });

    test('per-call context overrides default on key collision', () {
      final auth = root.child(
        'auth',
        defaultContext: {'feature': 'auth', 'env': 'prod'},
      );
      auth.info('login', context: {'env': 'staging', 'user_id': 7});
      expect(root.last!.context, {
        'feature': 'auth',
        'env': 'staging',
        'user_id': 7,
      });
    });

    test('nested child accumulates default context', () {
      final auth = root.child('auth', defaultContext: {'feature': 'auth'});
      final oauth = auth.child('oauth', defaultContext: {'flow': 'pkce'});
      oauth.info('exchange');
      expect(root.last!.context, {'feature': 'auth', 'flow': 'pkce'});
    });

    test('child without context emits no context entry on the parent record',
        () {
      final auth = root.child('auth');
      auth.info('quiet');
      expect(root.last!.context, isEmpty);
    });

    test('error + stackTrace propagate through child to parent', () {
      final auth = root.child('auth');
      final stack = StackTrace.fromString('synthetic');
      auth.error('boom', error: 'oops', stackTrace: stack);

      final record = root.last!;
      expect(record.message, '[auth] boom');
      expect(record.error, 'oops');
      expect(record.stackTrace, stack);
      expect(record.level, LogLevel.error);
    });
  });
}
