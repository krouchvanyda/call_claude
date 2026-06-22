import 'dart:ui';
import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/sales_orders_repository.dart';
import '../../data/repositories/sales_reps_repository.dart';
import '../../entities/activity_event.dart';
import '../../entities/sales_order.dart';
import '../../entities/sales_rep.dart';

/// Sales analytics page (Slices 6.3.1 + 6.3.2 + 6.3.3).
class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  late Future<_Bundle> _future;
  RevenuePeriod _period = RevenuePeriod.monthly;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bundle> _load() async {
    final orders = await getIt<SalesOrdersRepository>().getAll();
    final orderActivities =
        await getIt<ActivitiesRepository>().allOfType(ActivityEventType.order);
    final reps = await getIt<SalesRepsRepository>().getAll();
    return _Bundle(
      orders: orders,
      orderActivities: orderActivities,
      reps: reps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.salesAnalyticsTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas Gradient
            AppBackgroundGradient(),
            FutureBuilder<_Bundle>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final b = snap.data!;
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    _RevenueChartCard(
                      orders: b.orders,
                      period: _period,
                      onPeriodChanged: (p) => setState(() => _period = p),
                    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
                    const SizedBox(height: 16),
                    _TopRankingsRow(orders: b.orders).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),
                    _LeaderboardCard(activities: b.orderActivities, reps: b.reps).animate().fadeIn(delay: 300.ms),
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

class _Bundle {
  const _Bundle({
    required this.orders,
    required this.orderActivities,
    required this.reps,
  });
  final List<SalesOrder> orders;
  final List<ActivityEvent> orderActivities;
  final List<SalesRep> reps;
}

// ── Revenue chart (Slice 6.3.1) ─────────────────────────────────

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({
    required this.orders,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<SalesOrder> orders;
  final RevenuePeriod period;
  final ValueChanged<RevenuePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now().toUtc();
    final (from, to) = _rangeFor(now, period);
    final buckets = revenueByPeriod(
      orders,
      period: period,
      from: from,
      to: to,
    );
    final maxRevenue = buckets.fold<num>(
      0,
      (m, b) => b.amount > m ? b.amount : m,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_outlined, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      AppLabel(
                        text: l10n.salesAnalyticsRevenueHeading,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
                SegmentedButton<RevenuePeriod>(
                  segments: [
                    ButtonSegment(
                      value: RevenuePeriod.weekly,
                      label: AppLabel(
                        text: l10n.salesAnalyticsPeriodWeekly,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ButtonSegment(
                      value: RevenuePeriod.monthly,
                      label: AppLabel(
                        text: l10n.salesAnalyticsPeriodMonthly,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  selected: {period},
                  onSelectionChanged: (s) => onPeriodChanged(s.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (buckets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: AppLabel(
                    text: l10n.salesAnalyticsRevenueEmpty,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxRevenue == 0 ? 1 : maxRevenue * 1.1).toDouble(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            buckets[groupIndex].amount.toStringAsFixed(2),
                            TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= buckets.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: AppLabel(
                                text: _xLabel(buckets[idx].start, period),
                                fontSize: AppFontSize.value11,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: AppLabel(
                              text: _compactCurrency(v),
                              fontSize: AppFontSize.value11,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < buckets.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: buckets[i].amount.toDouble(),
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 16,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
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

  static (DateTime, DateTime) _rangeFor(DateTime now, RevenuePeriod p) {
    switch (p) {
      case RevenuePeriod.weekly:
        final daysFromMonday = (now.weekday - DateTime.monday) % 7;
        final thisMonday = DateTime.utc(now.year, now.month, now.day)
            .subtract(Duration(days: daysFromMonday));
        final from = thisMonday.subtract(const Duration(days: 7 * 5));
        final to = thisMonday.add(const Duration(days: 7));
        return (from, to);
      case RevenuePeriod.monthly:
        final thisMonthStart = DateTime.utc(now.year, now.month, 1);
        var cursor = thisMonthStart;
        for (var i = 0; i < 5; i++) {
          final m = cursor.month == 1 ? 12 : cursor.month - 1;
          final y = cursor.month == 1 ? cursor.year - 1 : cursor.year;
          cursor = DateTime.utc(y, m, 1);
        }
        final nextMonth = thisMonthStart.month == 12 ? 1 : thisMonthStart.month + 1;
        final nextYear = thisMonthStart.month == 12
            ? thisMonthStart.year + 1
            : thisMonthStart.year;
        final to = DateTime.utc(nextYear, nextMonth, 1);
        return (cursor, to);
    }
  }

  static String _xLabel(DateTime start, RevenuePeriod p) {
    switch (p) {
      case RevenuePeriod.weekly:
        return DateFormat('MM-dd').format(start);
      case RevenuePeriod.monthly:
        return DateFormat('MMM').format(start);
    }
  }

  static String _compactCurrency(num v) {
    if (v.abs() >= 1000) {
      return '\$${(v / 1000).toStringAsFixed(0)}k';
    }
    return '\$${v.toStringAsFixed(0)}';
  }
}

// ── Top customers / top products (Slice 6.3.2) ──────────────────

class _TopRankingsRow extends StatelessWidget {
  const _TopRankingsRow({required this.orders});
  final List<SalesOrder> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customers = topCustomers(orders, limit: 5);
    final products = topProducts(orders, limit: 5);
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final cards = [
        _RankingCard(
          title: l10n.salesAnalyticsTopCustomersHeading,
          icon: Icons.people_outline,
          entries: customers,
          emptyMessage: l10n.salesAnalyticsTopCustomersEmpty,
        ),
        _RankingCard(
          title: l10n.salesAnalyticsTopProductsHeading,
          icon: Icons.local_offer_outlined,
          entries: products,
          emptyMessage: l10n.salesAnalyticsTopProductsEmpty,
        ),
      ];
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        );
      }
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 16),
          cards[1],
        ],
      );
    });
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.icon,
    required this.entries,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<TopRanking<String>> entries;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                AppLabel(
                  text: title,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: AppLabel(
                  text: emptyMessage,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: theme.colorScheme.primary,
                  child: AppLabel(
                    text: '${i + 1}',
                    fontSize: AppFontSize.value11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: AppLabel(
                  text: entries[i].label,
                  fontSize: AppFontSize.value14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold,
                ),
                subtitle: AppLabel(
                  text: '${entries[i].units} units',
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                trailing: AppLabel(
                  text: entries[i].amount,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Leaderboard (Slice 6.3.3) ───────────────────────────────────

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.activities, required this.reps});

  final List<ActivityEvent> activities;
  final List<SalesRep> reps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final ranked = salesRepLeaderboard(activities, reps: reps);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                AppLabel(
                  text: l10n.salesAnalyticsLeaderboardHeading,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: AppLabel(
                  text: l10n.salesAnalyticsLeaderboardEmpty,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ranked.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
              itemBuilder: (_, index) => _LeaderboardRow(entry: ranked[index]),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final attainmentColor = entry.attainmentPct >= 100
        ? theme.colorScheme.tertiary
        : entry.attainmentPct >= 60
            ? theme.colorScheme.primary
            : theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: theme.colorScheme.primary,
            child: AppLabel(
              text: '${entry.rank}',
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: entry.rep.name,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 2),
                AppLabel(
                  text: l10n.salesAnalyticsLeaderboardDealsLabel(
                    entry.dealsClosed.toString(),
                  ),
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: LinearProgressIndicator(
                    value: (entry.attainmentPct / 100).clamp(0.0, 1.5),
                    backgroundColor:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation(attainmentColor),
                    minHeight: 6,
                  ),
                ),
                if (entry.rep.targetAmount.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppLabel(
                    text: l10n.salesAnalyticsLeaderboardAttainmentLabel(
                      entry.attainmentPct.toStringAsFixed(0),
                      entry.rep.targetAmount,
                    ),
                    fontSize: AppFontSize.value12,
                    color: attainmentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          AppLabel(
            text: entry.formattedRevenue,
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ],
      ),
    );
  }
}
