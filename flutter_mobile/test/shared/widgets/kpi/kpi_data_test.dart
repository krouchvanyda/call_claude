import 'package:erp_mobile/shared/widgets/kpi/kpi_data.dart';
import 'package:test/test.dart';

void main() {
  group('KpiTrend.fromDelta', () {
    test('strictly positive delta → up', () {
      expect(KpiTrend.fromDelta(0.05), KpiTrend.up);
      expect(KpiTrend.fromDelta(1234), KpiTrend.up);
    });

    test('strictly negative delta → down', () {
      expect(KpiTrend.fromDelta(-0.05), KpiTrend.down);
      expect(KpiTrend.fromDelta(-9999), KpiTrend.down);
    });

    test('zero delta → flat', () {
      expect(KpiTrend.fromDelta(0), KpiTrend.flat);
      expect(KpiTrend.fromDelta(0.0), KpiTrend.flat);
    });

    test(
        'delta within ±flatEpsilon collapses to flat (avoids "0.001 % up" '
        'jitter dominating the chip)', () {
      expect(
        KpiTrend.fromDelta(KpiTrend.flatEpsilon / 2),
        KpiTrend.flat,
      );
      expect(
        KpiTrend.fromDelta(-KpiTrend.flatEpsilon / 2),
        KpiTrend.flat,
      );
    });

    test('delta exactly at the epsilon boundary is still flat (inclusive)',
        () {
      expect(KpiTrend.fromDelta(KpiTrend.flatEpsilon), KpiTrend.flat);
      expect(KpiTrend.fromDelta(-KpiTrend.flatEpsilon), KpiTrend.flat);
    });

    test('delta just past the epsilon boundary trips to up / down', () {
      // Use a clearly-greater value to dodge floating-point ambiguity at
      // the exact boundary — we just want to lock "past = directional".
      expect(
        KpiTrend.fromDelta(KpiTrend.flatEpsilon * 2),
        KpiTrend.up,
      );
      expect(
        KpiTrend.fromDelta(-KpiTrend.flatEpsilon * 2),
        KpiTrend.down,
      );
    });
  });

  group('KpiData equality (freezed)', () {
    test('two instances with identical fields are equal', () {
      const a = KpiData(
        label: 'Revenue',
        value: r'$100',
        trend: KpiTrend.up,
        trendDelta: '+5%',
        sparkline: [1, 2, 3],
      );
      const b = KpiData(
        label: 'Revenue',
        value: r'$100',
        trend: KpiTrend.up,
        trendDelta: '+5%',
        sparkline: [1, 2, 3],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('changing any field breaks equality', () {
      const base = KpiData(
        label: 'Revenue',
        value: r'$100',
        trend: KpiTrend.up,
      );
      expect(base, isNot(base.copyWith(label: 'Cost')));
      expect(base, isNot(base.copyWith(value: r'$101')));
      expect(base, isNot(base.copyWith(trend: KpiTrend.down)));
      expect(base, isNot(base.copyWith(trendDelta: '+1%')));
      expect(base, isNot(base.copyWith(sparkline: const [1])));
    });

    test('default sparkline is empty (not null)', () {
      const k = KpiData(
        label: 'X',
        value: '0',
        trend: KpiTrend.flat,
      );
      expect(k.sparkline, isEmpty);
    });
  });
}
