import 'package:erp_mobile/core/analytics/analytics_event.dart';
import 'package:erp_mobile/core/analytics/noop_analytics_service.dart';
import 'package:test/test.dart';

void main() {
  group('NoopAnalyticsService', () {
    const noop = NoopAnalyticsService();

    test('every method completes without throwing', () async {
      noop
        ..track(const AnalyticsEvent(name: 'x'))
        ..screen('Home', properties: {'tab': 1})
        ..setUserProperty('plan', 'pro');

      await noop.identify('user-1', traits: {'org': 'acme'});
      await noop.reset();
      await noop.flush();
      // Reaching here is the assertion.
    });
  });
}
