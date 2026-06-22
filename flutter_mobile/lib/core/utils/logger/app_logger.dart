import 'log_level.dart';

/// Cross-cutting structured logger. Every call carries:
/// - a [LogLevel],
/// - a human-readable message,
/// - an optional `error` + `stackTrace` (for exceptions),
/// - an optional `context` map of key/value tags (for log aggregators).
///
/// Subclasses only need to implement [log] — the level helpers
/// ([trace] / [debug] / [info] / [warn] / [error] / [fatal]) and [child]
/// inherit a default implementation. Keep the interface small so it stays
/// easy to swap (console, file, remote sink, in-memory test recorder).
abstract class AppLogger {
  const AppLogger();

  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  });

  // ── Level helpers ───────────────────────────────────────────
  void trace(String message, {Map<String, Object?>? context}) =>
      log(LogLevel.trace, message, context: context);

  void debug(String message, {Map<String, Object?>? context}) =>
      log(LogLevel.debug, message, context: context);

  void info(String message, {Map<String, Object?>? context}) =>
      log(LogLevel.info, message, context: context);

  void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) =>
      log(LogLevel.warning, message,
          error: error, stackTrace: stackTrace, context: context);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) =>
      log(LogLevel.error, message,
          error: error, stackTrace: stackTrace, context: context);

  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) =>
      log(LogLevel.fatal, message,
          error: error, stackTrace: stackTrace, context: context);

  /// Returns a logger that prefixes every message with `[tag]` and merges
  /// [defaultContext] with each call's `context`. Per-call entries win over
  /// defaults on key collision.
  ///
  /// Use to scope a logger to a feature: `final log = appLogger.child('auth');`.
  AppLogger child(String tag, {Map<String, Object?>? defaultContext}) =>
      _ChildLogger(this, tag, defaultContext ?? const {});
}

/// Forwards to a parent logger after applying a tag prefix and a baseline
/// context. Private so callers always go through [AppLogger.child].
class _ChildLogger extends AppLogger {
  _ChildLogger(this._parent, this._tag, this._defaultContext);

  final AppLogger _parent;
  final String _tag;
  final Map<String, Object?> _defaultContext;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    final merged = context == null || context.isEmpty
        ? _defaultContext
        : {..._defaultContext, ...context};
    _parent.log(
      level,
      '[$_tag] $message',
      error: error,
      stackTrace: stackTrace,
      context: merged.isEmpty ? null : merged,
    );
  }

  @override
  AppLogger child(String tag, {Map<String, Object?>? defaultContext}) =>
      _ChildLogger(
        _parent,
        '$_tag/$tag',
        defaultContext == null
            ? _defaultContext
            : {..._defaultContext, ...defaultContext},
      );
}
