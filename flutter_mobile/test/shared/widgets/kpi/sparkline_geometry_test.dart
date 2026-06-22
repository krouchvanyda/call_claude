import 'package:erp_mobile/shared/widgets/kpi/sparkline_geometry.dart';
import 'package:test/test.dart';

void main() {
  group('SparklineGeometry.normalise', () {
    test('empty input → empty output (caller skips drawing)', () {
      final out = SparklineGeometry.normalise(
        const [],
        width: 100,
        height: 24,
      );
      expect(out, isEmpty);
    });

    test('single point → centred dot at x=0, y=height/2', () {
      final out = SparklineGeometry.normalise(
        const [42.0],
        width: 100,
        height: 24,
      );
      expect(out, hasLength(1));
      expect(out.single.dx, 0);
      expect(out.single.dy, 12);
    });

    test('constant series → flat line through the midline (no /0 crash)', () {
      final out = SparklineGeometry.normalise(
        const [5.0, 5.0, 5.0, 5.0],
        width: 90,
        height: 30,
      );
      expect(out.length, 4);
      // X spans 0 → width with stepX = width / (n - 1) = 30.
      expect(out.map((o) => o.dx), [0, 30, 60, 90]);
      // Every point sits on the midline — locks the "no movement"
      // visual instead of pinning to the floor (which would happen
      // with a naive (v-min)/range that divides by zero).
      expect(out.every((o) => o.dy == 15), isTrue);
    });

    test(
        'rising series renders rising on screen — Flutter canvas Y is '
        'flipped, so high values map to small y', () {
      final out = SparklineGeometry.normalise(
        const [0.0, 50.0, 100.0],
        width: 200,
        height: 100,
      );
      expect(out, hasLength(3));
      // First (min) should be at the bottom (y == height).
      expect(out.first.dy, 100);
      // Last (max) should be at the top (y == 0).
      expect(out.last.dy, 0);
      // Middle value sits at the midline.
      expect(out[1].dy, 50);
      // X spans 0 → width.
      expect(out.map((o) => o.dx), [0, 100, 200]);
    });

    test('handles negative values by treating them as the minimum', () {
      final out = SparklineGeometry.normalise(
        const [-10.0, 0.0, 10.0],
        width: 100,
        height: 50,
      );
      // Spans from -10 (bottom) to +10 (top); 0 sits at midline.
      expect(out.first.dy, 50);
      expect(out[1].dy, 25);
      expect(out.last.dy, 0);
    });

    test('non-uniform series preserves relative ordering on the y-axis', () {
      final out = SparklineGeometry.normalise(
        const [10.0, 30.0, 5.0, 20.0],
        width: 30,
        height: 40,
      );
      // Min 5 → y=40, Max 30 → y=0.
      expect(out[2].dy, 40);
      expect(out[1].dy, 0);
      // 10 < 20 in raw values, so y(10) > y(20) on screen.
      expect(out.first.dy, greaterThan(out[3].dy));
    });
  });

  group('SparklineGeometry.isPolyline', () {
    test('< 2 points is not a polyline', () {
      expect(SparklineGeometry.isPolyline(const []), isFalse);
      expect(SparklineGeometry.isPolyline(const [1.0]), isFalse);
    });

    test('two distinct points form a polyline', () {
      expect(SparklineGeometry.isPolyline(const [1.0, 2.0]), isTrue);
    });

    test('all-equal series is NOT a polyline (avoid drawing a misleading line)',
        () {
      expect(
        SparklineGeometry.isPolyline(const [3.0, 3.0, 3.0, 3.0]),
        isFalse,
      );
    });

    test('series with one outlier is a polyline', () {
      expect(
        SparklineGeometry.isPolyline(const [3.0, 3.0, 3.0, 3.5]),
        isTrue,
      );
    });
  });

  group('sparklineBounds', () {
    test('returns (min, max) of a non-trivial series', () {
      final b = sparklineBounds(const [3.0, -1.0, 5.0, 2.0, -1.0]);
      expect(b.min, -1.0);
      expect(b.max, 5.0);
    });

    test('single-element series returns that element as both bounds', () {
      final b = sparklineBounds(const [7.0]);
      expect(b.min, 7.0);
      expect(b.max, 7.0);
    });

    test('throws on an empty series rather than returning sentinel values',
        () {
      expect(() => sparklineBounds(const []), throwsArgumentError);
    });
  });
}
