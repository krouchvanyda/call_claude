import 'package:erp_mobile/shared/widgets/charts/chart_axis_ticks.dart';
import 'package:erp_mobile/shared/widgets/charts/chart_data.dart';
import 'package:test/test.dart';

void main() {
  group('ChartAxisTicks.compute', () {
    test(
        '0 → 100 with default 5 target ticks → 0/20/.../100 — Heckbert '
        'prefers mantissa 1/2/5/10, so 20 wins over 25 even though both '
        'are "round"', () {
      final t = ChartAxisTicks.compute(
        dataMin: 0,
        dataMax: 100,
      );
      expect(t.min, 0);
      expect(t.max, 100);
      expect(t.step, 20);
      expect(t.values, [0, 20, 40, 60, 80, 100]);
    });

    test('messy input is rounded out to nice numbers', () {
      final t = ChartAxisTicks.compute(
        dataMin: 237,
        dataMax: 947,
      );
      // Expected from Heckbert: step ≈ 200, lo floored to 200, hi ceiled to 1000.
      expect(t.step, 200);
      expect(t.min, 200);
      expect(t.max, 1000);
      expect(t.values, [200, 400, 600, 800, 1000]);
    });

    test('reversed bounds are silently swapped', () {
      final a = ChartAxisTicks.compute(dataMin: 100, dataMax: 0);
      final b = ChartAxisTicks.compute(dataMin: 0, dataMax: 100);
      expect(a.min, b.min);
      expect(a.max, b.max);
      expect(a.step, b.step);
    });

    test(
        'degenerate range (min == max) pads symmetrically so the chart shows '
        'a visible band, not a zero-height stripe', () {
      final t = ChartAxisTicks.compute(dataMin: 50, dataMax: 50);
      // Padded by ±10% of |value| = ±5 → effective range [45, 55]; nice
      // numbers depend on Heckbert but min must be < 50 < max.
      expect(t.min, lessThan(50));
      expect(t.max, greaterThan(50));
    });

    test('degenerate range at zero falls back to ±1 padding (no /0 crash)',
        () {
      final t = ChartAxisTicks.compute(dataMin: 0, dataMax: 0);
      expect(t.min, lessThan(0));
      expect(t.max, greaterThan(0));
      expect(t.values, isNotEmpty);
    });

    test('respects targetTicks request (more ticks for richer axes)', () {
      final coarse =
          ChartAxisTicks.compute(dataMin: 0, dataMax: 100, targetTicks: 3);
      final fine =
          ChartAxisTicks.compute(dataMin: 0, dataMax: 100, targetTicks: 11);
      // More target ticks → smaller step → more values.
      expect(fine.values.length, greaterThan(coarse.values.length));
    });

    test('throws when targetTicks < 2 (caller bug, no silent fallback)', () {
      expect(
        () => ChartAxisTicks.compute(
            dataMin: 0, dataMax: 10, targetTicks: 1),
        throwsArgumentError,
      );
    });

    test('handles negative ranges with the same nice-number machinery', () {
      final t = ChartAxisTicks.compute(dataMin: -75, dataMax: 0);
      expect(t.min, lessThanOrEqualTo(-75));
      expect(t.max, greaterThanOrEqualTo(0));
      // Step should still be a nice multiple of 10/25/50.
      expect(t.values.last - t.values.first, t.step * (t.values.length - 1));
    });

    test('values are evenly spaced by step (within float tolerance)', () {
      final t = ChartAxisTicks.compute(dataMin: 1.4, dataMax: 8.7);
      for (var i = 1; i < t.values.length; i++) {
        expect(
          (t.values[i] - t.values[i - 1] - t.step).abs(),
          lessThan(1e-9),
          reason: 'tick $i drifted from the declared step',
        );
      }
    });
  });

  group('ChartAxisTicks.fromSeries', () {
    test('empty series list → safe [0, 1] placeholder (no axis crash)', () {
      final t = ChartAxisTicks.fromSeries(const []);
      expect(t.min, 0);
      expect(t.max, 1);
      expect(t.step, 1);
    });

    test('series with all-empty points → same placeholder', () {
      final t = ChartAxisTicks.fromSeries(const [
        ChartSeries(id: 'a', label: 'A'),
        ChartSeries(id: 'b', label: 'B'),
      ]);
      expect(t.min, 0);
      expect(t.max, 1);
    });

    test('aggregates min / max across multiple series', () {
      final t = ChartAxisTicks.fromSeries(const [
        ChartSeries(
          id: 'a',
          label: 'A',
          points: [ChartPoint(x: 0, y: 12), ChartPoint(x: 1, y: 18)],
        ),
        ChartSeries(
          id: 'b',
          label: 'B',
          points: [ChartPoint(x: 0, y: 4), ChartPoint(x: 1, y: 90)],
        ),
      ]);
      // Range is 4 → 90 across both series; nice numbers cover it.
      expect(t.min, lessThanOrEqualTo(4));
      expect(t.max, greaterThanOrEqualTo(90));
    });
  });

  group('ChartSeries / ChartPoint equality (freezed)', () {
    test('identical fields → equal', () {
      const a = ChartSeries(
        id: 'x',
        label: 'X',
        points: [ChartPoint(x: 1, y: 2)],
      );
      const b = ChartSeries(
        id: 'x',
        label: 'X',
        points: [ChartPoint(x: 1, y: 2)],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('default points list is empty (not null)', () {
      const s = ChartSeries(id: 'x', label: 'X');
      expect(s.points, isEmpty);
    });

    test('ChartPoint label defaults to null', () {
      const p = ChartPoint(x: 1, y: 2);
      expect(p.label, isNull);
    });
  });
}
