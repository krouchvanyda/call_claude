/// Centralised route path & name registry.
///
/// Keeping these as compile-time constants (instead of magic strings sprinkled
/// across pages) gives us refactor safety and a single audit point for the URL
/// surface area. Names are used for `context.goNamed(...)` / `pushNamed(...)`;
/// paths are used for the URL.
abstract final class RoutePaths {
  // Bootstrap / shell ────────────────────────────────────────────
  static const splash = '/';
  static const splashName = 'splash';

  // Auth (Module 1) ──────────────────────────────────────────────
  static const login = '/login';
  static const loginName = 'login';

  // MFA (Phase 1.2) ──────────────────────────────────────────────
  /// OTP / TOTP entry — the multi-step auth flow lands here after the
  /// password step when the server reports an MFA challenge.
  static const otp = '/mfa/otp';
  static const otpName = 'otp';

  // Biometric & Recovery (Phase 1.2) ─────────────────────────────
  static const biometricUnlock = '/biometric-unlock';
  static const biometricUnlockName = 'biometricUnlock';

  static const forgotPassword = '/forgot-password';
  static const forgotPasswordName = 'forgotPassword';

  // Dashboard (Module 2) ─────────────────────────────────────────
  static const dashboard = '/dashboard';
  static const dashboardName = 'dashboard';

  static const search = '/search';
  static const searchName = 'search';

  // Shell siblings of the dashboard (Slice 2.1.1). Each is the root of
  // a `StatefulShellRoute` branch — the bottom nav / rail / drawer
  // switches between them while preserving each branch's own
  // navigation stack.
  static const modules = '/modules';
  static const modulesName = 'modules';

  static const settings = '/settings';
  static const settingsName = 'settings';

  // Generic "coming soon" landing for Slice 2.1.2 module shortcut tiles
  // whose real feature module hasn't shipped yet. The `:label` param is
  // the human-readable module name (already localised by the catalog),
  // so the page itself has no per-module copy.
  static const comingSoon = '/coming-soon/:label';
  static const comingSoonName = 'comingSoon';
  static const comingSoonLabelParam = 'label';

  // Notification inbox (Slice 2.3.3) — full-screen list reached from
  // the AppBar bell badge. Lives in the Home shell branch so the
  // bottom nav / rail stays visible and the user can swap tabs
  // without losing inbox state.
  static const notificationInbox = '/notifications';
  static const notificationInboxName = 'notificationInbox';

  // Finance — Chart of Accounts (Slice 3.1.1). Lives under /finance/*
  // so future Module 3 routes (account detail, GL, AP/AR) share the
  // prefix. Inside the Home shell branch for now; Module 3 may get
  // its own branch when its surface area justifies one.
  static const chartOfAccounts = '/finance/accounts';
  static const chartOfAccountsName = 'chartOfAccounts';

  // Finance — Account detail + transactions (Slice 3.1.2). Path param
  // is the Account.id; reached by tapping a leaf row in the chart-of-
  // accounts tree.
  static const accountDetail = '/finance/accounts/:id';
  static const accountDetailName = 'accountDetail';
  static const accountDetailIdParam = 'id';

  // Finance — Invoices (Phase 3.2).
  static const invoiceList = '/finance/invoices';
  static const invoiceListName = 'invoiceList';

  static const invoiceNew = '/finance/invoices/new';
  static const invoiceNewName = 'invoiceNew';

  /// Slice 3.2.2 — invoice detail; `:id` is the Invoice.id.
  static const invoiceDetail = '/finance/invoices/:id';
  static const invoiceDetailName = 'invoiceDetail';
  static const invoiceDetailIdParam = 'id';

  /// Slice 3.2.3 — edit existing invoice.
  static const invoiceEdit = '/finance/invoices/:id/edit';
  static const invoiceEditName = 'invoiceEdit';

  // Finance — General Ledger (Phase 3.3).
  static const journalEntries = '/finance/gl/journal-entries';
  static const journalEntriesName = 'journalEntries';

  static const journalEntryDetail = '/finance/gl/journal-entries/:id';
  static const journalEntryDetailName = 'journalEntryDetail';
  static const journalEntryDetailIdParam = 'id';

  static const trialBalance = '/finance/gl/trial-balance';
  static const trialBalanceName = 'trialBalance';

  // Sales & CRM (Module 6) ─────────────────────────────────────
  // Phase 6.1 — Customers + contacts + activity timeline.
  static const salesCustomers = '/sales/customers';
  static const salesCustomersName = 'salesCustomers';

  static const salesCustomerDetail = '/sales/customers/:id';
  static const salesCustomerDetailName = 'salesCustomerDetail';
  static const salesCustomerDetailIdParam = 'id';

  static const salesContactNew = '/sales/customers/:id/contacts/new';
  static const salesContactNewName = 'salesContactNew';

