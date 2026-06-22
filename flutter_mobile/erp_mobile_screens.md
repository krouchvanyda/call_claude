# Enterprise ERP Mobile — Screen Inventory

> Full detail: screen name · route path · complexity · key widgets · BLoC · drift tables

### Complexity Legend
| Rating | Meaning |
|---|---|
| **S** | Simple — single BLoC, 1–3 widgets, straightforward read/display |
| **M** | Medium — multiple widgets, form validation or list + detail, 1–2 BLoCs |
| **L** | Large — complex state machine, custom painter, multi-BLoC, offline sync, or workflow logic |

---

## MODULE 0 — App Entry

---

### Screen 0.1 — Splash Screen
- Add Color to singleton
- Add Font size to singleton
- Custom text to AppLabel
- **Route:** `/` (initial route, replaced immediately after init)
- **Complexity:** M
- **Widgets:**
  - `AnimatedLogo` — company/app logo with fade-in or scale animation
  - `AppVersionText` — version number, bottom of screen
  - `LoadingIndicator` — subtle linear or circular progress shown during init checks
- **BLoC:** `AppInitBLoC`
  - Events: `AppStarted`
  - States: `AppInitLoading` → `AppInitAuthenticated` / `AppInitUnauthenticated` / `AppInitLocked`
  - On `AppStarted`:
    1. Check `flutter_secure_storage` for existing tokens
    2. Read `cached_user` from drift — if present and TTL valid, user is known
    3. Read `biometric_on` flag from drift
    4. Decide redirect:
       - No token → `/login`
       - Token + `biometric_on = true` + app was backgrounded → `/biometric-unlock`
       - Token + PIN lock policy triggered → `/lock`
       - Token valid + no lock required → `/dashboard`
- **drift tables:** `cached_user` (read id, biometric_on, last_login_at, cached_at for TTL check)
- **Notes:**
  - Splash is the **only screen with no back navigation** — always replaced, never pushed
  - All app-level init (DI warm-up, DB migration check, connectivity check) runs here via `AppInitBLoC`
  - Keep animation under 1.5s; do not block on network calls — use only local drift + secure storage reads
  - If drift migration is needed on upgrade, show a `MigratingDatabaseText` instead of version text

---

## MODULE 1 — Authentication & Identity

---

### Screen 1.1 — Login
- **Route:** `/login`
- **Complexity:** M
- **Widgets:**
  - `EmailField` — text input with email validator (`FormBLoC`)
  - `PasswordField` — obscured input with toggle visibility
  - `LoginButton` — disabled until form valid; shows `CircularProgressIndicator` on loading
  - `BiometricLoginButton` — visible only if `cached_user.biometric_on = true`
  - `ForgotPasswordLink` — navigates to `/forgot-password`
- **BLoC:** `AuthBLoC`
  - Event: `LoginSubmitted(email, password)`
  - States: `AuthInitial` → `AuthLoading` → `AuthSuccess` / `AuthFailure`
  - On success → `go_router` redirects to `/dashboard`
- **drift tables:** `cached_user` (read `biometric_on` flag on screen init)

---

### Screen 1.2 — Biometric Unlock
- **Route:** `/biometric-unlock`
- **Complexity:** S
- **Widgets:**
  - `FingerprintIcon` / `FaceIDIcon` — platform-adaptive
  - `UnlockPromptText` — "Use biometric to continue"
  - `UsePasswordFallbackButton` → navigates to `/login`
- **BLoC:** `BiometricBLoC`
  - Event: `BiometricRequested`
  - States: `BiometricPrompting` → `BiometricSuccess` / `BiometricFailure`
- **drift tables:** `cached_user` (read `biometric_on`, `last_login_at`)

---

### Screen 1.3 — OTP / MFA Verification
- **Route:** `/mfa`
- **Complexity:** M
- **Widgets:**
  - `OtpInputRow` — 6-digit segmented input
  - `ResendCodeButton` — with cooldown timer (30s)
  - `VerifyButton`
- **BLoC:** `MfaBLoC`
  - Event: `OtpSubmitted(code)`
  - States: `MfaInitial` → `MfaLoading` → `MfaSuccess` / `MfaFailure`
- **drift tables:** none — OTP is memory only (ephemeral)

---

### Screen 1.4 — Forgot Password
- **Route:** `/forgot-password`
- **Complexity:** S
- **Widgets:**
  - `EmailField`
  - `SendResetButton`
  - `BackToLoginLink`
- **BLoC:** `ForgotPasswordBLoC`
  - Event: `ResetRequested(email)`
  - States: `ForgotPasswordInitial` → `ForgotPasswordLoading` → `ForgotPasswordSent` / `ForgotPasswordFailure`
- **drift tables:** none

---

## MODULE 2 — Dashboard & Home

---

