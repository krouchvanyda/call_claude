/// Severity ladder for crash reports. Mirrors what most vendor SDKs
/// (Sentry / Firebase Crashlytics) accept on a `level` field.
enum CrashSeverity { warning, error, fatal }

/// Cross-cutting error sink. Crash hooks ([runWithCrashHooks]) and any
/// feature code that catches an exception both funnel into this interface;
/// the framework ships a logger-backed default and swaps in a vendor SDK
/// at the DI binding when telemetry is greenlit.
///
/// Kept Flutter-free so it stays unit-testable and so non-UI layers
/// (data sources, sync engine) can call it without dragging widgets in.
abstract class CrashReporter {
  const CrashReporter();

  /// Report an error with optional context.
  ///
  /// - [error] / [stack] — the raw thrown object.
  /// - [severity] — defaults to [CrashSeverity.error]; raise to `fatal` for
  ///   uncaught exceptions, drop to `warning` for handled-but-noteworthy
  ///   ones.
  /// - [description] — a one-liner about *where* this came from (e.g.
  ///   `'auth.signIn'`). Surfaces in the issue title.
  /// - [context] — structured tags propagated to the sink (request id,
  ///   user id, route, etc.).
  void report(
    Object error,
    StackTrace? stack, {
    CrashSeverity severity = CrashSeverity.error,
    String? description,
    Map<String, Object?>? context,
  });
}
