import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../features/auth/presentation/pages/biometric_unlock_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_entry_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/admin_demo_page.dart';
import '../../features/dashboard/presentation/pages/coming_soon_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/modules_page.dart';
import '../../features/auth/data/demo_sign_in.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/finance/presentation/pages/account_detail_page.dart';
import '../di/injection.dart';
import '../../features/finance/presentation/pages/chart_of_accounts_page.dart';
import '../../features/finance/presentation/pages/invoice_detail_page.dart';
import '../../features/finance/presentation/pages/invoice_form_page.dart';
import '../../features/finance/presentation/pages/invoice_list_page.dart';
import '../../features/finance/presentation/pages/journal_entry_detail_page.dart';
import '../../features/finance/presentation/pages/journal_entry_list_page.dart';
import '../../features/finance/presentation/pages/trial_balance_page.dart';
import '../../features/inventory/entities/stock_movement.dart';
import '../../features/sales/entities/contact.dart';
import '../../features/sales/presentation/pages/activity_form_page.dart';
import '../../features/sales/presentation/pages/contact_form_page.dart';
import '../../features/sales/presentation/pages/customer_detail_page.dart';
import '../../features/sales/presentation/pages/customer_list_page.dart';
import '../../features/sales/presentation/pages/quotation_detail_page.dart';
import '../../features/sales/presentation/pages/quotation_form_page.dart';
import '../../features/sales/presentation/pages/quotation_list_page.dart';
import '../../features/sales/presentation/pages/sales_analytics_page.dart';
import '../../features/sales/presentation/pages/sales_order_detail_page.dart';
import '../../features/sales/presentation/pages/sales_order_list_page.dart';
import '../../features/inventory/presentation/pages/cycle_count_page.dart';
import '../../features/inventory/presentation/pages/item_detail_page.dart';
import '../../features/inventory/presentation/pages/items_list_page.dart';
import '../../features/inventory/presentation/pages/low_stock_alerts_page.dart';
import '../../features/inventory/presentation/pages/scanner_page.dart';
import '../../features/inventory/presentation/pages/stock_movement_form_page.dart';
import '../../features/inventory/presentation/pages/stock_transfer_page.dart';
import '../../features/notifications/presentation/pages/notification_inbox_page.dart';
import '../../features/procurement/presentation/pages/goods_receipt_form_page.dart';
import '../../features/procurement/presentation/pages/po_detail_page.dart';
import '../../features/procurement/presentation/pages/po_list_page.dart';
import '../../features/procurement/presentation/pages/pr_detail_page.dart';
import '../../features/procurement/presentation/pages/pr_form_page.dart';
import '../../features/procurement/presentation/pages/pr_list_page.dart';
import '../../features/procurement/presentation/pages/vendor_detail_page.dart';
import '../../features/procurement/presentation/pages/vendor_form_page.dart';
import '../../features/procurement/presentation/pages/vendor_list_page.dart';
import '../../features/procurement/presentation/pages/vendor_scorecard_page.dart';
import '../../features/projects/presentation/pages/project_board_page.dart';
import '../../features/projects/presentation/pages/project_detail_page.dart';
import '../../features/projects/presentation/pages/project_list_page.dart';
import '../../features/projects/presentation/pages/task_detail_page.dart';
import '../../features/projects/presentation/pages/timesheet_form_page.dart';
import '../../features/projects/presentation/pages/timesheets_list_page.dart';
import '../../features/projects/presentation/pages/utilization_page.dart';
import '../../features/hr/presentation/pages/attendance_page.dart';
import '../../features/hr/presentation/pages/employee_detail_page.dart';
import '../../features/hr/presentation/pages/employee_list_page.dart';
import '../../features/hr/presentation/pages/leave_balance_page.dart';
import '../../features/hr/presentation/pages/leave_request_form_page.dart';
import '../../features/hr/presentation/pages/leave_requests_list_page.dart';
import '../../features/hr/presentation/pages/org_chart_page.dart';
import '../../features/hr/presentation/pages/payslip_detail_page.dart';
import '../../features/hr/presentation/pages/payslips_list_page.dart';
import '../../features/settings/presentation/pages/api_config_page.dart';
import '../../features/settings/presentation/pages/app_lock_page.dart';
import '../../features/settings/presentation/pages/appearance_page.dart';
import '../../features/settings/presentation/pages/assignments_page.dart';
import '../../features/settings/presentation/pages/audit_log_page.dart';
import '../../features/settings/presentation/pages/language_page.dart';
import '../../features/settings/presentation/pages/notification_preferences_page.dart';
import '../../features/settings/presentation/pages/role_editor_page.dart';
import '../../features/settings/presentation/pages/sessions_page.dart';
import '../../features/settings/presentation/pages/settings_home_page.dart';
import '../../features/search/presentation/pages/global_search_page.dart';
import '../../features/settings/presentation/pages/user_management_page.dart';
import 'app_shell.dart';
import 'auth_redirect_policy.dart';
import 'auth_session.dart';
import 'forbidden_page.dart';
import 'not_found_page.dart';
import 'permissions_snapshot.dart';
import 'route_access.dart';
import 'route_paths.dart';

