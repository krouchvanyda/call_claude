import 'package:erp_mobile/core/analytics/analytics_event.dart';
import 'package:erp_mobile/core/analytics/analytics_service.dart';

/// Captured analytics call — public so tests can pattern-match each
/// dispatched method.
sealed class AnalyticsCall {
  const AnalyticsCall();
}

class TrackedEvent extends AnalyticsCall {
  const TrackedEvent(this.event);
  final AnalyticsEvent event;
}

class ScreenViewed extends AnalyticsCall {
  const ScreenViewed(this.name, this.properties);
  final String name;
  final Map<String, Object?>? properties;
}

class UserPropertySet extends AnalyticsCall {
  const UserPropertySet(this.key, this.value);
  final String key;
  final Object? value;
}

class Identified extends AnalyticsCall {
  const Identified(this.userId, this.traits);
  final String userId;
  final Map<String, Object?>? traits;
}

class Reset extends AnalyticsCall {
  const Reset();
}

class Flushed extends AnalyticsCall {
  const Flushed();
}

/// In-memory [AnalyticsService] for tests. Append-only — assert against
/// `calls` (or the typed convenience getters) and clear between tests.
class RecordingAnalyticsService extends AnalyticsService {
  RecordingAnalyticsService();

  final List<AnalyticsCall> calls = [];

  @override
  void track(AnalyticsEvent event) => calls.add(TrackedEvent(event));

  @override
  void screen(String name, {Map<String, Object?>? properties}) =>
      calls.add(ScreenViewed(name, properties));

  @override
  void setUserProperty(String key, Object? value) =>
      calls.add(UserPropertySet(key, value));

  @override
  Future<void> identify(String userId,
      {Map<String, Object?>? traits}) async {
    calls.add(Identified(userId, traits));
  }

  @override
  Future<void> reset() async => calls.add(const Reset());

  @override
  Future<void> flush() async => calls.add(const Flushed());

  // ── Filter helpers ──────────────────────────────────────────
  Iterable<AnalyticsEvent> get trackedEvents =>
      calls.whereType<TrackedEvent>().map((c) => c.event);

  Iterable<ScreenViewed> get screens => calls.whereType<ScreenViewed>();

  void clear() => calls.clear();
}