  static const salesContactEdit = '/sales/customers/:id/contacts/:contactId';
  static const salesContactEditName = 'salesContactEdit';
  static const salesContactIdParam = 'contactId';

  static const salesActivityNew = '/sales/customers/:id/activities/new';
  static const salesActivityNewName = 'salesActivityNew';

  // Phase 6.2 — Quotations + sales orders.
  static const salesQuotationList = '/sales/quotations';
  static const salesQuotationListName = 'salesQuotationList';

  /// Register the literal `/new` BEFORE the `:id` route so go_router
  /// matches "new" as the literal first.
  static const salesQuotationNew = '/sales/quotations/new';
  static const salesQuotationNewName = 'salesQuotationNew';

  static const salesQuotationDetail = '/sales/quotations/:id';
  static const salesQuotationDetailName = 'salesQuotationDetail';
  static const salesQuotationDetailIdParam = 'id';

  static const salesOrderList = '/sales/orders';
  static const salesOrderListName = 'salesOrderList';

  static const salesOrderDetail = '/sales/orders/:id';
  static const salesOrderDetailName = 'salesOrderDetail';
  static const salesOrderDetailIdParam = 'id';

  // Phase 6.3 — Analytics (revenue chart + top rankings + leaderboard).
  static const salesAnalytics = '/sales/analytics';
  static const salesAnalyticsName = 'salesAnalytics';

  // Inventory (Module 5) ────────────────────────────────────────
  static const inventoryItems = '/inventory/items';
  static const inventoryItemsName = 'inventoryItems';

  static const inventoryItemDetail = '/inventory/items/:id';
  static const inventoryItemDetailName = 'inventoryItemDetail';
  static const inventoryItemDetailIdParam = 'id';

  static const inventoryGoodsIssue = '/inventory/items/:id/issue';
  static const inventoryGoodsIssueName = 'inventoryGoodsIssue';

  static const inventoryGoodsReceipt = '/inventory/items/:id/receipt';
  static const inventoryGoodsReceiptName = 'inventoryGoodsReceipt';

  static const inventoryTransfer = '/inventory/items/:id/transfer';
  static const inventoryTransferName = 'inventoryTransfer';

  static const inventoryScanner = '/inventory/scan';
  static const inventoryScannerName = 'inventoryScanner';

  static const inventoryLowStock = '/inventory/alerts';
  static const inventoryLowStockName = 'inventoryLowStock';

  static const inventoryCycleCount = '/inventory/cycle-count';
  static const inventoryCycleCountName = 'inventoryCycleCount';

  // Procurement (Module 4) ─────────────────────────────────────
  // Phase 4.1 — Purchase requests.
  static const purchaseRequestList = '/procurement/purchase-requests';
  static const purchaseRequestListName = 'purchaseRequestList';

  /// Slice 4.1.2 — register BEFORE the `:id` route so go_router matches
  /// the literal "new" first.
  static const purchaseRequestNew = '/procurement/purchase-requests/new';
  static const purchaseRequestNewName = 'purchaseRequestNew';

  /// Slice 4.1.3 — PR detail; `:id` is the PurchaseRequest.id.
  static const purchaseRequestDetail = '/procurement/purchase-requests/:id';
  static const purchaseRequestDetailName = 'purchaseRequestDetail';
  static const purchaseRequestDetailIdParam = 'id';

  // Phase 4.2 — Purchase orders.
  static const purchaseOrderList = '/procurement/purchase-orders';
  static const purchaseOrderListName = 'purchaseOrderList';

  static const purchaseOrderDetail = '/procurement/purchase-orders/:id';
  static const purchaseOrderDetailName = 'purchaseOrderDetail';
  static const purchaseOrderDetailIdParam = 'id';

  /// Slice 4.2.3 — goods receipt entry; `:poId` is the parent PO.
  static const goodsReceiptNew =
      '/procurement/purchase-orders/:poId/receipts/new';
  static const goodsReceiptNewName = 'goodsReceiptNew';
  static const goodsReceiptPoIdParam = 'poId';

  // Phase 4.3 — Vendors.
  static const vendorList = '/procurement/vendors';
  static const vendorListName = 'vendorList';

  static const vendorNew = '/procurement/vendors/new';
  static const vendorNewName = 'vendorNew';

  static const vendorDetail = '/procurement/vendors/:id';
  static const vendorDetailName = 'vendorDetail';
  static const vendorDetailIdParam = 'id';

  /// Slice 4.3.3 — performance scorecard; `:id` is the Vendor.id.
  static const vendorScorecard = '/procurement/vendors/:id/scorecard';
  static const vendorScorecardName = 'vendorScorecard';
  static const vendorScorecardIdParam = 'id';

  // Human Resources (Module 7) ─────────────────────────────────
  // Phase 7.1 — Employee directory + org chart.
  static const hrEmployees = '/hr/employees';
  static const hrEmployeesName = 'hrEmployees';