### Screen 2.1 — Dashboard Home
- **Route:** `/dashboard`
- **Complexity:** L
- **Widgets:**
  - `AppShell` — bottom nav bar (mobile) / side drawer (tablet); permission-filtered module tiles
  - `KpiCardGrid` — configurable grid of `KpiCard` widgets (value, trend arrow, sparkline via `fl_chart`)
  - `SyncStatusBanner` — visible when `SyncStatusBLoC` emits `SyncPending` or `SyncFailed`
  - `NotificationBadge` — icon button with unread count from drift
  - `GlobalSearchBar` → navigates to `/search`
- **BLoC:**
  - `KpiBLoC` — Event: `KpiRefreshRequested`; streams from `KpiRepository` (WebSocket + drift fallback)
  - `SyncStatusBLoC` — listens to sync engine; emits `SyncIdle` / `SyncPending` / `SyncFailed`
  - `NotificationBadgeBLoC` — Event: `BadgeRefreshRequested`; reads unread count from drift
- **drift tables:** `cached_kpi`, `cached_dashboard_layout`, `cached_notifications` (unread count)

---

### Screen 2.2 — Global Search
- **Route:** `/search`
- **Complexity:** M
- **Widgets:**
  - `SearchTextField` — autofocus on open
  - `SearchResultList` — federated results grouped by module (Finance, Inventory, HR…)
  - `SearchResultTile` — icon + title + subtitle + deep-link tap
  - `RecentSearchesRow` — last 5 queries from memory
- **BLoC:** `GlobalSearchBLoC`
  - Event: `SearchQueryChanged(query)`
  - States: `SearchInitial` → `SearchLoading` → `SearchResults(results)` / `SearchEmpty`
- **drift tables:** none (search hits remote API; results not cached)

---

### Screen 2.3 — Notification Center
- **Route:** `/notifications`
- **Complexity:** M
- **Widgets:**
  - `NotificationList` — `ListView` of `NotificationTile` (type icon, title, body, time, read/unread dot)
  - `MarkAllReadButton`
  - `EmptyNotificationsIllustration` — shown when list is empty
- **BLoC:** `NotificationBLoC`
  - Events: `NotificationsLoaded`, `NotificationMarkedRead(id)`, `AllNotificationsMarkedRead`
  - States: `NotificationInitial` → `NotificationLoaded(list)` / `NotificationEmpty`
- **drift tables:** `cached_notifications` (read, update `is_read`)

---

## MODULE 3 — Finance & Accounting

---

### Screen 3.1 — Chart of Accounts
- **Route:** `/finance/accounts`
- **Complexity:** M
- **Widgets:**
  - `AccountTreeView` — expandable/collapsible hierarchical `ListView`
  - `AccountSearchBar` — filters tree inline
  - `AccountTypeBadge` — Asset / Liability / Equity / Revenue / Expense chip
- **BLoC:** `ChartOfAccountsBLoC`
  - Event: `AccountsLoaded`, `AccountNodeExpanded(id)`
  - States: `AccountsLoading` → `AccountsLoaded(tree)` / `AccountsFailure`
- **drift tables:** `cached_accounts` (id, parent_id, name, type, cached_at)

---

### Screen 3.2 — Account Detail
- **Route:** `/finance/accounts/:id`
- **Complexity:** M
- **Widgets:**
  - `AccountHeaderCard` — name, code, type, balance
  - `TransactionList` — paginated `ListView` of `TransactionTile`
  - `DateRangeFilter` — picker to filter transactions
- **BLoC:** `AccountDetailBLoC`
  - Event: `AccountDetailLoaded(id)`, `DateRangeChanged(from, to)`
  - States: `AccountDetailLoading` → `AccountDetailLoaded` / `AccountDetailFailure`
- **drift tables:** `cached_accounts`, `cached_transactions`

---

### Screen 3.3 — Invoice List
- **Route:** `/finance/invoices`
- **Complexity:** M
- **Widgets:**
  - `InvoiceFilterBar` — status chips (All / Draft / Pending / Approved / Rejected)
  - `InvoiceSearchBar`
  - `InvoiceSortDropdown` — date, amount, status
  - `InvoiceList` — `ListView` of `InvoiceTile` (number, vendor/customer, amount, status chip)
  - `FAB` — create new invoice → `/finance/invoices/new`
- **BLoC:** `InvoiceListBLoC`
  - Events: `InvoicesLoaded`, `InvoiceFilterChanged(status)`, `InvoiceSortChanged(field)`
  - States: `InvoiceListLoading` → `InvoiceListLoaded(list)` / `InvoiceListFailure`
- **drift tables:** `cached_invoices`

---

