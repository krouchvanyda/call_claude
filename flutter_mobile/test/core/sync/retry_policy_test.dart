import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/core/sync/retry_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultRetryPolicy', () {
    const policy = DefaultRetryPolicy();

    test('transient failures map to retry', () {
      const cases = <Failure>[
        NetworkFailure(),
        TimeoutFailure(),
        ServerFailure(statusCode: 500),
        ServerFailure(statusCode: 502),
        RateLimitFailure(),
        UnknownFailure(message: 'mystery'),
      ];
      for (final f in cases) {
        expect(policy.decide(f), RetryDecision.retry,
            reason: '$f should be retried');
      }
    });

    test('permanent failures map to giveUp', () {
      const cases = <Failure>[
        ValidationFailure(),
        ForbiddenFailure(),
        UnauthorizedFailure(),
        NotFoundFailure(),
        ConflictFailure(),
        CancelledFailure(),
      ];
      for (final f in cases) {
        expect(policy.decide(f), RetryDecision.giveUp,
            reason: '$f should not be retried');
      }
    });
  });
}
