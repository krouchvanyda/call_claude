import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/timesheets_repository.dart';
import '../../entities/timesheet_entry.dart';

/// Slice 8.2.3 — utilization report.
class UtilizationPage extends StatefulWidget {
  const UtilizationPage({super.key});

  @override
  State<UtilizationPage> createState() => _UtilizationPageState();
}

enum _Window { week, month }

class _UtilizationPageState extends State<UtilizationPage> {
  _Window _window = _Window.week;

  ({DateTime from, DateTime to}) _range(DateTime now) {
    if (_window == _Window.week) {
      // Monday-anchored.
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return (
        from: DateTime.utc(monday.year, monday.month, monday.day),
        to: DateTime.utc(sunday.year, sunday.month, sunday.day),
      );
    }
    final firstOfMonth = DateTime.utc(now.year, now.month, 1);
    final firstNext = DateTime.utc(now.year, now.month + 1, 1);
    final lastOfMonth = firstNext.subtract(const Duration(days: 1));
    return (from: firstOfMonth, to: lastOfMonth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.utilizationPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<List<TimesheetEntry>>(
              stream: GetIt.I<TimesheetsRepository>().watchAll(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data ?? const <TimesheetEntry>[];
                final r = _range(DateTime.now());
                final buckets = computeUtilization(
                  entries: entries,
                  from: r.from,
                  to: r.to,
                );
                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    SegmentedButton<_Window>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        ButtonSegment(
                          value: _Window.week,
                          label: AppLabel(
                            text: l10n.utilizationThisWeekToggle,
                            fontSize: AppFontSize.value13,
                          ),
                        ),
                        ButtonSegment(
                          value: _Window.month,
                          label: AppLabel(
                            text: l10n.utilizationThisMonthToggle,
                            fontSize: AppFontSize.value13,
                          ),
                        ),
                      ],
                      selected: {_window},
                      onSelectionChanged: (s) =>
                          setState(() => _window = s.first),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabel(
                            text: l10n.utilizationApprovedHoursHeading,
                            fontSize: AppFontSize.value11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          const SizedBox(height: 4),
                          AppLabel(
                            text:
                                '${r.from.toIso8601String().split('T').first}  →  ${r.to.toIso8601String().split('T').first}',
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 24),
                          if (buckets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: AppLabel(
                                  text: l10n.utilizationNoHoursInWindow,
                                  fontSize: AppFontSize.value14,
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 220,
                              child: _UtilizationBarChart(buckets: buckets),
                            ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 300.ms),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < buckets.length; i++) ...[
                            _LeaderRow(bucket: buckets[i])
                                .animate()
                                .fadeIn(delay: (i * 50).ms)
                                .slideY(begin: 0.05, end: 0, duration: 250.ms),
                            if (i < buckets.length - 1)
                              const Divider(height: 1, thickness: 0.5),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilizationBarChart extends StatelessWidget {
  const _UtilizationBarChart({required this.buckets});
  final List<UtilizationBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = buckets.fold<double>(
      0,
      (m, b) => b.loggedHours > m ? b.loggedHours : m,
    );
    // Pad the y-axis so the tallest bar isn't flush with the top.
    final yMax = (maxY == 0 ? 8.0 : maxY * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: yMax,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yMax / 4,
              getTitlesWidget: (v, _) => AppLabel(
                text: v.toInt().toString(),
                fontSize: AppFontSize.value10,
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= buckets.length) {
                  return const SizedBox.shrink();
                }
                final name = buckets[idx].employeeName;
                final short = name.split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppLabel(
                    text: short,
                    fontSize: AppFontSize.value10,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].loggedHours,
                  width: 16,
                  color: _utilizationColor(buckets[i].utilizationPct),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _utilizationColor(double pct) {
    if (pct >= 100) return Colors.green;
    if (pct >= 75) return Colors.blue;
    if (pct >= 50) return Colors.amber.shade700;
    return Colors.red;
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.bucket});
  final UtilizationBucket bucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = bucket.utilizationPct.clamp(0.0, 200.0);
    final indicatorColor = _indicatorColor(pct);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppLabel(
                  text: bucket.employeeName,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppLabel(
                text:
                    '${bucket.loggedHours.toStringAsFixed(1)}h / ${bucket.targetHours.toStringAsFixed(0)}h',
                fontSize: AppFontSize.value12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AppLabel(
                  text: '${pct.toStringAsFixed(0)}%',
                  fontSize: AppFontSize.value10,
                  color: indicatorColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _indicatorColor(double pct) {
    if (pct >= 100) return Colors.green;
    if (pct >= 75) return Colors.blue;
    if (pct >= 50) return Colors.amber.shade700;
    return Colors.red;
  }
}