### Screen 3.4 — Invoice Detail
- **Route:** `/finance/invoices/:id`
- **Complexity:** L
- **Widgets:**
  - `InvoiceHeaderCard` — number, date, due date, vendor/customer, amount
  - `InvoiceStatusChip` — DRAFT / PENDING_APPROVAL / APPROVED / REJECTED
  - `InvoiceLineItemsTable`
  - `PdfPreviewButton` → opens PDF viewer
  - `ApproveButton` + `RejectButton` — wrapped in `PermissionGuard(scope: 'finance.approve')`; disabled when status is terminal
  - `RejectBottomSheet` — appears on reject tap; contains `ReasonTextField` (`FormBLoC`)
  - `ConfirmApproveBottomSheet` — appears on approve tap
- **BLoC:**
  - `InvoiceDetailBLoC` — Event: `InvoiceDetailLoaded(id)`
  - `InvoiceActionBLoC` — Events: `InvoiceApproved(id)` / `InvoiceRejected(id, reason)`; States: `InvoiceActionLoading` → `InvoiceActionSuccess` / `InvoiceActionFailure`
- **drift tables:** `cached_invoices` (status, approved_by, rejected_reason, actioned_at)

---

### Screen 3.5 — Create / Edit Invoice
- **Route:** `/finance/invoices/new` · `/finance/invoices/:id/edit`
- **Complexity:** L
- **Widgets:**
  - `VendorCustomerPicker` — searchable dropdown
  - `DatePickerField` — invoice date + due date
  - `LineItemsFormList` — dynamic add/remove rows (description, qty, unit price, tax)
  - `TotalSummaryRow` — subtotal, tax, total (computed live)
  - `SaveDraftButton` + `SubmitForApprovalButton`
- **BLoC:** `InvoiceFormBLoC`
  - Events: `FieldChanged(field, value)`, `LineItemAdded`, `LineItemRemoved(index)`, `InvoiceSaved`, `InvoiceSubmitted`
  - States: `InvoiceFormInitial` → `InvoiceFormValid` / `InvoiceFormInvalid` / `InvoiceFormSaving` / `InvoiceFormSuccess`
- **drift tables:** `cached_invoices` (upsert on save draft)

---

### Screen 3.6 — Journal Entry List
- **Route:** `/finance/journal`
- **Complexity:** S
- **Widgets:**
  - `JournalEntryList` — `ListView` of `JournalEntryTile` (date, reference, debit/credit totals)
  - `DateRangeFilter`
- **BLoC:** `JournalBLoC`
  - Event: `JournalEntriesLoaded`, `DateRangeChanged`
  - States: `JournalLoading` → `JournalLoaded(list)` / `JournalFailure`
- **drift tables:** `cached_journal_entries`

---

### Screen 3.7 — Trial Balance Report
- **Route:** `/finance/trial-balance`
- **Complexity:** M
- **Widgets:**
  - `PeriodSelector` — month/year picker
  - `TrialBalanceTable` — paginated, account name + debit + credit columns
  - `ExportCsvButton` — triggers `dart:io` CSV export
- **BLoC:** `TrialBalanceBLoC`
  - Event: `TrialBalanceLoaded(period)`
  - States: `TrialBalanceLoading` → `TrialBalanceLoaded(rows)` / `TrialBalanceFailure`
- **drift tables:** `cached_trial_balance`

---

## MODULE 4 — Procurement

---

### Screen 4.1 — Purchase Request List
- **Route:** `/procurement/requests`
- **Complexity:** M
- **Widgets:**
  - `PRStatusFilterChips` — All / Draft / Pending / Approved / Rejected
  - `PRList` — `ListView` of `PRTile` (PR number, requester, amount, status chip)
  - `FAB` → `/procurement/requests/new`
- **BLoC:** `PurchaseRequestListBLoC`
  - Events: `PRListLoaded`, `PRFilterChanged(status)`
  - States: `PRListLoading` → `PRListLoaded(list)` / `PRListFailure`
- **drift tables:** `cached_purchase_requests`

---

### Screen 4.2 — Create Purchase Request
- **Route:** `/procurement/requests/new`
- **Complexity:** L
- **Widgets:**
  - `LineItemsFormList` — description, qty, estimated cost, cost center
  - `ApproverPicker` — searchable from employee list
  - `AttachmentUploader`
  - `SaveDraftButton` + `SubmitButton`
- **BLoC:** `PRFormBLoC`
  - Events: `FieldChanged`, `LineItemAdded`, `LineItemRemoved`, `PRSubmitted`
  - States: `PRFormInitial` → `PRFormValid` / `PRFormInvalid` / `PRFormSuccess`
- **drift tables:** `cached_purchase_requests` (upsert draft)

---

### Screen 4.3 — Purchase Request Detail + Approval
- **Route:** `/procurement/requests/:id`
- **Complexity:** L
- **Widgets:**
  - `PRHeaderCard` — number, requester, department, date
  - `PRLineItemsTable`
  - `ApproveButton` + `RejectButton` — `PermissionGuard(scope: 'procurement.approve')`
  - `ApprovalHistoryTimeline`