  static const hrEmployeeDetail = '/hr/employees/:id';
  static const hrEmployeeDetailName = 'hrEmployeeDetail';
  static const hrEmployeeDetailIdParam = 'id';

  static const hrOrgChart = '/hr/org-chart';
  static const hrOrgChartName = 'hrOrgChart';

  // Phase 7.2 — Leave management.
  static const hrLeaveRequests = '/hr/leave-requests';
  static const hrLeaveRequestsName = 'hrLeaveRequests';

  /// Register the literal `/new` BEFORE the `:id` route so go_router
  /// matches "new" as the literal first.
  static const hrLeaveRequestNew = '/hr/leave-requests/new';
  static const hrLeaveRequestNewName = 'hrLeaveRequestNew';

  static const hrLeaveBalance = '/hr/leave-balance';
  static const hrLeaveBalanceName = 'hrLeaveBalance';

  // Phase 7.3 — Attendance + payslips.
  static const hrAttendance = '/hr/attendance';
  static const hrAttendanceName = 'hrAttendance';

  static const hrPayslips = '/hr/payslips';
  static const hrPayslipsName = 'hrPayslips';

  static const hrPayslipDetail = '/hr/payslips/:id';
  static const hrPayslipDetailName = 'hrPayslipDetail';
  static const hrPayslipDetailIdParam = 'id';

  // Project Management (Module 8) ─────────────────────────────
  // Phase 8.1 — Projects + tasks.
  static const projectList = '/projects';
  static const projectListName = 'projectList';

  static const projectDetail = '/projects/:id';
  static const projectDetailName = 'projectDetail';
  static const projectDetailIdParam = 'id';

  /// Slice 8.1.2 — Kanban board scoped to a project.
  static const projectBoard = '/projects/:id/board';
  static const projectBoardName = 'projectBoard';

  /// Slice 8.1.3 — task detail + comments.
  static const taskDetail = '/projects/:id/tasks/:taskId';
  static const taskDetailName = 'taskDetail';
  static const taskDetailTaskIdParam = 'taskId';

  // Phase 8.2 — Timesheets.
  static const timesheets = '/timesheets';
  static const timesheetsName = 'timesheets';

  /// Register the literal `/new` BEFORE the `:id` route so go_router
  /// matches "new" as the literal first.
  static const timesheetNew = '/timesheets/new';
  static const timesheetNewName = 'timesheetNew';

  static const timesheetApprovals = '/timesheets/approvals';
  static const timesheetApprovalsName = 'timesheetApprovals';

  static const timesheetUtilization = '/timesheets/utilization';
  static const timesheetUtilizationName = 'timesheetUtilization';

  // Settings & Administration (Module 9) ──────────────────────
  // Phase 9.1 — User preferences.
  static const settingsAppearance = '/settings/appearance';
  static const settingsAppearanceName = 'settingsAppearance';

  static const settingsLanguage = '/settings/language';
  static const settingsLanguageName = 'settingsLanguage';

  static const settingsNotifications = '/settings/notifications';
  static const settingsNotificationsName = 'settingsNotifications';

  // Phase 9.2 — Admin (RBAC-gated).
  static const settingsUsers = '/settings/users';
  static const settingsUsersName = 'settingsUsers';

  static const settingsRoles = '/settings/roles';
  static const settingsRolesName = 'settingsRoles';

  static const settingsAssignments = '/settings/assignments';
  static const settingsAssignmentsName = 'settingsAssignments';

  static const settingsApiConfig = '/settings/api-config';
  static const settingsApiConfigName = 'settingsApiConfig';

  // Phase 9.3 — Security.
  static const settingsSessions = '/settings/sessions';
  static const settingsSessionsName = 'settingsSessions';

  static const settingsAuditLog = '/settings/audit-log';
  static const settingsAuditLogName = 'settingsAuditLog';

  static const settingsAppLock = '/settings/app-lock';
  static const settingsAppLockName = 'settingsAppLock';

  // Permission-gated demo route (Slice 1.3.2 — exists so the route
  // guard's "no access → /forbidden" branch is end-to-end demoable
  // before feature modules add their own gated routes).
  static const adminDemo = '/admin-demo';
  static const adminDemoName = 'adminDemo';

  // Forbidden — landing for an authenticated user who lacks the
  // required permission for the route they tried to reach.
  static const forbidden = '/forbidden';
  static const forbiddenName = 'forbidden';

  // Catch-all ────────────────────────────────────────────────────
  static const notFoundName = 'notFound';

  /// Locations the router considers "public" — reachable without an
  /// authenticated [AuthSession]. The OTP page is included because the
  /// user is *mid-challenge* at that point (credentials submitted, no
  /// session token yet); the auth guard would otherwise bounce them to
  /// `/login` and lose the challenge context.
  static const publicLocations = <String>{splash, login, otp, forgotPassword, biometricUnlock};
}