/// Owns the app's [GoRouter] instance and wires both [AuthSession] and
/// [PermissionsSnapshot] in as the `refreshListenable`, so a sign-in/out
/// OR a permission-set change instantly re-evaluates the guard.
///
/// **Route topology** (Slice 2.1.1):
/// - Top-level (no nav chrome): `/splash`, `/login`, `/mfa/otp` — pre-auth
///   takeovers.
/// - [StatefulShellRoute.indexedStack] hosting three sibling branches:
///   - **Home** branch: `/dashboard`, `/admin-demo`, `/forbidden` — the
///     forbidden page lives here so the bounce target keeps the shell
///     chrome and the user can recover via bottom nav.
///   - **Modules** branch: `/modules`.
///   - **Settings** branch: `/settings`.
///
/// The redirect rules live in [resolveAuthRedirect] (pure Dart) so they
/// can be unit-tested without Flutter. Permission lookups go through
/// [RouteAccess] (the location → required Permission table) and
/// [PermissionsSnapshot.holds] (the in-memory mirror of drift).
@lazySingleton
class AppRouter {
  AppRouter(AuthSession session, PermissionsSnapshot permissions)
      : config = _build(session, permissions);

  final GoRouter config;

  /// Slice 10.2.9 — handle on the root navigator GoRouter creates, so
  /// widgets that live OUTSIDE the router subtree (e.g. the
  /// [IncomingCallOverlay] mounted via `MaterialApp.builder`) can push
  /// full-screen routes without depending on `Navigator.of(context)`.
  /// Without this the accept-call button silently failed because the
  /// overlay's context had no Navigator ancestor — the router's
  /// Navigator was a sibling in the Stack, not above the overlay sheet.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

