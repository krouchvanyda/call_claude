import '../error/failure.dart';

enum RetryDecision { retry, giveUp }

/// Maps a [Failure] to a retry verdict.
///
/// Kept as an interface so applications can swap in stricter or laxer
/// policies (e.g. "retry everything except validation errors" for a
/// background batch importer).
abstract class RetryPolicy {
  const RetryPolicy();
  RetryDecision decide(Failure failure);
}

/// The framework default: retry only failures that look transient.
///
/// Permanent failures (validation, forbidden, not-found, conflict, cancel)
/// flow straight to dead-letter so the user / oncall sees them quickly
/// instead of repeatedly hammering the server.
class DefaultRetryPolicy extends RetryPolicy {
  const DefaultRetryPolicy();

  @override
  RetryDecision decide(Failure failure) => switch (failure) {
        NetworkFailure() => RetryDecision.retry,
        TimeoutFailure() => RetryDecision.retry,
        ServerFailure() => RetryDecision.retry,
        RateLimitFailure() => RetryDecision.retry,
        // `unknown` is conservative: prefer retry because we couldn't classify
        // the cause; the max-attempts cap keeps it from looping forever.
        UnknownFailure() => RetryDecision.retry,
        ValidationFailure() => RetryDecision.giveUp,
        ForbiddenFailure() => RetryDecision.giveUp,
        UnauthorizedFailure() => RetryDecision.giveUp,
        NotFoundFailure() => RetryDecision.giveUp,
        ConflictFailure() => RetryDecision.giveUp,
        CancelledFailure() => RetryDecision.giveUp,
      };
}