- **BLoC:** `PRDetailBLoC`, `PRActionBLoC`
  - Same pattern as Invoice approve/reject (Slice 3.2.4)
- **drift tables:** `cached_purchase_requests` (status, approved_by, actioned_at)

---

### Screen 4.4 — Purchase Order List
- **Route:** `/procurement/orders`
- **Complexity:** M
- **Widgets:**
  - `POList` — `ListView` of `POTile` (PO number, vendor, amount, status)
  - `POFilterBar`
  - `FAB` → convert from PR or create new
- **BLoC:** `PurchaseOrderListBLoC`
- **drift tables:** `cached_purchase_orders`

---

### Screen 4.5 — Purchase Order Detail
- **Route:** `/procurement/orders/:id`
- **Complexity:** M
- **Widgets:**
  - `POHeaderCard`
  - `POLineItemsTable`
  - `GoodsReceiptButton` → `/procurement/orders/:id/receipt`
  - `POStatusChip`
- **BLoC:** `PODetailBLoC`
- **drift tables:** `cached_purchase_orders`

---

### Screen 4.6 — Goods Receipt Entry
- **Route:** `/procurement/orders/:id/receipt`
- **Complexity:** M
- **Widgets:**
  - `ReceivedQtyFormList` — per line item: ordered qty vs received qty input
  - `ReceiptDatePicker`
  - `ConfirmReceiptButton`
- **BLoC:** `GoodsReceiptBLoC`
  - Event: `GoodsReceiptSubmitted(orderId, lines)`
  - States: `GoodsReceiptLoading` → `GoodsReceiptSuccess` / `GoodsReceiptFailure`
- **drift tables:** `cached_purchase_orders` (update received quantities)

---

### Screen 4.7 — Vendor List
- **Route:** `/procurement/vendors`
- **Complexity:** S
- **Widgets:**
  - `VendorSearchBar`
  - `VendorList` — `ListView` of `VendorTile` (name, category, rating stars)
  - `FAB` → `/procurement/vendors/new`
- **BLoC:** `VendorListBLoC`
- **drift tables:** `cached_vendors`

---

### Screen 4.8 — Vendor Detail
- **Route:** `/procurement/vendors/:id`
- **Complexity:** M
- **Widgets:**
  - `VendorProfileCard` — name, contact, payment terms, category
  - `VendorScorecard` — on-time delivery %, quality rating, spend total
  - `POHistoryList` — recent POs with this vendor
- **BLoC:** `VendorDetailBLoC`
- **drift tables:** `cached_vendors`, `cached_purchase_orders`

---

## MODULE 5 — Inventory & Warehouse

---

### Screen 5.1 — Item Catalog
- **Route:** `/inventory/items`
- **Complexity:** M
- **Widgets:**
  - `ItemSearchBar`
  - `WarehouseFilterDropdown`
  - `ItemList` — `ListView` of `ItemTile` (SKU, name, stock level, unit, low-stock badge)
- **BLoC:** `ItemCatalogBLoC`
  - Events: `ItemsLoaded`, `WarehouseFilterChanged(warehouseId)`, `SearchQueryChanged`
  - States: `ItemCatalogLoading` → `ItemCatalogLoaded(items)` / `ItemCatalogFailure`
- **drift tables:** `cached_items` (id, sku, name, unit, warehouse_id, stock_qty, min_stock, cached_at)

---

### Screen 5.2 — Item Detail
- **Route:** `/inventory/items/:id`
- **Complexity:** M
- **Widgets:**
  - `ItemHeaderCard` — SKU, name, category, unit of measure
  - `StockLevelIndicator` — current qty vs min stock (progress bar)
  - `MovementHistoryList` — in/out transactions with date + qty + reference
  - `LowStockBadge` — shown if `stock_qty < min_stock`
- **BLoC:** `ItemDetailBLoC`
- **drift tables:** `cached_items`, `cached_stock_movements`

---

### Screen 5.3 — Barcode / QR Scanner
- **Route:** `/inventory/scan`
- **Complexity:** L
- **Widgets:**
  - `MobileScannerView` — full-screen camera (`mobile_scanner`)
  - `ScanOverlayFrame` — target reticle
  - `ScannedResultCard` — slides up on successful scan showing item name + current stock
  - `ScanActionButtons` — Goods Issue / Goods Receipt / Transfer
- **BLoC:** `ScanBLoC`
  - Event: `BarcodeDetected(code)`
  - States: `ScanIdle` → `ScanDetected(item)` / `ScanNotFound` / `ScanFailure`
- **drift tables:** `cached_items` (lookup by SKU/barcode)

---

### Screen 5.4 — Goods Issue / Receipt Flow
- **Route:** `/inventory/transaction`
- **Complexity:** M
- **Widgets:**
  - `ItemScanOrSearchField` — scan barcode or search by name
  - `QtyInputField`
  - `ReferenceField` — PO number / SO number
  - `WarehouseLocationPicker`
  - `ConfirmTransactionButton`
