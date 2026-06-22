import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'crash_reporter.dart';
import 'error_boundary_widget.dart';

/// Wires every global error capture point in the framework to [reporter]
/// and runs [body] inside a guarded zone so async errors are caught too.
///
/// Captures three classes of failures:
/// 1. **Widget-build / framework errors** — via `FlutterError.onError`.
/// 2. **Platform-dispatcher uncaught errors** — Dart-VM-level exceptions
///    that escape the framework (e.g. async errors in microtasks scheduled
///    by platform channels).
/// 3. **Async errors** in [body] itself — via `runZonedGuarded`.
///
/// Also installs [ErrorWidget.builder] so the dreaded red-screen is
/// replaced by a friendly placeholder (debug shows details; release shows
/// just a generic message).
///
/// **Call shape** in `main()`:
/// ```dart
/// void main() => runWithCrashHooks(
///   reporter: LoggingCrashReporter(ConsoleLogger()),
///   body: () async {
///     WidgetsFlutterBinding.ensureInitialized();
///     configureDependencies();
///     runApp(const ErpMobileApp());
///   },
/// );
/// ```
///
/// Note we deliberately **construct the reporter outside DI** so crash
/// reporting still works if DI initialisation itself throws.
void runWithCrashHooks({
  required CrashReporter reporter,
  required FutureOr<void> Function() body,
}) {
  FlutterError.onError = (details) {
    // In debug, also let Flutter print its full diagnostic dump (with
    // the offending widget tree, source locations, etc.) so render
    // errors like RenderFlex overflows are actionable. The reporter
    // call below still funnels the exception into the crash logger.
    assert(() {
      FlutterError.dumpErrorToConsole(details);
      return true;
    }());
    reporter.report(
      details.exception,
      details.stack,
      severity: CrashSeverity.fatal,
      description: 'FlutterError: ${details.context ?? 'unknown context'}',
      context: <String, Object?>{
        'library': details.library ?? 'unknown',
        if (details.silent) 'silent': true,
      },
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(
      error,
      stack,
      severity: CrashSeverity.fatal,
      description: 'PlatformDispatcher uncaught',
    );
    // Returning true marks the error as handled so the engine doesn't
    // re-print it; we've already routed it to the reporter.
    return true;
  };

  ErrorWidget.builder =
      (details) => ErrorBoundaryWidget(details: details);

  runZonedGuarded(
    () async => await body(),
    (error, stack) {
      reporter.report(
        error,
        stack,
        severity: CrashSeverity.fatal,
        description: 'runZonedGuarded uncaught',
      );
    },
  );
}
