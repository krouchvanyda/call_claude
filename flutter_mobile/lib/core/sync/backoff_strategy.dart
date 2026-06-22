import 'dart:math' as math;

/// Computes how long to wait before the next retry attempt.
///
/// `attempts` is the *number of failures so far* (1 after the first failure,
/// 2 after the second, …). Strategies are pure and stateless so the engine
/// can pass a freshly-read `op.attempts` straight in.
abstract class BackoffStrategy {
  const BackoffStrategy();
  Duration delayFor(int attempts);
}

/// `base * factor ^ (attempts - 1)` capped at [maxDelay].
///
/// Defaults: 2s, 4s, 8s, 16s, … up to a 5-minute ceiling.
class ExponentialBackoff extends BackoffStrategy {
  const ExponentialBackoff({
    this.base = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    this.factor = 2,
  });

  final Duration base;
  final Duration maxDelay;
  final num factor;

  @override
  Duration delayFor(int attempts) {
    if (attempts <= 0) return Duration.zero;
    // `math.pow(int, int)` silently wraps once the result exceeds int64,
    // turning `pow(2, 99)` into 0 and undermining the cap. Force the
    // exponent into floating-point so overflow saturates to infinity (which
    // we explicitly handle below) instead of corrupting the comparison.
    final exponent = math.pow(factor.toDouble(), attempts - 1);
    final raw = base.inMilliseconds * exponent;
    if (!raw.isFinite || raw >= maxDelay.inMilliseconds) {
      return maxDelay;
    }
    return Duration(milliseconds: raw.round());
  }
}