- **BLoC:** `StockTransactionBLoC`
  - Event: `TransactionSubmitted(type, itemId, qty, reference)`
  - Online: posts to API; Offline: enqueues to `SyncQueue`
- **drift tables:** `cached_items` (optimistic qty update), `sync_queue`

---

### Screen 5.5 — Stock Transfer
- **Route:** `/inventory/transfer`
- **Complexity:** M
- **Widgets:**
  - `FromWarehousePicker`
  - `ToWarehousePicker`
  - `ItemTransferFormList` — item + qty rows
  - `ConfirmTransferButton`
- **BLoC:** `StockTransferBLoC`
- **drift tables:** `cached_items`, `sync_queue`

---

### Screen 5.6 — Inventory Count / Cycle Count
- **Route:** `/inventory/count`
- **Complexity:** L
- **Widgets:**
  - `CountSessionHeader` — warehouse, date, counter name
  - `CountItemList` — item rows with expected qty + `ActualQtyInput`
  - `VarianceIndicator` — highlights discrepancies in red
  - `SubmitCountButton`
- **BLoC:** `InventoryCountBLoC`
  - Events: `CountStarted`, `CountItemUpdated(itemId, actualQty)`, `CountSubmitted`
  - States: `CountInProgress(items)` → `CountSubmitting` → `CountSuccess` / `CountFailure`
- **drift tables:** `cached_items`, `cached_count_sessions`

---

## MODULE 6 — Sales & CRM

---

### Screen 6.1 — Customer List
- **Route:** `/sales/customers`
- **Complexity:** S
- **Widgets:**
  - `CustomerSearchBar`
  - `CustomerList` — `ListView` of `CustomerTile` (name, phone, last order date)
  - `FAB` → `/sales/customers/new`
- **BLoC:** `CustomerListBLoC`
- **drift tables:** `cached_customers`

---

### Screen 6.2 — Customer Detail
- **Route:** `/sales/customers/:id`
- **Complexity:** M
- **Widgets:**
  - `CustomerProfileCard` — name, address, payment terms, credit limit
  - `ContactsList` — linked contacts with call/email actions
  - `ActivityTimeline` — orders, calls, notes in chronological order
  - `NewOrderFAB` → `/sales/quotations/new?customerId=:id`
- **BLoC:** `CustomerDetailBLoC`
- **drift tables:** `cached_customers`, `cached_contacts`, `cached_activities`

---

### Screen 6.3 — Sales Quotation List
- **Route:** `/sales/quotations`
- **Complexity:** M
- **Widgets:**
  - `QuotationFilterChips` — Draft / Sent / Accepted / Rejected
  - `QuotationList` — `ListView` of `QuotationTile`
  - `FAB` → `/sales/quotations/new`
- **BLoC:** `QuotationListBLoC`
- **drift tables:** `cached_quotations`

---

### Screen 6.4 — Create / Edit Quotation
- **Route:** `/sales/quotations/new` · `/sales/quotations/:id/edit`
- **Complexity:** L
- **Widgets:**
  - `CustomerPicker`
  - `ValidityDatePicker`
  - `LineItemsFormList` — product, qty, unit price, discount, tax
  - `TotalSummaryRow`
  - `SaveDraftButton` + `SendToCustomerButton`
- **BLoC:** `QuotationFormBLoC`
- **drift tables:** `cached_quotations` (upsert draft)

---

### Screen 6.5 — Sales Order Detail
- **Route:** `/sales/orders/:id`
- **Complexity:** M
- **Widgets:**
  - `OrderHeaderCard` — SO number, customer, date, delivery date
  - `OrderLineItemsTable`
  - `FulfillmentStatusStepper` — Confirmed → Picking → Shipped → Delivered
  - `ConvertFromQuotationButton` — visible only if source is quotation
- **BLoC:** `SalesOrderDetailBLoC`
- **drift tables:** `cached_sales_orders`

---

### Screen 6.6 — Sales Analytics
- **Route:** `/sales/analytics`
- **Complexity:** L
- **Widgets:**
  - `PeriodToggle` — Week / Month / Quarter / Year
  - `RevenueLineChart` (`fl_chart`)
  - `TopCustomersTable`
  - `TopProductsTable`
  - `SalesRepLeaderboard` — ranked list with avatar + total sales
- **BLoC:** `SalesAnalyticsBLoC`
  - Event: `AnalyticsLoaded(period)`
  - States: `AnalyticsLoading` → `AnalyticsLoaded(data)` / `AnalyticsFailure`
- **drift tables:** `cached_sales_analytics` (TTL-based, refreshed per period change)

---

## MODULE 7 — Human Resources

---

