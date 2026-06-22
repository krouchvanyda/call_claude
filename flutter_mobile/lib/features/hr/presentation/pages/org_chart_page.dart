import 'dart:ui';
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
import '../../data/repositories/employees_repository.dart';
import '../../entities/employee.dart';

/// Slice 7.1.3 — indented tree view of the manager hierarchy.
///
/// Renders the flattened forest as a `ListView.builder` rather than a
/// recursive widget so deep org structures don't blow the build stack
/// and so each row gets the standard list virtualisation.
class OrgChartPage extends StatelessWidget {
  const OrgChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrOrgChartPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<List<Employee>>(
              future: GetIt.I<EmployeesRepository>().getAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final employees = snapshot.data ?? const <Employee>[];
                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        AppLabel(
                          text: l10n.hrOrgChartEmptyTitle,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 8),
                        AppLabel(
                          text: l10n.hrOrgChartEmptySubtitle,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  );
                }

                final flat = flattenOrgChart(buildOrgChart(employees));

                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 12,
                    right: 16,
                    bottom: 40,
                  ),
                  itemCount: flat.length,
                  itemBuilder: (context, idx) {
                    final node = flat[idx];
                    return Padding(
                      padding: EdgeInsets.only(left: 20.0 * node.depth),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Tree Line Connector for nested nodes
                          if (node.depth > 0)
                            Container(
                              width: 16,
                              height: 60,
                              margin: const EdgeInsets.only(right: 8),
                              child: CustomPaint(
                                painter: _TreeLinePainter(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _OrgNodeCard(node: node)
                                  .animate()
                                  .fadeIn(delay: (idx * 30).ms)
                                  .slideX(begin: 0.05, end: 0, duration: 250.ms),
                            ),
                          ),
                        ],
                      ),
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

class _OrgNodeCard extends StatelessWidget {
  const _OrgNodeCard({required this.node});
  final OrgNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopLevel = node.depth == 0;

    return Container(
      decoration: BoxDecoration(
        color: isTopLevel
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isTopLevel
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isTopLevel ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isTopLevel
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          child: AppLabel(
            text: node.employee.name.isEmpty ? '?' : node.employee.name[0],
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        title: AppLabel(
          text: node.employee.name,
          fontSize: isTopLevel ? AppFontSize.value16 : AppFontSize.value14,
          fontWeight: FontWeight.bold,
          color: isTopLevel
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        subtitle: AppLabel(
          text: '${node.employee.position} • ${node.employee.department}',
          fontSize: AppFontSize.value12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        trailing: node.reports.isNotEmpty
            ? Tooltip(
                message: '${node.reports.length} direct reports',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      AppLabel(
                        text: '${node.reports.length}',
                        fontSize: AppFontSize.value11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Custom painter to draw hierarchy branch connector lines
class _TreeLinePainter extends CustomPainter {
  const _TreeLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Start at top middle of connector spacer, go down to middle, then turn right
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    // If it's a continuing branch, we could draw all the way down, but a simple L shape is very clean!
    path.moveTo(size.width / 2, size.height / 2);
    path.lineTo(size.width / 2, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
