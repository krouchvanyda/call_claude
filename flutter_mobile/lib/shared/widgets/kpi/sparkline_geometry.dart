import 'dart:math' as math;

/// Pure-Dart 2D point — `({double dx, double dy})` record. Avoids
/// importing `dart:ui` `Offset` so the geometry stays unit-testable
/// without Flutter (the painter converts at the boundary).
typedef Point2D = ({double dx, double dy});

/// Pure-Dart geometry for the KPI sparkline — split out from the
/// `CustomPainter` so the normalisation rules (degenerate inputs,
/// constant-series fallback, vertical inversion) live in unit tests
/// rather than in widget rendering.
///
/// **Y inversion**: Flutter's canvas Y grows downward; sparkline values
/// grow upward. The mapping flips accordingly so a rising series
/// renders as a rising line on screen.
class SparklineGeometry {
  /// Maps a series of [points] (newest-last) into pixel-space coordinates
  /// inside a rectangle of the given [width] × [height].
  ///
  /// Edge cases:
  /// - Empty [points] → empty list (caller should skip rendering).
  /// - Single point → centred dot at `(0, height/2)`.
  /// - All values equal → flat line through the vertical centre
  ///   (avoids a divide-by-zero on min == max and a misleading
  ///   pinned-to-bottom line).
  static List<Point2D> normalise(
    List<double> points, {
    required double width,
    required double height,
  }) {
    if (points.isEmpty) return const <Point2D>[];
    if (points.length == 1) {
      return [(dx: 0, dy: height / 2)];
    }

    var minVal = points.first;
    var maxVal = points.first;
    for (final p in points) {
      if (p < minVal) minVal = p;
      if (p > maxVal) maxVal = p;
    }
    final range = maxVal - minVal;

    final stepX = width / (points.length - 1);
    if (range == 0) {
      // Constant series — render a flat line through the midline so
      // the user sees "no movement" rather than "pinned to floor".
      return [
        for (var i = 0; i < points.length; i++)
          (dx: stepX * i, dy: height / 2),
      ];
    }

    return [
      for (var i = 0; i < points.length; i++)
        (
          dx: stepX * i,
          // Flip Y: high values render near the top (small y).
          dy: height - ((points[i] - minVal) / range) * height,
        ),
    ];
  }

  /// True iff [points] has at least two values and they are *not* all
  /// identical — i.e. the geometry will produce a visible polyline
  /// rather than a midline / dot. Lets the painter / widget skip
  /// drawing degenerate sparklines that would visually mislead.
  static bool isPolyline(List<double> points) {
    if (points.length < 2) return false;
    final first = points.first;
    for (final p in points) {
      if ((p - first).abs() > _equalityEpsilon) return true;
    }
    return false;
  }

  static const double _equalityEpsilon = 1e-9;
}

/// Convenience: returns the (min, max) of a non-empty series. Exported
/// so tests can assert exact bounds without re-implementing the loop.
({double min, double max}) sparklineBounds(List<double> points) {
  if (points.isEmpty) {
    throw ArgumentError.value(
      points,
      'points',
      'sparklineBounds requires a non-empty series',
    );
  }
  var minVal = points.first;
  var maxVal = points.first;
  for (final p in points) {
    minVal = math.min(minVal, p);
    maxVal = math.max(maxVal, p);
  }
  return (min: minVal, max: maxVal);
}
