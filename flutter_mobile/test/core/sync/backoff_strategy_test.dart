import 'package:erp_mobile/core/sync/backoff_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('ExponentialBackoff', () {
    const strategy = ExponentialBackoff();

    test('attempts <= 0 → Duration.zero', () {
      expect(strategy.delayFor(0), Duration.zero);
      expect(strategy.delayFor(-1), Duration.zero);
    });

    test('grows geometrically: 2s, 4s, 8s, 16s, 32s, 64s', () {
      expect(strategy.delayFor(1), const Duration(seconds: 2));
      expect(strategy.delayFor(2), const Duration(seconds: 4));
      expect(strategy.delayFor(3), const Duration(seconds: 8));
      expect(strategy.delayFor(4), const Duration(seconds: 16));
      expect(strategy.delayFor(5), const Duration(seconds: 32));
      expect(strategy.delayFor(6), const Duration(seconds: 64));
    });

    test('caps at maxDelay', () {
      expect(strategy.delayFor(20), const Duration(minutes: 5));
      expect(strategy.delayFor(100), const Duration(minutes: 5));
    });

    test('honours custom base + maxDelay', () {
      const custom = ExponentialBackoff(
        base: Duration(seconds: 1),
        maxDelay: Duration(seconds: 10),
      );
      expect(custom.delayFor(1), const Duration(seconds: 1));
      expect(custom.delayFor(2), const Duration(seconds: 2));
      expect(custom.delayFor(4), const Duration(seconds: 8));
      expect(custom.delayFor(5), const Duration(seconds: 10),
          reason: 'capped');
    });
  });
}
