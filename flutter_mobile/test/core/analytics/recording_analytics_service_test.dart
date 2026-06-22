import 'package:erp_mobile/core/analytics/analytics_event.dart';
import 'package:test/test.dart';

import '../../_support/recording_analytics_service.dart';

void main() {
  group('RecordingAnalyticsService', () {
    late RecordingAnalyticsService analytics;

    setUp(() => analytics = RecordingAnalyticsService());

    test('starts empty', () {
      expect(analytics.calls, isEmpty);
    });

    test('track captures the event verbatim', () {
      const event =
          AnalyticsEvent(name: 'login', properties: {'method': 'sso'});
      analytics.track(event);

      expect(analytics.calls.single, isA<TrackedEvent>());
      expect((analytics.calls.single as TrackedEvent).event, event);
      expect(analytics.trackedEvents, [event]);
    });

    test('screen captures name and properties', () {
      analytics.screen('Dashboard', properties: {'tab': 'overview'});

      final call = analytics.calls.single as ScreenViewed;
      expect(call.name, 'Dashboard');
      expect(call.properties, {'tab': 'overview'});
    });

    test('setUserProperty captures key + value', () {
      analytics.setUserProperty('plan', 'pro');

      final call = analytics.calls.single as UserPropertySet;
      expect(call.key, 'plan');
      expect(call.value, 'pro');
    });

    test('identify captures userId + traits', () async {
      await analytics.identify('user-1', traits: {'org': 'acme'});

      final call = analytics.calls.single as Identified;
      expect(call.userId, 'user-1');
      expect(call.traits, {'org': 'acme'});
    });

    test('reset and flush record their own marker calls', () async {
      await analytics.reset();
      await analytics.flush();
      expect(analytics.calls, hasLength(2));
      expect(analytics.calls[0], isA<Reset>());
      expect(analytics.calls[1], isA<Flushed>());
    });

    test('typed convenience getters filter correctly', () {
      analytics
        ..track(const AnalyticsEvent(name: 'a'))
        ..screen('Home')
        ..track(const AnalyticsEvent(name: 'b'))
        ..setUserProperty('k', 'v')
        ..screen('Settings');

      expect(analytics.trackedEvents.map((e) => e.name), ['a', 'b']);
      expect(analytics.screens.map((s) => s.name), ['Home', 'Settings']);
    });

    test('clear empties the call list', () {
      analytics
        ..track(const AnalyticsEvent(name: 'x'))
        ..clear();
      expect(analytics.calls, isEmpty);
    });
  });
}
