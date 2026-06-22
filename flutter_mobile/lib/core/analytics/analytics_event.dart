import 'package:collection/collection.dart';

/// Single analytics event — a stable name plus a property bag.
///
/// Plain class instead of `freezed` because `freezed` wouldn't deep-compare
/// the `properties` map and the resulting `==` would silently misbehave in
/// tests. Uses `MapEquality` for value equality.
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    this.properties = const <String, Object?>{},
  });

  /// Stable, snake- or dot-cased identifier — e.g. `'invoice.created'`.
  /// Treat as part of your public schema: renaming breaks dashboards.
  final String name;

  /// Free-form property bag. Keys should be snake_case; values should be
  /// JSON-serialisable scalars / lists / maps.
  final Map<String, Object?> properties;

  static const _eq = MapEquality<String, Object?>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsEvent &&
          name == other.name &&
          _eq.equals(properties, other.properties);

  @override
  int get hashCode => Object.hash(name, _eq.hash(properties));

  @override
  String toString() => 'AnalyticsEvent($name, $properties)';
}
