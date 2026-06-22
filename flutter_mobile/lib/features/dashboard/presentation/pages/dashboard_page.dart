import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dashboard/dashboard_grid.dart';
import '../../../../core/dashboard/dashboard_widget.dart';
import '../../../../core/dashboard/widgets/chart_dashboard_widgets.dart';
import '../../../../core/dashboard/widgets/kpi_dashboard_widget.dart';
import '../../../../core/di/app_env.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/push/local_push_simulator.dart';
import '../../../../core/push/push_message_router.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/realtime/realtime_status_indicator.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../features/auth/entities/permission.dart';
import '../../../../features/notifications/presentation/widgets/notifications_badge.dart';
import '../../../../features/search/presentation/widgets/global_search_anchor.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/charts/chart_data.dart';
import '../../../../shared/widgets/kpi/kpi_data.dart';
import '../../../../shared/widgets/permission_guard.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _adminPermission = Permission(token: 'admin');

  late final RealtimeService _realtime;
  late final PushMessageRouter _pushRouter;
  late final PushNotificationService _pushService;
  int _demoPushCount = 0;

  @override
  void initState() {
    super.initState();
    _realtime = getIt<RealtimeService>();
    _pushRouter = getIt<PushMessageRouter>();
    _pushService = getIt<PushNotificationService>();
    
    if (getIt<AppEnv>().realtimeEnabled) {
      unawaited(_realtime.connect());
      _realtime.subscribe('dashboard.default');
    }
    unawaited(_pushRouter.start());
  }

  void _simulatePush({String? routeName, Map<String, String> routeParams = const {}}) {
    final svc = _pushService;
    if (svc is! LocalPushSimulator) return;
    _demoPushCount++;
    final l10n = AppLocalizations.of(context);
    svc.simulateNow(
      title: l10n.pushDemoTitle(_demoPushCount),
      body: routeName == null ? l10n.pushDemoBody : l10n.pushDemoRoutedBody,
      category: 'system',
      data: {
        if (routeName != null) 'route': routeName,
        for (final e in routeParams.entries) 'route.${e.key}': e.value,
      },
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.pushDemoSnack),
        action: routeName == null
            ? null
            : SnackBarAction(
                label: l10n.notificationDeepLinkViewAction,
                onPressed: () => context.goNamed(
                  routeName,
                  pathParameters: routeParams,
                ),
              ),
      ));
  }

  static DashboardLayout _buildDefaultLayout(AppLocalizations l10n) => [
        KpiDashboardWidget(
          id: 'revenue-mtd',
          data: KpiData(
            label: l10n.dashboardKpiRevenueLabel,
            value: r'$84,210',
            trend: KpiTrend.up,
            trendDelta: '+12.4%',
            sparkline: const [62, 58, 65, 71, 70, 78, 84],
          ),
        ),
        KpiDashboardWidget(
          id: 'open-invoices',
          data: KpiData(
            label: l10n.dashboardKpiOpenInvoicesLabel,
            value: '47',
            trend: KpiTrend.down,
            trendDelta: '-6 vs prior',
            sparkline: const [70, 66, 62, 58, 53, 50, 47],
          ),
        ),
        KpiDashboardWidget(
          id: 'avg-fulfilment',
          data: KpiData(
            label: l10n.dashboardKpiAvgFulfilmentLabel,
            value: '3.2',
            trend: KpiTrend.flat,
            trendDelta: '~0',
            sparkline: const [3.1, 3.3, 3.2, 3.2, 3.1, 3.2, 3.2],
          ),
          colSpan: 2,
        ),
        LineChartDashboardWidget(
          id: 'revenue-trend',
          title: l10n.chartRevenueTrendTitle,
          colSpan: 2,
          series: [
            ChartSeries(
              id: 'revenue',
              label: l10n.chartSeriesRevenue,
              points: const [
                ChartPoint(x: 1, y: 62, label: 'W1'),
                ChartPoint(x: 2, y: 58, label: 'W2'),
                ChartPoint(x: 3, y: 65, label: 'W3'),
                ChartPoint(x: 4, y: 71, label: 'W4'),
                ChartPoint(x: 5, y: 70, label: 'W5'),
                ChartPoint(x: 6, y: 78, label: 'W6'),
                ChartPoint(x: 7, y: 84, label: 'W7'),
              ],
            ),
            ChartSeries(
              id: 'target',
              label: l10n.chartSeriesTarget,
              points: const [
                ChartPoint(x: 1, y: 60),
                ChartPoint(x: 2, y: 62),
                ChartPoint(x: 3, y: 64),
                ChartPoint(x: 4, y: 66),
                ChartPoint(x: 5, y: 68),
                ChartPoint(x: 6, y: 70),
                ChartPoint(x: 7, y: 72),
              ],
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.dashboardTitle,
        actions: const [
          /// checking in with a realtime status (online or offline) here felt natural given the dashboard context, but can easily be moved to a more global position like the main app bar if desired
          // RealtimeStatusIndicator(),
          NotificationsBadge(),
          GlobalSearchAnchor(),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Elements
            const AppBackgroundGradient(),
            
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: context.dynamicAppBarPadding + kToolbarHeight ,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLabel(
                        text: l10n.dashboardGreeting,
                        fontSize: AppFontSize.value16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                      AppLabel(
                        text: l10n.dashboardUserNamePlaceholder,
                        fontSize: AppFontSize.value22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.1, end: 0),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Main Content
                  DashboardGrid(layout: _buildDefaultLayout(l10n)).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                  
                  const SizedBox(height: 40),
                  
                  // Quick Actions & Demo section
                  _SectionHeader(title: l10n.dashboardQuickAccessSection, icon: Icons.bolt_rounded),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // _QuickActionChip(
                      //   label: 'Admin Demo',
                      //   icon: Icons.admin_panel_settings_outlined,
                      //   onTap: () => context.goNamed(RoutePaths.adminDemoName),
                      // ),
                      // _QuickActionChip(
                      //   label: 'Chart of Accounts',
                      //   icon: Icons.account_balance_outlined,
                      //   onTap: () => context.goNamed(RoutePaths.chartOfAccountsName),
                      // ),
                      if (_pushService is LocalPushSimulator) ...[
                        _QuickActionChip(
                          label: l10n.dashboardSimulatePushAction,
                          icon: Icons.notifications_active_outlined,
                          onTap: () => _simulatePush(),
                        ),
                        _QuickActionChip(
                          label: l10n.dashboardRoutedPushAction,
                          icon: Icons.open_in_new_rounded,
                          onTap: () => _simulatePush(routeName: RoutePaths.adminDemoName),
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 32),
                  
                  // Permission Status
                  // _SectionHeader(title: 'Security Context', icon: Icons.security_rounded),
                  // const SizedBox(height: 16),
                  // PermissionGuard.builder(
                  //   required: _adminPermission,
                  //   builder: (context, allowed) {
                  //     final color = allowed
                  //         ? theme.colorScheme.primary
                  //         : theme.colorScheme.error;
                  //     return Container(
                  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  //       decoration: BoxDecoration(
                  //         color: color.withOpacity(0.08),
                  //         borderRadius: BorderRadius.circular(16),
                  //         border: Border.all(color: color.withOpacity(0.2)),
                  //       ),
                  //       child: Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Icon(
                  //             allowed ? Icons.verified_user_rounded : Icons.lock_person_rounded,
                  //             color: color,
                  //             size: 20,
                  //           ),
                  //           const SizedBox(width: 12),
                  //           Text(
                  //             allowed
                  //                 ? l10n.permissionGuardDemoGranted
                  //                 : l10n.permissionGuardDemoDenied,
                  //             style: theme.textTheme.labelLarge?.copyWith(
                  //               color: color,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        AppLabel(
          text: title,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            AppLabel(
              text: label,
              fontSize: AppFontSize.value14,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
