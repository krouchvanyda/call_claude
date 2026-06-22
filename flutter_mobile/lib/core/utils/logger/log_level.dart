/// Severity ladder used by [AppLogger].
///
/// Ordered cheapest → most severe so consumers (like a min-level filter)
/// can compare via `index >= threshold.index`.
enum LogLevel { trace, debug, info, warning, error, fatal }
