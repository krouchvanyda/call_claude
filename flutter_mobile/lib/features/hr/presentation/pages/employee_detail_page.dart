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
import '../../data/repositories/employees_repository.dart';
import '../../entities/employee.dart';
import 'attendance_page.dart';
import 'leave_balance_page.dart';
import 'org_chart_page.dart';
import 'payslips_list_page.dart';

/// Slice 7.1.2 — employee profile detail.
class EmployeeDetailPage extends StatelessWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrEmployeeDetailPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<Employee?>(
              future: GetIt.I<EmployeesRepository>().findById(employeeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final emp = snapshot.data;
                if (emp == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          AppLabel(
                            text: l10n.hrEmployeeDetailNotFoundTitle,
                            fontSize: AppFontSize.value16,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 8),
                          AppLabel(
                            text: l10n.hrEmployeeDetailNotFoundBody(employeeId),
                            fontSize: AppFontSize.value14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final statusColor = _statusColor(theme, emp.status);

                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    // Header Card
                    _HeaderCard(employee: emp, statusColor: statusColor)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.05, end: 0, duration: 300.ms),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _SectionHeading(title: l10n.hrEmployeeDetailSectionQuickActions),
                    const SizedBox(height: 10),
                    _QuickActionsRow(employeeId: emp.id)
                        .animate()
                        .fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),

                    // Categorized Details
                    _SectionHeading(title: l10n.hrEmployeeDetailSectionContact),
                    const SizedBox(height: 10),
                    _DetailsCard(
                      items: [
                        _DetailItem(
                          icon: Icons.email_outlined,
                          label: l10n.commonEmailLabel,
                          value: emp.email,
                        ),
                        _DetailItem(
                          icon: Icons.phone_outlined,
                          label: l10n.commonPhoneNumberLabel,
                          value: emp.phone,
                        ),
                        _DetailItem(
                          icon: Icons.location_on_outlined,
                          label: l10n.hrEmployeeDetailOfficeLocationLabel,
                          value: emp.location ?? 'Remote / Not Specified',
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 24),

                    _SectionHeading(title: l10n.hrEmployeeDetailSectionEmployment),
                    const SizedBox(height: 10),
                    _DetailsCard(
                      items: [
                        _DetailItem(
                          icon: Icons.business_center_outlined,
                          label: l10n.hrEmployeeDetailDepartmentLabel,
                          value: emp.department,
                        ),
                        _DetailItem(
                          icon: Icons.badge_outlined,
                          label: l10n.hrEmployeeDetailPositionTitleLabel,
                          value: emp.position,
                        ),
                        _DetailItem(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.hrEmployeeDetailHireDateLabel,
                          value: emp.hiredAt.toIso8601String().split('T').first,
                        ),
                        _DetailItem(
                          icon: Icons.payments_outlined,
                          label: l10n.hrEmployeeDetailMonthlySalaryLabel,
                          value: emp.monthlySalary,
                        ),
                        if (emp.managerId != null)
                          _DetailItem(
                            icon: Icons.supervisor_account_outlined,
                            label: l10n.hrEmployeeDetailManagerIdLabel,
                            value: emp.managerId!,
                          ),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, EmploymentStatus s) {
    return switch (s) {
      EmploymentStatus.active => theme.colorScheme.primary,
      EmploymentStatus.onLeave => theme.colorScheme.secondary,
      EmploymentStatus.suspended => theme.colorScheme.error,
      EmploymentStatus.terminated => theme.colorScheme.outline,
    };
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.employee, required this.statusColor});
  final Employee employee;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
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
          CircleAvatar(
            radius: 46,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: employee.avatarUrl != null
                ? NetworkImage(employee.avatarUrl!)
                : null,
            child: employee.avatarUrl == null
                ? AppLabel(
                    text: employee.name.isEmpty ? '?' : employee.name[0],
                    fontSize: AppFontSize.value32,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          AppLabel(
            text: employee.name,
            fontSize: AppFontSize.value24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          AppLabel(
            text: employee.position,
            fontSize: AppFontSize.value16,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _StatusBadge(status: employee.status, color: statusColor),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final EmploymentStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      EmploymentStatus.active => 'ACTIVE',
      EmploymentStatus.onLeave => 'ON LEAVE',
      EmploymentStatus.suspended => 'SUSPENDED',
      EmploymentStatus.terminated => 'TERMINATED',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppLabel(
        text: text,
        fontSize: AppFontSize.value12,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AppLabel(
        text: title.toUpperCase(),
        fontSize: AppFontSize.value11,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.employeeId});
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 24) / 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionButton(
              icon: Icons.timer_outlined,
              label: l10n.hrEmployeeDetailTabAttendance,
              color: Colors.teal,
              width: width,
              onTap: () => ConfigRouter.pushPageAnimation(context, const AttendancePage()),
            ),
            _ActionButton(
              icon: Icons.receipt_long_outlined,
              label: l10n.hrEmployeeDetailTabPayslips,
              color: Colors.indigo,
              width: width,
              onTap: () => ConfigRouter.pushPageAnimation(context, const PayslipsListPage()),
            ),
            _ActionButton(
              icon: Icons.event_available_outlined,
              label: l10n.hrEmployeeDetailTabLeaves,
              color: Colors.orange,
              width: width,
              onTap: () => ConfigRouter.pushPageAnimation(context, const LeaveBalancePage()),
            ),
            _ActionButton(
              icon: Icons.account_tree_outlined,
              label: l10n.hrEmployeeDetailTabOrgChart,
              color: Colors.blueGrey,
              width: width,
              onTap: () => ConfigRouter.pushPageAnimation(context, const OrgChartPage()),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.width,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                AppLabel(
                  text: label,
                  fontSize: AppFontSize.value10,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.items});
  final List<_DetailItem> items;

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
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                indent: 52,
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: label,
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 2),
                AppLabel(
                  text: value,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
