import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/leave_requests_repository.dart';
import '../../entities/leave_request.dart';
import 'leave_request_form_page.dart';
import 'leave_requests_list_page.dart';

/// Slice 7.2.2 — leave balance widget.
///
/// Layered: pulls baselines from [LeaveBalancesRepository], requests
/// from [LeaveRequestsRepository], and recombines via
/// [computeEffectiveBalances] so newly-approved requests in the demo
/// session immediately decrement the displayed remainder.
class LeaveBalancePage extends StatelessWidget {
  const LeaveBalancePage({super.key, this.employeeId = 'emp-001'});
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final balanceRepo = GetIt.I<LeaveBalancesRepository>();
    final reqRepo = GetIt.I<LeaveRequestsRepository>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrLeaveBalancePageTitle,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.hrLeaveBalanceHistoryTooltip,
            icon: const Icon(Icons.history_rounded, size: 24),
            onPressed: () => ConfigRouter.pushPageAnimation(context, const LeaveRequestsListPage()),
          ),
          IconButton(
            tooltip: l10n.hrLeaveBalanceRequestLeaveTooltip,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
            onPressed: () => ConfigRouter.pushPageAnimation(context, const LeaveRequestFormPage()),
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<List<LeaveBalance>>(
              stream: balanceRepo.watchForEmployee(employeeId),
              builder: (context, balanceSnap) {
                if (balanceSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final baselines = balanceSnap.data ?? const <LeaveBalance>[];
                if (baselines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_chart_outlined_rounded,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        AppLabel(
                          text: l10n.hrLeaveBalanceNoEntitlements,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  );
                }
                return StreamBuilder<List<LeaveRequest>>(
                  stream: reqRepo.watchAll(),
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? const <LeaveRequest>[];
                    final effective = computeEffectiveBalances(
                      baselines: baselines,
                      requests: requests,
                      employeeId: employeeId,
                    );

                    // Compute overall summary stats
                    int totalDays = 0;
                    int totalRemaining = 0;
                    for (var b in effective) {
                      totalDays += b.totalDays;
                      totalRemaining += b.remainingDays;
                    }
                    final totalUsed = totalDays - totalRemaining;

                    return ListView(
                      padding: EdgeInsets.only(
                        top: context.dynamicAppBarPadding,
                        left: 16,
                        right: 16,
                        bottom: 40,
                      ),
                      children: [
                        // Immersive Header Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryStat(
                                label: l10n.hrLeaveBalanceRemainingLabel,
                                count: '$totalRemaining',
                                color: theme.colorScheme.onPrimary,
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                              ),
                              _SummaryStat(
                                label: l10n.hrLeaveBalanceTakenLabel,
                                count: '$totalUsed',
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                              ),
                              _SummaryStat(
                                label: l10n.hrLeaveBalanceTotalLabel,
                                count: '$totalDays',
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 400.ms),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AppLabel(
                            text: l10n.hrLeaveBalanceBreakdownHeading,
                            fontSize: AppFontSize.value12,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (int i = 0; i < effective.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BalanceCard(balance: effective[i])
                                .animate()
                                .fadeIn(delay: (i * 40).ms)
                                .slideY(begin: 0.05, end: 0, duration: 300.ms),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppLabel(
          text: count,
          fontSize: AppFontSize.value32,
          fontWeight: FontWeight.w900,
          color: color,
        ),
        const SizedBox(height: 4),
        AppLabel(
          text: label.toUpperCase(),
          fontSize: AppFontSize.value11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = balance.remainingDays;
    final pctUsed = balance.totalDays == 0
        ? 0.0
        : (balance.usedDays / balance.totalDays).clamp(0.0, 1.0);

    final Map<LeaveType, Color> categoryColors = {
      LeaveType.annual: Colors.teal,
      LeaveType.sick: Colors.pink,
      LeaveType.unpaid: Colors.amber,
    };
    final accentColor = categoryColors[balance.type] ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppLabel(
                    text: balance.type.name.toUpperCase(),
                    fontSize: AppFontSize.value16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                AppLabel(
                  text: '$remaining Remaining',
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: pctUsed,
                minHeight: 10,
                backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppLabel(
                  text: '${balance.usedDays} used days',
                  fontSize: AppFontSize.value14,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                AppLabel(
                  text: 'out of ${balance.totalDays} days',
                  fontSize: AppFontSize.value14,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