### Screen 7.1 — Employee Directory
- **Route:** `/hr/employees`
- **Complexity:** S
- **Widgets:**
  - `EmployeeSearchBar`
  - `DepartmentFilterDropdown`
  - `EmployeeList` — `ListView` of `EmployeeTile` (avatar, name, title, department)
- **BLoC:** `EmployeeListBLoC`
- **drift tables:** `cached_employees`

---

### Screen 7.2 — Employee Profile
- **Route:** `/hr/employees/:id`
- **Complexity:** M
- **Widgets:**
  - `EmployeeAvatarHeader` — photo, name, title, department, email, phone
  - `EmployeeInfoTabs` — Personal / Employment / Documents
  - `OrgChartButton` → `/hr/orgchart?focusId=:id`
- **BLoC:** `EmployeeDetailBLoC`
- **drift tables:** `cached_employees`

---

### Screen 7.3 — Org Chart
- **Route:** `/hr/orgchart`
- **Complexity:** L
- **Widgets:**
  - `OrgChartTreeWidget` — custom `CustomPainter`, zoomable/pannable
  - `OrgChartNodeCard` — avatar + name + title
  - `FocusEmployeeHighlight` — highlights the focused node if `focusId` param passed
- **BLoC:** `OrgChartBLoC`
  - Event: `OrgChartLoaded`, `NodeFocused(id)`
  - States: `OrgChartLoading` → `OrgChartLoaded(tree)` / `OrgChartFailure`
- **drift tables:** `cached_employees` (id, name, title, manager_id, avatar_url)

---

### Screen 7.4 — Leave Request Form
- **Route:** `/hr/leave/new`
- **Complexity:** M
- **Widgets:**
  - `LeaveTypePicker` — Annual / Sick / Unpaid / Maternity etc.
  - `DateRangePicker` — start + end date calendar
  - `LeaveDayCountDisplay` — computed working days
  - `LeaveBalanceWidget` — remaining balance per type
  - `ReasonTextField`
  - `SubmitLeaveButton`
- **BLoC:** `LeaveRequestFormBLoC`
  - Events: `LeaveTypeChanged`, `DateRangeChanged`, `LeaveSubmitted`
  - States: `LeaveFormInitial` → `LeaveFormValid` / `LeaveFormInvalid` / `LeaveFormSuccess`
- **drift tables:** `cached_leave_balances`, `cached_leave_requests`

---

### Screen 7.5 — Leave List (My Leaves)
- **Route:** `/hr/leave`
- **Complexity:** M
- **Widgets:**
  - `LeaveStatusFilterChips` — All / Pending / Approved / Rejected
  - `LeaveList` — `ListView` of `LeaveTile` (type, dates, status chip)
  - `LeaveBalanceSummaryCard` — remaining days per leave type
  - `FAB` → `/hr/leave/new`
- **BLoC:** `LeaveListBLoC`
- **drift tables:** `cached_leave_requests`, `cached_leave_balances`

---

### Screen 7.6 — Manager Leave Approval
- **Route:** `/hr/leave/approvals`
- **Complexity:** M
- **Widgets:**
  - `PendingLeaveList` — filtered to subordinates' pending requests
  - `LeaveTile` — name, type, dates, days count
  - `ApproveButton` + `RejectButton` — `PermissionGuard(scope: 'hr.approve')`
- **BLoC:** `LeaveApprovalBLoC`
- **drift tables:** `cached_leave_requests` (status update on action)

---

### Screen 7.7 — Attendance Log
- **Route:** `/hr/attendance`
- **Complexity:** M
- **Widgets:**
  - `ClockInOutButton` — toggles between clock-in and clock-out with timestamp
  - `AttendanceCalendar` — monthly view, color-coded present/absent/late
  - `AttendanceLogList` — daily rows with clock-in, clock-out, total hours
- **BLoC:** `AttendanceBLoC`
  - Events: `ClockInRequested`, `ClockOutRequested`, `AttendanceLoaded(month)`
  - States: `AttendanceLoading` → `AttendanceLoaded(log)` / `AttendanceFailure`
- **drift tables:** `cached_attendance`

---

### Screen 7.8 — Payslip Viewer
- **Route:** `/hr/payslips`
- **Complexity:** M
- **Widgets:**
  - `PayslipMonthPicker`
  - `PayslipSummaryCard` — gross, deductions, net pay
  - `PayslipPdfButton` — opens PDF viewer inline
  - `OvertimeSummaryRow`
  - `DeductionBreakdownList`
- **BLoC:** `PayslipBLoC`
  - Event: `PayslipLoaded(month, year)`
  - States: `PayslipLoading` → `PayslipLoaded(data)` / `PayslipFailure`
- **drift tables:** `cached_payslips`

---

## MODULE 8 — Project Management

---

### Screen 8.1 — Project List
- **Route:** `/projects`
- **Complexity:** S
- **Widgets:**
  - `ProjectSearchBar`
  - `ProjectStatusFilterChips` — Active / On Hold / Completed
  - `ProjectList` — `ListView` of `ProjectTile` (name, progress bar, deadline, manager avatar)
  - `FAB` → `/projects/new`
