import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_font_size.dart';
import '../../../core/theme/app_label.dart';
import 'chart_axis_ticks.dart';
import 'chart_data.dart';

/// Themed multi-series line chart wrapper around fl_chart (Slice 2.2.3).
///
/// **Why a wrapper, not raw `LineChart` at every call site**: keeps the
/// fl_chart API surface in one place so future styling / branding /
/// upgrades land in a single edit. Feature blocs hand in plain
/// [ChartSeries] values; this widget maps them to fl_chart types at
/// the boundary.
///
/// Series colours cycle through the theme's primary palette
/// deterministically by index — first series is `primary`, then
/// `secondary`, then `tertiary`, then their containers, then back to
/// the start. Real branding overrides via a future `ChartColorScheme`
/// theme extension.
class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.title,
    required this.series,
    this.showLegend = true,
  });

  final String title;
  final List<ChartSeries> series;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yTicks = ChartAxisTicks.fromSeries(series);
    final colors = _seriesColors(theme);

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
              child: LineChart(
                LineChartData(
                  minY: yTicks.min,
                  maxY: yTicks.max,
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
                          final label = _xLabel(series, value);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: AppLabel(
                              text: label,
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
                  lineBarsData: [
                    for (var i = 0; i < series.length; i++)
                      LineChartBarData(
                        spots: [
                          for (final p in series[i].points)
                            FlSpot(p.x, p.y),
                        ],
                        color: colors[i % colors.length],
                        barWidth: 2,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),
            if (showLegend && series.length > 1) ...[
              const SizedBox(height: 8),
              _Legend(series: series, colors: colors),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns the X-label for [value] by matching the nearest series
  /// point with an explicit `label` override; falls back to the raw
  /// numeric value rounded to int.
  static String _xLabel(List<ChartSeries> all, double value) {
    for (final s in all) {
      for (final p in s.points) {
        if ((p.x - value).abs() < 0.0001 && p.label != null) {
          return p.label!;
        }
      }
    }
    return value.toStringAsFixed(0);
  }

  /// Whole-number ticks render without decimals; otherwise one place.
  static String _formatTick(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

List<Color> _seriesColors(ThemeData theme) => [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
    ];

class _Legend extends StatelessWidget {
  const _Legend({required this.series, required this.colors});

  final List<ChartSeries> series;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (var i = 0; i < series.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              AppLabel(text: series[i].label, fontSize: AppFontSize.value11),
            ],
          ),
      ],
    );
  }
}
