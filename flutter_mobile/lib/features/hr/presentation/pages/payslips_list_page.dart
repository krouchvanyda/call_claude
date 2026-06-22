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
import '../../data/repositories/payslips_repository.dart';
import '../../entities/payslip.dart';
import 'payslip_detail_page.dart';

/// Slice 7.3.2 + 7.3.3 — payslip history with a period rollup card on
/// top so the user sees overtime / deductions at a glance without
/// drilling into individual slips.
class PayslipsListPage extends StatelessWidget {
  const PayslipsListPage({super.key, this.employeeId = 'emp-001'});
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrPayslipsPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<List<Payslip>>(
              stream: GetIt.I<PayslipsRepository>().watchForEmployee(employeeId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final slips = snap.data ?? const <Payslip>[];
                if (slips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        AppLabel(
                          text: l10n.hrPayslipsEmpty,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  );
                }
                final summary = summarizePeriod(slips);

                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    _SummaryCard(buckets: summary, periods: slips.length)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.05, end: 0, duration: 350.ms),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AppLabel(
                        text: l10n.hrPayslipsArchiveHeading,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < slips.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PayslipRow(slip: slips[i])
                            .animate()
                            .fadeIn(delay: (i * 30).ms)
                            .slideY(begin: 0.05, end: 0, duration: 250.ms),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.buckets, required this.periods});
  final PayslipBuckets buckets;
  final int periods;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppLabel(
                text: l10n.hrPayslipsAggregateSummaryHeading,
                fontSize: AppFontSize.value16,
                fontWeight: FontWeight.bold,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: AppLabel(
                  text: '$periods Periods',
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _row(context, 'Total Earnings', formatAmount(buckets.earnings)),
          _row(context, 'Total Overtime', formatAmount(buckets.overtime)),
          _row(context, 'Total Deductions', '-${formatAmount(buckets.deductions)}', isDeduction: true),
          _row(context, 'Total Tax', '-${formatAmount(buckets.tax)}', isDeduction: true),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: Colors.teal.withValues(alpha: 0.2),
              ),
            ),
            child: _row(
              context,
              'Cumulative Net Pay',
              formatAmount(buckets.netPay),
              bold: true,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool isDeduction = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final displayColor = color ??
        (isDeduction
            ? theme.colorScheme.error
            : bold
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: AppLabel(
              text: label,
              fontSize: AppFontSize.value14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: bold
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppLabel(
            text: value,
            fontSize: bold ? AppFontSize.value18 : AppFontSize.value14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
            color: displayColor,
          ),
        ],
      ),
    );
  }
}

class _PayslipRow extends StatelessWidget {
  const _PayslipRow({required this.slip});
  final Payslip slip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: AppLabel(
          text:
              '${_formatDate(slip.periodStart)}   ➔   ${_formatDate(slip.periodEnd)}',
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.15)),
                ),
                child: AppLabel(
                  text: l10n.hrPayslipsNetPayLabel(slip.netPay),
                  fontSize: AppFontSize.value11,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              AppLabel(
                text: l10n.hrPayslipsGrossPayLabel(slip.grossPay),
                fontSize: AppFontSize.value11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.outline,
        ),
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          PayslipDetailPage(payslipId: slip.id),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => dt.toIso8601String().split('T').first;
}
