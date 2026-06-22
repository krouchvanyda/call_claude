import 'package:flutter/widgets.dart';

import '../../../shared/widgets/charts/bar_chart_card.dart';
import '../../../shared/widgets/charts/chart_data.dart';
import '../../../shared/widgets/charts/line_chart_card.dart';
import '../dashboard_widget.dart';

/// Dashboard adapter for [LineChartCard] (Slice 2.2.3).
///
/// Same pattern as [`KpiDashboardWidget`] from 2.2.2 — the underlying
/// chart card stays a generic, reusable widget; the adapter contributes
/// dashboard layout metadata (id / colSpan / heightDp).
class LineChartDashboardWidget extends DashboardWidget {
  const LineChartDashboardWidget({
    required this.id,
    required this.title,
    required this.series,
    this.colSpan = 2,
    this.heightDp = 240,
    this.showLegend = true,
  });

  @override
  final String id;

  @override
  final int colSpan;

  @override
  final double? heightDp;

  final String title;
  final List<ChartSeries> series;
  final bool showLegend;

  @override
  Widget build(BuildContext context) => LineChartCard(
        title: title,
        series: series,
        showLegend: showLegend,
      );
}

/// Dashboard adapter for [BarChartCard] (Slice 2.2.3).
class BarChartDashboardWidget extends DashboardWidget {
  const BarChartDashboardWidget({
    required this.id,
    required this.title,
    required this.series,
    this.colSpan = 2,
    this.heightDp = 240,
  });

  @override
  final String id;

  @override
  final int colSpan;

  @override
  final double? heightDp;

  final String title;
  final ChartSeries series;

  @override
  Widget build(BuildContext context) => BarChartCard(
        title: title,
        series: series,
      );
}
