// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ERP Mobile';

  @override
  String get loginAppBarTitle => 'Sign in';

  @override
  String get loginButton => 'Sign in (placeholder)';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardPlaceholder =>
      'Dashboard placeholder — Module 2 will fill this in.';

  @override
  String get signOutTooltip => 'Sign out';

  @override
  String get notFoundTitle => 'Not found';

  @override
  String notFoundBody(String location) {
    return 'No route matches \"$location\"';
  }

  @override
  String get goHome => 'Go home';

  @override
  String get loginOtpDemoLink => '[demo] Try MFA code';

  @override
  String get otpPageTitle => 'Verification';

  @override
  String get otpSubtitle =>
      'Enter the 6-digit code from your authenticator app or SMS.';

  @override
  String otpDevHint(String code) {
    return 'Demo: enter $code to continue';
  }

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String get otpErrorIncorrect => 'Code is incorrect. Please try again.';

  @override
  String get otpErrorExpired => 'This code has expired. Request a new one.';

  @override
  String get otpErrorTooManyAttempts =>
      'Too many attempts. Please try again later.';

  @override
  String get otpErrorNetwork =>
      'Couldn\'t reach the server. Check your connection.';

  @override
  String get forbiddenTitle => 'Access denied';

  @override
  String forbiddenBody(String location) {
    return 'You don\'t have permission to access \"$location\".';
  }

  @override
  String get adminDemoTitle => 'Admin demo';

  @override
  String get adminDemoBody =>
      'You reached the admin-only demo route — RBAC works.';

  @override
  String get dashboardAdminDemoLink => '[demo] Open admin-only page';

  @override
  String get permissionGuardDemoGranted =>
      '[demo] PermissionGuard: admin granted';

  @override
  String get permissionGuardDemoDenied =>
      '[demo] PermissionGuard: admin denied';

  @override
  String get shellHome => 'Home';

  @override
  String get shellModules => 'Modules';

  @override
  String get shellSettings => 'Settings';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesPlaceholder =>
      'Module shortcut tiles land here in Slice 2.1.2.';

  @override
  String get modulesEmpty =>
      'No modules are available for your role yet. Ask an admin to grant the permissions you need.';

  @override
  String get shortcutAdminDemo => 'Admin demo';

  @override
  String get shortcutFinance => 'Finance';

  @override
  String get shortcutProcurement => 'Procurement';

  @override
  String get shortcutInventory => 'Inventory';

  @override
  String get shortcutSales => 'Sales';

  @override
  String get shortcutHr => 'HR';

  @override
  String get shortcutProjects => 'Projects';

  @override
  String comingSoonBody(String module) {
    return '$module ships in a future release.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPlaceholder => 'Real preferences land here in Module 9.';

  @override
  String get globalSearchTooltip => 'Search';

  @override
  String get globalSearchHint => 'Search modules, records, people…';

  @override
  String get globalSearchPrompt =>
      'Type to search across every module you can access.';

  @override
  String globalSearchNoResults(String query) {
    return 'No results for \"$query\".';
  }

  @override
  String globalSearchError(String message) {
    return 'Search failed: $message';
  }

  @override
  String get kpiTrendUp => 'up';

  @override
  String get kpiTrendDown => 'down';

  @override
  String get kpiTrendFlat => 'flat';

  @override
  String get kpiTrendUpTooltip => 'Up vs prior period';

  @override
  String get kpiTrendDownTooltip => 'Down vs prior period';

  @override
  String get kpiTrendFlatTooltip => 'No meaningful change vs prior period';

  @override
  String get chartRevenueTrendTitle => 'Revenue trend';

  @override
  String get chartSalesByRegionTitle => 'Sales by region';

  @override
  String get chartSeriesRevenue => 'Revenue';

  @override
  String get chartSeriesTarget => 'Target';

  @override
  String get chartSeriesSales => 'Sales';

  @override
  String get realtimeStatusLive => 'Live';

  @override
  String get realtimeStatusConnecting => 'Connecting';

  @override
  String get realtimeStatusReconnecting => 'Reconnecting';

  @override
  String get realtimeStatusOffline => 'Offline';

  @override
  String get pushDemoButton => '[dev] Simulate push';

  @override
  String pushDemoTitle(int count) {
    return 'Demo notification #$count';
  }

  @override
  String get pushDemoBody =>
      'Routed through PushMessageRouter into the inbox cache.';

  @override
  String get pushDemoSnack => 'Pushed to inbox.';

  @override
  String get notificationsBadgeTooltip => 'Notifications';

  @override
  String get notificationInboxTitle => 'Notifications';

  @override
  String get notificationInboxEmpty =>
      'You\'re all caught up. New notifications will appear here.';

  @override
  String notificationInboxError(String message) {
    return 'Couldn\'t load notifications: $message';
  }

  @override
  String get notificationInboxMarkAllRead => 'Mark all as read';

  @override
  String get notificationInboxDismissedSnack => 'Notification dismissed.';

  @override
  String notificationDeepLinkError(String message) {
    return 'Couldn\'t open this notification: $message';
  }

  @override
  String get notificationDeepLinkViewAction => 'View';

  @override
  String get pushDemoRoutedButton => '[dev] Simulate routed push';

  @override
  String get pushDemoRoutedBody =>
      'Tap this notification — or the Snackbar\'s View — to deep-link to the target.';

  @override
  String get chartOfAccountsTitle => 'Chart of accounts';

  @override
  String get chartOfAccountsEmpty => 'No accounts have been loaded yet.';

  @override
  String chartOfAccountsError(String message) {
    return 'Couldn\'t load the chart of accounts: $message';
  }

  @override
  String get chartOfAccountsExpandAll => 'Expand all';

  @override
  String get chartOfAccountsCollapseAll => 'Collapse all';

  @override
  String get dashboardChartOfAccountsLink => '[demo] Open chart of accounts';

  @override
  String get accountTypeAsset => 'Asset';

  @override
  String get accountTypeLiability => 'Liability';

  @override
  String get accountTypeEquity => 'Equity';

  @override
  String get accountTypeRevenue => 'Revenue';

  @override
  String get accountTypeExpense => 'Expense';

  @override
  String get accountDetailTitle => 'Account';

  @override
  String get accountDetailNoTransactions =>
      'No transactions have been posted to this account yet.';

  @override
  String accountDetailNotFound(String accountId) {
    return 'We couldn\'t find an account with id \"$accountId\".';
  }

  @override
  String accountDetailError(String message) {
    return 'Couldn\'t load this account: $message';
  }

  @override
  String get invoiceListTitle => 'Invoices';

  @override
  String get invoiceListSearchHint => 'Search by number or customer';

  @override
  String get invoiceListSortTooltip => 'Sort';

  @override
  String get invoiceListEmpty => 'No invoices match your filters.';

  @override
  String invoiceListError(String message) {
    return 'Couldn\'t load invoices: $message';
  }

  @override
  String invoiceListDueLabel(String date) {
    return 'due $date';
  }

  @override
  String get invoiceStatusDraft => 'Draft';

  @override
  String get invoiceStatusPendingApproval => 'Pending approval';

  @override
  String get invoiceStatusApproved => 'Approved';

  @override
  String get invoiceStatusRejected => 'Rejected';

  @override
  String get invoiceSortIssuedDesc => 'Issued (newest)';

  @override
  String get invoiceSortIssuedAsc => 'Issued (oldest)';

  @override
  String get invoiceSortDueAsc => 'Due (soonest)';

  @override
  String get invoiceSortAmountDesc => 'Amount (largest)';

  @override
  String get invoiceSortNumberAsc => 'Invoice number';

  @override
  String get invoiceDetailTitle => 'Invoice';

  @override
  String get invoiceDetailIssuedLabel => 'Issued';

  @override
  String get invoiceDetailDueLabel => 'Due';

  @override
  String get invoiceDetailLinesHeading => 'Line items';

  @override
  String get invoiceDetailSubtotalLabel => 'Subtotal';

  @override
  String get invoiceDetailTaxLabel => 'Tax';

  @override
  String get invoiceDetailTotalLabel => 'Total';

  @override
  String get invoiceDetailNotesHeading => 'Notes';

  @override
  String get invoiceDetailPdfHeading => 'PDF preview';

  @override
  String get invoiceDetailPdfPlaceholder =>
      'PDF rendering ships with the backend that serves it.';

  @override
  String invoiceDetailNotFound(String invoiceId) {
    return 'We couldn\'t find an invoice with id \"$invoiceId\".';
  }

  @override
  String invoiceDetailError(String message) {
    return 'Couldn\'t load this invoice: $message';
  }

  @override
  String get invoiceApproveAction => 'Approve';

  @override
  String get invoiceRejectAction => 'Reject';

  @override
  String get invoiceSubmitAction => 'Submit for approval';

  @override
  String get invoiceReopenAction => 'Re-open for revision';

  @override
  String get invoiceActionCancel => 'Cancel';

  @override
  String get invoiceApproveSheetTitle => 'Approve this invoice?';

  @override
  String invoiceApproveSheetBody(String invoiceNumber) {
    return 'You\'re about to approve $invoiceNumber. The invoice will be locked once approved.';
  }

  @override
  String get invoiceRejectSheetTitle => 'Reject this invoice?';

  @override
  String invoiceRejectSheetBody(String invoiceNumber) {
    return '$invoiceNumber will be returned to the requester with the reason below.';
  }

  @override
  String get invoiceRejectReasonLabel => 'Reason';

  @override
  String get invoiceRejectReasonHint => 'Why is this invoice being rejected?';

  @override
  String get invoiceRejectReasonRequired => 'Please give a reason.';

  @override
  String invoiceActionSuccess(String status) {
    return 'Invoice marked as $status.';
  }

  @override
  String get invoiceActionForbidden =>
      'You don\'t have permission to action this invoice.';

  @override
  String get invoiceActionNotFound => 'That invoice no longer exists.';

  @override
  String get invoiceActionInvalidState =>
      'This invoice has already been actioned.';

  @override
  String get invoiceActionUnauthorized =>
      'Sign-in expired — please sign in again.';

  @override
  String invoiceActionGenericError(String message) {
    return 'Couldn\'t action the invoice: $message';
  }

  @override
  String get invoiceAuditApprovedHeading => 'Approved';

  @override
  String get invoiceAuditRejectedHeading => 'Rejected';

  @override
  String invoiceAuditActorLine(String userId) {
    return 'by $userId';
  }

  @override
  String invoiceAuditWhenLine(String when) {
    return 'at $when';
  }

  @override
  String invoiceAuditReasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get invoiceFormCreateTitle => 'New invoice';

  @override
  String get invoiceFormEditTitle => 'Edit invoice';

  @override
  String get invoiceFormSaveTooltip => 'Save';

  @override
  String get invoiceFormSaveAction => 'Save invoice';

  @override
  String get invoiceFormSavedSnack => 'Invoice saved.';

  @override
  String get invoiceFormCustomerLabel => 'Customer';

  @override
  String get invoiceFormIssuedLabel => 'Issued date';

  @override
  String get invoiceFormDueLabel => 'Due date';

  @override
  String get invoiceFormLineHeading => 'Line item';

  @override
  String get invoiceFormLineDescriptionLabel => 'Description';

  @override
  String get invoiceFormLineQuantityLabel => 'Quantity';

  @override
  String get invoiceFormLineUnitPriceLabel => 'Unit price';

  @override
  String get validatorRequired => 'Required';

  @override
  String get validatorInvalidNumber => 'Must be a number';

  @override
  String get validatorMustBePositive => 'Must be greater than 0';

  @override
  String get validatorMustBeNonNegative => 'Cannot be negative';

  @override
  String get validatorDueBeforeIssued =>
      'Due date must be on or after the issued date';

  @override
  String get journalEntriesTitle => 'Journal entries';

  @override
  String get journalEntriesEmpty => 'No journal entries posted in this period.';

  @override
  String get journalEntryDetailTitle => 'Journal entry';

  @override
  String journalEntryNotFound(String id) {
    return 'Journal entry \"$id\" was not found.';
  }

  @override
  String get journalEntryAccountColumn => 'Account';

  @override
  String get journalEntryDebitColumn => 'Debit';

  @override
  String get journalEntryCreditColumn => 'Credit';

  @override
  String get journalEntryTotalLabel => 'Total';

  @override
  String get trialBalanceTitle => 'Trial balance';

  @override
  String get trialBalanceEmpty => 'No accounts have non-zero balances yet.';

  @override
  String get trialBalanceColumnCode => 'Code';

  @override
  String get trialBalanceColumnName => 'Account';

  @override
  String get trialBalanceColumnDebit => 'Debit';

  @override
  String get trialBalanceColumnCredit => 'Credit';

  @override
  String trialBalancePageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get trialBalanceExportCsvTooltip => 'Export CSV';

  @override
  String trialBalanceExportSuccess(String path) {
    return 'CSV saved to $path';
  }

  @override
  String trialBalanceExportError(String message) {
    return 'CSV export failed: $message';
  }

  @override
  String get validatorInvalidEmail => 'Please enter a valid email';

  @override
  String get prListTitle => 'Purchase requests';

  @override
  String get prListNewTooltip => 'New PR';

  @override
  String get prListSearchHint => 'Search by number, requester, cost center';

  @override
  String get prListSortTooltip => 'Sort';

  @override
  String get prListEmpty => 'No purchase requests match your filters.';

  @override
  String prListError(String message) {
    return 'Couldn\'t load purchase requests: $message';
  }

  @override
  String get prStatusDraft => 'Draft';

  @override
  String get prStatusSubmitted => 'Submitted';

  @override
  String get prStatusApproved => 'Approved';

  @override
  String get prStatusRejected => 'Rejected';

  @override
  String get prStatusConverted => 'Converted';

  @override
  String get prSortCreatedDesc => 'Created (newest)';

  @override
  String get prSortCreatedAsc => 'Created (oldest)';

  @override
  String get prSortTotalDesc => 'Total (largest)';

  @override
  String get prSortNumberAsc => 'PR number';

  @override
  String get prFormCreateTitle => 'New purchase request';

  @override
  String get prFormSaveTooltip => 'Submit';

  @override
  String get prFormSubmitAction => 'Submit request';

  @override
  String get prFormSavedSnack => 'Purchase request submitted.';

  @override
  String prFormSaveFailed(String message) {
    return 'Couldn\'t submit the request: $message';
  }

  @override
  String get prFormRequesterLabel => 'Requester';

  @override
  String get prFormCostCenterLabel => 'Cost center';

  @override
  String get prFormApproverLabel => 'Approver';

  @override
  String get prFormJustificationLabel => 'Justification (optional)';

  @override
  String get prFormLinesHeading => 'Line items';

  @override
  String prFormLineHeading(int index) {
    return 'Line $index';
  }

  @override
  String get prFormAddLineAction => 'Add line';

  @override
  String get prFormRemoveLineTooltip => 'Remove line';

  @override
  String get prFormLineDescriptionLabel => 'Description';

  @override
  String get prFormLineQuantityLabel => 'Qty';

  @override
  String get prFormLineUnitPriceLabel => 'Unit price';

  @override
  String get prDetailTitle => 'Purchase request';

  @override
  String prDetailNotFound(String prId) {
    return 'We couldn\'t find a purchase request with id \"$prId\".';
  }

  @override
  String prDetailError(String message) {
    return 'Couldn\'t load this purchase request: $message';
  }

  @override
  String get prDetailRequesterLabel => 'Requester';

  @override
  String get prDetailCostCenterLabel => 'Cost center';

  @override
  String get prDetailApproverLabel => 'Approver';

  @override
  String get prDetailCreatedLabel => 'Created';

  @override
  String get prDetailJustificationHeading => 'Justification';

  @override
  String get prDetailLinesHeading => 'Line items';

  @override
  String get prDetailTotalLabel => 'Total';

  @override
  String get prApproveAction => 'Approve';

  @override
  String get prRejectAction => 'Reject';

  @override
  String get prSubmitAction => 'Submit';

  @override
  String get prConvertAction => 'Convert to PO';

  @override
  String get prSubmittedSnack => 'Purchase request submitted.';

  @override
  String prApprovedSnack(String status) {
    return 'Purchase request marked as $status.';
  }

  @override
  String get prRejectedSnack => 'Purchase request rejected.';

  @override
  String get prConvertedSnack => 'Purchase order created.';

  @override
  String prApprovalNotAllowed(String action) {
    return 'This request can\'t be $action from its current status.';
  }

  @override
  String prApprovalFailed(String message) {
    return 'Couldn\'t update the request: $message';
  }

  @override
  String get prRejectDialogTitle => 'Reject request';

  @override
  String get prRejectReasonLabel => 'Reason';

  @override
  String get prRejectReasonHint => 'Why is this request being rejected?';

  @override
  String get prRejectReasonRequired => 'Please give a reason.';

  @override
  String get prRejectCancel => 'Cancel';

  @override
  String get prRejectConfirm => 'Reject request';

  @override
  String get prConvertDialogTitle => 'Convert to purchase order';

  @override
  String get prConvertVendorLabel => 'Vendor';

  @override
  String get prConvertExpectedLabel => 'Expected delivery';

  @override
  String get prConvertVendorRequired => 'Please pick a vendor.';

  @override
  String get prConvertConfirm => 'Create PO';

  @override
  String get prConvertCancel => 'Cancel';

  @override
  String get poListTitle => 'Purchase orders';

  @override
  String get poListEmpty => 'No purchase orders yet.';

  @override
  String poListExpectedLabel(String date) {
    return 'expected $date';
  }

  @override
  String get poStatusOpen => 'Open';

  @override
  String get poStatusPartial => 'Partial';

  @override
  String get poStatusFull => 'Received';

  @override
  String get poStatusClosed => 'Closed';

  @override
  String get poStatusCancelled => 'Cancelled';

  @override
  String get poDetailTitle => 'Purchase order';

  @override
  String poDetailNotFound(String poId) {
    return 'We couldn\'t find a purchase order with id \"$poId\".';
  }

  @override
  String get poDetailCreatedLabel => 'Created';

  @override
  String get poDetailExpectedLabel => 'Expected';

  @override
  String get poDetailSourcePrLabel => 'Source PR';

  @override
  String get poDetailLinesHeading => 'Line items';

  @override
  String get poDetailTotalLabel => 'Total';

  @override
  String get poDetailReceiptsHeading => 'Goods receipts';

  @override
  String get poDetailReceiptsEmpty => 'No receipts recorded yet.';

  @override
  String poDetailReceiptItemsBadge(int count) {
    return '$count item(s)';
  }

  @override
  String get poDetailRecordReceiptAction => 'Record goods receipt';

  @override
  String poLineOrderedLabel(String qty) {
    return 'ordered $qty';
  }

  @override
  String poLineReceivedLabel(String qty) {
    return 'received $qty';
  }

  @override
  String poLineOutstandingLabel(String qty) {
    return 'outstanding $qty';
  }

  @override
  String get goodsReceiptFormTitle => 'Goods receipt';

  @override
  String goodsReceiptFormForPo(String number) {
    return 'Receiving against $number';
  }

  @override
  String get goodsReceiptReceivedByLabel => 'Received by';

  @override
  String get goodsReceiptNoteLabel => 'Note (optional)';

  @override
  String get goodsReceiptLinesHeading => 'Quantities received';

  @override
  String get goodsReceiptQuantityLabel => 'Receiving now';

  @override
  String get goodsReceiptSubmitAction => 'Record receipt';

  @override
  String get goodsReceiptSavedSnack => 'Goods receipt recorded.';

  @override
  String goodsReceiptSaveFailed(String message) {
    return 'Couldn\'t record receipt: $message';
  }

  @override
  String get goodsReceiptErrorPoClosed =>
      'This PO is closed and can\'t take more receipts.';

  @override
  String get goodsReceiptErrorNoLines =>
      'Enter a quantity for at least one line.';

  @override
  String get goodsReceiptErrorNonPositive => 'Quantity must be greater than 0.';

  @override
  String get goodsReceiptErrorUnknownLine =>
      'One of the lines doesn\'t belong to this PO.';

  @override
  String get goodsReceiptErrorExceedsOutstanding =>
      'You can\'t receive more than the outstanding quantity.';

  @override
  String get vendorListTitle => 'Vendors';

  @override
  String get vendorListEmpty => 'No vendors onboarded yet.';

  @override
  String get vendorListNewTooltip => 'Onboard vendor';

  @override
  String get vendorStatusActive => 'Active';

  @override
  String get vendorStatusOnHold => 'On hold';

  @override
  String get vendorStatusArchived => 'Archived';

  @override
  String get vendorDetailTitle => 'Vendor';

  @override
  String vendorDetailNotFound(String vendorId) {
    return 'We couldn\'t find a vendor with id \"$vendorId\".';
  }

  @override
  String get vendorDetailTaxIdLabel => 'Tax ID';

  @override
  String get vendorDetailOnboardedLabel => 'Onboarded';

  @override
  String get vendorDetailContactHeading => 'Contact';

  @override
  String get vendorDetailContactPersonLabel => 'Contact person';

  @override
  String get vendorDetailEmailLabel => 'Email';

  @override
  String get vendorDetailPhoneLabel => 'Phone';

  @override
  String get vendorDetailAddressLabel => 'Address';

  @override
  String get vendorDetailNotesHeading => 'Notes';

  @override
  String get vendorDetailScorecardAction => 'View performance scorecard';

  @override
  String get vendorFormTitle => 'Onboard vendor';

  @override
  String get vendorFormSaveTooltip => 'Save';

  @override
  String get vendorFormSaveAction => 'Save vendor';

  @override
  String get vendorFormSavedSnack => 'Vendor onboarded.';

  @override
  String vendorFormSaveFailed(String message) {
    return 'Couldn\'t save the vendor: $message';
  }

  @override
  String get vendorFormNameLabel => 'Vendor name';

  @override
  String get vendorFormTaxIdLabel => 'Tax ID';

  @override
  String get vendorFormEmailLabel => 'Email';

  @override
  String get vendorFormPhoneLabel => 'Phone';

  @override
  String get vendorFormAddressLabel => 'Address';

  @override
  String get vendorFormContactPersonLabel => 'Contact person (optional)';

  @override
  String get vendorFormNotesLabel => 'Notes (optional)';

  @override
  String get vendorScorecardTitle => 'Vendor scorecard';

  @override
  String get vendorScorecardCompositeLabel => 'Composite score';

  @override
  String get vendorScorecardOnTimeLabel => 'On-time delivery';

  @override
  String get vendorScorecardDefectLabel => 'Defect rate';

  @override
  String get vendorScorecardDisputesLabel => 'Open disputes';

  @override
  String get vendorScorecardSpendLabel => 'Total spend';

  @override
  String get inventoryItemsTitle => 'Inventory items';

  @override
  String get inventoryScanTooltip => 'Scan barcode';

  @override
  String get inventoryLowStockAlertsTooltip => 'Low stock alerts';

  @override
  String get inventoryItemsSearchHint =>
      'Search by SKU, name, location, barcode';

  @override
  String get inventoryItemsSortTooltip => 'Sort';

  @override
  String get inventoryItemsEmpty => 'No items match the current filters.';

  @override
  String inventoryItemsError(String message) {
    return 'Couldn\'t load inventory: $message';
  }

  @override
  String inventoryItemsOnHand(String qty) {
    return 'on-hand $qty';
  }

  @override
  String inventoryReorderBadge(String qty) {
    return 'reorder at $qty';
  }

  @override
  String get inventoryLowStockChip => 'Low stock only';

  @override
  String get inventorySortNameAsc => 'Name (A–Z)';

  @override
  String get inventorySortSkuAsc => 'SKU';

  @override
  String get inventorySortOnHandAsc => 'On-hand (low first)';

  @override
  String get inventorySortOnHandDesc => 'On-hand (high first)';

  @override
  String get inventoryItemDetailTitle => 'Item';

  @override
  String inventoryItemNotFound(String itemId) {
    return 'We couldn\'t find an item with id \"$itemId\".';
  }

  @override
  String get inventoryDetailWarehouseLabel => 'Warehouse';

  @override
  String get inventoryDetailLocationLabel => 'Location';

  @override
  String get inventoryDetailReorderLabel => 'Reorder point';

  @override
  String get inventoryDetailUnitCostLabel => 'Unit cost';

  @override
  String get inventoryDetailBarcodeLabel => 'Barcode';

  @override
  String get inventoryDetailMovementsHeading => 'Movement history';

  @override
  String get inventoryDetailMovementsEmpty => 'No movements recorded yet.';

  @override
  String get inventoryMovementTypeReceipt => 'Goods receipt';

  @override
  String get inventoryMovementTypeIssue => 'Goods issue';

  @override
  String get inventoryMovementTypeTransfer => 'Transfer';

  @override
  String get inventoryMovementTypeAdjustment => 'Adjustment';

  @override
  String inventoryMovementRunningLabel(String qty) {
    return 'balance $qty';
  }

  @override
  String get inventoryIssueAction => 'Issue';

  @override
  String get inventoryReceiptAction => 'Receive';

  @override
  String get inventoryTransferAction => 'Transfer';

  @override
  String get inventoryLowStockTitle => 'Low stock';

  @override
  String get inventoryLowStockEmpty => 'Every item is above its reorder point.';

  @override
  String get inventoryScannerTitle => 'Scan barcode';

  @override
  String get inventoryScannerEmpty => 'Scan or enter a code.';

  @override
  String inventoryScannerUnknown(String code) {
    return 'No item matches \"$code\".';
  }

  @override
  String inventoryScannerError(String message) {
    return 'Scanner error: $message';
  }

  @override
  String get inventoryScannerNoCamera =>
      'Camera not available on this platform — use manual entry below.';

  @override
  String get inventoryScannerManualHeading => 'Manual entry';

  @override
  String get inventoryScannerManualLabel => 'Barcode';

  @override
  String get inventoryScannerManualHint => 'Type or paste a code';

  @override
  String get inventoryScannerManualUseAction => 'Use';

  @override
  String get inventoryScannerBrowseFallback => 'Browse the catalog instead';

  @override
  String get inventoryReceiptFormTitle => 'Receive stock';

  @override
  String get inventoryIssueFormTitle => 'Issue stock';

  @override
  String get inventoryReceiptSuccessSnack => 'Stock received.';

  @override
  String get inventoryIssueSuccessSnack => 'Stock issued.';

  @override
  String get inventoryMovementGenericSuccess => 'Movement recorded.';

  @override
  String inventoryMovementFailed(String message) {
    return 'Couldn\'t record movement: $message';
  }

  @override
  String inventoryFormCurrentOnHand(String qty) {
    return 'Current on-hand: $qty';
  }

  @override
  String get inventoryFormQuantityLabel => 'Quantity';

  @override
  String get inventoryFormReferenceLabel => 'Reference (optional)';

  @override
  String get inventoryFormReferenceReceiptHint => 'e.g. PO-2026-001';

  @override
  String get inventoryFormReferenceIssueHint => 'e.g. SO-2026-014';

  @override
  String get inventoryFormNoteLabel => 'Note';

  @override
  String get inventoryQtyExceedsOnHand =>
      'Quantity exceeds the current on-hand.';

  @override
  String get inventoryTransferFormTitle => 'Transfer stock';

  @override
  String get inventoryTransferSourceHeading => 'From';

  @override
  String get inventoryTransferDestinationLabel => 'Destination bin';

  @override
  String get inventoryTransferNoDestinations =>
      'No active destination bins available for this SKU.';

  @override
  String get inventoryTransferReferenceHint => 'Internal transfer note';

  @override
  String get inventoryTransferPickDestination =>
      'Please pick a destination bin.';

  @override
  String get inventoryTransferSuccess => 'Stock transferred.';

  @override
  String get inventoryCycleCountTitle => 'Cycle count';

  @override
  String get inventoryCycleNoItems => 'No items to count.';

  @override
  String get inventoryCycleAllWarehouses => 'All warehouses';

  @override
  String inventoryCycleExpectedLabel(String qty) {
    return 'expected $qty';
  }

  @override
  String get inventoryCycleCountedLabel => 'Counted';

  @override
  String get inventoryCycleEmpty =>
      'Enter a counted quantity for at least one item.';

  @override
  String get inventoryCycleSubmitAction => 'Submit count';

  @override
  String inventoryCycleSuccess(int count, String variance) {
    return 'Posted $count adjustment(s); variance $variance.';
  }

  @override
  String get salesCustomersTitle => 'Customers';

  @override
  String get salesAnalyticsTooltip => 'Analytics';

  @override
  String get salesCustomersSearchHint => 'Search by name, email, industry';

  @override
  String get salesCustomersSortTooltip => 'Sort';

  @override
  String get salesCustomersEmpty => 'No customers match your filters.';

  @override
  String salesCustomersError(String message) {
    return 'Couldn\'t load customers: $message';
  }

  @override
  String salesCustomersOnboardedLabel(String date) {
    return 'since $date';
  }

  @override
  String get salesCustomersSortName => 'Name (A–Z)';

  @override
  String get salesCustomersSortLtv => 'Lifetime value';

  @override
  String get salesCustomersSortRecent => 'Recently added';

  @override
  String get salesStatusProspect => 'Prospect';

  @override
  String get salesStatusActive => 'Active';

  @override
  String get salesStatusOnHold => 'On hold';

  @override
  String get salesStatusChurned => 'Churned';

  @override
  String get salesSegmentSmb => 'SMB';

  @override
  String get salesSegmentMidMarket => 'Mid-market';

  @override
  String get salesSegmentEnterprise => 'Enterprise';

  @override
  String get salesCustomerDetailTitle => 'Customer';

  @override
  String salesCustomerNotFound(String customerId) {
    return 'We couldn\'t find a customer with id \"$customerId\".';
  }

  @override
  String get salesCustomerDetailEmailLabel => 'Email';

  @override
  String get salesCustomerDetailPhoneLabel => 'Phone';

  @override
  String get salesCustomerDetailAddressLabel => 'Billing address';

  @override
  String get salesCustomerDetailLifetimeValueLabel => 'Lifetime value';

  @override
  String get salesCustomerDetailSinceLabel => 'Customer since';

  @override
  String get salesCustomerDetailNotesHeading => 'Notes';

  @override
  String get salesCustomerDetailContactsHeading => 'Contacts';

  @override
  String get salesCustomerDetailContactsEmpty => 'No contacts linked yet.';

  @override
  String get salesCustomerDetailTimelineHeading => 'Activity';

  @override
  String get salesCustomerDetailTimelineEmpty => 'No activity yet.';

  @override
  String get salesContactAddAction => 'Add contact';

  @override
  String get salesContactEditAction => 'Edit';

  @override
  String get salesContactDeleteAction => 'Delete';

  @override
  String get salesContactPrimaryBadge => 'Primary';

  @override
  String get salesContactNewTitle => 'New contact';

  @override
  String get salesContactEditTitle => 'Edit contact';

  @override
  String get salesContactNameLabel => 'Name';

  @override
  String get salesContactRoleLabel => 'Role';

  @override
  String get salesContactEmailLabel => 'Email';

  @override
  String get salesContactPhoneLabel => 'Phone';

  @override
  String get salesContactPrimaryToggle => 'Primary contact';

  @override
  String get salesContactPrimaryDescription =>
      'Show this contact in the customer header.';

  @override
  String get salesContactSaveAction => 'Save contact';

  @override
  String get salesContactSavedSnack => 'Contact saved.';

  @override
  String salesContactSaveFailed(String message) {
    return 'Couldn\'t save contact: $message';
  }

  @override
  String get salesContactDeleteTitle => 'Delete contact?';

  @override
  String get salesContactDeleteBody =>
      'The contact will be removed from this customer.';

  @override
  String get salesContactDeleteConfirm => 'Delete';

  @override
  String get salesContactDeletedSnack => 'Contact removed.';

  @override
  String get salesActivityLogAction => 'Log activity';

  @override
  String get salesActivityFormTitle => 'Log activity';

  @override
  String get salesActivityTypeLabel => 'Type';

  @override
  String get salesActivitySummaryLabel => 'Summary';

  @override
  String get salesActivityActorLabel => 'Logged by';

  @override
  String get salesActivitySaveAction => 'Save activity';

  @override
  String get salesActivitySavedSnack => 'Activity logged.';

  @override
  String salesActivitySaveFailed(String message) {
    return 'Couldn\'t log activity: $message';
  }

  @override
  String get salesActivityTypeNote => 'Note';

  @override
  String get salesActivityTypeCall => 'Call';

  @override
  String get salesActivityTypeMeeting => 'Meeting';

  @override
  String get salesActivityTypeEmail => 'Email';

  @override
  String get salesActivityTypeQuotation => 'Quotation';

  @override
  String get salesActivityTypeOrder => 'Order';

  @override
  String get salesActivityTypePayment => 'Payment';

  @override
  String get salesQuotationListTitle => 'Quotations';

  @override
  String get salesQuotationNewTooltip => 'New quotation';

  @override
  String get salesQuotationSearchHint => 'Search by number or customer';

  @override
  String get salesQuotationSortTooltip => 'Sort';

  @override
  String get salesQuotationListEmpty => 'No quotations match your filters.';

  @override
  String salesQuotationValidUntilLabel(String date) {
    return 'valid until $date';
  }

  @override
  String get salesQuotationSortCreatedDesc => 'Created (newest)';

  @override
  String get salesQuotationSortCreatedAsc => 'Created (oldest)';

  @override
  String get salesQuotationSortTotalDesc => 'Total (largest)';

  @override
  String get salesQuotationSortValidity => 'Expiring next';

  @override
  String get salesQuotationStatusDraft => 'Draft';

  @override
  String get salesQuotationStatusSent => 'Sent';

  @override
  String get salesQuotationStatusAccepted => 'Accepted';

  @override
  String get salesQuotationStatusRejected => 'Rejected';

  @override
  String get salesQuotationStatusExpired => 'Expired';

  @override
  String get salesQuotationStatusConverted => 'Converted';

  @override
  String get salesQuotationNewTitle => 'New quotation';

  @override
  String get salesQuotationCustomerLabel => 'Customer';

  @override
  String get salesQuotationValidUntilField => 'Valid until';

  @override
  String get salesQuotationLinesHeading => 'Line items';

  @override
  String salesQuotationLineHeading(int index) {
    return 'Line $index';
  }

  @override
  String get salesQuotationAddLineAction => 'Add line';

  @override
  String get salesQuotationRemoveLineTooltip => 'Remove line';

  @override
  String get salesQuotationLineDescriptionLabel => 'Description';

  @override
  String get salesQuotationLineQuantityLabel => 'Qty';

  @override
  String get salesQuotationLineUnitPriceLabel => 'Unit price';

  @override
  String get salesQuotationSaveAction => 'Save quotation';

  @override
  String get salesQuotationSavedSnack => 'Quotation saved.';

  @override
  String salesQuotationSaveFailed(String message) {
    return 'Couldn\'t save quotation: $message';
  }

  @override
  String get salesQuotationPickCustomer => 'Please pick a customer.';

  @override
  String get salesQuotationDetailTitle => 'Quotation';

  @override
  String salesQuotationNotFound(String quotationId) {
    return 'We couldn\'t find a quotation with id \"$quotationId\".';
  }

  @override
  String get salesQuotationCreatedLabel => 'Created';

  @override
  String get salesQuotationValidUntilLabel2 => 'Valid until';

  @override
  String get salesQuotationDetailLinesHeading => 'Line items';

  @override
  String get salesQuotationTotalLabel => 'Total';

  @override
  String get salesQuotationNotesHeading => 'Notes';

  @override
  String get salesQuotationSendAction => 'Send to customer';

  @override
  String get salesQuotationAcceptAction => 'Mark accepted';

  @override
  String get salesQuotationRejectAction => 'Mark rejected';

  @override
  String get salesQuotationConvertAction => 'Convert to order';

  @override
  String get salesQuotationStatusUpdated => 'Quotation updated.';

  @override
  String get salesQuotationConvertedSnack => 'Sales order created.';

  @override
  String salesQuotationActionFailed(String message) {
    return 'Couldn\'t update quotation: $message';
  }

  @override
  String get salesQuotationConvertNotAccepted =>
      'Only accepted quotations can be converted.';

  @override
  String get salesQuotationConvertAlready =>
      'This quotation has already been converted.';

  @override
  String get salesQuotationConvertExpired => 'This quotation has expired.';

  @override
  String get salesOrderListTitle => 'Sales orders';

  @override
  String get salesOrderListEmpty => 'No orders yet.';

  @override
  String get salesOrderStatusPending => 'Pending';

  @override
  String get salesOrderStatusPacking => 'Packing';

  @override
  String get salesOrderStatusShipped => 'Shipped';

  @override
  String get salesOrderStatusDelivered => 'Delivered';

  @override
  String get salesOrderStatusCancelled => 'Cancelled';

  @override
  String get salesOrderDetailTitle => 'Sales order';

  @override
  String salesOrderNotFound(String orderId) {
    return 'We couldn\'t find an order with id \"$orderId\".';
  }

  @override
  String get salesOrderCreatedLabel => 'Created';

  @override
  String get salesOrderSourceQuotationLabel => 'Source quotation';

  @override
  String get salesOrderShippedAtLabel => 'Shipped';

  @override
  String get salesOrderDeliveredAtLabel => 'Delivered';

  @override
  String get salesOrderTrackingLabel => 'Tracking';

  @override
  String get salesOrderDetailLinesHeading => 'Line items';

  @override
  String get salesOrderCancelAction => 'Cancel';

  @override
  String get salesOrderStartPackingAction => 'Start packing';

  @override
  String get salesOrderShipAction => 'Ship';

  @override
  String get salesOrderMarkDeliveredAction => 'Mark delivered';

  @override
  String get salesOrderTrackingDialogTitle => 'Tracking reference';

  @override
  String get salesOrderTrackingConfirm => 'Confirm';

  @override
  String get salesOrderTrackingRequired =>
      'A tracking reference is required to ship.';

  @override
  String salesOrderAdvancedSnack(String status) {
    return 'Order marked as $status.';
  }

  @override
  String salesOrderAdvanceFailed(String message) {
    return 'Couldn\'t update order: $message';
  }

  @override
  String get salesAnalyticsTitle => 'Sales analytics';

  @override
  String get salesAnalyticsRevenueHeading => 'Revenue';

  @override
  String get salesAnalyticsRevenueEmpty => 'No revenue in the selected window.';

  @override
  String get salesAnalyticsPeriodWeekly => 'Weekly';

  @override
  String get salesAnalyticsPeriodMonthly => 'Monthly';

  @override
  String get salesAnalyticsTopCustomersHeading => 'Top customers';

  @override
  String get salesAnalyticsTopCustomersEmpty =>
      'No customer revenue to rank yet.';

  @override
  String get salesAnalyticsTopProductsHeading => 'Top products';

  @override
  String get salesAnalyticsTopProductsEmpty =>
      'No product revenue to rank yet.';

  @override
  String get salesAnalyticsLeaderboardHeading => 'Sales rep leaderboard';

  @override
  String get salesAnalyticsLeaderboardEmpty => 'No reps yet.';

  @override
  String salesAnalyticsLeaderboardDealsLabel(String count) {
    return '$count deals closed';
  }

  @override
  String salesAnalyticsLeaderboardAttainmentLabel(String pct, String target) {
    return '$pct% of $target';
  }

  @override
  String get errorBoundaryGenericMessage => 'Something went wrong';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get loginWelcomeSubtitle =>
      'Welcome back! Please sign in to continue.';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginForgotPasswordAction => 'Forgot Password?';

  @override
  String get loginSignInAction => 'Sign In';

  @override
  String get loginOrSecureWith => 'OR SECURE WITH';

  @override
  String get loginUseBiometricsAction => 'Use Biometrics';

  @override
  String get loginValidatorEmailRequired => 'Please enter your email';

  @override
  String get loginValidatorEmailInvalid => 'Please enter a valid email address';

  @override
  String get loginValidatorPasswordRequired => 'Please enter your password';

  @override
  String get loginValidatorPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get loginNoAccountPrompt => 'Don\'t have an account?';

  @override
  String get loginCreateAccountAction => 'Create one';

  @override
  String get registerWelcomeTitle => 'Create your account';

  @override
  String get registerWelcomeSubtitle =>
      'Start managing your business in minutes.';

  @override
  String get registerFullNameLabel => 'Full name';

  @override
  String get registerFullNameHint => 'Jane Doe';

  @override
  String get registerPhoneHint => '096 506 0999';

  @override
  String get registerValidatorPhoneRequired => 'Please enter your phone number';

  @override
  String get registerValidatorPhoneInvalid =>
      'Please enter a valid phone number';

  @override
  String get registerConfirmPasswordLabel => 'Confirm password';

  @override
  String get registerTermsPrefix =>
      'By tapping Create account you agree to our ';

  @override
  String get registerTermsLink => 'Terms';

  @override
  String get registerTermsAnd => ' and ';

  @override
  String get registerPrivacyLink => 'Privacy Policy';

  @override
  String get registerTermsSuffix => '.';

  @override
  String get registerSubmitAction => 'Create account';

  @override
  String get registerHaveAccountPrompt => 'Already have an account?';

  @override
  String get registerSignInAction => 'Sign in';

  @override
  String get registerValidatorFullNameRequired => 'Please enter your full name';

  @override
  String get registerValidatorPasswordsMismatch => 'Passwords do not match';

  @override
  String get registerValidatorAcceptTermsRequired =>
      'Please accept the terms to continue';

  @override
  String get registerAcceptTermsLabel =>
      'I accept the Terms and Privacy Policy';

  @override
  String get authGenericErrorFallback =>
      'Something went wrong. Please try again.';

  @override
  String get authNetworkErrorFallback =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email address and we will send you a link to reset your password.';

  @override
  String get forgotPasswordValidatorEmailRequired => 'Enter email';

  @override
  String get forgotPasswordSendResetAction => 'Send Reset Link';

  @override
  String get forgotPasswordSentTitle => 'Email Sent!';

  @override
  String get forgotPasswordSentSubtitle =>
      'Please check your inbox for instructions to reset your password.';

  @override
  String get forgotPasswordBackToLoginAction => 'Back to Login';

  @override
  String get biometricPageTitle => 'Biometric Unlock';

  @override
  String get biometricAuthenticatingTitle => 'Authenticating...';

  @override
  String get biometricHoldFingerSubtitle =>
      'Please hold your finger on the sensor';

  @override
  String get biometricUseFingerprintSubtitle =>
      'Use your fingerprint or face to continue';

  @override
  String get biometricUnlockNowAction => 'Unlock Now';

  @override
  String get biometricUsePasswordInsteadAction => 'Use Password Instead';

  @override
  String get otpResendCodeAction => 'Resend Code (30s)';

  @override
  String get splashTagline => 'Enterprise Excellence';

  @override
  String get dashboardGreeting => 'Good Morning,';

  @override
  String get dashboardUserNamePlaceholder => 'Demo Approver';

  @override
  String get dashboardQuickAccessSection => 'Quick Access';

  @override
  String get dashboardSimulatePushAction => 'Simulate Push';

  @override
  String get dashboardRoutedPushAction => 'Routed Push';

  @override
  String get dashboardKpiRevenueLabel => 'Revenue (MTD)';

  @override
  String get dashboardKpiOpenInvoicesLabel => 'Open invoices';

  @override
  String get dashboardKpiAvgFulfilmentLabel => 'Avg fulfilment (d)';

  @override
  String get accountDetailTransactionsHeading => 'TRANSACTIONS';

  @override
  String get accountDetailCurrentBalanceLabel => 'CURRENT BALANCE';

  @override
  String invoiceDetailRejectionReasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String invoiceListIssuedDateLabel(String date) {
    return 'ISSUED: $date';
  }

  @override
  String journalEntryListReferenceLabel(String reference, String date) {
    return 'REF: $reference · $date';
  }

  @override
  String commonSkuLabel(String sku) {
    return 'SKU: $sku';
  }

  @override
  String prListCreatedDateLabel(String date) {
    return 'CREATED: $date';
  }

  @override
  String prListDepartmentLabel(String dept) {
    return 'DEPT: $dept';
  }

  @override
  String inventorySkuLocationCompound(String sku, String loc) {
    return 'SKU: $sku · LOC: $loc';
  }

  @override
  String inventoryWarehouseLocationLabel(String wh, String loc) {
    return 'WH: $wh · LOC: $loc';
  }

  @override
  String get inventoryCurrentStockLabel => 'CURRENT STOCK';

  @override
  String get inventoryAvailableToTransferLabel => 'AVAILABLE TO TRANSFER';

  @override
  String get customerFormCompanyOrPersonNameLabel => 'Company or Person Name';

  @override
  String get customerFormIndustryOptionalLabel => 'Industry (Optional)';

  @override
  String get commonPhoneNumberLabel => 'Phone Number';

  @override
  String get commonPhoneLabel => 'Phone';

  @override
  String get customerFormBillingAddressLabel => 'Billing Address';

  @override
  String get customerFormNotesRemarksOptionalLabel =>
      'Notes / Remarks (Optional)';

  @override
  String customerFormSaveFailureSnack(String error) {
    return 'Failed to save customer: $error';
  }

  @override
  String get customerListNewCustomerAction => 'New Customer';

  @override
  String get commonCancelAction => 'Cancel';

  @override
  String get commonRetryAction => 'Retry';

  @override
  String get commonLoadFailedFallback => 'Could not load. Please try again.';

  @override
  String get assignmentsPageTitle => 'Assign Permissions & Roles';

  @override
  String get assignmentsRolesTab => 'Roles → Permissions';

  @override
  String get assignmentsUsersTab => 'Users → Roles';

  @override
  String get assignmentsPickRolePrompt => 'Pick a role to edit its permissions';

  @override
  String get assignmentsPickUserPrompt => 'Pick a user to edit their roles';

  @override
  String get assignmentsPermissionsSectionTitle => 'Permissions';

  @override
  String get assignmentsRolesSectionTitle => 'Roles';

  @override
  String assignmentsCountSuffix(int count) {
    return '$count selected';
  }

  @override
  String get assignmentsSaveAction => 'Save changes';

  @override
  String get assignmentsNoChangesYet => 'No changes';

  @override
  String get assignmentsSavedSnack => 'Saved';

  @override
  String get assignmentsSaveFailedSnack => 'Could not save changes';

  @override
  String get assignmentsForbiddenMessage =>
      'You don\'t have permission to make changes here.';

  @override
  String get assignmentsSuperAdminOnlyTitle => 'Super-administrators only';

  @override
  String get assignmentsSuperAdminOnlyMessage =>
      'Only super-administrators can assign roles and permissions. Sign in with a super-admin account to use this page.';

  @override
  String get assignmentsUsersSearchHint => 'Search users…';

  @override
  String get assignmentsSearchPermissionsHint => 'Search permissions…';

  @override
  String get assignmentsRolePickerLabel => 'Role';

  @override
  String get assignmentsSystemRoleBadge => 'SYSTEM';

  @override
  String get assignmentsSystemRoleLockedMessage =>
      'System roles are read-only. Create a custom role to assign different permissions.';

  @override
  String get assignmentsLoadMoreAction => 'Load more';

  @override
  String get assignmentsEmptyUsers => 'No users yet.';

  @override
  String get assignmentsNoUserSelected =>
      'Pick a user from the list to assign roles.';

  @override
  String get assignmentsNoRoleSelected =>
      'Pick a role above to start assigning permissions.';

  @override
  String get assignmentsAssignSubtitle =>
      'Pick a role, then the users to assign it to. Each user gets exactly one role.';

  @override
  String assignmentsSaveActionAssign(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# users',
      one: '# user',
    );
    return 'Assign role to $_temp0';
  }

  @override
  String get assignmentsUserFieldLabel => 'USERS';

  @override
  String get assignmentsRoleFieldLabel => 'ROLE';

  @override
  String get assignmentsModeFieldLabel => 'MODE';

  @override
  String get assignmentsRoleHelperPickUserFirst =>
      'Pick at least one user to enable role assignment.';

  @override
  String get assignmentsRoleHelperCurrentRole =>
      'Applies the selected role to every picked user.';

  @override
  String get assignmentsPickUsersPrompt => 'Pick users…';

  @override
  String assignmentsUsersSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# users selected',
      one: '# user selected',
    );
    return '$_temp0';
  }

  @override
  String assignmentsUsersSelectedSummary(String first, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '# others',
      one: '# other',
    );
    return '$first +$_temp0';
  }

  @override
  String get assignmentsModeAdd => 'Add';

  @override
  String get assignmentsModeReplace => 'Replace';

  @override
  String get assignmentsModeRemove => 'Remove';

  @override
  String get assignmentsModeHelperAdd =>
      'Adds the role on top of each user\'s existing roles.';

  @override
  String get assignmentsModeHelperReplace =>
      'Replaces each user\'s roles with only the picked role.';

  @override
  String get assignmentsModeHelperRemove =>
      'Strips the picked role from each user (others kept).';

  @override
  String assignmentsSaveActionBulk(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# users',
      one: '# user',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# users',
      one: '# user',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# users',
      one: '# user',
    );
    String _temp3 = intl.Intl.selectLogic(mode, {
      'add': 'Add role to $_temp0',
      'replace': 'Replace roles on $_temp1',
      'remove': 'Remove role from $_temp2',
      'other': 'Save changes',
    });
    return '$_temp3';
  }

  @override
  String get assignmentsSelectAllAction => 'Select all';

  @override
  String get assignmentsClearSelectionAction => 'Clear';

  @override
  String get assignmentsConfirmDoneAction => 'Done';

  @override
  String get assignmentsUserNoRoleBadge => 'No role';

  @override
  String assignmentsUserRolesMore(int count) {
    return '+$count';
  }

  @override
  String get assignmentsFilterAll => 'All';

  @override
  String get assignmentsFilterHasRole => 'Has role';

  @override
  String get assignmentsFilterNoRole => 'No role';

  @override
  String get commonApproveAction => 'Approve';

  @override
  String get commonRejectAction => 'Reject';

  @override
  String get hrEmployeeDetailNotFoundTitle => 'Employee not found';

  @override
  String hrEmployeeDetailNotFoundBody(String employeeId) {
    return 'No employee with ID \"$employeeId\" exists.';
  }

  @override
  String get hrEmployeeDetailOfficeLocationLabel => 'Office Location';

  @override
  String get hrEmployeeDetailDepartmentLabel => 'Department';

  @override
  String get hrEmployeeDetailPositionTitleLabel => 'Position Title';

  @override
  String get hrEmployeeDetailHireDateLabel => 'Hire Date';

  @override
  String get hrEmployeeDetailMonthlySalaryLabel => 'Monthly Salary';

  @override
  String get hrEmployeeDetailManagerIdLabel => 'Manager ID';

  @override
  String get hrEmployeeDetailTabAttendance => 'Attendance';

  @override
  String get hrEmployeeDetailTabPayslips => 'Payslips';

  @override
  String get hrEmployeeDetailTabLeaves => 'Leaves';

  @override
  String get hrEmployeeDetailTabOrgChart => 'Org Chart';

  @override
  String get hrEmployeeListOrgChartTooltip => 'Org chart';

  @override
  String get hrEmployeeListSortTooltip => 'Sort';

  @override
  String get hrEmployeeListSortNameAz => 'Name (A–Z)';

  @override
  String get hrEmployeeListSortRecentlyHired => 'Recently hired';

  @override
  String get hrEmployeeListSortDepartment => 'Department';

  @override
  String get hrEmployeeListErrorLoading => 'Error loading directory';

  @override
  String get hrEmployeeListSearchHint => 'Search name, email, position…';

  @override
  String get hrEmployeeListEmptyTitle => 'No matching employees';

  @override
  String get hrEmployeeListEmptySubtitle =>
      'Try refining your search query or filters';

  @override
  String get hrLeaveApprovalRejectReasonTitle => 'Reason for rejection';

  @override
  String get hrLeaveApprovalConfirmRejectionAction => 'Confirm Rejection';

  @override
  String get hrLeaveApprovalConfirmApprovalTitle =>
      'Approve this leave request?';

  @override
  String get hrLeaveApprovalNoteHint => 'Add a note (optional)';

  @override
  String get hrLeaveApprovalNoYearlyBalance => 'No yearly balance configured';

  @override
  String get hrLeaveApprovalFromLabel => 'From';

  @override
  String get hrLeaveApprovalToLabel => 'To';

  @override
  String hrLeaveApprovalSubmittedAt(String timestamp) {
    return 'Submitted $timestamp';
  }

  @override
  String get hrLeaveApprovalIfApprovedLabel => 'If Approved';

  @override
  String get hrLeaveApprovalIfRejectedLabel => 'If Rejected';

  @override
  String get hrLeaveRequestsTabAll => 'All';

  @override
  String get hrLeaveRequestsTabPending => 'Pending';

  @override
  String get hrLeaveRequestsTabMine => 'Mine';

  @override
  String get hrLeaveRequestsNewRequestTooltip => 'New request';

  @override
  String get hrLeaveRequestsEmptyTitle => 'No leave requests';

  @override
  String get hrLeaveRequestsEmptySubtitle =>
      'There are no requests matching this filter.';

  @override
  String get hrLeaveRequestsApprovedSnack => 'Leave request approved.';

  @override
  String get hrLeaveRequestsRejectDialogTitle => 'Reject Leave Request';

  @override
  String get hrLeaveRequestsRejectedSnack => 'Leave request rejected.';

  @override
  String get hrLeaveRequestsRejectionReasonRequiredSnack =>
      'A rejection reason is required.';

  @override
  String get hrLeaveFormSubmittedSnack =>
      'Leave request submitted successfully.';

  @override
  String get hrLeaveFormPreferencesSection => 'LEAVE PREFERENCES';

  @override
  String get hrLeaveFormDurationSection => 'DURATION SELECTOR';

  @override
  String get hrLeaveFormAttachmentsSection => 'ATTACHMENTS & EVIDENCE';

  @override
  String get hrLeaveFormJustificationSection => 'JUSTIFICATION';

  @override
  String get hrLeaveFormSubmitAction => 'Submit Leave Request';

  @override
  String get hrLeaveFormUploadingAttachment => 'Uploading attachment...';

  @override
  String get hrLeaveFormReadyToUpload => 'Ready to upload';

  @override
  String get hrLeaveFormRemoveAttachmentTooltip => 'Remove';

  @override
  String get hrLeaveFormTapToUploadDocument => 'TAP TO UPLOAD DOCUMENT';

  @override
  String get hrLeaveFormUploadSupportedFormats =>
      'Support PDF, PNG, JPG up to 10MB (Medical Cert, etc.)';

  @override
  String get hrLeaveBalanceHistoryTooltip => 'Leave History';

  @override
  String get hrLeaveBalanceRequestLeaveTooltip => 'Request Leave';

  @override
  String get hrLeaveBalanceNoEntitlements => 'No entitlements on file';

  @override
  String get hrLeaveBalanceRemainingLabel => 'Remaining';

  @override
  String get hrLeaveBalanceTakenLabel => 'Taken';

  @override
  String get hrLeaveBalanceTotalLabel => 'Total';

  @override
  String get hrLeaveBalanceBreakdownHeading => 'ENTITLEMENT BREAKDOWN';

  @override
  String get hrAttendanceRecentEntriesHeading => 'RECENT ENTRIES';

  @override
  String get hrAttendanceEmptyMessage => 'No attendance records yet';

  @override
  String get hrPayslipsEmpty => 'No payslips on file';

  @override
  String get hrPayslipsArchiveHeading => 'PAYSLIP ARCHIVE';

  @override
  String get hrPayslipsAggregateSummaryHeading => 'Aggregate Summary';

  @override
  String hrPayslipsNetPayLabel(String amount) {
    return 'Net: $amount';
  }

  @override
  String hrPayslipsGrossPayLabel(String amount) {
    return 'Gross: $amount';
  }

  @override
  String hrPayslipDetailNotFound(String payslipId) {
    return 'No payslip with id \"$payslipId\".';
  }

  @override
  String get hrPayslipDetailNetPayoutLabel => 'NET PAYOUT';

  @override
  String get hrPayslipDetailBreakdownHeading => 'LINE ITEM BREAKDOWN';

  @override
  String get hrOrgChartPageTitle => 'Organization Chart';

  @override
  String get hrOrgChartEmptyTitle => 'No employees found';

  @override
  String get hrOrgChartEmptySubtitle => 'Add employees to see the hierarchy.';

  @override
  String get hrAttendancePageTitle => 'Attendance Log';

  @override
  String get hrEmployeeDetailPageTitle => 'Employee Profile';

  @override
  String get hrEmployeeDetailSectionQuickActions => 'Quick Actions';

  @override
  String get hrEmployeeDetailSectionContact => 'Contact Information';

  @override
  String get hrEmployeeDetailSectionEmployment => 'Employment Details';

  @override
  String get hrEmployeeListPageTitle => 'Employee Directory';

  @override
  String get hrLeaveApprovalPageTitle => 'Leave Request';

  @override
  String get hrLeaveBalancePageTitle => 'Leave Balance';

  @override
  String get hrLeaveRequestsPageTitle => 'Leave Requests';

  @override
  String get hrLeaveFormPageTitle => 'New Leave Request';

  @override
  String get hrPayslipsPageTitle => 'Payslips History';

  @override
  String get hrPayslipDetailPageTitle => 'Payslip Detail';

  @override
  String get projectBoardPageTitle => 'Task Board';

  @override
  String get projectBoardNewTaskAction => 'New Task';

  @override
  String get projectBoardDropZoneHint => 'Drop tasks here';

  @override
  String get projectDetailPageTitle => 'Project Details';

  @override
  String get projectDetailOpenBoardTooltip => 'Open Board';

  @override
  String get projectDetailEditProjectTooltip => 'Edit Project';

  @override
  String projectDetailNotFound(String projectId) {
    return 'No project with id \"$projectId\".';
  }

  @override
  String projectDetailProjectIdLabel(String code) {
    return 'Project ID: $code';
  }

  @override
  String get projectDetailDescriptionHeading => 'DESCRIPTION';

  @override
  String get projectDetailTasksHeading => 'PROJECT TASKS';

  @override
  String get projectDetailNoTasks => 'No tasks assigned yet.';

  @override
  String get projectFormNameLabel => 'Project name';

  @override
  String get projectFormCodeLabel => 'Project code';

  @override
  String get projectFormDescriptionLabel => 'Description';

  @override
  String get projectFormStartLabel => 'Start';

  @override
  String get projectFormEndLabel => 'End';

  @override
  String projectFormDurationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get projectFormBudgetLabel => 'Budget (formatted)';

  @override
  String get projectFormPickEmployeeAction => 'Pick an employee';

  @override
  String get projectListPageTitle => 'Projects';

  @override
  String get projectListTimesheetsTooltip => 'Timesheets';

  @override
  String get projectListSortTooltip => 'Sort';

  @override
  String get projectListSortNameAz => 'Name (A–Z)';

  @override
  String get projectListSortRecentlyStarted => 'Recently started';

  @override
  String get projectListSortDueSoonest => 'Due soonest';

  @override
  String projectListErrorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get projectListViewListAction => 'List View';

  @override
  String get projectListViewGanttAction => 'Gantt Chart';

  @override
  String get projectListSearchHint => 'Search name, code, owner…';

  @override
  String get projectListEmpty => 'No projects match.';

  @override
  String get projectListNewProjectAction => 'New Project';

  @override
  String projectListCodeOwnerSubtitle(String code, String owner) {
    return 'Code: $code • Owner: $owner';
  }

  @override
  String get taskAssignPageTitle => 'Assign Task';

  @override
  String get taskAssignErrorLoading => 'Could not load employees';

  @override
  String taskAssignSuccessSnack(String name) {
    return 'Assigned to $name';
  }

  @override
  String taskAssignFailureSnack(String error) {
    return 'Assign failed: $error';
  }

  @override
  String get taskAssignCurrentlyLabel => 'Currently: ';

  @override
  String get taskAssignSearchHint => 'Search by name, role or department…';

  @override
  String get taskAssignClearTooltip => 'Clear';

  @override
  String get taskAssignNoteHint =>
      'Add a note to the assignee… (e.g. \"context in #project-alpha\")';

  @override
  String get taskAssignEmpty => 'No employees match that search.';

  @override
  String get taskDetailPageTitle => 'Task Details';

  @override
  String get taskDetailMoreTooltip => 'More';

  @override
  String get taskDetailEditTaskAction => 'Edit task';

  @override
  String get taskDetailReassignAction => 'Reassign';

  @override
  String taskDetailNotFound(String taskId) {
    return 'No task with id \"$taskId\".';
  }

  @override
  String get taskDetailDescriptionHeading => 'DESCRIPTION';

  @override
  String get taskDetailCommentsHeading => 'COMMENTS';

  @override
  String get taskDetailNoComments => 'No comments yet.';

  @override
  String get taskDetailAddCommentHint => 'Add a comment…';

  @override
  String get taskFormPageTitleEdit => 'Edit Task';

  @override
  String get taskFormPageTitleNew => 'New Task';

  @override
  String get taskFormTitleRequiredValidator => 'Title is required';

  @override
  String get taskFormTitleHint => 'What needs to be done?';

  @override
  String get taskFormDescriptionHint => 'Add a description…';

  @override
  String get taskFormStatusLabel => 'Status';

  @override
  String get taskFormPriorityLabel => 'Priority';

  @override
  String get taskFormAssigneeLabel => 'Assignee';

  @override
  String get taskFormUnassignedLabel => 'Unassigned';

  @override
  String get taskFormDueDateLabel => 'Due Date';

  @override
  String get taskFormClearDueDateTooltip => 'Clear due date';

  @override
  String get taskFormAddDueDateAction => 'Add due date';

  @override
  String get taskFormAssignToAction => 'Assign to…';

  @override
  String get taskFormUnassignAction => 'Unassign';

  @override
  String get timesheetsPageTitle => 'Timesheets';

  @override
  String get timesheetsUtilizationTooltip => 'Utilization';

  @override
  String get timesheetsTabMine => 'Mine';

  @override
  String get timesheetsTabApprovals => 'Approvals';

  @override
  String get timesheetsTabAll => 'All';

  @override
  String get timesheetsEmpty => 'No timesheet entries found.';

  @override
  String get timesheetsLogTimeAction => 'Log time';

  @override
  String timesheetsTaskLabel(String title) {
    return 'Task: $title';
  }

  @override
  String timesheetsRejectionNoteLabel(String note) {
    return 'Rejection Note: $note';
  }

  @override
  String get timesheetsSubmitForApprovalAction => 'Submit for Approval';

  @override
  String get timesheetsReopenAsDraftAction => 'Re-open as Draft';

  @override
  String get timesheetsApprovedSnack => 'Timesheet approved.';

  @override
  String get timesheetsRejectDialogTitle => 'Reject timesheet';

  @override
  String get timesheetsRejectedSnack => 'Timesheet rejected.';

  @override
  String get timesheetsReasonRequiredSnack => 'A reason is required.';

  @override
  String get timesheetsSubmittedSnack => 'Submitted for approval.';

  @override
  String get timesheetsReopenedSnack => 'Reopened as draft.';

  @override
  String get timesheetFormPageTitle => 'Log Time';

  @override
  String get timesheetFormSubmitToggleLabel =>
      'Submit for approval immediately';

  @override
  String get timesheetFormSubmitToggleHint =>
      'Otherwise it lands as a draft you can edit later.';

  @override
  String get timesheetFormSaveAction => 'Save Timesheet';

  @override
  String get utilizationPageTitle => 'Utilization';

  @override
  String get utilizationThisWeekToggle => 'This week';

  @override
  String get utilizationThisMonthToggle => 'This month';

  @override
  String get utilizationApprovedHoursHeading => 'APPROVED HOURS VS TARGET';

  @override
  String get utilizationNoHoursInWindow => 'No approved hours in this window.';

  @override
  String get ganttChartNoProjects => 'No projects in this window.';

  @override
  String get settingsHomePageTitle => 'Settings';

  @override
  String get settingsHomeAccountSection => 'Account';

  @override
  String get settingsHomeMyProfileTitle => 'My profile';

  @override
  String get settingsHomeMyProfileSubtitle => 'Contact, personal, security';

  @override
  String get settingsHomeMyRolesTitle => 'My roles & permissions';

  @override
  String get settingsHomeMyRolesSubtitle => 'What you can do in the app';

  @override
  String get settingsHomePreferencesSection => 'Preferences';

  @override
  String get settingsHomeAppearanceTitle => 'Appearance';

  @override
  String get settingsHomeAppearanceSubtitle => 'Light, dark, or follow system';

  @override
  String get settingsHomeLanguageTitle => 'Language';

  @override
  String get settingsHomeLanguageSubtitle => 'English / ខ្មែរ';

  @override
  String get settingsHomeNotificationsTitle => 'Notifications';

  @override
  String get settingsHomeNotificationsSubtitle => 'Push + email per category';

  @override
  String get settingsHomeSecuritySection => 'Security & Access';

  @override
  String get settingsHomeActiveDevicesTitle => 'Active devices';

  @override
  String get settingsHomeActiveDevicesSubtitle => 'Sessions you can revoke';

  @override
  String get settingsHomeAuditLogTitle => 'Audit log';

  @override
  String get settingsHomeAuditLogSubtitle => 'Who did what, when';

  @override
  String get settingsHomeAppLockTitle => 'App lock';

  @override
  String get settingsHomeAppLockSubtitle => 'PIN + biometric re-auth';

  @override
  String get settingsHomeAdminSection => 'Administration';

  @override
  String get settingsHomeUserMgmtTitle => 'User management';

  @override
  String get settingsHomeUserMgmtSubtitle => 'Invite, suspend, assign roles';

  @override
  String get settingsHomeRolesPermsTitle => 'Roles & permissions';

  @override
  String get settingsHomeRolesPermsSubtitle => 'Editor for custom roles';

  @override
  String get settingsHomeApiConfigTitle => 'API configuration';

  @override
  String get settingsHomeApiConfigSubtitle => 'Switch environment / tenant';

  @override
  String get settingsHomeSignOutAction => 'Sign out';

  @override
  String get settingsHomeSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsHomeSignOutConfirmMessage =>
      'You\'ll need to sign in again to access your data on this device.';

  @override
  String get settingsHomeSignOutErrorSnack =>
      'Could not sign out cleanly. Please try again.';

  @override
  String get appearancePageTitle => 'Appearance';

  @override
  String get appearanceChooseThemeHeading => 'CHOOSE THEME MODE';

  @override
  String get appearanceModeSystem => 'System default';

  @override
  String get appearanceModeLight => 'Light Mode';

  @override
  String get appearanceModeDark => 'Dark Mode';

  @override
  String get appearanceSubtitleSystem => 'Follow the OS appearance setting';

  @override
  String get appearanceSubtitleLight => 'Always use the light palette';

  @override
  String get appearanceSubtitleDark => 'Always use the dark palette';

  @override
  String get languagePageTitle => 'Language';

  @override
  String get languageSelectPreferredHeading => 'SELECT PREFERRED LANGUAGE';

  @override
  String get languageDemoLaunchNote =>
      'Language change applies on next app launch in this demo build.';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languageKhmerLabel => 'Khmer';

  @override
  String get languageEnglishNative => 'United Kingdom';

  @override
  String get languageKhmerNative => 'ភាសាខ្មែរ';

  @override
  String get notificationPrefsPageTitle => 'Notifications';

  @override
  String get notificationPrefsChannelsHeading => 'NOTIFICATION CHANNELS';

  @override
  String get notificationPrefsPushTitle => 'Push Notifications';

  @override
  String get notificationPrefsEmailTitle => 'Email Updates';

  @override
  String get notificationPrefsChannelApprovals => 'Approvals';

  @override
  String get notificationPrefsChannelMentions => 'Mentions & comments';

  @override
  String get notificationPrefsChannelSystemAlerts => 'System alerts';

  @override
  String get notificationPrefsChannelMarketing => 'Marketing & tips';

  @override
  String get notificationPrefsChannelApprovalsDescription =>
      'Invoices, leave requests, timesheets pending action';

  @override
  String get notificationPrefsChannelMentionsDescription =>
      'Someone @-mentioned you on a task or comment';

  @override
  String get notificationPrefsChannelSystemAlertsDescription =>
      'Sync failures, downtime windows, security events';

  @override
  String get notificationPrefsChannelMarketingDescription =>
      'Product news, tips, and feature announcements';

  @override
  String get sessionsPageTitle => 'Active devices';

  @override
  String get sessionsSignOutOthersSnack => 'Other devices signed out.';

  @override
  String get sessionsSignOutOthersAction => 'Sign out all other devices';

  @override
  String get sessionsEmpty => 'No active sessions.';

  @override
  String get sessionsThisDeviceLabel => 'This device';

  @override
  String get sessionsRevokeAccessAction => 'Revoke Access';

  @override
  String get sessionsLastActiveLabel => 'Last active';

  @override
  String get sessionsSignedInLabel => 'Signed in';

  @override
  String get sessionsLocationLabel => 'Location';

  @override
  String get sessionsIpAddressLabel => 'IP Address';

  @override
  String sessionsRevokedSnack(String device) {
    return '$device signed out.';
  }

  @override
  String get auditLogPageTitle => 'Audit Log';

  @override
  String get auditLogSearchHint => 'Search actor, target, or details…';

  @override
  String get auditLogEmpty => 'No log entries match your filters.';

  @override
  String get auditLogDetailDialogTitle => 'Audit Entry Details';

  @override
  String get auditLogAdditionalMetadataLabel => 'Additional Metadata:';

  @override
  String get auditLogCloseAction => 'Close';

  @override
  String get auditLogActorIdLabel => 'Actor ID';

  @override
  String get auditLogActorNameLabel => 'Actor Name';

  @override
  String get auditLogActionVerbLabel => 'Action Verb';

  @override
  String get auditLogTargetTypeLabel => 'Target Type';

  @override
  String get auditLogTargetIdLabel => 'Target ID';

  @override
  String get auditLogTargetLabelLabel => 'Target Label';

  @override
  String get auditLogTimestampLabel => 'Timestamp';

  @override
  String get appLockPageTitle => 'App Lock Settings';

  @override
  String get appLockDeviceProtectionHeading => 'DEVICE PROTECTION';

  @override
  String get appLockPinTitle => 'App Lock PIN';

  @override
  String get appLockPinSubtitle => 'Require a secure 4–8 digit PIN on resume';

  @override
  String get appLockBiometricTitle => 'Biometric Authentication';

  @override
  String get appLockBiometricSubtitle =>
      'Use Face ID / Fingerprint instead of entering PIN';

  @override
  String get appLockTimeoutHeading => 'TIMEOUT CONFIGURATION';

  @override
  String get appLockAutoLockDurationTitle => 'Auto-lock Duration';

  @override
  String get appLockChangePinTitle => 'Change Lock PIN';

  @override
  String get appLockChangePinSubtitle => 'Replace existing security entry code';

  @override
  String get appLockPinUpdatedSnack => 'PIN updated successfully.';

  @override
  String get appLockSetSecurePinAction => 'Set Secure PIN';

  @override
  String get appLockSavePinAction => 'Save PIN';

  @override
  String get appLockCannotEnableFallback => 'Cannot enable.';

  @override
  String get appLockLockImmediatelySubtitle =>
      'Lock immediately on backgrounding';

  @override
  String appLockMinutesAfterBackgroundSubtitle(int count) {
    return '$count minutes after backgrounding';
  }

  @override
  String get appLockRequiresPinSubtitle =>
      'Requires App Lock PIN to be enabled';

  @override
  String get appLockFootnote =>
      'Your PIN and biometric metrics are secure. Keys are strictly kept inside the hardware OS-backed Keystore / Keychain. Uninstalling or wiping application storage resets lock settings.';

  @override
  String get appLockAutoLockSheetSubtitle =>
      'Select the inactivity grace period before the app locks';

  @override
  String get appLockHeaderEnabledTitle => 'App Protection Enabled';

  @override
  String get appLockHeaderDisabledTitle => 'App Protection Disabled';

  @override
  String get appLockHeaderEnabledSubtitle =>
      'Your device settings mandate a security checkpoint upon resume.';

  @override
  String get appLockHeaderDisabledSubtitle =>
      'Configure a security PIN below to safeguard your ERP environment data.';

  @override
  String get appLockOptionImmediately => 'Immediately';

  @override
  String appLockOptionMinute(int count) {
    return '$count minute';
  }

  @override
  String appLockOptionMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get appLockOptionImmediatelySubtitle =>
      'Lock the app the instant it goes to background';

  @override
  String appLockOptionMinuteSubtitle(int count) {
    return 'Lock the app after $count minute in background';
  }

  @override
  String appLockOptionMinutesSubtitle(int count) {
    return 'Lock the app after $count minutes in background';
  }

  @override
  String get appLockPinFieldLabel => 'PIN (4–8 digits)';

  @override
  String get appLockConfirmPinLabel => 'Confirm PIN';

  @override
  String get apiConfigPageTitle => 'API Configuration';

  @override
  String get apiConfigClustersHeading => 'AVAILABLE ENVIRONMENT CLUSTERS';

  @override
  String apiConfigSwitchedSnack(String name) {
    return 'Switched environment cluster to \"$name\".';
  }

  @override
  String get apiConfigAddClusterAction => 'Add Cluster';

  @override
  String get apiConfigAddCustomClusterTitle => 'Add Custom Cluster';

  @override
  String get apiConfigBuiltInBadge => 'BUILT-IN';

  @override
  String apiConfigDeletedSnack(String name) {
    return 'Deleted environment cluster \"$name\".';
  }

  @override
  String get apiConfigClusterNameLabel => 'Cluster Name';

  @override
  String get apiConfigClusterNameHint => 'e.g. Asia Pacific Staging';

  @override
  String get apiConfigBaseUrlLabel => 'Base URL';

  @override
  String get apiConfigBaseUrlHint => 'https://api-apac.tenant.example.com';

  @override
  String get apiConfigBannerWarning =>
      'Switching environment clusters signs you out of the current tenant session to prevent cross-contamination of credentials.';

  @override
  String get apiConfigCannotDeleteFallback => 'Cannot delete.';

  @override
  String get roleEditorPageTitle => 'Roles & Permissions';

  @override
  String get roleEditorNewRoleAction => 'New Role';

  @override
  String get roleEditorCreateCustomRoleTitle => 'Create Custom Role';

  @override
  String get roleEditorRoleNameLabel => 'Role Name (e.g. Finance Admin)';

  @override
  String get roleEditorDescriptionLabel => 'Description';

  @override
  String get roleEditorAssignScopesHeading => 'Assign Permission Scopes';

  @override
  String get roleEditorCreateRoleAction => 'Create Role';

  @override
  String get roleEditorSystemBadge => 'SYSTEM';

  @override
  String get roleEditorPermissionScopesHeading => 'PERMISSION SCOPES';

  @override
  String get roleEditorDeleteRoleAction => 'Delete Role';

  @override
  String roleEditorUpdateFailedSnack(String error) {
    return 'Cannot update permissions: $error';
  }

  @override
  String roleEditorDeleteConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get roleEditorDeleteConfirmMessage =>
      'This action cannot be undone and will strip permissions from all assigned users.';

  @override
  String get roleEditorCannotDeleteFallback => 'Cannot delete.';

  @override
  String get roleEditorDeleteAction => 'Delete';

  @override
  String get userMgmtPageTitle => 'User Managements';

  @override
  String get userMgmtEmpty => 'No users match the selected status.';

  @override
  String get userMgmtInviteUserAction => 'Invite User';

  @override
  String get userMgmtInviteSheetTitle => 'Invite a new user';

  @override
  String get userMgmtAssignRolesLabel => 'Assign Roles';

  @override
  String userMgmtInvitedSnack(String email) {
    return 'Invited $email';
  }

  @override
  String get userMgmtSendInvitationAction => 'Send Invitation';

  @override
  String get userMgmtYouBadge => 'You';

  @override
  String get userMgmtActivateUserAction => 'Activate User';

  @override
  String get userMgmtSuspendUserAction => 'Suspend User';

  @override
  String userMgmtStatusSetSnack(String status) {
    return 'Status set to $status.';
  }

  @override
  String get userMgmtFilterAll => 'All';

  @override
  String get userMgmtFilterActive => 'Active';

  @override
  String get userMgmtFilterInvited => 'Invited';

  @override
  String get userMgmtFilterSuspended => 'Suspended';

  @override
  String get userMgmtNewUserPlaceholder => 'New User';

  @override
  String get userMgmtEmailAddressLabel => 'Email Address';

  @override
  String get userMgmtFullNameLabel => 'Full Name';

  @override
  String get userMgmtCannotApplyFallback => 'Cannot apply.';

  @override
  String get userMgmtStatusActive => 'ACTIVE';

  @override
  String get userMgmtStatusInvited => 'INVITED';

  @override
  String get userMgmtStatusSuspended => 'SUSPENDED';

  @override
  String get myRolesPageTitle => 'My Roles & Permissions';

  @override
  String get myRolesGrantedTitle => 'Granted';

  @override
  String get myRolesNotGrantedTitle => 'Not Granted';

  @override
  String get myRolesAssignedRolesLabel => 'Your assigned roles';

  @override
  String myRolesSyncedAtLabel(String timestamp) {
    return 'Synced $timestamp';
  }

  @override
  String get myRolesSearchHint => 'Search permissions…';

  @override
  String get myProfilePageTitle => 'My Profile';

  @override
  String get myProfileUpdatedSnack => 'Profile updated.';

  @override
  String get myProfileEditAction => 'Edit';

  @override
  String get myProfileContactSection => 'Contact';

  @override
  String get myProfilePersonalSection => 'Personal';

  @override
  String get myProfileAccountSecuritySection => 'Account Security';

  @override
  String get myProfilePhotoLocalSheetSubtitle =>
      'Photo only changes on this device.';

  @override
  String get myProfileImageReadErrorSnack =>
      'Could not read the selected image.';

  @override
  String myProfileImagePickErrorSnack(String error) {
    return 'Could not pick image: $error';
  }

  @override
  String get myProfileEmployeeRowLabel => 'Employee';

  @override
  String get myProfileTenureRowLabel => 'Tenure';

  @override
  String get myProfileLastLoginRowLabel => 'Last login';

  @override
  String get myProfileEmployeeIdLabel => 'Employee ID';

  @override
  String get myProfileHireDateLabel => 'Hire date';

  @override
  String get myProfileBirthdateLabel => 'Birthdate';

  @override
  String get myProfileAddressLabel => 'Address';

  @override
  String get myProfileEmergencyContactLabel => 'Emergency contact';

  @override
  String get myProfileEmergencyPhoneLabel => 'Emergency phone';

  @override
  String get myProfileFullNameLabel => 'Full name';

  @override
  String get myProfileSaveChangesAction => 'Save changes';

  @override
  String get myProfileChangePasswordTitle => 'Change password';

  @override
  String get myProfileChangePasswordSubtitle => 'Requires current password';

  @override
  String get myProfileChangePinTitle => 'Change PIN';

  @override
  String get myProfileChangePinSubtitle => 'Set or replace your unlock PIN';

  @override
  String get myProfileEnableBiometricTitle => 'Enable biometric';

  @override
  String myProfileLastLoginAtLabel(String date) {
    return 'Last login: $date';
  }

  @override
  String get myProfileReAuthBadge => 'RE-AUTH';

  @override
  String get myProfileBiometricUnlockTitle => 'Biometric unlock';

  @override
  String get myProfileConfirmAction => 'Confirm';

  @override
  String myProfileSaveErrorSnack(String error) {
    return 'Could not save changes: $error';
  }

  @override
  String get myProfileChangePhotoSheetTitle => 'Change profile photo';

  @override
  String get myProfileAddPhotoSheetTitle => 'Add a profile photo';

  @override
  String get myProfileEmailRequiresVerificationHelper =>
      'Requires verification on the new address';

  @override
  String get myProfilePhoneRequiresVerificationHelper =>
      'Requires SMS verification on the new number';

  @override
  String get myProfileManagedByHrBadge => 'Managed by HR';

  @override
  String get myProfileChangePasswordReAuthMessage =>
      'Re-enter your current password to confirm this change.';

  @override
  String get myProfileChangePinReAuthMessage =>
      'Re-authenticate before changing your PIN.';

  @override
  String get myProfileEnableBiometricReAuthMessage =>
      'Re-authenticate to bind your device biometric to this app.';

  @override
  String get myProfileCannotToggleBiometricFallback =>
      'Cannot toggle biometric';

  @override
  String get myProfilePasswordChangeStubSnack =>
      'Password change flow would open here.';

  @override
  String get myProfileCurrentPasswordLabel => 'Current password';

  @override
  String get myProfileBiometricEnabledSubtitle =>
      'Tap to disable — re-auth not required';

  @override
  String get myProfileBiometricDisabledSubtitle => 'Re-auth required to enable';

  @override
  String get myProfileNameFieldHumanLabel => 'Name';

  @override
  String get myProfileEmailFieldHumanLabel => 'Email';

  @override
  String get myProfilePhoneFieldHumanLabel => 'Phone';

  @override
  String get myProfileRelativeToday => 'Today';

  @override
  String get myProfileRelativeYesterday => 'Yesterday';

  @override
  String myProfileRelativeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String myProfileRelativeWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String myProfileRelativeMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String myProfileRelativeYearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String get myProfileTenureLessThanMonth => '<1 mo';

  @override
  String myProfileTenureMonths(int count) {
    return '$count mo';
  }

  @override
  String myProfileTenureYear(int count) {
    return '$count yr';
  }

  @override
  String myProfileTenureYears(int count) {
    return '$count yrs';
  }

  @override
  String myProfileTenureYearsMonths(int years, int months) {
    return '${years}y ${months}m';
  }
}
