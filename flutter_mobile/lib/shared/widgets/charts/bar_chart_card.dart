import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_font_size.dart';
import '../../../core/theme/app_label.dart';
import 'chart_axis_ticks.dart';
import 'chart_data.dart';

/// Themed single-series bar chart wrapper around fl_chart (Slice 2.2.3).
///
/// Bars are categorical — `point.x` is treated as a slot index and
/// `point.label` as the X-axis label (e.g. region name, weekday).
/// For multi-series clustered bars, prefer a future
/// `GroupedBarChartCard`; this one keeps the simple case simple.
class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.title,
    required this.series,
  });

  final String title;
  final ChartSeries series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yTicks = ChartAxisTicks.fromSeries([series]);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabel(text: title, fontSize: AppFontSize.value14, fontWeight: FontWeight.w600),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  minY: yTicks.min,
                  maxY: yTicks.max,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yTicks.step,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yTicks.step,
                        reservedSize: 36,
                        getTitlesWidget: (value, _) => AppLabel(
                          text: _formatTick(value),
                          fontSize: AppFontSize.value11,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= series.points.length) {
                            return const SizedBox.shrink();
                          }
                          final p = series.points[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: AppLabel(
                              text: p.label ?? p.x.toStringAsFixed(0),
                              fontSize: AppFontSize.value11,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < series.points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: series.points[i].y,
                            color: theme.colorScheme.primary,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTick(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}
