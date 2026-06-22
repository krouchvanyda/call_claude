import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// Application title shown on splash and home screens
  ///
  /// In en, this message translates to:
  /// **'ERP Mobile'**
  String get appName;

  /// Title bar on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginAppBarTitle;

  /// Primary button on the login form. Placeholder copy until Module 1 ships the real OAuth flow.
  ///
  /// In en, this message translates to:
  /// **'Sign in (placeholder)'**
  String get loginButton;

  /// Title bar on the dashboard / home screen
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// Body text on the dashboard while Module 2 is unimplemented
  ///
  /// In en, this message translates to:
  /// **'Dashboard placeholder — Module 2 will fill this in.'**
  String get dashboardPlaceholder;

  /// Tooltip on the sign-out icon button in the dashboard app bar
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTooltip;

  /// Title bar on the 404 / no-route-matched page
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFoundTitle;

  /// Body text on the 404 page; explains which path the router could not resolve
  ///
  /// In en, this message translates to:
  /// **'No route matches \"{location}\"'**
  String notFoundBody(String location);

  /// Action button that returns the user to the splash / home route
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// Subtle text button on the login page that navigates to the OTP demo route (Slice 1.2.1)
  ///
  /// In en, this message translates to:
  /// **'[demo] Try MFA code'**
  String get loginOtpDemoLink;

  /// Title bar on the OTP / TOTP entry page
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get otpPageTitle;

  /// Body copy under the OTP page icon, instructing the user
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app or SMS.'**
  String get otpSubtitle;

  /// Italic hint reminding the user of the dev backdoor code while the real verifier is not wired
  ///
  /// In en, this message translates to:
  /// **'Demo: enter {code} to continue'**
  String otpDevHint(String code);

  /// Primary action button on the OTP page
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// Error shown under the OTP boxes when the entered code does not match
  ///
  /// In en, this message translates to:
  /// **'Code is incorrect. Please try again.'**
  String get otpErrorIncorrect;

  /// Error shown when the OTP validity window has elapsed
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one.'**
  String get otpErrorExpired;

  /// Error shown when the server throttles further OTP attempts
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get otpErrorTooManyAttempts;

  /// Error shown when the OTP verifier is unreachable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection.'**
  String get otpErrorNetwork;

  /// Title bar on the 403 / permission-gated landing page
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get forbiddenTitle;

  /// Body text on the forbidden page; explains which path was denied
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to access \"{location}\".'**
  String forbiddenBody(String location);

  /// Title bar on the permission-gated demo page (Slice 1.3.2)
  ///
  /// In en, this message translates to:
  /// **'Admin demo'**
  String get adminDemoTitle;

  /// Body of the admin demo page, confirming the route guard let the user through
  ///
  /// In en, this message translates to:
  /// **'You reached the admin-only demo route — RBAC works.'**
  String get adminDemoBody;

  /// Subtle text button on the dashboard that navigates to the admin-only demo route (Slice 1.3.2)
  ///
  /// In en, this message translates to:
  /// **'[demo] Open admin-only page'**
  String get dashboardAdminDemoLink;

  /// Chip label on the dashboard when the live PermissionGuard verdict for `admin` is allowed (Slice 1.3.3)
  ///
  /// In en, this message translates to:
  /// **'[demo] PermissionGuard: admin granted'**
  String get permissionGuardDemoGranted;

  /// Chip label on the dashboard when the live PermissionGuard verdict for `admin` is denied (Slice 1.3.3)
  ///
  /// In en, this message translates to:
  /// **'[demo] PermissionGuard: admin denied'**
  String get permissionGuardDemoDenied;

  /// Bottom-nav / rail label for the Home (dashboard) shell branch
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellHome;

  /// Bottom-nav / rail label for the Modules shell branch (Slice 2.1.2 fills it)
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get shellModules;

  /// Bottom-nav / rail label for the Settings shell branch (Module 9 fills it)
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shellSettings;

  /// AppBar title on the Modules placeholder page
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modulesTitle;

  /// Body text on the Modules placeholder page (kept for compatibility — no longer rendered after Slice 2.1.2)
  ///
  /// In en, this message translates to:
  /// **'Module shortcut tiles land here in Slice 2.1.2.'**
  String get modulesPlaceholder;

  /// Empty-state message on the Modules grid when the signed-in user holds no permission that satisfies any catalog tile
  ///
  /// In en, this message translates to:
  /// **'No modules are available for your role yet. Ask an admin to grant the permissions you need.'**
  String get modulesEmpty;

  /// Module-grid tile label for the Slice 1.3.2 admin-only demo route
  ///
  /// In en, this message translates to:
  /// **'Admin demo'**
  String get shortcutAdminDemo;

  /// Module-grid tile label for the Finance feature module (CLAUDE.md Module 3)
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get shortcutFinance;

  /// Module-grid tile label for the Procurement feature module (CLAUDE.md Module 4)
  ///
  /// In en, this message translates to:
  /// **'Procurement'**
  String get shortcutProcurement;

  /// Module-grid tile label for the Inventory feature module (CLAUDE.md Module 5)
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get shortcutInventory;

  /// Module-grid tile label for the Sales & CRM feature module (CLAUDE.md Module 6)
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get shortcutSales;

  /// Module-grid tile label for the Human Resources feature module (CLAUDE.md Module 7)
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get shortcutHr;

  /// Module-grid tile label for the Project Management feature module (CLAUDE.md Module 8)
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get shortcutProjects;

  /// Body of the generic coming-soon landing page; explains which module the user reached
  ///
  /// In en, this message translates to:
  /// **'{module} ships in a future release.'**
  String comingSoonBody(String module);

  /// AppBar title on the Settings placeholder page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Body text on the Settings placeholder page
  ///
  /// In en, this message translates to:
  /// **'Real preferences land here in Module 9.'**
  String get settingsPlaceholder;

  /// Tooltip on the global search icon button in the AppBar (Slice 2.1.3)
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get globalSearchTooltip;

  /// Placeholder text inside the global search overlay's text field
  ///
  /// In en, this message translates to:
  /// **'Search modules, records, people…'**
  String get globalSearchHint;

  /// Idle-state body shown in the search overlay before the user has typed anything
  ///
  /// In en, this message translates to:
  /// **'Type to search across every module you can access.'**
  String get globalSearchPrompt;

  /// Empty-results body shown after a search returns nothing across all providers
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\".'**
  String globalSearchNoResults(String query);

  /// Body shown when the federated search use case itself throws (per-provider failures are absorbed silently)
  ///
  /// In en, this message translates to:
  /// **'Search failed: {message}'**
  String globalSearchError(String message);

  /// Fallback short label on a KPI trend chip when the caller didn't supply a numeric delta — direction is up
  ///
  /// In en, this message translates to:
  /// **'up'**
  String get kpiTrendUp;

  /// Fallback short label on a KPI trend chip — direction is down
  ///
  /// In en, this message translates to:
  /// **'down'**
  String get kpiTrendDown;

  /// Fallback short label on a KPI trend chip — no meaningful change since the prior period
  ///
  /// In en, this message translates to:
  /// **'flat'**
  String get kpiTrendFlat;

  /// Tooltip surfaced when hovering / long-pressing a KPI trend chip pointing up
  ///
  /// In en, this message translates to:
  /// **'Up vs prior period'**
  String get kpiTrendUpTooltip;

  /// Tooltip surfaced when hovering / long-pressing a KPI trend chip pointing down
  ///
  /// In en, this message translates to:
  /// **'Down vs prior period'**
  String get kpiTrendDownTooltip;

  /// Tooltip surfaced when hovering / long-pressing a flat KPI trend chip
  ///
  /// In en, this message translates to:
  /// **'No meaningful change vs prior period'**
  String get kpiTrendFlatTooltip;

  /// Title of the demo line chart on the dashboard (Slice 2.2.3)
  ///
  /// In en, this message translates to:
  /// **'Revenue trend'**
  String get chartRevenueTrendTitle;

  /// Title of the demo bar chart on the dashboard (Slice 2.2.3)
  ///
  /// In en, this message translates to:
  /// **'Sales by region'**
  String get chartSalesByRegionTitle;

  /// Legend label for the revenue series on the line chart
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get chartSeriesRevenue;

  /// Legend label for the target series on the line chart
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get chartSeriesTarget;

  /// Legend label for the sales series on the bar chart
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get chartSeriesSales;

  /// Realtime status pill — WebSocket is connected, server pushes are flowing (Slice 2.2.4)
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get realtimeStatusLive;

  /// Realtime status pill — first-attempt handshake is in flight
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get realtimeStatusConnecting;

  /// Realtime status pill — connection dropped, sleeping a backoff window before the next attempt
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get realtimeStatusReconnecting;

  /// Realtime status pill — service hasn't started or reconnect attempts have been exhausted
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get realtimeStatusOffline;

  /// Dashboard button that fires a fake push payload through the router (Slice 2.3.2). Visible only when LocalPushSimulator is bound.
  ///
  /// In en, this message translates to:
  /// **'[dev] Simulate push'**
  String get pushDemoButton;

  /// Title of the synthetic push payload generated by the dashboard demo button
  ///
  /// In en, this message translates to:
  /// **'Demo notification #{count}'**
  String pushDemoTitle(int count);

  /// Body of the synthetic push payload from the demo button
  ///
  /// In en, this message translates to:
  /// **'Routed through PushMessageRouter into the inbox cache.'**
  String get pushDemoBody;

  /// Snackbar confirming the simulated push reached the inbox
  ///
  /// In en, this message translates to:
  /// **'Pushed to inbox.'**
  String get pushDemoSnack;

  /// Tooltip on the AppBar bell icon (Slice 2.3.3)
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsBadgeTooltip;

  /// AppBar title on the notification inbox page
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationInboxTitle;

  /// Body shown in the inbox when there are zero non-dismissed notifications
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up. New notifications will appear here.'**
  String get notificationInboxEmpty;

  /// Body shown when the inbox watch stream errors
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notifications: {message}'**
  String notificationInboxError(String message);

  /// Tooltip on the AppBar action that fires the MarkedAllRead event
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationInboxMarkAllRead;

  /// Snackbar surfaced after a swipe-to-dismiss gesture
  ///
  /// In en, this message translates to:
  /// **'Notification dismissed.'**
  String get notificationInboxDismissedSnack;

  /// Snackbar shown when a notification's routeName doesn't resolve (e.g. stale push pointing at a route renamed since) — Slice 2.3.4
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this notification: {message}'**
  String notificationDeepLinkError(String message);

  /// Snackbar action label that follows a foreground push directly to its deep-link target (Slice 2.3.4)
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get notificationDeepLinkViewAction;

  /// Dashboard button that fires a fake push payload carrying a deep-link route (Slice 2.3.4). Visible only when LocalPushSimulator is bound.
  ///
  /// In en, this message translates to:
  /// **'[dev] Simulate routed push'**
  String get pushDemoRoutedButton;

  /// Body of the synthetic routed push payload
  ///
  /// In en, this message translates to:
  /// **'Tap this notification — or the Snackbar\'s View — to deep-link to the target.'**
  String get pushDemoRoutedBody;

  /// AppBar title on the chart-of-accounts tree view (Slice 3.1.1)
  ///
  /// In en, this message translates to:
  /// **'Chart of accounts'**
  String get chartOfAccountsTitle;

  /// Empty-state body shown when the accounts feed yields no rows
  ///
  /// In en, this message translates to:
  /// **'No accounts have been loaded yet.'**
  String get chartOfAccountsEmpty;

  /// Body shown when the accounts watch stream errors
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the chart of accounts: {message}'**
  String chartOfAccountsError(String message);

  /// Tooltip on the AppBar action that opens every non-leaf node
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get chartOfAccountsExpandAll;

  /// Tooltip on the AppBar action that collapses every non-leaf node
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get chartOfAccountsCollapseAll;

  /// Dashboard text button bypassing the Modules grid's RBAC gate to reach /finance/accounts directly (Slice 3.1.1)
  ///
  /// In en, this message translates to:
  /// **'[demo] Open chart of accounts'**
  String get dashboardChartOfAccountsLink;

  /// Localised label for AccountType.asset
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get accountTypeAsset;

  /// Localised label for AccountType.liability
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get accountTypeLiability;

  /// Localised label for AccountType.equity
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get accountTypeEquity;

  /// Localised label for AccountType.revenue
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get accountTypeRevenue;

  /// Localised label for AccountType.expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get accountTypeExpense;

  /// Fallback AppBar title on the account detail page before the account loads (Slice 3.1.2)
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountDetailTitle;

  /// Empty-state body shown when an account has zero transactions
  ///
  /// In en, this message translates to:
  /// **'No transactions have been posted to this account yet.'**
  String get accountDetailNoTransactions;

  /// Body shown when the URL's :id doesn't match any account (deleted server-side, typo, etc.)
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an account with id \"{accountId}\".'**
  String accountDetailNotFound(String accountId);

  /// Body shown when either watch stream errors
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this account: {message}'**
  String accountDetailError(String message);

  /// AppBar title on the invoice list page (Slice 3.2.1)
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoiceListTitle;

  /// Placeholder in the invoice list search field
  ///
  /// In en, this message translates to:
  /// **'Search by number or customer'**
  String get invoiceListSearchHint;

  /// Tooltip on the invoice list sort menu
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get invoiceListSortTooltip;

  /// Empty state on the invoice list
  ///
  /// In en, this message translates to:
  /// **'No invoices match your filters.'**
  String get invoiceListEmpty;

  /// Failure body on the invoice list
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load invoices: {message}'**
  String invoiceListError(String message);

  /// Subtitle suffix "due 2026-06-01" on each invoice tile
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String invoiceListDueLabel(String date);

  /// Invoice approval status — editable, not yet submitted
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get invoiceStatusDraft;

  /// Invoice approval status — submitted, awaiting decision
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get invoiceStatusPendingApproval;

  /// Invoice approval status — approver said yes
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get invoiceStatusApproved;

  /// Invoice approval status — approver said no
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get invoiceStatusRejected;

  /// Invoice list sort axis
  ///
  /// In en, this message translates to:
  /// **'Issued (newest)'**
  String get invoiceSortIssuedDesc;

  /// Invoice list sort axis
  ///
  /// In en, this message translates to:
  /// **'Issued (oldest)'**
  String get invoiceSortIssuedAsc;

  /// Invoice list sort axis
  ///
  /// In en, this message translates to:
  /// **'Due (soonest)'**
  String get invoiceSortDueAsc;

  /// Invoice list sort axis
  ///
  /// In en, this message translates to:
  /// **'Amount (largest)'**
  String get invoiceSortAmountDesc;

  /// Invoice list sort axis
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceSortNumberAsc;

  /// Slice 3.2.2 detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceDetailTitle;

  /// Header meta label
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get invoiceDetailIssuedLabel;

  /// Header meta label
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get invoiceDetailDueLabel;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get invoiceDetailLinesHeading;

  /// Totals row label
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoiceDetailSubtotalLabel;

  /// Totals row label
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get invoiceDetailTaxLabel;

  /// Totals row label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get invoiceDetailTotalLabel;

  /// Notes section heading
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get invoiceDetailNotesHeading;

  /// Heading on the PDF placeholder card
  ///
  /// In en, this message translates to:
  /// **'PDF preview'**
  String get invoiceDetailPdfHeading;

  /// Body on the PDF placeholder card
  ///
  /// In en, this message translates to:
  /// **'PDF rendering ships with the backend that serves it.'**
  String get invoiceDetailPdfPlaceholder;

  /// Not-found body on the detail page
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an invoice with id \"{invoiceId}\".'**
  String invoiceDetailNotFound(String invoiceId);

  /// Failure body on the detail page
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this invoice: {message}'**
  String invoiceDetailError(String message);

  /// Slice 3.2.4 approve button label
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get invoiceApproveAction;

  /// Slice 3.2.4 reject button label
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get invoiceRejectAction;

  /// Slice 3.2.4 draft → pendingApproval transition button
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get invoiceSubmitAction;

  /// Slice 3.2.4 rejected → draft transition button
  ///
  /// In en, this message translates to:
  /// **'Re-open for revision'**
  String get invoiceReopenAction;

  /// Generic cancel for approve/reject bottom sheets
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get invoiceActionCancel;

  /// Approve bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Approve this invoice?'**
  String get invoiceApproveSheetTitle;

  /// Approve bottom sheet body
  ///
  /// In en, this message translates to:
  /// **'You\'re about to approve {invoiceNumber}. The invoice will be locked once approved.'**
  String invoiceApproveSheetBody(String invoiceNumber);

  /// Reject bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Reject this invoice?'**
  String get invoiceRejectSheetTitle;

  /// Reject bottom sheet body
  ///
  /// In en, this message translates to:
  /// **'{invoiceNumber} will be returned to the requester with the reason below.'**
  String invoiceRejectSheetBody(String invoiceNumber);

  /// Reject reason field label
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get invoiceRejectReasonLabel;

  /// Reject reason field hint
  ///
  /// In en, this message translates to:
  /// **'Why is this invoice being rejected?'**
  String get invoiceRejectReasonHint;

  /// Reject form validator — empty reason
  ///
  /// In en, this message translates to:
  /// **'Please give a reason.'**
  String get invoiceRejectReasonRequired;

  /// Snackbar after a successful workflow action
  ///
  /// In en, this message translates to:
  /// **'Invoice marked as {status}.'**
  String invoiceActionSuccess(String status);

  /// Snackbar when finance.approve is missing
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to action this invoice.'**
  String get invoiceActionForbidden;

  /// Snackbar when the invoice id is unknown
  ///
  /// In en, this message translates to:
  /// **'That invoice no longer exists.'**
  String get invoiceActionNotFound;

  /// Snackbar for the InvalidStateFailure / no-double-action guard
  ///
  /// In en, this message translates to:
  /// **'This invoice has already been actioned.'**
  String get invoiceActionInvalidState;

  /// Snackbar when no signed-in user is present
  ///
  /// In en, this message translates to:
  /// **'Sign-in expired — please sign in again.'**
  String get invoiceActionUnauthorized;

  /// Fallback snackbar for unmapped failures
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t action the invoice: {message}'**
  String invoiceActionGenericError(String message);

  /// Audit card heading on approved invoices
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get invoiceAuditApprovedHeading;

  /// Audit card heading on rejected invoices
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get invoiceAuditRejectedHeading;

  /// Audit card — who actioned
  ///
  /// In en, this message translates to:
  /// **'by {userId}'**
  String invoiceAuditActorLine(String userId);

  /// Audit card — when actioned
  ///
  /// In en, this message translates to:
  /// **'at {when}'**
  String invoiceAuditWhenLine(String when);

  /// Audit card — rejection reason
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String invoiceAuditReasonLine(String reason);

  /// Slice 3.2.3 form AppBar title (create mode)
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get invoiceFormCreateTitle;

  /// Slice 3.2.3 form AppBar title (edit mode)
  ///
  /// In en, this message translates to:
  /// **'Edit invoice'**
  String get invoiceFormEditTitle;

  /// Tooltip on the save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get invoiceFormSaveTooltip;

  /// Bottom save button label
  ///
  /// In en, this message translates to:
  /// **'Save invoice'**
  String get invoiceFormSaveAction;

  /// Snackbar after a successful save
  ///
  /// In en, this message translates to:
  /// **'Invoice saved.'**
  String get invoiceFormSavedSnack;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get invoiceFormCustomerLabel;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Issued date'**
  String get invoiceFormIssuedLabel;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get invoiceFormDueLabel;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Line item'**
  String get invoiceFormLineHeading;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get invoiceFormLineDescriptionLabel;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get invoiceFormLineQuantityLabel;

  /// Form field label
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get invoiceFormLineUnitPriceLabel;

  /// Form validator: empty field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validatorRequired;

  /// Form validator: non-numeric
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get validatorInvalidNumber;

  /// Form validator: zero or negative
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get validatorMustBePositive;

  /// Form validator: negative
  ///
  /// In en, this message translates to:
  /// **'Cannot be negative'**
  String get validatorMustBeNonNegative;

  /// Form validator: due-before-issued
  ///
  /// In en, this message translates to:
  /// **'Due date must be on or after the issued date'**
  String get validatorDueBeforeIssued;

  /// Slice 3.3.1 AppBar title
  ///
  /// In en, this message translates to:
  /// **'Journal entries'**
  String get journalEntriesTitle;

  /// Empty state on the journal entry list
  ///
  /// In en, this message translates to:
  /// **'No journal entries posted in this period.'**
  String get journalEntriesEmpty;

  /// Detail page AppBar title
  ///
  /// In en, this message translates to:
  /// **'Journal entry'**
  String get journalEntryDetailTitle;

  /// Not-found body
  ///
  /// In en, this message translates to:
  /// **'Journal entry \"{id}\" was not found.'**
  String journalEntryNotFound(String id);

  /// Detail table column header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get journalEntryAccountColumn;

  /// Detail table column header
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get journalEntryDebitColumn;

  /// Detail table column header
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get journalEntryCreditColumn;

  /// Detail totals row label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get journalEntryTotalLabel;

  /// Slice 3.3.2 AppBar title
  ///
  /// In en, this message translates to:
  /// **'Trial balance'**
  String get trialBalanceTitle;

  /// Empty state on the trial balance
  ///
  /// In en, this message translates to:
  /// **'No accounts have non-zero balances yet.'**
  String get trialBalanceEmpty;

  /// Trial balance column header
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get trialBalanceColumnCode;

  /// Trial balance column header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get trialBalanceColumnName;

  /// Trial balance column header
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get trialBalanceColumnDebit;

  /// Trial balance column header
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get trialBalanceColumnCredit;

  /// Pagination chip text
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String trialBalancePageOf(int current, int total);

  /// Slice 3.3.3 export action tooltip
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get trialBalanceExportCsvTooltip;

  /// Snackbar after a successful export
  ///
  /// In en, this message translates to:
  /// **'CSV saved to {path}'**
  String trialBalanceExportSuccess(String path);

  /// Snackbar after a failed export
  ///
  /// In en, this message translates to:
  /// **'CSV export failed: {message}'**
  String trialBalanceExportError(String message);

  /// Form validator: bad email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validatorInvalidEmail;

  /// Slice 4.1.1 PR list AppBar title
  ///
  /// In en, this message translates to:
  /// **'Purchase requests'**
  String get prListTitle;

  /// AppBar add-button tooltip
  ///
  /// In en, this message translates to:
  /// **'New PR'**
  String get prListNewTooltip;

  /// PR list search field hint
  ///
  /// In en, this message translates to:
  /// **'Search by number, requester, cost center'**
  String get prListSearchHint;

  /// PR list sort menu tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get prListSortTooltip;

  /// PR list empty state
  ///
  /// In en, this message translates to:
  /// **'No purchase requests match your filters.'**
  String get prListEmpty;

  /// PR list failure body
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load purchase requests: {message}'**
  String prListError(String message);

  /// PR status label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get prStatusDraft;

  /// PR status label
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get prStatusSubmitted;

  /// PR status label
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prStatusApproved;

  /// PR status label
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get prStatusRejected;

  /// PR status label — PR has become a PO
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get prStatusConverted;

  /// PR sort axis
  ///
  /// In en, this message translates to:
  /// **'Created (newest)'**
  String get prSortCreatedDesc;

  /// PR sort axis
  ///
  /// In en, this message translates to:
  /// **'Created (oldest)'**
  String get prSortCreatedAsc;

  /// PR sort axis
  ///
  /// In en, this message translates to:
  /// **'Total (largest)'**
  String get prSortTotalDesc;

  /// PR sort axis
  ///
  /// In en, this message translates to:
  /// **'PR number'**
  String get prSortNumberAsc;

  /// Slice 4.1.2 form AppBar title
  ///
  /// In en, this message translates to:
  /// **'New purchase request'**
  String get prFormCreateTitle;

  /// PR form save button tooltip
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get prFormSaveTooltip;

  /// PR form bottom submit button
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get prFormSubmitAction;

  /// Snackbar after PR save
  ///
  /// In en, this message translates to:
  /// **'Purchase request submitted.'**
  String get prFormSavedSnack;

  /// Snackbar after PR save failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit the request: {message}'**
  String prFormSaveFailed(String message);

  /// PR form field label
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get prFormRequesterLabel;

  /// PR form field label
  ///
  /// In en, this message translates to:
  /// **'Cost center'**
  String get prFormCostCenterLabel;

  /// PR form field label
  ///
  /// In en, this message translates to:
  /// **'Approver'**
  String get prFormApproverLabel;

  /// PR form field label
  ///
  /// In en, this message translates to:
  /// **'Justification (optional)'**
  String get prFormJustificationLabel;

  /// PR form lines section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get prFormLinesHeading;

  /// Per-line numbered heading inside the PR form
  ///
  /// In en, this message translates to:
  /// **'Line {index}'**
  String prFormLineHeading(int index);

  /// PR form add-line button
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get prFormAddLineAction;

  /// PR form remove-line tooltip
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get prFormRemoveLineTooltip;

  /// PR line field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get prFormLineDescriptionLabel;

  /// PR line field label
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get prFormLineQuantityLabel;

  /// PR line field label
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get prFormLineUnitPriceLabel;

  /// Slice 4.1.3 detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Purchase request'**
  String get prDetailTitle;

  /// Not-found body on PR detail
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a purchase request with id \"{prId}\".'**
  String prDetailNotFound(String prId);

  /// Failure body on PR detail
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this purchase request: {message}'**
  String prDetailError(String message);

  /// PR detail meta label
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get prDetailRequesterLabel;

  /// PR detail meta label
  ///
  /// In en, this message translates to:
  /// **'Cost center'**
  String get prDetailCostCenterLabel;

  /// PR detail meta label
  ///
  /// In en, this message translates to:
  /// **'Approver'**
  String get prDetailApproverLabel;

  /// PR detail meta label
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get prDetailCreatedLabel;

  /// PR detail section heading
  ///
  /// In en, this message translates to:
  /// **'Justification'**
  String get prDetailJustificationHeading;

  /// PR detail section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get prDetailLinesHeading;

  /// PR detail total row label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get prDetailTotalLabel;

  /// PR detail action
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get prApproveAction;

  /// PR detail action
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get prRejectAction;

  /// PR detail action — draft → submitted
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get prSubmitAction;

  /// PR detail action — approved → PO
  ///
  /// In en, this message translates to:
  /// **'Convert to PO'**
  String get prConvertAction;

  /// Snackbar after PR submit
  ///
  /// In en, this message translates to:
  /// **'Purchase request submitted.'**
  String get prSubmittedSnack;

  /// Snackbar after PR approval
  ///
  /// In en, this message translates to:
  /// **'Purchase request marked as {status}.'**
  String prApprovedSnack(String status);

  /// Snackbar after PR reject
  ///
  /// In en, this message translates to:
  /// **'Purchase request rejected.'**
  String get prRejectedSnack;

  /// Snackbar after PR→PO convert
  ///
  /// In en, this message translates to:
  /// **'Purchase order created.'**
  String get prConvertedSnack;

  /// Snackbar when transition is illegal
  ///
  /// In en, this message translates to:
  /// **'This request can\'t be {action} from its current status.'**
  String prApprovalNotAllowed(String action);

  /// Snackbar after persistence failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the request: {message}'**
  String prApprovalFailed(String message);

  /// Reject dialog title
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get prRejectDialogTitle;

  /// Reject dialog field label
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get prRejectReasonLabel;

  /// Reject dialog field hint
  ///
  /// In en, this message translates to:
  /// **'Why is this request being rejected?'**
  String get prRejectReasonHint;

  /// Reject dialog validation
  ///
  /// In en, this message translates to:
  /// **'Please give a reason.'**
  String get prRejectReasonRequired;

  /// Reject dialog cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get prRejectCancel;

  /// Reject dialog confirm
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get prRejectConfirm;

  /// Convert dialog title
  ///
  /// In en, this message translates to:
  /// **'Convert to purchase order'**
  String get prConvertDialogTitle;

  /// Convert dialog vendor field
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get prConvertVendorLabel;

  /// Convert dialog date field
  ///
  /// In en, this message translates to:
  /// **'Expected delivery'**
  String get prConvertExpectedLabel;

  /// Convert dialog validation
  ///
  /// In en, this message translates to:
  /// **'Please pick a vendor.'**
  String get prConvertVendorRequired;

  /// Convert dialog confirm
  ///
  /// In en, this message translates to:
  /// **'Create PO'**
  String get prConvertConfirm;

  /// Convert dialog cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get prConvertCancel;

  /// Slice 4.2.1 list AppBar title
  ///
  /// In en, this message translates to:
  /// **'Purchase orders'**
  String get poListTitle;

  /// PO list empty state
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get poListEmpty;

  /// PO list subtitle
  ///
  /// In en, this message translates to:
  /// **'expected {date}'**
  String poListExpectedLabel(String date);

  /// PO status label
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get poStatusOpen;

  /// PO status label
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get poStatusPartial;

  /// PO status label
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get poStatusFull;

  /// PO status label
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get poStatusClosed;

  /// PO status label
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get poStatusCancelled;

  /// PO detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Purchase order'**
  String get poDetailTitle;

  /// PO not-found body
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a purchase order with id \"{poId}\".'**
  String poDetailNotFound(String poId);

  /// PO detail meta label
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get poDetailCreatedLabel;

  /// PO detail meta label
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get poDetailExpectedLabel;

  /// PO detail meta label
  ///
  /// In en, this message translates to:
  /// **'Source PR'**
  String get poDetailSourcePrLabel;

  /// PO detail section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get poDetailLinesHeading;

  /// PO detail total row
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get poDetailTotalLabel;

  /// PO detail receipts section heading
  ///
  /// In en, this message translates to:
  /// **'Goods receipts'**
  String get poDetailReceiptsHeading;

  /// PO detail empty receipts message
  ///
  /// In en, this message translates to:
  /// **'No receipts recorded yet.'**
  String get poDetailReceiptsEmpty;

  /// Badge showing how many lines a receipt covered
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String poDetailReceiptItemsBadge(int count);

  /// PO detail bottom action
  ///
  /// In en, this message translates to:
  /// **'Record goods receipt'**
  String get poDetailRecordReceiptAction;

  /// PO line meta
  ///
  /// In en, this message translates to:
  /// **'ordered {qty}'**
  String poLineOrderedLabel(String qty);

  /// PO line meta
  ///
  /// In en, this message translates to:
  /// **'received {qty}'**
  String poLineReceivedLabel(String qty);

  /// PO line meta
  ///
  /// In en, this message translates to:
  /// **'outstanding {qty}'**
  String poLineOutstandingLabel(String qty);

  /// Slice 4.2.3 form title
  ///
  /// In en, this message translates to:
  /// **'Goods receipt'**
  String get goodsReceiptFormTitle;

  /// GR form subtitle
  ///
  /// In en, this message translates to:
  /// **'Receiving against {number}'**
  String goodsReceiptFormForPo(String number);

  /// GR form field
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get goodsReceiptReceivedByLabel;

  /// GR form field
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get goodsReceiptNoteLabel;

  /// GR form section heading
  ///
  /// In en, this message translates to:
  /// **'Quantities received'**
  String get goodsReceiptLinesHeading;

  /// GR form per-line input
  ///
  /// In en, this message translates to:
  /// **'Receiving now'**
  String get goodsReceiptQuantityLabel;

  /// GR form submit
  ///
  /// In en, this message translates to:
  /// **'Record receipt'**
  String get goodsReceiptSubmitAction;

  /// GR snackbar
  ///
  /// In en, this message translates to:
  /// **'Goods receipt recorded.'**
  String get goodsReceiptSavedSnack;

  /// GR failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t record receipt: {message}'**
  String goodsReceiptSaveFailed(String message);

  /// GR validator error
  ///
  /// In en, this message translates to:
  /// **'This PO is closed and can\'t take more receipts.'**
  String get goodsReceiptErrorPoClosed;

  /// GR validator error
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity for at least one line.'**
  String get goodsReceiptErrorNoLines;

  /// GR validator error
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0.'**
  String get goodsReceiptErrorNonPositive;

  /// GR validator error
  ///
  /// In en, this message translates to:
  /// **'One of the lines doesn\'t belong to this PO.'**
  String get goodsReceiptErrorUnknownLine;

  /// GR validator error
  ///
  /// In en, this message translates to:
  /// **'You can\'t receive more than the outstanding quantity.'**
  String get goodsReceiptErrorExceedsOutstanding;

  /// Slice 4.3.1 list AppBar title
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendorListTitle;

  /// Vendor list empty state
  ///
  /// In en, this message translates to:
  /// **'No vendors onboarded yet.'**
  String get vendorListEmpty;

  /// AppBar add tooltip
  ///
  /// In en, this message translates to:
  /// **'Onboard vendor'**
  String get vendorListNewTooltip;

  /// Vendor status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get vendorStatusActive;

  /// Vendor status label
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get vendorStatusOnHold;

  /// Vendor status label
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get vendorStatusArchived;

  /// Vendor detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorDetailTitle;

  /// Vendor not-found body
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a vendor with id \"{vendorId}\".'**
  String vendorDetailNotFound(String vendorId);

  /// Vendor detail meta
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get vendorDetailTaxIdLabel;

  /// Vendor detail meta
  ///
  /// In en, this message translates to:
  /// **'Onboarded'**
  String get vendorDetailOnboardedLabel;

  /// Vendor detail section
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get vendorDetailContactHeading;

  /// Vendor detail field
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get vendorDetailContactPersonLabel;

  /// Vendor detail field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get vendorDetailEmailLabel;

  /// Vendor detail field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get vendorDetailPhoneLabel;

  /// Vendor detail field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get vendorDetailAddressLabel;

  /// Vendor detail section
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vendorDetailNotesHeading;

  /// Vendor detail link to 4.3.3
  ///
  /// In en, this message translates to:
  /// **'View performance scorecard'**
  String get vendorDetailScorecardAction;

  /// Slice 4.3.2 form title
  ///
  /// In en, this message translates to:
  /// **'Onboard vendor'**
  String get vendorFormTitle;

  /// Vendor form save tooltip
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vendorFormSaveTooltip;

  /// Vendor form bottom save button
  ///
  /// In en, this message translates to:
  /// **'Save vendor'**
  String get vendorFormSaveAction;

  /// Vendor save snackbar
  ///
  /// In en, this message translates to:
  /// **'Vendor onboarded.'**
  String get vendorFormSavedSnack;

  /// Vendor save failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the vendor: {message}'**
  String vendorFormSaveFailed(String message);

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Vendor name'**
  String get vendorFormNameLabel;

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get vendorFormTaxIdLabel;

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get vendorFormEmailLabel;

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get vendorFormPhoneLabel;

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get vendorFormAddressLabel;

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Contact person (optional)'**
  String get vendorFormContactPersonLabel;

  /// Vendor form field
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get vendorFormNotesLabel;

  /// Slice 4.3.3 page title
  ///
  /// In en, this message translates to:
  /// **'Vendor scorecard'**
  String get vendorScorecardTitle;

  /// Composite section label
  ///
  /// In en, this message translates to:
  /// **'Composite score'**
  String get vendorScorecardCompositeLabel;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'On-time delivery'**
  String get vendorScorecardOnTimeLabel;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Defect rate'**
  String get vendorScorecardDefectLabel;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Open disputes'**
  String get vendorScorecardDisputesLabel;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Total spend'**
  String get vendorScorecardSpendLabel;

  /// Slice 5.1.1 list AppBar title
  ///
  /// In en, this message translates to:
  /// **'Inventory items'**
  String get inventoryItemsTitle;

  /// AppBar scan button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get inventoryScanTooltip;

  /// AppBar alerts button tooltip
  ///
  /// In en, this message translates to:
  /// **'Low stock alerts'**
  String get inventoryLowStockAlertsTooltip;

  /// Items list search hint
  ///
  /// In en, this message translates to:
  /// **'Search by SKU, name, location, barcode'**
  String get inventoryItemsSearchHint;

  /// Items list sort tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get inventoryItemsSortTooltip;

  /// Items list empty state
  ///
  /// In en, this message translates to:
  /// **'No items match the current filters.'**
  String get inventoryItemsEmpty;

  /// Items list failure body
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load inventory: {message}'**
  String inventoryItemsError(String message);

  /// Items list trailing — current on-hand
  ///
  /// In en, this message translates to:
  /// **'on-hand {qty}'**
  String inventoryItemsOnHand(String qty);

  /// Badge under on-hand when item is at/below reorder
  ///
  /// In en, this message translates to:
  /// **'reorder at {qty}'**
  String inventoryReorderBadge(String qty);

  /// Filter chip — low-stock only
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get inventoryLowStockChip;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get inventorySortNameAsc;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get inventorySortSkuAsc;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'On-hand (low first)'**
  String get inventorySortOnHandAsc;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'On-hand (high first)'**
  String get inventorySortOnHandDesc;

  /// Slice 5.1.2 detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get inventoryItemDetailTitle;

  /// Detail not-found body
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an item with id \"{itemId}\".'**
  String inventoryItemNotFound(String itemId);

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get inventoryDetailWarehouseLabel;

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get inventoryDetailLocationLabel;

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Reorder point'**
  String get inventoryDetailReorderLabel;

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get inventoryDetailUnitCostLabel;

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get inventoryDetailBarcodeLabel;

  /// Detail section heading
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get inventoryDetailMovementsHeading;

  /// Detail empty ledger
  ///
  /// In en, this message translates to:
  /// **'No movements recorded yet.'**
  String get inventoryDetailMovementsEmpty;

  /// Ledger row label
  ///
  /// In en, this message translates to:
  /// **'Goods receipt'**
  String get inventoryMovementTypeReceipt;

  /// Ledger row label
  ///
  /// In en, this message translates to:
  /// **'Goods issue'**
  String get inventoryMovementTypeIssue;

  /// Ledger row label
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get inventoryMovementTypeTransfer;

  /// Ledger row label
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get inventoryMovementTypeAdjustment;

  /// Trailing running-balance on a ledger row
  ///
  /// In en, this message translates to:
  /// **'balance {qty}'**
  String inventoryMovementRunningLabel(String qty);

  /// Detail bottom-bar action
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get inventoryIssueAction;

  /// Detail bottom-bar action
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get inventoryReceiptAction;

  /// Detail bottom-bar action
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get inventoryTransferAction;

  /// Slice 5.1.3 alerts page title
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventoryLowStockTitle;

  /// Alerts empty state
  ///
  /// In en, this message translates to:
  /// **'Every item is above its reorder point.'**
  String get inventoryLowStockEmpty;

  /// Slice 5.2.1 scanner title
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get inventoryScannerTitle;

  /// Inline error when scan/entry is empty
  ///
  /// In en, this message translates to:
  /// **'Scan or enter a code.'**
  String get inventoryScannerEmpty;

  /// Inline error when barcode resolves to nothing
  ///
  /// In en, this message translates to:
  /// **'No item matches \"{code}\".'**
  String inventoryScannerUnknown(String code);

  /// Snackbar for scanner exceptions
  ///
  /// In en, this message translates to:
  /// **'Scanner error: {message}'**
  String inventoryScannerError(String message);

  /// Shown on web/desktop instead of the camera preview
  ///
  /// In en, this message translates to:
  /// **'Camera not available on this platform — use manual entry below.'**
  String get inventoryScannerNoCamera;

  /// Heading for the manual entry section
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get inventoryScannerManualHeading;

  /// Manual entry field label
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get inventoryScannerManualLabel;

  /// Manual entry field hint
  ///
  /// In en, this message translates to:
  /// **'Type or paste a code'**
  String get inventoryScannerManualHint;

  /// Manual entry submit button
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get inventoryScannerManualUseAction;

  /// Fallback link to the catalog list
  ///
  /// In en, this message translates to:
  /// **'Browse the catalog instead'**
  String get inventoryScannerBrowseFallback;

  /// Slice 5.2.2 GR form title
  ///
  /// In en, this message translates to:
  /// **'Receive stock'**
  String get inventoryReceiptFormTitle;

  /// Slice 5.2.2 GI form title
  ///
  /// In en, this message translates to:
  /// **'Issue stock'**
  String get inventoryIssueFormTitle;

  /// GR success snackbar
  ///
  /// In en, this message translates to:
  /// **'Stock received.'**
  String get inventoryReceiptSuccessSnack;

  /// GI success snackbar
  ///
  /// In en, this message translates to:
  /// **'Stock issued.'**
  String get inventoryIssueSuccessSnack;

  /// Fallback success snackbar
  ///
  /// In en, this message translates to:
  /// **'Movement recorded.'**
  String get inventoryMovementGenericSuccess;

  /// Failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t record movement: {message}'**
  String inventoryMovementFailed(String message);

  /// Form header showing current quantity
  ///
  /// In en, this message translates to:
  /// **'Current on-hand: {qty}'**
  String inventoryFormCurrentOnHand(String qty);

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryFormQuantityLabel;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get inventoryFormReferenceLabel;

  /// Form hint
  ///
  /// In en, this message translates to:
  /// **'e.g. PO-2026-001'**
  String get inventoryFormReferenceReceiptHint;

  /// Form hint
  ///
  /// In en, this message translates to:
  /// **'e.g. SO-2026-014'**
  String get inventoryFormReferenceIssueHint;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get inventoryFormNoteLabel;

  /// Inline error when issue qty > on-hand
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds the current on-hand.'**
  String get inventoryQtyExceedsOnHand;

  /// Slice 5.2.3 transfer form title
  ///
  /// In en, this message translates to:
  /// **'Transfer stock'**
  String get inventoryTransferFormTitle;

  /// Source card heading
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get inventoryTransferSourceHeading;

  /// Destination dropdown label
  ///
  /// In en, this message translates to:
  /// **'Destination bin'**
  String get inventoryTransferDestinationLabel;

  /// Empty destinations message
  ///
  /// In en, this message translates to:
  /// **'No active destination bins available for this SKU.'**
  String get inventoryTransferNoDestinations;

  /// Transfer reference hint
  ///
  /// In en, this message translates to:
  /// **'Internal transfer note'**
  String get inventoryTransferReferenceHint;

  /// Snackbar when destination missing
  ///
  /// In en, this message translates to:
  /// **'Please pick a destination bin.'**
  String get inventoryTransferPickDestination;

  /// Transfer success snackbar
  ///
  /// In en, this message translates to:
  /// **'Stock transferred.'**
  String get inventoryTransferSuccess;

  /// Slice 5.2.4 cycle count title
  ///
  /// In en, this message translates to:
  /// **'Cycle count'**
  String get inventoryCycleCountTitle;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No items to count.'**
  String get inventoryCycleNoItems;

  /// Filter chip — no warehouse filter
  ///
  /// In en, this message translates to:
  /// **'All warehouses'**
  String get inventoryCycleAllWarehouses;

  /// Per-line expected qty
  ///
  /// In en, this message translates to:
  /// **'expected {qty}'**
  String inventoryCycleExpectedLabel(String qty);

  /// Per-line counted qty input
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get inventoryCycleCountedLabel;

  /// Snackbar when no lines
  ///
  /// In en, this message translates to:
  /// **'Enter a counted quantity for at least one item.'**
  String get inventoryCycleEmpty;

  /// Cycle count bottom action
  ///
  /// In en, this message translates to:
  /// **'Submit count'**
  String get inventoryCycleSubmitAction;

  /// Cycle count success snackbar
  ///
  /// In en, this message translates to:
  /// **'Posted {count} adjustment(s); variance {variance}.'**
  String inventoryCycleSuccess(int count, String variance);

  /// Slice 6.1.1 list AppBar title
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get salesCustomersTitle;

  /// AppBar analytics button tooltip
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get salesAnalyticsTooltip;

  /// Customer list search hint
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, industry'**
  String get salesCustomersSearchHint;

  /// Customer list sort tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get salesCustomersSortTooltip;

  /// Customer list empty state
  ///
  /// In en, this message translates to:
  /// **'No customers match your filters.'**
  String get salesCustomersEmpty;

  /// Customer list failure body
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load customers: {message}'**
  String salesCustomersError(String message);

  /// Subtitle date label
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String salesCustomersOnboardedLabel(String date);

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get salesCustomersSortName;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Lifetime value'**
  String get salesCustomersSortLtv;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get salesCustomersSortRecent;

  /// Customer status
  ///
  /// In en, this message translates to:
  /// **'Prospect'**
  String get salesStatusProspect;

  /// Customer status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get salesStatusActive;

  /// Customer status
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get salesStatusOnHold;

  /// Customer status
  ///
  /// In en, this message translates to:
  /// **'Churned'**
  String get salesStatusChurned;

  /// Customer segment
  ///
  /// In en, this message translates to:
  /// **'SMB'**
  String get salesSegmentSmb;

  /// Customer segment
  ///
  /// In en, this message translates to:
  /// **'Mid-market'**
  String get salesSegmentMidMarket;

  /// Customer segment
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get salesSegmentEnterprise;

  /// Slice 6.1 detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get salesCustomerDetailTitle;

  /// Detail not-found body
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a customer with id \"{customerId}\".'**
  String salesCustomerNotFound(String customerId);

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get salesCustomerDetailEmailLabel;

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get salesCustomerDetailPhoneLabel;

  /// Detail meta label
  ///
  /// In en, this message translates to:
  /// **'Billing address'**
  String get salesCustomerDetailAddressLabel;

  /// Detail chip label
  ///
  /// In en, this message translates to:
  /// **'Lifetime value'**
  String get salesCustomerDetailLifetimeValueLabel;

  /// Detail chip label
  ///
  /// In en, this message translates to:
  /// **'Customer since'**
  String get salesCustomerDetailSinceLabel;

  /// Detail notes heading
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get salesCustomerDetailNotesHeading;

  /// Contacts card heading
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get salesCustomerDetailContactsHeading;

  /// Contacts empty state
  ///
  /// In en, this message translates to:
  /// **'No contacts linked yet.'**
  String get salesCustomerDetailContactsEmpty;

  /// Timeline card heading
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get salesCustomerDetailTimelineHeading;

  /// Timeline empty state
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get salesCustomerDetailTimelineEmpty;

  /// Contacts card add button
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get salesContactAddAction;

  /// Contact tile menu
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get salesContactEditAction;

  /// Contact tile menu
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get salesContactDeleteAction;

  /// Badge on the primary contact tile
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get salesContactPrimaryBadge;

  /// Contact form title (create)
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get salesContactNewTitle;

  /// Contact form title (edit)
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get salesContactEditTitle;

  /// Contact form field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get salesContactNameLabel;

  /// Contact form field
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get salesContactRoleLabel;

  /// Contact form field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get salesContactEmailLabel;

  /// Contact form field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get salesContactPhoneLabel;

  /// Toggle label
  ///
  /// In en, this message translates to:
  /// **'Primary contact'**
  String get salesContactPrimaryToggle;

  /// Toggle description
  ///
  /// In en, this message translates to:
  /// **'Show this contact in the customer header.'**
  String get salesContactPrimaryDescription;

  /// Form submit
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get salesContactSaveAction;

  /// Save success snackbar
  ///
  /// In en, this message translates to:
  /// **'Contact saved.'**
  String get salesContactSavedSnack;

  /// Save failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save contact: {message}'**
  String salesContactSaveFailed(String message);

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete contact?'**
  String get salesContactDeleteTitle;

  /// Confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'The contact will be removed from this customer.'**
  String get salesContactDeleteBody;

  /// Confirmation confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get salesContactDeleteConfirm;

  /// Delete success snackbar
  ///
  /// In en, this message translates to:
  /// **'Contact removed.'**
  String get salesContactDeletedSnack;

  /// Timeline card add button
  ///
  /// In en, this message translates to:
  /// **'Log activity'**
  String get salesActivityLogAction;

  /// Activity form AppBar title
  ///
  /// In en, this message translates to:
  /// **'Log activity'**
  String get salesActivityFormTitle;

  /// Activity form field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get salesActivityTypeLabel;

  /// Activity form field
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get salesActivitySummaryLabel;

  /// Activity form field
  ///
  /// In en, this message translates to:
  /// **'Logged by'**
  String get salesActivityActorLabel;

  /// Activity form submit
  ///
  /// In en, this message translates to:
  /// **'Save activity'**
  String get salesActivitySaveAction;

  /// Save success snackbar
  ///
  /// In en, this message translates to:
  /// **'Activity logged.'**
  String get salesActivitySavedSnack;

  /// Save failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t log activity: {message}'**
  String salesActivitySaveFailed(String message);

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get salesActivityTypeNote;

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get salesActivityTypeCall;

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get salesActivityTypeMeeting;

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get salesActivityTypeEmail;

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get salesActivityTypeQuotation;

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get salesActivityTypeOrder;

  /// Activity type label
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get salesActivityTypePayment;

  /// Slice 6.2.1 list title
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get salesQuotationListTitle;

  /// AppBar add tooltip
  ///
  /// In en, this message translates to:
  /// **'New quotation'**
  String get salesQuotationNewTooltip;

  /// Quotation list search hint
  ///
  /// In en, this message translates to:
  /// **'Search by number or customer'**
  String get salesQuotationSearchHint;

  /// Quotation list sort tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get salesQuotationSortTooltip;

  /// Quotation list empty state
  ///
  /// In en, this message translates to:
  /// **'No quotations match your filters.'**
  String get salesQuotationListEmpty;

  /// Tile subtitle validity label
  ///
  /// In en, this message translates to:
  /// **'valid until {date}'**
  String salesQuotationValidUntilLabel(String date);

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Created (newest)'**
  String get salesQuotationSortCreatedDesc;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Created (oldest)'**
  String get salesQuotationSortCreatedAsc;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Total (largest)'**
  String get salesQuotationSortTotalDesc;

  /// Sort axis
  ///
  /// In en, this message translates to:
  /// **'Expiring next'**
  String get salesQuotationSortValidity;

  /// Quotation status
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get salesQuotationStatusDraft;

  /// Quotation status
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get salesQuotationStatusSent;

  /// Quotation status
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get salesQuotationStatusAccepted;

  /// Quotation status
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get salesQuotationStatusRejected;

  /// Quotation status
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get salesQuotationStatusExpired;

  /// Quotation status — promoted to a sales order
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get salesQuotationStatusConverted;

  /// Quotation form AppBar title
  ///
  /// In en, this message translates to:
  /// **'New quotation'**
  String get salesQuotationNewTitle;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get salesQuotationCustomerLabel;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get salesQuotationValidUntilField;

  /// Form section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get salesQuotationLinesHeading;

  /// Numbered per-line heading
  ///
  /// In en, this message translates to:
  /// **'Line {index}'**
  String salesQuotationLineHeading(int index);

  /// Form add-line button
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get salesQuotationAddLineAction;

  /// Form remove-line tooltip
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get salesQuotationRemoveLineTooltip;

  /// Line field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get salesQuotationLineDescriptionLabel;

  /// Line field
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get salesQuotationLineQuantityLabel;

  /// Line field
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get salesQuotationLineUnitPriceLabel;

  /// Form submit
  ///
  /// In en, this message translates to:
  /// **'Save quotation'**
  String get salesQuotationSaveAction;

  /// Save success snackbar
  ///
  /// In en, this message translates to:
  /// **'Quotation saved.'**
  String get salesQuotationSavedSnack;

  /// Save failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save quotation: {message}'**
  String salesQuotationSaveFailed(String message);

  /// Form validation snackbar
  ///
  /// In en, this message translates to:
  /// **'Please pick a customer.'**
  String get salesQuotationPickCustomer;

  /// Detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get salesQuotationDetailTitle;

  /// Detail not-found body
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a quotation with id \"{quotationId}\".'**
  String salesQuotationNotFound(String quotationId);

  /// Detail meta
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get salesQuotationCreatedLabel;

  /// Detail meta
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get salesQuotationValidUntilLabel2;

  /// Detail section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get salesQuotationDetailLinesHeading;

  /// Detail total row
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get salesQuotationTotalLabel;

  /// Detail notes heading
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get salesQuotationNotesHeading;

  /// Draft → sent action
  ///
  /// In en, this message translates to:
  /// **'Send to customer'**
  String get salesQuotationSendAction;

  /// Sent → accepted action
  ///
  /// In en, this message translates to:
  /// **'Mark accepted'**
  String get salesQuotationAcceptAction;

  /// Sent → rejected action
  ///
  /// In en, this message translates to:
  /// **'Mark rejected'**
  String get salesQuotationRejectAction;

  /// Accepted → converted action
  ///
  /// In en, this message translates to:
  /// **'Convert to order'**
  String get salesQuotationConvertAction;

  /// Status change snackbar
  ///
  /// In en, this message translates to:
  /// **'Quotation updated.'**
  String get salesQuotationStatusUpdated;

  /// Convert success snackbar
  ///
  /// In en, this message translates to:
  /// **'Sales order created.'**
  String get salesQuotationConvertedSnack;

  /// Action failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update quotation: {message}'**
  String salesQuotationActionFailed(String message);

  /// Convert refusal copy
  ///
  /// In en, this message translates to:
  /// **'Only accepted quotations can be converted.'**
  String get salesQuotationConvertNotAccepted;

  /// Convert refusal copy
  ///
  /// In en, this message translates to:
  /// **'This quotation has already been converted.'**
  String get salesQuotationConvertAlready;

  /// Convert refusal copy
  ///
  /// In en, this message translates to:
  /// **'This quotation has expired.'**
  String get salesQuotationConvertExpired;

  /// Slice 6.2.1 order list title
  ///
  /// In en, this message translates to:
  /// **'Sales orders'**
  String get salesOrderListTitle;

  /// Order list empty state
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get salesOrderListEmpty;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get salesOrderStatusPending;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get salesOrderStatusPacking;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get salesOrderStatusShipped;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get salesOrderStatusDelivered;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get salesOrderStatusCancelled;

  /// Order detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Sales order'**
  String get salesOrderDetailTitle;

  /// Detail not-found body
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an order with id \"{orderId}\".'**
  String salesOrderNotFound(String orderId);

  /// Detail meta
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get salesOrderCreatedLabel;

  /// Detail meta
  ///
  /// In en, this message translates to:
  /// **'Source quotation'**
  String get salesOrderSourceQuotationLabel;

  /// Detail meta
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get salesOrderShippedAtLabel;

  /// Detail meta
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get salesOrderDeliveredAtLabel;

  /// Detail meta and tracking dialog label
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get salesOrderTrackingLabel;

  /// Detail section heading
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get salesOrderDetailLinesHeading;

  /// Cancellation action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get salesOrderCancelAction;

  /// pending → packing action
  ///
  /// In en, this message translates to:
  /// **'Start packing'**
  String get salesOrderStartPackingAction;

  /// packing → shipped action
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get salesOrderShipAction;

  /// shipped → delivered action
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get salesOrderMarkDeliveredAction;

  /// Tracking prompt title
  ///
  /// In en, this message translates to:
  /// **'Tracking reference'**
  String get salesOrderTrackingDialogTitle;

  /// Tracking prompt confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get salesOrderTrackingConfirm;

  /// Snackbar when tracking is empty
  ///
  /// In en, this message translates to:
  /// **'A tracking reference is required to ship.'**
  String get salesOrderTrackingRequired;

  /// Advance success snackbar
  ///
  /// In en, this message translates to:
  /// **'Order marked as {status}.'**
  String salesOrderAdvancedSnack(String status);

  /// Advance failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update order: {message}'**
  String salesOrderAdvanceFailed(String message);

  /// Slice 6.3 analytics page title
  ///
  /// In en, this message translates to:
  /// **'Sales analytics'**
  String get salesAnalyticsTitle;

  /// Revenue chart heading
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get salesAnalyticsRevenueHeading;

  /// Revenue chart empty state
  ///
  /// In en, this message translates to:
  /// **'No revenue in the selected window.'**
  String get salesAnalyticsRevenueEmpty;

  /// Period toggle
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get salesAnalyticsPeriodWeekly;

  /// Period toggle
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get salesAnalyticsPeriodMonthly;

  /// Top customers card heading
  ///
  /// In en, this message translates to:
  /// **'Top customers'**
  String get salesAnalyticsTopCustomersHeading;

  /// Top customers empty state
  ///
  /// In en, this message translates to:
  /// **'No customer revenue to rank yet.'**
  String get salesAnalyticsTopCustomersEmpty;

  /// Top products card heading
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get salesAnalyticsTopProductsHeading;

  /// Top products empty state
  ///
  /// In en, this message translates to:
  /// **'No product revenue to rank yet.'**
  String get salesAnalyticsTopProductsEmpty;

  /// Leaderboard card heading
  ///
  /// In en, this message translates to:
  /// **'Sales rep leaderboard'**
  String get salesAnalyticsLeaderboardHeading;

  /// Leaderboard empty state
  ///
  /// In en, this message translates to:
  /// **'No reps yet.'**
  String get salesAnalyticsLeaderboardEmpty;

  /// Deals count under a rep
  ///
  /// In en, this message translates to:
  /// **'{count} deals closed'**
  String salesAnalyticsLeaderboardDealsLabel(String count);

  /// Attainment line
  ///
  /// In en, this message translates to:
  /// **'{pct}% of {target}'**
  String salesAnalyticsLeaderboardAttainmentLabel(String pct, String target);

  /// Top-line message shown by ErrorBoundaryWidget when any widget's build() throws. Falls back to hardcoded English if Localizations are not in scope (which happens when the error fires before MaterialApp mounts).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorBoundaryGenericMessage;

  /// Form field label for email address; shared across login + forgot-password.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmailLabel;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginForgotPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPasswordAction;

  /// No description provided for @loginSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignInAction;

  /// No description provided for @loginOrSecureWith.
  ///
  /// In en, this message translates to:
  /// **'OR SECURE WITH'**
  String get loginOrSecureWith;

  /// No description provided for @loginUseBiometricsAction.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get loginUseBiometricsAction;

  /// No description provided for @loginValidatorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get loginValidatorEmailRequired;

  /// No description provided for @loginValidatorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get loginValidatorEmailInvalid;

  /// No description provided for @loginValidatorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginValidatorPasswordRequired;

  /// No description provided for @loginValidatorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginValidatorPasswordTooShort;

  /// No description provided for @loginNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccountPrompt;

  /// No description provided for @loginCreateAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get loginCreateAccountAction;

  /// No description provided for @registerWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerWelcomeTitle;

  /// No description provided for @registerWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start managing your business in minutes.'**
  String get registerWelcomeSubtitle;

  /// No description provided for @registerFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerFullNameLabel;

  /// No description provided for @registerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get registerFullNameHint;

  /// No description provided for @registerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'096 506 0999'**
  String get registerPhoneHint;

  /// No description provided for @registerValidatorPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get registerValidatorPhoneRequired;

  /// No description provided for @registerValidatorPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get registerValidatorPhoneInvalid;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By tapping Create account you agree to our '**
  String get registerTermsPrefix;

  /// No description provided for @registerTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get registerTermsLink;

  /// No description provided for @registerTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get registerTermsAnd;

  /// No description provided for @registerPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get registerPrivacyLink;

  /// No description provided for @registerTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get registerTermsSuffix;

  /// No description provided for @registerSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSubmitAction;

  /// No description provided for @registerHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccountPrompt;

  /// No description provided for @registerSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get registerSignInAction;

  /// No description provided for @registerValidatorFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get registerValidatorFullNameRequired;

  /// No description provided for @registerValidatorPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerValidatorPasswordsMismatch;

  /// No description provided for @registerValidatorAcceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms to continue'**
  String get registerValidatorAcceptTermsRequired;

  /// No description provided for @registerAcceptTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms and Privacy Policy'**
  String get registerAcceptTermsLabel;

  /// No description provided for @authGenericErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericErrorFallback;

  /// No description provided for @authNetworkErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get authNetworkErrorFallback;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordValidatorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get forgotPasswordValidatorEmailRequired;

  /// No description provided for @forgotPasswordSendResetAction.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordSendResetAction;

  /// No description provided for @forgotPasswordSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Sent!'**
  String get forgotPasswordSentTitle;

  /// No description provided for @forgotPasswordSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox for instructions to reset your password.'**
  String get forgotPasswordSentSubtitle;

  /// No description provided for @forgotPasswordBackToLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordBackToLoginAction;

  /// No description provided for @biometricPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometricPageTitle;

  /// No description provided for @biometricAuthenticatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get biometricAuthenticatingTitle;

  /// No description provided for @biometricHoldFingerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please hold your finger on the sensor'**
  String get biometricHoldFingerSubtitle;

  /// No description provided for @biometricUseFingerprintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or face to continue'**
  String get biometricUseFingerprintSubtitle;

  /// No description provided for @biometricUnlockNowAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock Now'**
  String get biometricUnlockNowAction;

  /// No description provided for @biometricUsePasswordInsteadAction.
  ///
  /// In en, this message translates to:
  /// **'Use Password Instead'**
  String get biometricUsePasswordInsteadAction;

  /// No description provided for @otpResendCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Resend Code (30s)'**
  String get otpResendCodeAction;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Excellence'**
  String get splashTagline;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get dashboardGreeting;

  /// Placeholder name shown on the dashboard hero until real auth user name is wired through. Should still translate so the demo reads natively in any locale.
  ///
  /// In en, this message translates to:
  /// **'Demo Approver'**
  String get dashboardUserNamePlaceholder;

  /// No description provided for @dashboardQuickAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get dashboardQuickAccessSection;

  /// No description provided for @dashboardSimulatePushAction.
  ///
  /// In en, this message translates to:
  /// **'Simulate Push'**
  String get dashboardSimulatePushAction;

  /// No description provided for @dashboardRoutedPushAction.
  ///
  /// In en, this message translates to:
  /// **'Routed Push'**
  String get dashboardRoutedPushAction;

  /// No description provided for @dashboardKpiRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue (MTD)'**
  String get dashboardKpiRevenueLabel;

  /// No description provided for @dashboardKpiOpenInvoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Open invoices'**
  String get dashboardKpiOpenInvoicesLabel;

  /// No description provided for @dashboardKpiAvgFulfilmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg fulfilment (d)'**
  String get dashboardKpiAvgFulfilmentLabel;

  /// No description provided for @accountDetailTransactionsHeading.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTIONS'**
  String get accountDetailTransactionsHeading;

  /// No description provided for @accountDetailCurrentBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT BALANCE'**
  String get accountDetailCurrentBalanceLabel;

  /// Banner on rejected invoice detail showing the rejection reason
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String invoiceDetailRejectionReasonLabel(String reason);

  /// Issued-date pill on invoice list tile
  ///
  /// In en, this message translates to:
  /// **'ISSUED: {date}'**
  String invoiceListIssuedDateLabel(String date);

  /// Reference + posted-date subtitle on journal entry tile
  ///
  /// In en, this message translates to:
  /// **'REF: {reference} · {date}'**
  String journalEntryListReferenceLabel(String reference, String date);

  /// Generic 'SKU: {value}' label shared across procurement (PO, PR, goods receipt) and inventory (item list, item detail, stock movement, stock transfer)
  ///
  /// In en, this message translates to:
  /// **'SKU: {sku}'**
  String commonSkuLabel(String sku);

  /// Created-date pill on purchase request list tile
  ///
  /// In en, this message translates to:
  /// **'CREATED: {date}'**
  String prListCreatedDateLabel(String date);

  /// Department/cost-center pill on purchase request list tile
  ///
  /// In en, this message translates to:
  /// **'DEPT: {dept}'**
  String prListDepartmentLabel(String dept);

  /// Compound SKU + location label on cycle count rows
  ///
  /// In en, this message translates to:
  /// **'SKU: {sku} · LOC: {loc}'**
  String inventorySkuLocationCompound(String sku, String loc);

  /// Warehouse + location label on item list tile
  ///
  /// In en, this message translates to:
  /// **'WH: {wh} · LOC: {loc}'**
  String inventoryWarehouseLocationLabel(String wh, String loc);

  /// No description provided for @inventoryCurrentStockLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STOCK'**
  String get inventoryCurrentStockLabel;

  /// No description provided for @inventoryAvailableToTransferLabel.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE TO TRANSFER'**
  String get inventoryAvailableToTransferLabel;

  /// No description provided for @customerFormCompanyOrPersonNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company or Person Name'**
  String get customerFormCompanyOrPersonNameLabel;

  /// No description provided for @customerFormIndustryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry (Optional)'**
  String get customerFormIndustryOptionalLabel;

  /// Generic phone-number form field label shared across customer form (sales) and employee detail (hr).
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get commonPhoneNumberLabel;

  /// Short 'Phone' label used in compact contact info rows (e.g. my-profile). Distinct from commonPhoneNumberLabel which is for form fields.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get commonPhoneLabel;

  /// No description provided for @customerFormBillingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get customerFormBillingAddressLabel;

  /// No description provided for @customerFormNotesRemarksOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes / Remarks (Optional)'**
  String get customerFormNotesRemarksOptionalLabel;

  /// SnackBar shown when saving a customer throws
  ///
  /// In en, this message translates to:
  /// **'Failed to save customer: {error}'**
  String customerFormSaveFailureSnack(String error);

  /// No description provided for @customerListNewCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get customerListNewCustomerAction;

  /// No description provided for @commonCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancelAction;

  /// No description provided for @commonRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetryAction;

  /// No description provided for @commonLoadFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Please try again.'**
  String get commonLoadFailedFallback;

  /// No description provided for @assignmentsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Permissions & Roles'**
  String get assignmentsPageTitle;

  /// No description provided for @assignmentsRolesTab.
  ///
  /// In en, this message translates to:
  /// **'Roles → Permissions'**
  String get assignmentsRolesTab;

  /// No description provided for @assignmentsUsersTab.
  ///
  /// In en, this message translates to:
  /// **'Users → Roles'**
  String get assignmentsUsersTab;

  /// No description provided for @assignmentsPickRolePrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick a role to edit its permissions'**
  String get assignmentsPickRolePrompt;

  /// No description provided for @assignmentsPickUserPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick a user to edit their roles'**
  String get assignmentsPickUserPrompt;

  /// No description provided for @assignmentsPermissionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get assignmentsPermissionsSectionTitle;

  /// No description provided for @assignmentsRolesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get assignmentsRolesSectionTitle;

  /// No description provided for @assignmentsCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String assignmentsCountSuffix(int count);

  /// No description provided for @assignmentsSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get assignmentsSaveAction;

  /// No description provided for @assignmentsNoChangesYet.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get assignmentsNoChangesYet;

  /// No description provided for @assignmentsSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get assignmentsSavedSnack;

  /// No description provided for @assignmentsSaveFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes'**
  String get assignmentsSaveFailedSnack;

  /// No description provided for @assignmentsForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to make changes here.'**
  String get assignmentsForbiddenMessage;

  /// No description provided for @assignmentsSuperAdminOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Super-administrators only'**
  String get assignmentsSuperAdminOnlyTitle;

  /// No description provided for @assignmentsSuperAdminOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Only super-administrators can assign roles and permissions. Sign in with a super-admin account to use this page.'**
  String get assignmentsSuperAdminOnlyMessage;

  /// No description provided for @assignmentsUsersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users…'**
  String get assignmentsUsersSearchHint;

  /// No description provided for @assignmentsSearchPermissionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search permissions…'**
  String get assignmentsSearchPermissionsHint;

  /// No description provided for @assignmentsRolePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get assignmentsRolePickerLabel;

  /// No description provided for @assignmentsSystemRoleBadge.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get assignmentsSystemRoleBadge;

  /// No description provided for @assignmentsSystemRoleLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'System roles are read-only. Create a custom role to assign different permissions.'**
  String get assignmentsSystemRoleLockedMessage;

  /// No description provided for @assignmentsLoadMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get assignmentsLoadMoreAction;

  /// No description provided for @assignmentsEmptyUsers.
  ///
  /// In en, this message translates to:
  /// **'No users yet.'**
  String get assignmentsEmptyUsers;

  /// No description provided for @assignmentsNoUserSelected.
  ///
  /// In en, this message translates to:
  /// **'Pick a user from the list to assign roles.'**
  String get assignmentsNoUserSelected;

  /// No description provided for @assignmentsNoRoleSelected.
  ///
  /// In en, this message translates to:
  /// **'Pick a role above to start assigning permissions.'**
  String get assignmentsNoRoleSelected;

  /// No description provided for @assignmentsAssignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a role, then the users to assign it to. Each user gets exactly one role.'**
  String get assignmentsAssignSubtitle;

  /// No description provided for @assignmentsSaveActionAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign role to {count, plural, one{# user} other{# users}}'**
  String assignmentsSaveActionAssign(int count);

  /// No description provided for @assignmentsUserFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'USERS'**
  String get assignmentsUserFieldLabel;

  /// No description provided for @assignmentsRoleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get assignmentsRoleFieldLabel;

  /// No description provided for @assignmentsModeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get assignmentsModeFieldLabel;

  /// No description provided for @assignmentsRoleHelperPickUserFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one user to enable role assignment.'**
  String get assignmentsRoleHelperPickUserFirst;

  /// No description provided for @assignmentsRoleHelperCurrentRole.
  ///
  /// In en, this message translates to:
  /// **'Applies the selected role to every picked user.'**
  String get assignmentsRoleHelperCurrentRole;

  /// No description provided for @assignmentsPickUsersPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick users…'**
  String get assignmentsPickUsersPrompt;

  /// No description provided for @assignmentsUsersSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# user selected} other{# users selected}}'**
  String assignmentsUsersSelectedCount(int count);

  /// No description provided for @assignmentsUsersSelectedSummary.
  ///
  /// In en, this message translates to:
  /// **'{first} +{others, plural, one{# other} other{# others}}'**
  String assignmentsUsersSelectedSummary(String first, int others);

  /// No description provided for @assignmentsModeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get assignmentsModeAdd;

  /// No description provided for @assignmentsModeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get assignmentsModeReplace;

  /// No description provided for @assignmentsModeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get assignmentsModeRemove;

  /// No description provided for @assignmentsModeHelperAdd.
  ///
  /// In en, this message translates to:
  /// **'Adds the role on top of each user\'s existing roles.'**
  String get assignmentsModeHelperAdd;

  /// No description provided for @assignmentsModeHelperReplace.
  ///
  /// In en, this message translates to:
  /// **'Replaces each user\'s roles with only the picked role.'**
  String get assignmentsModeHelperReplace;

  /// No description provided for @assignmentsModeHelperRemove.
  ///
  /// In en, this message translates to:
  /// **'Strips the picked role from each user (others kept).'**
  String get assignmentsModeHelperRemove;

  /// No description provided for @assignmentsSaveActionBulk.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, add{Add role to {count, plural, one{# user} other{# users}}} replace{Replace roles on {count, plural, one{# user} other{# users}}} remove{Remove role from {count, plural, one{# user} other{# users}}} other{Save changes}}'**
  String assignmentsSaveActionBulk(String mode, int count);

  /// No description provided for @assignmentsSelectAllAction.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get assignmentsSelectAllAction;

  /// No description provided for @assignmentsClearSelectionAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get assignmentsClearSelectionAction;

  /// No description provided for @assignmentsConfirmDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get assignmentsConfirmDoneAction;

  /// No description provided for @assignmentsUserNoRoleBadge.
  ///
  /// In en, this message translates to:
  /// **'No role'**
  String get assignmentsUserNoRoleBadge;

  /// No description provided for @assignmentsUserRolesMore.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String assignmentsUserRolesMore(int count);

  /// No description provided for @assignmentsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get assignmentsFilterAll;

  /// No description provided for @assignmentsFilterHasRole.
  ///
  /// In en, this message translates to:
  /// **'Has role'**
  String get assignmentsFilterHasRole;

  /// No description provided for @assignmentsFilterNoRole.
  ///
  /// In en, this message translates to:
  /// **'No role'**
  String get assignmentsFilterNoRole;

  /// No description provided for @commonApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get commonApproveAction;

  /// No description provided for @commonRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get commonRejectAction;

  /// No description provided for @hrEmployeeDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee not found'**
  String get hrEmployeeDetailNotFoundTitle;

  /// No description provided for @hrEmployeeDetailNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'No employee with ID \"{employeeId}\" exists.'**
  String hrEmployeeDetailNotFoundBody(String employeeId);

  /// No description provided for @hrEmployeeDetailOfficeLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Office Location'**
  String get hrEmployeeDetailOfficeLocationLabel;

  /// No description provided for @hrEmployeeDetailDepartmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get hrEmployeeDetailDepartmentLabel;

  /// No description provided for @hrEmployeeDetailPositionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Position Title'**
  String get hrEmployeeDetailPositionTitleLabel;

  /// No description provided for @hrEmployeeDetailHireDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get hrEmployeeDetailHireDateLabel;

  /// No description provided for @hrEmployeeDetailMonthlySalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Salary'**
  String get hrEmployeeDetailMonthlySalaryLabel;

  /// No description provided for @hrEmployeeDetailManagerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Manager ID'**
  String get hrEmployeeDetailManagerIdLabel;

  /// No description provided for @hrEmployeeDetailTabAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get hrEmployeeDetailTabAttendance;

  /// No description provided for @hrEmployeeDetailTabPayslips.
  ///
  /// In en, this message translates to:
  /// **'Payslips'**
  String get hrEmployeeDetailTabPayslips;

  /// No description provided for @hrEmployeeDetailTabLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get hrEmployeeDetailTabLeaves;

  /// No description provided for @hrEmployeeDetailTabOrgChart.
  ///
  /// In en, this message translates to:
  /// **'Org Chart'**
  String get hrEmployeeDetailTabOrgChart;

  /// No description provided for @hrEmployeeListOrgChartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Org chart'**
  String get hrEmployeeListOrgChartTooltip;

  /// No description provided for @hrEmployeeListSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get hrEmployeeListSortTooltip;

  /// No description provided for @hrEmployeeListSortNameAz.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get hrEmployeeListSortNameAz;

  /// No description provided for @hrEmployeeListSortRecentlyHired.
  ///
  /// In en, this message translates to:
  /// **'Recently hired'**
  String get hrEmployeeListSortRecentlyHired;

  /// No description provided for @hrEmployeeListSortDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get hrEmployeeListSortDepartment;

  /// No description provided for @hrEmployeeListErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading directory'**
  String get hrEmployeeListErrorLoading;

  /// No description provided for @hrEmployeeListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, email, position…'**
  String get hrEmployeeListSearchHint;

  /// No description provided for @hrEmployeeListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching employees'**
  String get hrEmployeeListEmptyTitle;

  /// No description provided for @hrEmployeeListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try refining your search query or filters'**
  String get hrEmployeeListEmptySubtitle;

  /// No description provided for @hrLeaveApprovalRejectReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get hrLeaveApprovalRejectReasonTitle;

  /// No description provided for @hrLeaveApprovalConfirmRejectionAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get hrLeaveApprovalConfirmRejectionAction;

  /// No description provided for @hrLeaveApprovalConfirmApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this leave request?'**
  String get hrLeaveApprovalConfirmApprovalTitle;

  /// No description provided for @hrLeaveApprovalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get hrLeaveApprovalNoteHint;

  /// No description provided for @hrLeaveApprovalNoYearlyBalance.
  ///
  /// In en, this message translates to:
  /// **'No yearly balance configured'**
  String get hrLeaveApprovalNoYearlyBalance;

  /// No description provided for @hrLeaveApprovalFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get hrLeaveApprovalFromLabel;

  /// No description provided for @hrLeaveApprovalToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get hrLeaveApprovalToLabel;

  /// No description provided for @hrLeaveApprovalSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted {timestamp}'**
  String hrLeaveApprovalSubmittedAt(String timestamp);

  /// No description provided for @hrLeaveApprovalIfApprovedLabel.
  ///
  /// In en, this message translates to:
  /// **'If Approved'**
  String get hrLeaveApprovalIfApprovedLabel;

  /// No description provided for @hrLeaveApprovalIfRejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'If Rejected'**
  String get hrLeaveApprovalIfRejectedLabel;

  /// No description provided for @hrLeaveRequestsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hrLeaveRequestsTabAll;

  /// No description provided for @hrLeaveRequestsTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get hrLeaveRequestsTabPending;

  /// No description provided for @hrLeaveRequestsTabMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get hrLeaveRequestsTabMine;

  /// No description provided for @hrLeaveRequestsNewRequestTooltip.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get hrLeaveRequestsNewRequestTooltip;

  /// No description provided for @hrLeaveRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No leave requests'**
  String get hrLeaveRequestsEmptyTitle;

  /// No description provided for @hrLeaveRequestsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no requests matching this filter.'**
  String get hrLeaveRequestsEmptySubtitle;

  /// No description provided for @hrLeaveRequestsApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Leave request approved.'**
  String get hrLeaveRequestsApprovedSnack;

  /// No description provided for @hrLeaveRequestsRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Leave Request'**
  String get hrLeaveRequestsRejectDialogTitle;

  /// No description provided for @hrLeaveRequestsRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Leave request rejected.'**
  String get hrLeaveRequestsRejectedSnack;

  /// No description provided for @hrLeaveRequestsRejectionReasonRequiredSnack.
  ///
  /// In en, this message translates to:
  /// **'A rejection reason is required.'**
  String get hrLeaveRequestsRejectionReasonRequiredSnack;

  /// No description provided for @hrLeaveFormSubmittedSnack.
  ///
  /// In en, this message translates to:
  /// **'Leave request submitted successfully.'**
  String get hrLeaveFormSubmittedSnack;

  /// No description provided for @hrLeaveFormPreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'LEAVE PREFERENCES'**
  String get hrLeaveFormPreferencesSection;

  /// No description provided for @hrLeaveFormDurationSection.
  ///
  /// In en, this message translates to:
  /// **'DURATION SELECTOR'**
  String get hrLeaveFormDurationSection;

  /// No description provided for @hrLeaveFormAttachmentsSection.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS & EVIDENCE'**
  String get hrLeaveFormAttachmentsSection;

  /// No description provided for @hrLeaveFormJustificationSection.
  ///
  /// In en, this message translates to:
  /// **'JUSTIFICATION'**
  String get hrLeaveFormJustificationSection;

  /// No description provided for @hrLeaveFormSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Leave Request'**
  String get hrLeaveFormSubmitAction;

  /// No description provided for @hrLeaveFormUploadingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Uploading attachment...'**
  String get hrLeaveFormUploadingAttachment;

  /// No description provided for @hrLeaveFormReadyToUpload.
  ///
  /// In en, this message translates to:
  /// **'Ready to upload'**
  String get hrLeaveFormReadyToUpload;

  /// No description provided for @hrLeaveFormRemoveAttachmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get hrLeaveFormRemoveAttachmentTooltip;

  /// No description provided for @hrLeaveFormTapToUploadDocument.
  ///
  /// In en, this message translates to:
  /// **'TAP TO UPLOAD DOCUMENT'**
  String get hrLeaveFormTapToUploadDocument;

  /// No description provided for @hrLeaveFormUploadSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Support PDF, PNG, JPG up to 10MB (Medical Cert, etc.)'**
  String get hrLeaveFormUploadSupportedFormats;

  /// No description provided for @hrLeaveBalanceHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Leave History'**
  String get hrLeaveBalanceHistoryTooltip;

  /// No description provided for @hrLeaveBalanceRequestLeaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get hrLeaveBalanceRequestLeaveTooltip;

  /// No description provided for @hrLeaveBalanceNoEntitlements.
  ///
  /// In en, this message translates to:
  /// **'No entitlements on file'**
  String get hrLeaveBalanceNoEntitlements;

  /// No description provided for @hrLeaveBalanceRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get hrLeaveBalanceRemainingLabel;

  /// No description provided for @hrLeaveBalanceTakenLabel.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get hrLeaveBalanceTakenLabel;

  /// No description provided for @hrLeaveBalanceTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get hrLeaveBalanceTotalLabel;

  /// No description provided for @hrLeaveBalanceBreakdownHeading.
  ///
  /// In en, this message translates to:
  /// **'ENTITLEMENT BREAKDOWN'**
  String get hrLeaveBalanceBreakdownHeading;

  /// No description provided for @hrAttendanceRecentEntriesHeading.
  ///
  /// In en, this message translates to:
  /// **'RECENT ENTRIES'**
  String get hrAttendanceRecentEntriesHeading;

  /// No description provided for @hrAttendanceEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No attendance records yet'**
  String get hrAttendanceEmptyMessage;

  /// No description provided for @hrPayslipsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payslips on file'**
  String get hrPayslipsEmpty;

  /// No description provided for @hrPayslipsArchiveHeading.
  ///
  /// In en, this message translates to:
  /// **'PAYSLIP ARCHIVE'**
  String get hrPayslipsArchiveHeading;

  /// No description provided for @hrPayslipsAggregateSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Aggregate Summary'**
  String get hrPayslipsAggregateSummaryHeading;

  /// No description provided for @hrPayslipsNetPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Net: {amount}'**
  String hrPayslipsNetPayLabel(String amount);

  /// No description provided for @hrPayslipsGrossPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross: {amount}'**
  String hrPayslipsGrossPayLabel(String amount);

  /// No description provided for @hrPayslipDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No payslip with id \"{payslipId}\".'**
  String hrPayslipDetailNotFound(String payslipId);

  /// No description provided for @hrPayslipDetailNetPayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'NET PAYOUT'**
  String get hrPayslipDetailNetPayoutLabel;

  /// No description provided for @hrPayslipDetailBreakdownHeading.
  ///
  /// In en, this message translates to:
  /// **'LINE ITEM BREAKDOWN'**
  String get hrPayslipDetailBreakdownHeading;

  /// No description provided for @hrOrgChartPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization Chart'**
  String get hrOrgChartPageTitle;

  /// No description provided for @hrOrgChartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get hrOrgChartEmptyTitle;

  /// No description provided for @hrOrgChartEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add employees to see the hierarchy.'**
  String get hrOrgChartEmptySubtitle;

  /// No description provided for @hrAttendancePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Log'**
  String get hrAttendancePageTitle;

  /// No description provided for @hrEmployeeDetailPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Profile'**
  String get hrEmployeeDetailPageTitle;

  /// No description provided for @hrEmployeeDetailSectionQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get hrEmployeeDetailSectionQuickActions;

  /// No description provided for @hrEmployeeDetailSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get hrEmployeeDetailSectionContact;

  /// No description provided for @hrEmployeeDetailSectionEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment Details'**
  String get hrEmployeeDetailSectionEmployment;

  /// No description provided for @hrEmployeeListPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Directory'**
  String get hrEmployeeListPageTitle;

  /// No description provided for @hrLeaveApprovalPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Request'**
  String get hrLeaveApprovalPageTitle;

  /// No description provided for @hrLeaveBalancePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance'**
  String get hrLeaveBalancePageTitle;

  /// No description provided for @hrLeaveRequestsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get hrLeaveRequestsPageTitle;

  /// No description provided for @hrLeaveFormPageTitle.
  ///
  /// In en, this message translates to:
  /// **'New Leave Request'**
  String get hrLeaveFormPageTitle;

  /// No description provided for @hrPayslipsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Payslips History'**
  String get hrPayslipsPageTitle;

  /// No description provided for @hrPayslipDetailPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Payslip Detail'**
  String get hrPayslipDetailPageTitle;

  /// No description provided for @projectBoardPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Board'**
  String get projectBoardPageTitle;

  /// No description provided for @projectBoardNewTaskAction.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get projectBoardNewTaskAction;

  /// No description provided for @projectBoardDropZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Drop tasks here'**
  String get projectBoardDropZoneHint;

  /// No description provided for @projectDetailPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetailPageTitle;

  /// No description provided for @projectDetailOpenBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Board'**
  String get projectDetailOpenBoardTooltip;

  /// No description provided for @projectDetailEditProjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get projectDetailEditProjectTooltip;

  /// No description provided for @projectDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No project with id \"{projectId}\".'**
  String projectDetailNotFound(String projectId);

  /// No description provided for @projectDetailProjectIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Project ID: {code}'**
  String projectDetailProjectIdLabel(String code);

  /// No description provided for @projectDetailDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get projectDetailDescriptionHeading;

  /// No description provided for @projectDetailTasksHeading.
  ///
  /// In en, this message translates to:
  /// **'PROJECT TASKS'**
  String get projectDetailTasksHeading;

  /// No description provided for @projectDetailNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned yet.'**
  String get projectDetailNoTasks;

  /// No description provided for @projectFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectFormNameLabel;

  /// No description provided for @projectFormCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Project code'**
  String get projectFormCodeLabel;

  /// No description provided for @projectFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectFormDescriptionLabel;

  /// No description provided for @projectFormStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get projectFormStartLabel;

  /// No description provided for @projectFormEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get projectFormEndLabel;

  /// No description provided for @projectFormDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String projectFormDurationLabel(String duration);

  /// No description provided for @projectFormBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget (formatted)'**
  String get projectFormBudgetLabel;

  /// No description provided for @projectFormPickEmployeeAction.
  ///
  /// In en, this message translates to:
  /// **'Pick an employee'**
  String get projectFormPickEmployeeAction;

  /// No description provided for @projectListPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectListPageTitle;

  /// No description provided for @projectListTimesheetsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Timesheets'**
  String get projectListTimesheetsTooltip;

  /// No description provided for @projectListSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get projectListSortTooltip;

  /// No description provided for @projectListSortNameAz.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get projectListSortNameAz;

  /// No description provided for @projectListSortRecentlyStarted.
  ///
  /// In en, this message translates to:
  /// **'Recently started'**
  String get projectListSortRecentlyStarted;

  /// No description provided for @projectListSortDueSoonest.
  ///
  /// In en, this message translates to:
  /// **'Due soonest'**
  String get projectListSortDueSoonest;

  /// No description provided for @projectListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String projectListErrorMessage(String message);

  /// No description provided for @projectListViewListAction.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get projectListViewListAction;

  /// No description provided for @projectListViewGanttAction.
  ///
  /// In en, this message translates to:
  /// **'Gantt Chart'**
  String get projectListViewGanttAction;

  /// No description provided for @projectListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, code, owner…'**
  String get projectListSearchHint;

  /// No description provided for @projectListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects match.'**
  String get projectListEmpty;

  /// No description provided for @projectListNewProjectAction.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get projectListNewProjectAction;

  /// No description provided for @projectListCodeOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Code: {code} • Owner: {owner}'**
  String projectListCodeOwnerSubtitle(String code, String owner);

  /// No description provided for @taskAssignPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Task'**
  String get taskAssignPageTitle;

  /// No description provided for @taskAssignErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Could not load employees'**
  String get taskAssignErrorLoading;

  /// No description provided for @taskAssignSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String taskAssignSuccessSnack(String name);

  /// No description provided for @taskAssignFailureSnack.
  ///
  /// In en, this message translates to:
  /// **'Assign failed: {error}'**
  String taskAssignFailureSnack(String error);

  /// No description provided for @taskAssignCurrentlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currently: '**
  String get taskAssignCurrentlyLabel;

  /// No description provided for @taskAssignSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, role or department…'**
  String get taskAssignSearchHint;

  /// No description provided for @taskAssignClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get taskAssignClearTooltip;

  /// No description provided for @taskAssignNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note to the assignee… (e.g. \"context in #project-alpha\")'**
  String get taskAssignNoteHint;

  /// No description provided for @taskAssignEmpty.
  ///
  /// In en, this message translates to:
  /// **'No employees match that search.'**
  String get taskAssignEmpty;

  /// No description provided for @taskDetailPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetailPageTitle;

  /// No description provided for @taskDetailMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get taskDetailMoreTooltip;

  /// No description provided for @taskDetailEditTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskDetailEditTaskAction;

  /// No description provided for @taskDetailReassignAction.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get taskDetailReassignAction;

  /// No description provided for @taskDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No task with id \"{taskId}\".'**
  String taskDetailNotFound(String taskId);

  /// No description provided for @taskDetailDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get taskDetailDescriptionHeading;

  /// No description provided for @taskDetailCommentsHeading.
  ///
  /// In en, this message translates to:
  /// **'COMMENTS'**
  String get taskDetailCommentsHeading;

  /// No description provided for @taskDetailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get taskDetailNoComments;

  /// No description provided for @taskDetailAddCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get taskDetailAddCommentHint;

  /// No description provided for @taskFormPageTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get taskFormPageTitleEdit;

  /// No description provided for @taskFormPageTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get taskFormPageTitleNew;

  /// No description provided for @taskFormTitleRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get taskFormTitleRequiredValidator;

  /// No description provided for @taskFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskFormTitleHint;

  /// No description provided for @taskFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a description…'**
  String get taskFormDescriptionHint;

  /// No description provided for @taskFormStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskFormStatusLabel;

  /// No description provided for @taskFormPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskFormPriorityLabel;

  /// No description provided for @taskFormAssigneeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get taskFormAssigneeLabel;

  /// No description provided for @taskFormUnassignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get taskFormUnassignedLabel;

  /// No description provided for @taskFormDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get taskFormDueDateLabel;

  /// No description provided for @taskFormClearDueDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get taskFormClearDueDateTooltip;

  /// No description provided for @taskFormAddDueDateAction.
  ///
  /// In en, this message translates to:
  /// **'Add due date'**
  String get taskFormAddDueDateAction;

  /// No description provided for @taskFormAssignToAction.
  ///
  /// In en, this message translates to:
  /// **'Assign to…'**
  String get taskFormAssignToAction;

  /// No description provided for @taskFormUnassignAction.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get taskFormUnassignAction;

  /// No description provided for @timesheetsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Timesheets'**
  String get timesheetsPageTitle;

  /// No description provided for @timesheetsUtilizationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Utilization'**
  String get timesheetsUtilizationTooltip;

  /// No description provided for @timesheetsTabMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get timesheetsTabMine;

  /// No description provided for @timesheetsTabApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get timesheetsTabApprovals;

  /// No description provided for @timesheetsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get timesheetsTabAll;

  /// No description provided for @timesheetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timesheet entries found.'**
  String get timesheetsEmpty;

  /// No description provided for @timesheetsLogTimeAction.
  ///
  /// In en, this message translates to:
  /// **'Log time'**
  String get timesheetsLogTimeAction;

  /// No description provided for @timesheetsTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task: {title}'**
  String timesheetsTaskLabel(String title);

  /// No description provided for @timesheetsRejectionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection Note: {note}'**
  String timesheetsRejectionNoteLabel(String note);

  /// No description provided for @timesheetsSubmitForApprovalAction.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get timesheetsSubmitForApprovalAction;

  /// No description provided for @timesheetsReopenAsDraftAction.
  ///
  /// In en, this message translates to:
  /// **'Re-open as Draft'**
  String get timesheetsReopenAsDraftAction;

  /// No description provided for @timesheetsApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Timesheet approved.'**
  String get timesheetsApprovedSnack;

  /// No description provided for @timesheetsRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject timesheet'**
  String get timesheetsRejectDialogTitle;

  /// No description provided for @timesheetsRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Timesheet rejected.'**
  String get timesheetsRejectedSnack;

  /// No description provided for @timesheetsReasonRequiredSnack.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get timesheetsReasonRequiredSnack;

  /// No description provided for @timesheetsSubmittedSnack.
  ///
  /// In en, this message translates to:
  /// **'Submitted for approval.'**
  String get timesheetsSubmittedSnack;

  /// No description provided for @timesheetsReopenedSnack.
  ///
  /// In en, this message translates to:
  /// **'Reopened as draft.'**
  String get timesheetsReopenedSnack;

  /// No description provided for @timesheetFormPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Time'**
  String get timesheetFormPageTitle;

  /// No description provided for @timesheetFormSubmitToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval immediately'**
  String get timesheetFormSubmitToggleLabel;

  /// No description provided for @timesheetFormSubmitToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Otherwise it lands as a draft you can edit later.'**
  String get timesheetFormSubmitToggleHint;

  /// No description provided for @timesheetFormSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Timesheet'**
  String get timesheetFormSaveAction;

  /// No description provided for @utilizationPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Utilization'**
  String get utilizationPageTitle;

  /// No description provided for @utilizationThisWeekToggle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get utilizationThisWeekToggle;

  /// No description provided for @utilizationThisMonthToggle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get utilizationThisMonthToggle;

  /// No description provided for @utilizationApprovedHoursHeading.
  ///
  /// In en, this message translates to:
  /// **'APPROVED HOURS VS TARGET'**
  String get utilizationApprovedHoursHeading;

  /// No description provided for @utilizationNoHoursInWindow.
  ///
  /// In en, this message translates to:
  /// **'No approved hours in this window.'**
  String get utilizationNoHoursInWindow;

  /// No description provided for @ganttChartNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects in this window.'**
  String get ganttChartNoProjects;

  /// No description provided for @settingsHomePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHomePageTitle;

  /// No description provided for @settingsHomeAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsHomeAccountSection;

  /// No description provided for @settingsHomeMyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get settingsHomeMyProfileTitle;

  /// No description provided for @settingsHomeMyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact, personal, security'**
  String get settingsHomeMyProfileSubtitle;

  /// No description provided for @settingsHomeMyRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'My roles & permissions'**
  String get settingsHomeMyRolesTitle;

  /// No description provided for @settingsHomeMyRolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you can do in the app'**
  String get settingsHomeMyRolesSubtitle;

  /// No description provided for @settingsHomePreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsHomePreferencesSection;

  /// No description provided for @settingsHomeAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsHomeAppearanceTitle;

  /// No description provided for @settingsHomeAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark, or follow system'**
  String get settingsHomeAppearanceSubtitle;

  /// No description provided for @settingsHomeLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsHomeLanguageTitle;

  /// No description provided for @settingsHomeLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English / ខ្មែរ'**
  String get settingsHomeLanguageSubtitle;

  /// No description provided for @settingsHomeNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsHomeNotificationsTitle;

  /// No description provided for @settingsHomeNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push + email per category'**
  String get settingsHomeNotificationsSubtitle;

  /// No description provided for @settingsHomeSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security & Access'**
  String get settingsHomeSecuritySection;

  /// No description provided for @settingsHomeActiveDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active devices'**
  String get settingsHomeActiveDevicesTitle;

  /// No description provided for @settingsHomeActiveDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions you can revoke'**
  String get settingsHomeActiveDevicesSubtitle;

  /// No description provided for @settingsHomeAuditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get settingsHomeAuditLogTitle;

  /// No description provided for @settingsHomeAuditLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who did what, when'**
  String get settingsHomeAuditLogSubtitle;

  /// No description provided for @settingsHomeAppLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsHomeAppLockTitle;

  /// No description provided for @settingsHomeAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PIN + biometric re-auth'**
  String get settingsHomeAppLockSubtitle;

  /// No description provided for @settingsHomeAdminSection.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get settingsHomeAdminSection;

  /// No description provided for @settingsHomeUserMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get settingsHomeUserMgmtTitle;

  /// No description provided for @settingsHomeUserMgmtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite, suspend, assign roles'**
  String get settingsHomeUserMgmtSubtitle;

  /// No description provided for @settingsHomeRolesPermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles & permissions'**
  String get settingsHomeRolesPermsTitle;

  /// No description provided for @settingsHomeRolesPermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Editor for custom roles'**
  String get settingsHomeRolesPermsSubtitle;

  /// No description provided for @settingsHomeApiConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'API configuration'**
  String get settingsHomeApiConfigTitle;

  /// No description provided for @settingsHomeApiConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch environment / tenant'**
  String get settingsHomeApiConfigSubtitle;

  /// No description provided for @settingsHomeSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsHomeSignOutAction;

  /// No description provided for @settingsHomeSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsHomeSignOutConfirmTitle;

  /// No description provided for @settingsHomeSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your data on this device.'**
  String get settingsHomeSignOutConfirmMessage;

  /// No description provided for @settingsHomeSignOutErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out cleanly. Please try again.'**
  String get settingsHomeSignOutErrorSnack;

  /// No description provided for @appearancePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearancePageTitle;

  /// No description provided for @appearanceChooseThemeHeading.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE THEME MODE'**
  String get appearanceChooseThemeHeading;

  /// No description provided for @appearanceModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceModeSystem;

  /// No description provided for @appearanceModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get appearanceModeLight;

  /// No description provided for @appearanceModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get appearanceModeDark;

  /// No description provided for @appearanceSubtitleSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow the OS appearance setting'**
  String get appearanceSubtitleSystem;

  /// No description provided for @appearanceSubtitleLight.
  ///
  /// In en, this message translates to:
  /// **'Always use the light palette'**
  String get appearanceSubtitleLight;

  /// No description provided for @appearanceSubtitleDark.
  ///
  /// In en, this message translates to:
  /// **'Always use the dark palette'**
  String get appearanceSubtitleDark;

  /// No description provided for @languagePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePageTitle;

  /// No description provided for @languageSelectPreferredHeading.
  ///
  /// In en, this message translates to:
  /// **'SELECT PREFERRED LANGUAGE'**
  String get languageSelectPreferredHeading;

  /// No description provided for @languageDemoLaunchNote.
  ///
  /// In en, this message translates to:
  /// **'Language change applies on next app launch in this demo build.'**
  String get languageDemoLaunchNote;

  /// No description provided for @languageEnglishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishLabel;

  /// No description provided for @languageKhmerLabel.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get languageKhmerLabel;

  /// No description provided for @languageEnglishNative.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get languageEnglishNative;

  /// No description provided for @languageKhmerNative.
  ///
  /// In en, this message translates to:
  /// **'ភាសាខ្មែរ'**
  String get languageKhmerNative;

  /// No description provided for @notificationPrefsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationPrefsPageTitle;

  /// No description provided for @notificationPrefsChannelsHeading.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION CHANNELS'**
  String get notificationPrefsChannelsHeading;

  /// No description provided for @notificationPrefsPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notificationPrefsPushTitle;

  /// No description provided for @notificationPrefsEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Updates'**
  String get notificationPrefsEmailTitle;

  /// No description provided for @notificationPrefsChannelApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get notificationPrefsChannelApprovals;

  /// No description provided for @notificationPrefsChannelMentions.
  ///
  /// In en, this message translates to:
  /// **'Mentions & comments'**
  String get notificationPrefsChannelMentions;

  /// No description provided for @notificationPrefsChannelSystemAlerts.
  ///
  /// In en, this message translates to:
  /// **'System alerts'**
  String get notificationPrefsChannelSystemAlerts;

  /// No description provided for @notificationPrefsChannelMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing & tips'**
  String get notificationPrefsChannelMarketing;

  /// No description provided for @notificationPrefsChannelApprovalsDescription.
  ///
  /// In en, this message translates to:
  /// **'Invoices, leave requests, timesheets pending action'**
  String get notificationPrefsChannelApprovalsDescription;

  /// No description provided for @notificationPrefsChannelMentionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Someone @-mentioned you on a task or comment'**
  String get notificationPrefsChannelMentionsDescription;

  /// No description provided for @notificationPrefsChannelSystemAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync failures, downtime windows, security events'**
  String get notificationPrefsChannelSystemAlertsDescription;

  /// No description provided for @notificationPrefsChannelMarketingDescription.
  ///
  /// In en, this message translates to:
  /// **'Product news, tips, and feature announcements'**
  String get notificationPrefsChannelMarketingDescription;

  /// No description provided for @sessionsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Active devices'**
  String get sessionsPageTitle;

  /// No description provided for @sessionsSignOutOthersSnack.
  ///
  /// In en, this message translates to:
  /// **'Other devices signed out.'**
  String get sessionsSignOutOthersSnack;

  /// No description provided for @sessionsSignOutOthersAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get sessionsSignOutOthersAction;

  /// No description provided for @sessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active sessions.'**
  String get sessionsEmpty;

  /// No description provided for @sessionsThisDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get sessionsThisDeviceLabel;

  /// No description provided for @sessionsRevokeAccessAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke Access'**
  String get sessionsRevokeAccessAction;

  /// No description provided for @sessionsLastActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get sessionsLastActiveLabel;

  /// No description provided for @sessionsSignedInLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get sessionsSignedInLabel;

  /// No description provided for @sessionsLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sessionsLocationLabel;

  /// No description provided for @sessionsIpAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get sessionsIpAddressLabel;

  /// No description provided for @sessionsRevokedSnack.
  ///
  /// In en, this message translates to:
  /// **'{device} signed out.'**
  String sessionsRevokedSnack(String device);

  /// No description provided for @auditLogPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLogPageTitle;

  /// No description provided for @auditLogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search actor, target, or details…'**
  String get auditLogSearchHint;

  /// No description provided for @auditLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No log entries match your filters.'**
  String get auditLogEmpty;

  /// No description provided for @auditLogDetailDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Entry Details'**
  String get auditLogDetailDialogTitle;

  /// No description provided for @auditLogAdditionalMetadataLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Metadata:'**
  String get auditLogAdditionalMetadataLabel;

  /// No description provided for @auditLogCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get auditLogCloseAction;

  /// No description provided for @auditLogActorIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Actor ID'**
  String get auditLogActorIdLabel;

  /// No description provided for @auditLogActorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Actor Name'**
  String get auditLogActorNameLabel;

  /// No description provided for @auditLogActionVerbLabel.
  ///
  /// In en, this message translates to:
  /// **'Action Verb'**
  String get auditLogActionVerbLabel;

  /// No description provided for @auditLogTargetTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Type'**
  String get auditLogTargetTypeLabel;

  /// No description provided for @auditLogTargetIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Target ID'**
  String get auditLogTargetIdLabel;

  /// No description provided for @auditLogTargetLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Label'**
  String get auditLogTargetLabelLabel;

  /// No description provided for @auditLogTimestampLabel.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get auditLogTimestampLabel;

  /// No description provided for @appLockPageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Lock Settings'**
  String get appLockPageTitle;

  /// No description provided for @appLockDeviceProtectionHeading.
  ///
  /// In en, this message translates to:
  /// **'DEVICE PROTECTION'**
  String get appLockDeviceProtectionHeading;

  /// No description provided for @appLockPinTitle.
  ///
  /// In en, this message translates to:
  /// **'App Lock PIN'**
  String get appLockPinTitle;

  /// No description provided for @appLockPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require a secure 4–8 digit PIN on resume'**
  String get appLockPinSubtitle;

  /// No description provided for @appLockBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get appLockBiometricTitle;

  /// No description provided for @appLockBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID / Fingerprint instead of entering PIN'**
  String get appLockBiometricSubtitle;

  /// No description provided for @appLockTimeoutHeading.
  ///
  /// In en, this message translates to:
  /// **'TIMEOUT CONFIGURATION'**
  String get appLockTimeoutHeading;

  /// No description provided for @appLockAutoLockDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock Duration'**
  String get appLockAutoLockDurationTitle;

  /// No description provided for @appLockChangePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Lock PIN'**
  String get appLockChangePinTitle;

  /// No description provided for @appLockChangePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace existing security entry code'**
  String get appLockChangePinSubtitle;

  /// No description provided for @appLockPinUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'PIN updated successfully.'**
  String get appLockPinUpdatedSnack;

  /// No description provided for @appLockSetSecurePinAction.
  ///
  /// In en, this message translates to:
  /// **'Set Secure PIN'**
  String get appLockSetSecurePinAction;

  /// No description provided for @appLockSavePinAction.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get appLockSavePinAction;

  /// No description provided for @appLockCannotEnableFallback.
  ///
  /// In en, this message translates to:
  /// **'Cannot enable.'**
  String get appLockCannotEnableFallback;

  /// No description provided for @appLockLockImmediatelySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock immediately on backgrounding'**
  String get appLockLockImmediatelySubtitle;

  /// No description provided for @appLockMinutesAfterBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes after backgrounding'**
  String appLockMinutesAfterBackgroundSubtitle(int count);

  /// No description provided for @appLockRequiresPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires App Lock PIN to be enabled'**
  String get appLockRequiresPinSubtitle;

  /// No description provided for @appLockFootnote.
  ///
  /// In en, this message translates to:
  /// **'Your PIN and biometric metrics are secure. Keys are strictly kept inside the hardware OS-backed Keystore / Keychain. Uninstalling or wiping application storage resets lock settings.'**
  String get appLockFootnote;

  /// No description provided for @appLockAutoLockSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the inactivity grace period before the app locks'**
  String get appLockAutoLockSheetSubtitle;

  /// No description provided for @appLockHeaderEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'App Protection Enabled'**
  String get appLockHeaderEnabledTitle;

  /// No description provided for @appLockHeaderDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'App Protection Disabled'**
  String get appLockHeaderDisabledTitle;

  /// No description provided for @appLockHeaderEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your device settings mandate a security checkpoint upon resume.'**
  String get appLockHeaderEnabledSubtitle;

  /// No description provided for @appLockHeaderDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure a security PIN below to safeguard your ERP environment data.'**
  String get appLockHeaderDisabledSubtitle;

  /// No description provided for @appLockOptionImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get appLockOptionImmediately;

  /// No description provided for @appLockOptionMinute.
  ///
  /// In en, this message translates to:
  /// **'{count} minute'**
  String appLockOptionMinute(int count);

  /// No description provided for @appLockOptionMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String appLockOptionMinutes(int count);

  /// No description provided for @appLockOptionImmediatelySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the app the instant it goes to background'**
  String get appLockOptionImmediatelySubtitle;

  /// No description provided for @appLockOptionMinuteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the app after {count} minute in background'**
  String appLockOptionMinuteSubtitle(int count);

  /// No description provided for @appLockOptionMinutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the app after {count} minutes in background'**
  String appLockOptionMinutesSubtitle(int count);

  /// No description provided for @appLockPinFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN (4–8 digits)'**
  String get appLockPinFieldLabel;

  /// No description provided for @appLockConfirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get appLockConfirmPinLabel;

  /// No description provided for @apiConfigPageTitle.
  ///
  /// In en, this message translates to:
  /// **'API Configuration'**
  String get apiConfigPageTitle;

  /// No description provided for @apiConfigClustersHeading.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE ENVIRONMENT CLUSTERS'**
  String get apiConfigClustersHeading;

  /// No description provided for @apiConfigSwitchedSnack.
  ///
  /// In en, this message translates to:
  /// **'Switched environment cluster to \"{name}\".'**
  String apiConfigSwitchedSnack(String name);

  /// No description provided for @apiConfigAddClusterAction.
  ///
  /// In en, this message translates to:
  /// **'Add Cluster'**
  String get apiConfigAddClusterAction;

  /// No description provided for @apiConfigAddCustomClusterTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Cluster'**
  String get apiConfigAddCustomClusterTitle;

  /// No description provided for @apiConfigBuiltInBadge.
  ///
  /// In en, this message translates to:
  /// **'BUILT-IN'**
  String get apiConfigBuiltInBadge;

  /// No description provided for @apiConfigDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Deleted environment cluster \"{name}\".'**
  String apiConfigDeletedSnack(String name);

  /// No description provided for @apiConfigClusterNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Cluster Name'**
  String get apiConfigClusterNameLabel;

  /// No description provided for @apiConfigClusterNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Asia Pacific Staging'**
  String get apiConfigClusterNameHint;

  /// No description provided for @apiConfigBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get apiConfigBaseUrlLabel;

  /// No description provided for @apiConfigBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://api-apac.tenant.example.com'**
  String get apiConfigBaseUrlHint;

  /// No description provided for @apiConfigBannerWarning.
  ///
  /// In en, this message translates to:
  /// **'Switching environment clusters signs you out of the current tenant session to prevent cross-contamination of credentials.'**
  String get apiConfigBannerWarning;

  /// No description provided for @apiConfigCannotDeleteFallback.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete.'**
  String get apiConfigCannotDeleteFallback;

  /// No description provided for @roleEditorPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get roleEditorPageTitle;

  /// No description provided for @roleEditorNewRoleAction.
  ///
  /// In en, this message translates to:
  /// **'New Role'**
  String get roleEditorNewRoleAction;

  /// No description provided for @roleEditorCreateCustomRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Role'**
  String get roleEditorCreateCustomRoleTitle;

  /// No description provided for @roleEditorRoleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Name (e.g. Finance Admin)'**
  String get roleEditorRoleNameLabel;

  /// No description provided for @roleEditorDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get roleEditorDescriptionLabel;

  /// No description provided for @roleEditorAssignScopesHeading.
  ///
  /// In en, this message translates to:
  /// **'Assign Permission Scopes'**
  String get roleEditorAssignScopesHeading;

  /// No description provided for @roleEditorCreateRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get roleEditorCreateRoleAction;

  /// No description provided for @roleEditorSystemBadge.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get roleEditorSystemBadge;

  /// No description provided for @roleEditorPermissionScopesHeading.
  ///
  /// In en, this message translates to:
  /// **'PERMISSION SCOPES'**
  String get roleEditorPermissionScopesHeading;

  /// No description provided for @roleEditorDeleteRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Role'**
  String get roleEditorDeleteRoleAction;

  /// No description provided for @roleEditorUpdateFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Cannot update permissions: {error}'**
  String roleEditorUpdateFailedSnack(String error);

  /// No description provided for @roleEditorDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String roleEditorDeleteConfirmTitle(String name);

  /// No description provided for @roleEditorDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone and will strip permissions from all assigned users.'**
  String get roleEditorDeleteConfirmMessage;

  /// No description provided for @roleEditorCannotDeleteFallback.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete.'**
  String get roleEditorCannotDeleteFallback;

  /// No description provided for @roleEditorDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get roleEditorDeleteAction;

  /// No description provided for @userMgmtPageTitle.
  ///
  /// In en, this message translates to:
  /// **'User Managements'**
  String get userMgmtPageTitle;

  /// No description provided for @userMgmtEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users match the selected status.'**
  String get userMgmtEmpty;

  /// No description provided for @userMgmtInviteUserAction.
  ///
  /// In en, this message translates to:
  /// **'Invite User'**
  String get userMgmtInviteUserAction;

  /// No description provided for @userMgmtInviteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a new user'**
  String get userMgmtInviteSheetTitle;

  /// No description provided for @userMgmtAssignRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign Roles'**
  String get userMgmtAssignRolesLabel;

  /// No description provided for @userMgmtInvitedSnack.
  ///
  /// In en, this message translates to:
  /// **'Invited {email}'**
  String userMgmtInvitedSnack(String email);

  /// No description provided for @userMgmtSendInvitationAction.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get userMgmtSendInvitationAction;

  /// No description provided for @userMgmtYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get userMgmtYouBadge;

  /// No description provided for @userMgmtActivateUserAction.
  ///
  /// In en, this message translates to:
  /// **'Activate User'**
  String get userMgmtActivateUserAction;

  /// No description provided for @userMgmtSuspendUserAction.
  ///
  /// In en, this message translates to:
  /// **'Suspend User'**
  String get userMgmtSuspendUserAction;

  /// No description provided for @userMgmtStatusSetSnack.
  ///
  /// In en, this message translates to:
  /// **'Status set to {status}.'**
  String userMgmtStatusSetSnack(String status);

  /// No description provided for @userMgmtFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get userMgmtFilterAll;

  /// No description provided for @userMgmtFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userMgmtFilterActive;

  /// No description provided for @userMgmtFilterInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get userMgmtFilterInvited;

  /// No description provided for @userMgmtFilterSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get userMgmtFilterSuspended;

  /// No description provided for @userMgmtNewUserPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get userMgmtNewUserPlaceholder;

  /// No description provided for @userMgmtEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get userMgmtEmailAddressLabel;

  /// No description provided for @userMgmtFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get userMgmtFullNameLabel;

  /// No description provided for @userMgmtCannotApplyFallback.
  ///
  /// In en, this message translates to:
  /// **'Cannot apply.'**
  String get userMgmtCannotApplyFallback;

  /// No description provided for @userMgmtStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get userMgmtStatusActive;

  /// No description provided for @userMgmtStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'INVITED'**
  String get userMgmtStatusInvited;

  /// No description provided for @userMgmtStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'SUSPENDED'**
  String get userMgmtStatusSuspended;

  /// No description provided for @myRolesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'My Roles & Permissions'**
  String get myRolesPageTitle;

  /// No description provided for @myRolesGrantedTitle.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get myRolesGrantedTitle;

  /// No description provided for @myRolesNotGrantedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Granted'**
  String get myRolesNotGrantedTitle;

  /// No description provided for @myRolesAssignedRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'Your assigned roles'**
  String get myRolesAssignedRolesLabel;

  /// No description provided for @myRolesSyncedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Synced {timestamp}'**
  String myRolesSyncedAtLabel(String timestamp);

  /// No description provided for @myRolesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search permissions…'**
  String get myRolesSearchHint;

  /// No description provided for @myProfilePageTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfilePageTitle;

  /// No description provided for @myProfileUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get myProfileUpdatedSnack;

  /// No description provided for @myProfileEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get myProfileEditAction;

  /// No description provided for @myProfileContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get myProfileContactSection;

  /// No description provided for @myProfilePersonalSection.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get myProfilePersonalSection;

  /// No description provided for @myProfileAccountSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get myProfileAccountSecuritySection;

  /// No description provided for @myProfilePhotoLocalSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photo only changes on this device.'**
  String get myProfilePhotoLocalSheetSubtitle;

  /// No description provided for @myProfileImageReadErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected image.'**
  String get myProfileImageReadErrorSnack;

  /// No description provided for @myProfileImagePickErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image: {error}'**
  String myProfileImagePickErrorSnack(String error);

  /// No description provided for @myProfileEmployeeRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get myProfileEmployeeRowLabel;

  /// No description provided for @myProfileTenureRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get myProfileTenureRowLabel;

  /// No description provided for @myProfileLastLoginRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get myProfileLastLoginRowLabel;

  /// No description provided for @myProfileEmployeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get myProfileEmployeeIdLabel;

  /// No description provided for @myProfileHireDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hire date'**
  String get myProfileHireDateLabel;

  /// No description provided for @myProfileBirthdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get myProfileBirthdateLabel;

  /// No description provided for @myProfileAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get myProfileAddressLabel;

  /// No description provided for @myProfileEmergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get myProfileEmergencyContactLabel;

  /// No description provided for @myProfileEmergencyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency phone'**
  String get myProfileEmergencyPhoneLabel;

  /// No description provided for @myProfileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get myProfileFullNameLabel;

  /// No description provided for @myProfileSaveChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get myProfileSaveChangesAction;

  /// No description provided for @myProfileChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get myProfileChangePasswordTitle;

  /// No description provided for @myProfileChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires current password'**
  String get myProfileChangePasswordSubtitle;

  /// No description provided for @myProfileChangePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get myProfileChangePinTitle;

  /// No description provided for @myProfileChangePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set or replace your unlock PIN'**
  String get myProfileChangePinSubtitle;

  /// No description provided for @myProfileEnableBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric'**
  String get myProfileEnableBiometricTitle;

  /// No description provided for @myProfileLastLoginAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Last login: {date}'**
  String myProfileLastLoginAtLabel(String date);

  /// No description provided for @myProfileReAuthBadge.
  ///
  /// In en, this message translates to:
  /// **'RE-AUTH'**
  String get myProfileReAuthBadge;

  /// No description provided for @myProfileBiometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get myProfileBiometricUnlockTitle;

  /// No description provided for @myProfileConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get myProfileConfirmAction;

  /// No description provided for @myProfileSaveErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes: {error}'**
  String myProfileSaveErrorSnack(String error);

  /// No description provided for @myProfileChangePhotoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get myProfileChangePhotoSheetTitle;

  /// No description provided for @myProfileAddPhotoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo'**
  String get myProfileAddPhotoSheetTitle;

  /// No description provided for @myProfileEmailRequiresVerificationHelper.
  ///
  /// In en, this message translates to:
  /// **'Requires verification on the new address'**
  String get myProfileEmailRequiresVerificationHelper;

  /// No description provided for @myProfilePhoneRequiresVerificationHelper.
  ///
  /// In en, this message translates to:
  /// **'Requires SMS verification on the new number'**
  String get myProfilePhoneRequiresVerificationHelper;

  /// No description provided for @myProfileManagedByHrBadge.
  ///
  /// In en, this message translates to:
  /// **'Managed by HR'**
  String get myProfileManagedByHrBadge;

  /// No description provided for @myProfileChangePasswordReAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your current password to confirm this change.'**
  String get myProfileChangePasswordReAuthMessage;

  /// No description provided for @myProfileChangePinReAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Re-authenticate before changing your PIN.'**
  String get myProfileChangePinReAuthMessage;

  /// No description provided for @myProfileEnableBiometricReAuthMessage.
  ///
  /// In en, this message translates to:
  /// **'Re-authenticate to bind your device biometric to this app.'**
  String get myProfileEnableBiometricReAuthMessage;

  /// No description provided for @myProfileCannotToggleBiometricFallback.
  ///
  /// In en, this message translates to:
  /// **'Cannot toggle biometric'**
  String get myProfileCannotToggleBiometricFallback;

  /// No description provided for @myProfilePasswordChangeStubSnack.
  ///
  /// In en, this message translates to:
  /// **'Password change flow would open here.'**
  String get myProfilePasswordChangeStubSnack;

  /// No description provided for @myProfileCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get myProfileCurrentPasswordLabel;

  /// No description provided for @myProfileBiometricEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to disable — re-auth not required'**
  String get myProfileBiometricEnabledSubtitle;

  /// No description provided for @myProfileBiometricDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-auth required to enable'**
  String get myProfileBiometricDisabledSubtitle;

  /// No description provided for @myProfileNameFieldHumanLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get myProfileNameFieldHumanLabel;

  /// No description provided for @myProfileEmailFieldHumanLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get myProfileEmailFieldHumanLabel;

  /// No description provided for @myProfilePhoneFieldHumanLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get myProfilePhoneFieldHumanLabel;

  /// No description provided for @myProfileRelativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get myProfileRelativeToday;

  /// No description provided for @myProfileRelativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get myProfileRelativeYesterday;

  /// No description provided for @myProfileRelativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String myProfileRelativeDaysAgo(int count);

  /// No description provided for @myProfileRelativeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String myProfileRelativeWeeksAgo(int count);

  /// No description provided for @myProfileRelativeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String myProfileRelativeMonthsAgo(int count);

  /// No description provided for @myProfileRelativeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String myProfileRelativeYearsAgo(int count);

  /// No description provided for @myProfileTenureLessThanMonth.
  ///
  /// In en, this message translates to:
  /// **'<1 mo'**
  String get myProfileTenureLessThanMonth;

  /// No description provided for @myProfileTenureMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} mo'**
  String myProfileTenureMonths(int count);

  /// No description provided for @myProfileTenureYear.
  ///
  /// In en, this message translates to:
  /// **'{count} yr'**
  String myProfileTenureYear(int count);

  /// No description provided for @myProfileTenureYears.
  ///
  /// In en, this message translates to:
  /// **'{count} yrs'**
  String myProfileTenureYears(int count);

  /// No description provided for @myProfileTenureYearsMonths.
  ///
  /// In en, this message translates to:
  /// **'{years}y {months}m'**
  String myProfileTenureYearsMonths(int years, int months);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
