import 'package:erp_mobile/core/analytics/analytics_event.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsEvent', () {
    test('two events with the same name and properties are equal', () {
      const a = AnalyticsEvent(
        name: 'invoice.created',
        properties: {'amount': 100, 'currency': 'USD'},
      );
      const b = AnalyticsEvent(
        name: 'invoice.created',
        properties: {'amount': 100, 'currency': 'USD'},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different names are unequal', () {
      const a = AnalyticsEvent(name: 'a');
      const b = AnalyticsEvent(name: 'b');
      expect(a, isNot(equals(b)));
    });

    test('different property values are unequal', () {
      const a = AnalyticsEvent(name: 'x', properties: {'k': 1});
      const b = AnalyticsEvent(name: 'x', properties: {'k': 2});
      expect(a, isNot(equals(b)));
    });

    test('different property keys are unequal', () {
      const a = AnalyticsEvent(name: 'x', properties: {'k': 1});
      const b = AnalyticsEvent(name: 'x', properties: {'j': 1});
      expect(a, isNot(equals(b)));
    });

    test('property order does not affect equality (Map deep-eq)', () {
      const a = AnalyticsEvent(
        name: 'x',
        properties: {'a': 1, 'b': 2},
      );
      const b = AnalyticsEvent(
        name: 'x',
        properties: {'b': 2, 'a': 1},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('default properties is an empty map', () {
      const a = AnalyticsEvent(name: 'x');
      expect(a.properties, isEmpty);
    });

    test('toString carries name and properties for log readability', () {
      const a = AnalyticsEvent(name: 'login', properties: {'method': 'sso'});
      expect(a.toString(), contains('login'));
      expect(a.toString(), contains('method'));
      expect(a.toString(), contains('sso'));
    });
  });
}