- **BLoC:** `ProjectListBLoC`
- **drift tables:** `cached_projects`

---

### Screen 8.2 — Project Detail / Gantt
- **Route:** `/projects/:id`
- **Complexity:** L
- **Widgets:**
  - `ProjectHeaderCard` — name, dates, budget, status
  - `GanttTimelineWidget` — custom `CustomPainter`, horizontal scroll, task bars with dependencies
  - `ProjectTabBar` — Gantt / Kanban / Team / Files
- **BLoC:** `ProjectDetailBLoC`
  - Event: `ProjectDetailLoaded(id)`
  - States: `ProjectDetailLoading` → `ProjectDetailLoaded(project, tasks)` / `ProjectDetailFailure`
- **drift tables:** `cached_projects`, `cached_tasks`

---

### Screen 8.3 — Task Kanban Board
- **Route:** `/projects/:id/board`
- **Complexity:** L
- **Widgets:**
  - `KanbanBoardView` — horizontal scroll, columns per status (To Do / In Progress / Review / Done)
  - `KanbanCard` — task title, assignee avatar, priority badge, due date
  - `DragTarget` per column — `flutter_reorderable_list` for drag-and-drop
  - `AddTaskButton` per column
- **BLoC:** `KanbanBLoC`
  - Events: `TaskMoved(taskId, newStatus)`, `TasksLoaded(projectId)`
  - States: `KanbanLoading` → `KanbanLoaded(columns)` / `KanbanFailure`
- **drift tables:** `cached_tasks` (status update on drag)

---

### Screen 8.4 — Task Detail
- **Route:** `/projects/:projectId/tasks/:taskId`
- **Complexity:** M
- **Widgets:**
  - `TaskHeaderCard` — title, assignee, priority, due date, status chip
  - `TaskDescriptionBlock`
  - `CommentThread` — `ListView` of `CommentTile` (avatar, text, timestamp)
  - `CommentInputField` + `SendButton`
  - `SubtaskList` — checkable subtasks
- **BLoC:** `TaskDetailBLoC`, `CommentBLoC`
- **drift tables:** `cached_tasks`, `cached_comments`

---

### Screen 8.5 — Timesheet Entry
- **Route:** `/projects/timesheets`
- **Complexity:** L
- **Widgets:**
  - `WeekNavigator` — prev/next week arrows
  - `TimesheetGrid` — rows = projects/tasks, columns = days; each cell = `HoursInput`
  - `TotalHoursRow` — sum per day + week total
  - `SubmitTimesheetButton`
- **BLoC:** `TimesheetBLoC`
  - Events: `TimesheetLoaded(week)`, `HoursUpdated(taskId, day, hours)`, `TimesheetSubmitted`
  - States: `TimesheetLoading` → `TimesheetLoaded(grid)` / `TimesheetSuccess` / `TimesheetFailure`
- **drift tables:** `cached_timesheets`

---

### Screen 8.6 — Utilization Report
- **Route:** `/projects/utilization`
- **Complexity:** M
- **Widgets:**
  - `PeriodSelector`
  - `UtilizationBarChart` (`fl_chart`) — hours per project per person
  - `TeamMemberUtilizationList` — member name + % utilized + total hours
- **BLoC:** `UtilizationBLoC`
- **drift tables:** `cached_timesheets` (aggregated)

---

## MODULE 9 — Settings & Administration

---

### Screen 9.1 — Settings Home
- **Route:** `/settings`
- **Complexity:** S
- **Widgets:**
  - `SettingsSectionList` — grouped: Preferences / Security / Admin (RBAC-gated)
  - `UserProfileTile` — avatar, name, role
  - `LogoutButton`
- **BLoC:** none (static navigation screen)
- **drift tables:** `cached_user` (read name, avatar)

---

### Screen 9.2 — User Preferences
- **Route:** `/settings/preferences`
- **Complexity:** S
- **Widgets:**
  - `ThemeToggle` — Light / Dark / System
  - `LanguageSelector` — dropdown of supported locales (ARB keys)
  - `NotificationPreferenceToggles` — per notification type on/off
- **BLoC:** `PreferencesBLoC`
  - Events: `ThemeChanged(mode)`, `LanguageChanged(locale)`, `NotificationPrefToggled(type)`
  - States: `PreferencesLoaded(prefs)` → `PreferencesUpdated`
- **drift tables:** `cached_user_preferences` (theme, locale, notif_prefs JSON)

---

### Screen 9.3 — Active Sessions
- **Route:** `/settings/sessions`
- **Complexity:** M
- **Widgets:**
  - `SessionList` — `ListView` of `SessionTile` (device name, OS, last active, current badge)
  - `RevokeSessionButton` per tile
  - `RevokeAllOtherSessionsButton`
