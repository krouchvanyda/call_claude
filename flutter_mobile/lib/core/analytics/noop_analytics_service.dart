import 'analytics_event.dart';
import 'analytics_service.dart';

/// Default [AnalyticsService] — discards every call.
///
/// Lets feature code call `analytics.track(...)` from day one without
/// shipping a vendor SDK. Replace the DI binding with a real implementation
/// (Firebase/Segment/Mixpanel) when product instrumentation is greenlit.
class NoopAnalyticsService extends AnalyticsService {
  const NoopAnalyticsService();

  @override
  void track(AnalyticsEvent event) {}

  @override
  void screen(String name, {Map<String, Object?>? properties}) {}

  @override
  void setUserProperty(String key, Object? value) {}

  @override
  Future<void> identify(String userId, {Map<String, Object?>? traits}) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> flush() async {}
}
