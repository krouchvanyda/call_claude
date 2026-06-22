import 'package:freezed_annotation/freezed_annotation.dart';

part 'chart_data.freezed.dart';

/// One data point in a [ChartSeries] (Slice 2.2.3).
///
/// **Pure data**: no Flutter imports, no `Color`, no fl_chart types.
/// The widget layer maps `ChartSeries` → fl_chart's `LineChartBarData` /
/// `BarChartGroupData` at the boundary so feature blocs can construct
/// chart data without depending on the chart library.
@freezed
class ChartPoint with _$ChartPoint {
  const factory ChartPoint({
    /// X-axis position. For time-series this is typically a Unix-epoch
    /// millisecond or a day index; the widget layer formats the label.
    required double x,

    /// Y-axis value.
    required double y,

    /// Optional category / X-axis label override (e.g. "Q1", "Mon").
    /// `null` falls back to the widget's default formatter.
    String? label,
  }) = _ChartPoint;
}

/// One named series — a labelled set of points with metadata used by
/// the widget layer to drive colour assignment, legend display, and
/// emphasis ("primary" series might render thicker, etc.).
@freezed
class ChartSeries with _$ChartSeries {
  const factory ChartSeries({
    /// Stable id — used for keying widgets, not user-facing.
    required String id,

    /// Translated display label (used in legends / tooltips).
    required String label,

    /// Newest-last data points. Empty list = no series rendered.
    @Default(<ChartPoint>[]) List<ChartPoint> points,
  }) = _ChartSeries;
}