- **BLoC:** `SessionManagementBLoC`
  - Events: `SessionsLoaded`, `SessionRevoked(sessionId)`, `AllOtherSessionsRevoked`
  - States: `SessionsLoading` → `SessionsLoaded(list)` / `SessionsFailure`
- **drift tables:** none (reads from API; no local cache for security reasons)

---

### Screen 9.4 — Audit Log Viewer
- **Route:** `/settings/audit`
- **Complexity:** M
- **Widgets:**
  - `AuditLogFilterBar` — by user, module, action type, date range
  - `AuditLogList` — `ListView` of `AuditLogTile` (timestamp, user, action, record reference)
  - `AuditLogDetailSheet` — bottom sheet with full payload on tile tap
- **BLoC:** `AuditLogBLoC`
  - Event: `AuditLogsLoaded(filters)`
  - States: `AuditLogLoading` → `AuditLogLoaded(entries)` / `AuditLogFailure`
- **drift tables:** `cached_audit_logs`

---

### Screen 9.5 — User Management (Admin)
- **Route:** `/settings/admin/users`
- **Complexity:** M
- **Widgets:**
  - `UserList` — `ListView` of `UserManagementTile` (avatar, name, role, status badge)
  - `InviteUserButton`
  - `DeactivateUserButton` per tile — `PermissionGuard(scope: 'admin.users')`
- **BLoC:** `UserManagementBLoC`
- **drift tables:** none (admin reads from API only)

---

### Screen 9.6 — Role & Permission Editor (Admin)
- **Route:** `/settings/admin/roles`
- **Complexity:** L
- **Widgets:**
  - `RoleList` — all roles
  - `PermissionMatrix` — role × scope grid with toggles
  - `SaveRolesButton`
- **BLoC:** `RoleEditorBLoC`
  - Events: `RolesLoaded`, `PermissionToggled(role, scope)`, `RolesSaved`
  - States: `RoleEditorLoading` → `RoleEditorLoaded(matrix)` / `RoleEditorSaving` / `RoleEditorSuccess`
- **drift tables:** `user_permissions` (invalidated and re-fetched after save)

---

### Screen 9.7 — API / Environment Config (Admin)
- **Route:** `/settings/admin/config`
- **Complexity:** S
- **Widgets:**
  - `EnvironmentSelector` — Production / Staging / Custom
  - `BaseUrlTextField`
  - `TenantIdTextField`
  - `SaveConfigButton` + `TestConnectionButton`
- **BLoC:** `EnvConfigBLoC`
  - Events: `ConfigLoaded`, `ConfigSaved(env, baseUrl, tenantId)`, `ConnectionTested`
  - States: `ConfigLoading` → `ConfigLoaded` / `ConfigSaving` / `ConfigTestSuccess` / `ConfigTestFailure`
- **drift tables:** `cached_env_config` (baseUrl, tenantId, environment, updated_at)

---

### Screen 9.8 — PIN Lock / Biometric Re-Auth
- **Route:** `/lock`
- **Complexity:** M
- **Widgets:**
  - `PinPadWidget` — 4–6 digit numeric pad
  - `BiometricPromptButton` — if `biometric_on = true`
  - `LogoutInsteadLink`
- **BLoC:** `AppLockBLoC`
  - Events: `PinSubmitted(pin)`, `BiometricRequested`, `LogoutRequested`
  - States: `AppLocked` → `AppUnlocking` → `AppUnlocked` / `AppLockFailure(attemptsRemaining)`
- **drift tables:** `cached_user` (read `biometric_on`); PIN hash stored in `flutter_secure_storage`

---

## Screen Count & Complexity Summary

| Module | S | M | L | Total |
|---|---|---|---|---|
| Module 0 — App Entry | 0 | 1 | 0 | 1 |
| Module 1 — Auth & Identity | 2 | 2 | 0 | 4 |
| Module 2 — Dashboard & Home | 0 | 2 | 1 | 3 |
| Module 3 — Finance & Accounting | 1 | 3 | 3 | 7 |
| Module 4 — Procurement | 1 | 4 | 3 | 8 |
| Module 5 — Inventory & Warehouse | 0 | 3 | 3 | 6 |
| Module 6 — Sales & CRM | 1 | 3 | 2 | 6 |
| Module 7 — Human Resources | 1 | 6 | 1 | 8 |
| Module 8 — Project Management | 1 | 2 | 3 | 6 |
| Module 9 — Settings & Admin | 3 | 4 | 1 | 8 |
| **Total** | **10** | **30** | **17** | **57** |

### Complexity breakdown
- **S (Simple) — 10 screens** — straightforward to build; 1–2 days each
- **M (Medium) — 30 screens** — standard sprint work; 3–5 days each
- **L (Large) — 17 screens** — plan a full sprint per screen; custom painters, multi-BLoC, offline sync logic