  static GoRouter _build(
    AuthSession session,
    PermissionsSnapshot permissions,
  ) =>
      GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: RoutePaths.splash,
        debugLogDiagnostics: kDebugMode,
        // Either signal triggers a redirect re-evaluation. Listenable.merge
        // keeps both subscriptions live for the router's lifetime; both
        // are app-scoped singletons so there's no leak risk on dispose.
        refreshListenable: Listenable.merge([session, permissions]),
        redirect: (context, state) {
          final required =
              RouteAccess.requiredFor(state.matchedLocation);
          final hasAccess =
              required == null || permissions.holds(required);
          return resolveAuthRedirect(
            matchedLocation: state.matchedLocation,
            isAuthenticated: session.isAuthenticated,
            hasRouteAccess: hasAccess,
          );
        },
        errorBuilder: (context, state) =>
            NotFoundPage(location: state.matchedLocation),
        routes: [
          // ── Pre-auth takeovers (no shell chrome) ─────────────────
          GoRoute(
            path: RoutePaths.splash,
            name: RoutePaths.splashName,
            builder: (_, __) => const SplashPage(),
          ),
          GoRoute(
            path: RoutePaths.login,
            name: RoutePaths.loginName,
            builder: (_, __) => LoginPage(
              // Placeholder wiring until the real AuthBloc lands: flipping
              // the stub auth session emits a listener notification, which
              // GoRouter picks up via `refreshListenable` and bounces to
              // /dashboard via the redirect policy. No `context.go` here.
              onSimulatedLogin: () async {
                // Slice 3.2.4 — write the demo user + finance.approve
                // permission BEFORE flipping the auth flag so the
                // permissions snapshot has a current user by the time
                // the redirect bounces us into the dashboard.
                await getIt<DemoSignInService>().seed();
                if (session is StubAuthSession) {
                  session.simulateSignIn();
                }
              },
            ),
          ),
          GoRoute(
            path: RoutePaths.otp,
            name: RoutePaths.otpName,
            builder: (_, __) => const OtpEntryPage(),
          ),
          GoRoute(
            path: RoutePaths.biometricUnlock,
            name: RoutePaths.biometricUnlockName,
            builder: (_, __) => const BiometricUnlockPage(),
          ),
          GoRoute(
            path: RoutePaths.forgotPassword,
            name: RoutePaths.forgotPasswordName,
            builder: (_, __) => const ForgotPasswordPage(),
          ),

          // ── Authenticated shell (bottom nav / rail / drawer) ─────
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              // Branch 0 — Home / Dashboard. Hosts /admin-demo and
              // /forbidden so they keep the chrome and the user can
              // recover via bottom nav after a permission bounce.
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.dashboard,
                    name: RoutePaths.dashboardName,
                    builder: (_, __) => const DashboardPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.adminDemo,
                    name: RoutePaths.adminDemoName,
                    builder: (_, __) => const AdminDemoPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.forbidden,
                    name: RoutePaths.forbiddenName,
                    builder: (_, state) => ForbiddenPage(
                      attemptedLocation: state.uri.queryParameters['from'],
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.notificationInbox,
                    name: RoutePaths.notificationInboxName,
                    builder: (_, __) => const NotificationInboxPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.search,
                    name: RoutePaths.searchName,
                    builder: (_, __) => const GlobalSearchPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.chartOfAccounts,
                    name: RoutePaths.chartOfAccountsName,
                    builder: (_, __) => const ChartOfAccountsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.accountDetail,
                    name: RoutePaths.accountDetailName,
                    builder: (_, state) => AccountDetailPage(
                      accountId: state.pathParameters[
                              RoutePaths.accountDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Phase 3.2 — invoices.
                  GoRoute(
                    path: RoutePaths.invoiceList,
                    name: RoutePaths.invoiceListName,
                    builder: (_, __) => const InvoiceListPage(),
                  ),
                  // /invoices/new — register BEFORE the :id route so
                  // go_router matches "new" as the literal first.
                  GoRoute(
                    path: RoutePaths.invoiceNew,
                    name: RoutePaths.invoiceNewName,
                    builder: (_, __) => const InvoiceFormPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.invoiceDetail,
                    name: RoutePaths.invoiceDetailName,
                    builder: (_, state) => InvoiceDetailPage(
                      invoiceId: state.pathParameters[
                              RoutePaths.invoiceDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.invoiceEdit,
                    name: RoutePaths.invoiceEditName,
                    builder: (_, state) => InvoiceFormPage(
                      invoiceId: state.pathParameters[
                          RoutePaths.invoiceDetailIdParam],
                    ),
                  ),
                  // Phase 3.3 — GL.
                  GoRoute(
                    path: RoutePaths.journalEntries,
                    name: RoutePaths.journalEntriesName,
                    builder: (_, __) => const JournalEntryListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.journalEntryDetail,
                    name: RoutePaths.journalEntryDetailName,
                    builder: (_, state) => JournalEntryDetailPage(
                      entryId: state.pathParameters[
                              RoutePaths.journalEntryDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.trialBalance,
                    name: RoutePaths.trialBalanceName,
                    builder: (_, __) => const TrialBalancePage(),
                  ),
                  // Procurement (Module 4) — Phase 4.1 PRs.
                  GoRoute(
                    path: RoutePaths.purchaseRequestList,
                    name: RoutePaths.purchaseRequestListName,
                    builder: (_, __) => const PurchaseRequestListPage(),
                  ),
                  // /procurement/purchase-requests/new — register BEFORE
                  // the :id route so go_router matches "new" as the literal.
                  GoRoute(
                    path: RoutePaths.purchaseRequestNew,
                    name: RoutePaths.purchaseRequestNewName,
                    builder: (_, __) => const PurchaseRequestFormPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.purchaseRequestDetail,
                    name: RoutePaths.purchaseRequestDetailName,
                    builder: (_, state) => PurchaseRequestDetailPage(
                      prId: state.pathParameters[
                              RoutePaths.purchaseRequestDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Phase 4.2 POs.
                  GoRoute(
                    path: RoutePaths.purchaseOrderList,
                    name: RoutePaths.purchaseOrderListName,
                    builder: (_, __) => const PurchaseOrderListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.purchaseOrderDetail,
                    name: RoutePaths.purchaseOrderDetailName,
                    builder: (_, state) => PurchaseOrderDetailPage(
                      poId: state.pathParameters[
                              RoutePaths.purchaseOrderDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.goodsReceiptNew,
                    name: RoutePaths.goodsReceiptNewName,
                    builder: (_, state) => GoodsReceiptFormPage(
                      purchaseOrderId: state.pathParameters[
                              RoutePaths.goodsReceiptPoIdParam] ??
                          '',
                    ),
                  ),
                  // Phase 4.3 Vendors.
                  GoRoute(
                    path: RoutePaths.vendorList,
                    name: RoutePaths.vendorListName,
                    builder: (_, __) => const VendorListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.vendorNew,
                    name: RoutePaths.vendorNewName,
                    builder: (_, __) => const VendorFormPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.vendorDetail,
                    name: RoutePaths.vendorDetailName,
                    builder: (_, state) => VendorDetailPage(
                      vendorId: state.pathParameters[
                              RoutePaths.vendorDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.vendorScorecard,
                    name: RoutePaths.vendorScorecardName,
                    builder: (_, state) => VendorScorecardPage(
                      vendorId: state.pathParameters[
                              RoutePaths.vendorScorecardIdParam] ??
                          '',
                    ),
                  ),
                  // Sales & CRM (Module 6) — Phase 6.1 customers.
                  GoRoute(
                    path: RoutePaths.salesCustomers,
                    name: RoutePaths.salesCustomersName,
                    builder: (_, __) => const CustomerListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.salesAnalytics,
                    name: RoutePaths.salesAnalyticsName,
                    builder: (_, __) => const SalesAnalyticsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.salesCustomerDetail,
                    name: RoutePaths.salesCustomerDetailName,
                    builder: (_, state) => CustomerDetailPage(
                      customerId: state.pathParameters[
                              RoutePaths.salesCustomerDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.salesContactNew,
                    name: RoutePaths.salesContactNewName,
                    builder: (_, state) => ContactFormPage(
                      customerId: state.pathParameters[
                              RoutePaths.salesCustomerDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.salesContactEdit,
                    name: RoutePaths.salesContactEditName,
                    builder: (_, state) => ContactFormPage(
                      customerId: state.pathParameters[
                              RoutePaths.salesCustomerDetailIdParam] ??
                          '',
                      initial: state.extra as CustomerContact?,
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.salesActivityNew,
                    name: RoutePaths.salesActivityNewName,
                    builder: (_, state) => ActivityFormPage(
                      customerId: state.pathParameters[
                              RoutePaths.salesCustomerDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Phase 6.2 — quotations + sales orders.
                  GoRoute(
                    path: RoutePaths.salesQuotationList,
                    name: RoutePaths.salesQuotationListName,
                    builder: (_, __) => const QuotationListPage(),
                  ),
                  // Register the literal `/new` BEFORE the `:id` route.
                  GoRoute(
                    path: RoutePaths.salesQuotationNew,
                    name: RoutePaths.salesQuotationNewName,
                    builder: (_, __) => const QuotationFormPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.salesQuotationDetail,
                    name: RoutePaths.salesQuotationDetailName,
                    builder: (_, state) => QuotationDetailPage(
                      quotationId: state.pathParameters[
                              RoutePaths.salesQuotationDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.salesOrderList,
                    name: RoutePaths.salesOrderListName,
                    builder: (_, __) => const SalesOrderListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.salesOrderDetail,
                    name: RoutePaths.salesOrderDetailName,
                    builder: (_, state) => SalesOrderDetailPage(
                      orderId: state.pathParameters[
                              RoutePaths.salesOrderDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Inventory (Module 5) — Phase 5.1 catalog + alerts.
                  GoRoute(
                    path: RoutePaths.inventoryItems,
                    name: RoutePaths.inventoryItemsName,
                    builder: (_, __) => const ItemsListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryScanner,
                    name: RoutePaths.inventoryScannerName,
                    builder: (_, __) => const ScannerPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryLowStock,
                    name: RoutePaths.inventoryLowStockName,
                    builder: (_, __) => const LowStockAlertsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryCycleCount,
                    name: RoutePaths.inventoryCycleCountName,
                    builder: (_, __) => const CycleCountPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryItemDetail,
                    name: RoutePaths.inventoryItemDetailName,
                    builder: (_, state) => ItemDetailPage(
                      itemId: state.pathParameters[
                              RoutePaths.inventoryItemDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryGoodsIssue,
                    name: RoutePaths.inventoryGoodsIssueName,
                    builder: (_, state) => StockMovementFormPage(
                      itemId: state.pathParameters[
                              RoutePaths.inventoryItemDetailIdParam] ??
                          '',
                      type: StockMovementType.issue,
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryGoodsReceipt,
                    name: RoutePaths.inventoryGoodsReceiptName,
                    builder: (_, state) => StockMovementFormPage(
                      itemId: state.pathParameters[
                              RoutePaths.inventoryItemDetailIdParam] ??
                          '',
                      type: StockMovementType.receipt,
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.inventoryTransfer,
                    name: RoutePaths.inventoryTransferName,
                    builder: (_, state) => StockTransferPage(
                      sourceItemId: state.pathParameters[
                              RoutePaths.inventoryItemDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Human Resources (Module 7) — Phase 7.1 employees.
                  GoRoute(
                    path: RoutePaths.hrEmployees,
                    name: RoutePaths.hrEmployeesName,
                    builder: (_, __) => const EmployeeListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.hrOrgChart,
                    name: RoutePaths.hrOrgChartName,
                    builder: (_, __) => const OrgChartPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.hrEmployeeDetail,
                    name: RoutePaths.hrEmployeeDetailName,
                    builder: (_, state) => EmployeeDetailPage(
                      employeeId: state.pathParameters[
                              RoutePaths.hrEmployeeDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Phase 7.2 — Leave management. Register `/new`
                  // BEFORE the dynamic detail route so go_router matches
                  // "new" as the literal path first.
                  GoRoute(
                    path: RoutePaths.hrLeaveRequestNew,
                    name: RoutePaths.hrLeaveRequestNewName,
                    builder: (_, __) => const LeaveRequestFormPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.hrLeaveRequests,
                    name: RoutePaths.hrLeaveRequestsName,
                    builder: (_, __) => const LeaveRequestsListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.hrLeaveBalance,
                    name: RoutePaths.hrLeaveBalanceName,
                    builder: (_, __) => const LeaveBalancePage(),
                  ),
                  // Phase 7.3 — Attendance + payslips.
                  GoRoute(
                    path: RoutePaths.hrAttendance,
                    name: RoutePaths.hrAttendanceName,
                    builder: (_, __) => const AttendancePage(),
                  ),
                  GoRoute(
                    path: RoutePaths.hrPayslips,
                    name: RoutePaths.hrPayslipsName,
                    builder: (_, __) => const PayslipsListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.hrPayslipDetail,
                    name: RoutePaths.hrPayslipDetailName,
                    builder: (_, state) => PayslipDetailPage(
                      payslipId: state.pathParameters[
                              RoutePaths.hrPayslipDetailIdParam] ??
                          '',
                    ),
                  ),
                  // Project Management (Module 8) — Phase 8.1 projects + tasks.
                  GoRoute(
                    path: RoutePaths.projectList,
                    name: RoutePaths.projectListName,
                    builder: (_, __) => const ProjectListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.projectDetail,
                    name: RoutePaths.projectDetailName,
                    builder: (_, state) => ProjectDetailPage(
                      projectId: state.pathParameters[
                              RoutePaths.projectDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.projectBoard,
                    name: RoutePaths.projectBoardName,
                    builder: (_, state) => ProjectBoardPage(
                      projectId: state.pathParameters[
                              RoutePaths.projectDetailIdParam] ??
                          '',
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.taskDetail,
                    name: RoutePaths.taskDetailName,
                    builder: (_, state) => TaskDetailPage(
                      taskId: state.pathParameters[
                              RoutePaths.taskDetailTaskIdParam] ??
                          '',
                    ),
                  ),
                  // Phase 8.2 — Timesheets. `/new` registered BEFORE
                  // any dynamic routes so go_router prefers literal.
                  GoRoute(
                    path: RoutePaths.timesheetNew,
                    name: RoutePaths.timesheetNewName,
                    builder: (_, __) => const TimesheetFormPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.timesheets,
                    name: RoutePaths.timesheetsName,
                    builder: (_, __) => const TimesheetsListPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.timesheetUtilization,
                    name: RoutePaths.timesheetUtilizationName,
                    builder: (_, __) => const UtilizationPage(),
                  ),
                ],
              ),
              // Branch 1 — Modules. Hosts the permission-filtered shortcut
              // grid (Slice 2.1.2) and the shared `/coming-soon/:label`
              // landing for tiles whose feature module hasn't shipped.
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.modules,
                    name: RoutePaths.modulesName,
                    builder: (_, __) => const ModulesPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.comingSoon,
                    name: RoutePaths.comingSoonName,
                    builder: (_, state) => ComingSoonPage(
                      moduleLabel: state.pathParameters[
                              RoutePaths.comingSoonLabelParam] ??
                          '',
                    ),
                  ),
                ],
              ),
              // Branch 2 — Settings (Module 9). Hosts the settings hub
              // and all 9 sub-pages so they all live under the Settings
              // shell branch and the bottom nav stays on Settings while
              // the user drills down.
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.settings,
                    name: RoutePaths.settingsName,
                    builder: (_, __) => SettingsHomePage(
                      // Full sign-out via AuthRepository — revokes the
                      // refresh token server-side, clears
                      // flutter_secure_storage, wipes the cached user from
                      // drift, then SessionSignal.invalidate() flips the
                      // AuthSession bool and the router bounces to /login.
                      // Using `session.signOut()` here would only flip the
                      // stub's bool and leave tokens + cache on the device.
                      onSignOut: () => getIt<AuthRepository>().signOut(),
                    ),
                  ),
                  // Phase 9.1 — preferences.
                  GoRoute(
                    path: RoutePaths.settingsAppearance,
                    name: RoutePaths.settingsAppearanceName,
                    builder: (_, __) => const AppearancePage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsLanguage,
                    name: RoutePaths.settingsLanguageName,
                    builder: (_, __) => const LanguagePage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsNotifications,
                    name: RoutePaths.settingsNotificationsName,
                    builder: (_, __) => const NotificationPreferencesPage(),
                  ),
                  // Phase 9.2 — admin.
                  GoRoute(
                    path: RoutePaths.settingsUsers,
                    name: RoutePaths.settingsUsersName,
                    builder: (_, __) => const UserManagementPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsRoles,
                    name: RoutePaths.settingsRolesName,
                    builder: (_, __) => const RoleEditorPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsAssignments,
                    name: RoutePaths.settingsAssignmentsName,
                    builder: (_, __) => const AssignmentsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsApiConfig,
                    name: RoutePaths.settingsApiConfigName,
                    builder: (_, __) => const ApiConfigPage(),
                  ),
                  // Phase 9.3 — security.
                  GoRoute(
                    path: RoutePaths.settingsSessions,
                    name: RoutePaths.settingsSessionsName,
                    builder: (_, __) => const SessionsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsAuditLog,
                    name: RoutePaths.settingsAuditLogName,
                    builder: (_, __) => const AuditLogPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsAppLock,
                    name: RoutePaths.settingsAppLockName,
                    builder: (_, __) => const AppLockPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}
