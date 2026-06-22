// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'ERP Mobile';

  @override
  String get loginAppBarTitle => 'ចូលគណនី';

  @override
  String get loginButton => 'ចូល (សាកល្បង)';

  @override
  String get dashboardTitle => 'ផ្ទាំងគ្រប់គ្រង';

  @override
  String get dashboardPlaceholder =>
      'ផ្ទាំងគ្រប់គ្រងសាកល្បង — Module 2 នឹងបំពេញ។';

  @override
  String get signOutTooltip => 'ចាកចេញ';

  @override
  String get notFoundTitle => 'រកមិនឃើញ';

  @override
  String notFoundBody(String location) {
    return 'មិនមានផ្លូវសម្រាប់ \"$location\"';
  }

  @override
  String get goHome => 'ទៅទំព័រដើម';

  @override
  String get loginOtpDemoLink => '[demo] សាកល្បងលេខកូដ MFA';

  @override
  String get otpPageTitle => 'ផ្ទៀងផ្ទាត់';

  @override
  String get otpSubtitle => 'បញ្ចូលលេខកូដ ៦ ខ្ទង់ពីកម្មវិធីផ្ទៀងផ្ទាត់ឬ SMS។';

  @override
  String otpDevHint(String code) {
    return 'សាកល្បង៖ បញ្ចូល $code ដើម្បីបន្ត';
  }

  @override
  String get otpVerifyButton => 'ផ្ទៀងផ្ទាត់';

  @override
  String get otpErrorIncorrect => 'លេខកូដខុស។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get otpErrorExpired => 'លេខកូដនេះបានផុតកំណត់។ សូមស្នើសុំលេខកូដថ្មី។';

  @override
  String get otpErrorTooManyAttempts =>
      'ការព្យាយាមច្រើនពេក។ សូមព្យាយាមនៅពេលក្រោយ។';

  @override
  String get otpErrorNetwork =>
      'មិនអាចទាក់ទងម៉ាស៊ីនមេបាន។ ពិនិត្យការតភ្ជាប់របស់អ្នក។';

  @override
  String get forbiddenTitle => 'គ្មានសិទ្ធិចូល';

  @override
  String forbiddenBody(String location) {
    return 'អ្នកមិនមានសិទ្ធិចូល \"$location\" ទេ។';
  }

  @override
  String get adminDemoTitle => 'ទំព័រសាកល្បងអ្នកគ្រប់គ្រង';

  @override
  String get adminDemoBody =>
      'អ្នកបានចូលដល់ផ្លូវសាកល្បងសម្រាប់អ្នកគ្រប់គ្រង — RBAC ដំណើរការ។';

  @override
  String get dashboardAdminDemoLink => '[demo] បើកទំព័រអ្នកគ្រប់គ្រង';

  @override
  String get permissionGuardDemoGranted => '[demo] អនុញ្ញាតជាអ្នកគ្រប់គ្រង';

  @override
  String get permissionGuardDemoDenied => '[demo] មិនអនុញ្ញាតជាអ្នកគ្រប់គ្រង';

  @override
  String get shellHome => 'ដើម';

  @override
  String get shellModules => 'ម៉ូឌុល';

  @override
  String get shellSettings => 'ការកំណត់';

  @override
  String get modulesTitle => 'ម៉ូឌុល';

  @override
  String get modulesPlaceholder => 'ប៊ូតុងម៉ូឌុលនឹងបង្ហាញនៅ Slice 2.1.2។';

  @override
  String get modulesEmpty =>
      'មិនមានម៉ូឌុលណាសម្រាប់តួនាទីរបស់អ្នកនៅឡើយទេ។ សូមស្នើសុំសិទ្ធិពីអ្នកគ្រប់គ្រង។';

  @override
  String get shortcutAdminDemo => 'ទំព័រសាកល្បងអ្នកគ្រប់គ្រង';

  @override
  String get shortcutFinance => 'ហិរញ្ញវត្ថុ';

  @override
  String get shortcutProcurement => 'ការទិញ';

  @override
  String get shortcutInventory => 'ឃ្លាំង';

  @override
  String get shortcutSales => 'លក់';

  @override
  String get shortcutHr => 'ធនធានមនុស្ស';

  @override
  String get shortcutProjects => 'គម្រោង';

  @override
  String comingSoonBody(String module) {
    return '$module នឹងមកដល់នៅការចេញផ្សាយក្រោយ។';
  }

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get settingsPlaceholder => 'ការកំណត់ពិតប្រាកដនឹងមកដល់នៅ Module 9។';

  @override
  String get globalSearchTooltip => 'ស្វែងរក';

  @override
  String get globalSearchHint => 'ស្វែងរកម៉ូឌុល កំណត់ត្រា មនុស្ស…';

  @override
  String get globalSearchPrompt =>
      'វាយពាក្យ ដើម្បីស្វែងរកគ្រប់ម៉ូឌុលដែលអ្នកអាចចូលបាន។';

  @override
  String globalSearchNoResults(String query) {
    return 'មិនមានលទ្ធផលសម្រាប់ \"$query\" ទេ។';
  }

  @override
  String globalSearchError(String message) {
    return 'ការស្វែងរកបានបរាជ័យ៖ $message';
  }

  @override
  String get kpiTrendUp => 'កើនឡើង';

  @override
  String get kpiTrendDown => 'ធ្លាក់ចុះ';

  @override
  String get kpiTrendFlat => 'ស្ថេរ';

  @override
  String get kpiTrendUpTooltip => 'កើនឡើងធៀបរយៈពេលមុន';

  @override
  String get kpiTrendDownTooltip => 'ធ្លាក់ចុះធៀបរយៈពេលមុន';

  @override
  String get kpiTrendFlatTooltip =>
      'មិនមានការផ្លាស់ប្ដូរច្បាស់លាស់ធៀបរយៈពេលមុន';

  @override
  String get chartRevenueTrendTitle => 'និន្នាការចំណូល';

  @override
  String get chartSalesByRegionTitle => 'ការលក់តាមតំបន់';

  @override
  String get chartSeriesRevenue => 'ចំណូល';

  @override
  String get chartSeriesTarget => 'គោលដៅ';

  @override
  String get chartSeriesSales => 'ការលក់';

  @override
  String get realtimeStatusLive => 'ផ្សាយផ្ទាល់';

  @override
  String get realtimeStatusConnecting => 'កំពុងតភ្ជាប់';

  @override
  String get realtimeStatusReconnecting => 'កំពុងតភ្ជាប់ឡើងវិញ';

  @override
  String get realtimeStatusOffline => 'ផ្ដាច់';

  @override
  String get pushDemoButton => '[dev] សាកល្បងផ្ញើជូនដំណឹង';

  @override
  String pushDemoTitle(int count) {
    return 'ការជូនដំណឹងសាកល្បង #$count';
  }

  @override
  String get pushDemoBody => 'បានបញ្ជូនតាម PushMessageRouter ទៅប្រអប់សារ។';

  @override
  String get pushDemoSnack => 'បានផ្ញើទៅប្រអប់សារ។';

  @override
  String get notificationsBadgeTooltip => 'ការជូនដំណឹង';

  @override
  String get notificationInboxTitle => 'ការជូនដំណឹង';

  @override
  String get notificationInboxEmpty =>
      'អ្នកបានពិនិត្យអស់ហើយ។ ការជូនដំណឹងថ្មីនឹងបង្ហាញនៅទីនេះ។';

  @override
  String notificationInboxError(String message) {
    return 'មិនអាចផ្ទុកការជូនដំណឹង៖ $message';
  }

  @override
  String get notificationInboxMarkAllRead => 'សម្គាល់ថាបានអានទាំងអស់';

  @override
  String get notificationInboxDismissedSnack => 'បានលុបការជូនដំណឹង។';

  @override
  String notificationDeepLinkError(String message) {
    return 'មិនអាចបើកការជូនដំណឹងនេះ៖ $message';
  }

  @override
  String get notificationDeepLinkViewAction => 'មើល';

  @override
  String get pushDemoRoutedButton => '[dev] សាកល្បងផ្ញើដែលមានតំណ';

  @override
  String get pushDemoRoutedBody =>
      'ចុចលើការជូនដំណឹងនេះ ឬប៊ូតុងមើលនៅ Snackbar ដើម្បីបើកគោលដៅ។';

  @override
  String get chartOfAccountsTitle => 'តារាងគណនី';

  @override
  String get chartOfAccountsEmpty => 'មិនទាន់មានគណនីត្រូវបានផ្ទុក។';

  @override
  String chartOfAccountsError(String message) {
    return 'មិនអាចផ្ទុកតារាងគណនី៖ $message';
  }

  @override
  String get chartOfAccountsExpandAll => 'ពង្រីកទាំងអស់';

  @override
  String get chartOfAccountsCollapseAll => 'បង្រួមទាំងអស់';

  @override
  String get dashboardChartOfAccountsLink => '[demo] បើកតារាងគណនី';

  @override
  String get accountTypeAsset => 'ទ្រព្យសកម្ម';

  @override
  String get accountTypeLiability => 'បំណុល';

  @override
  String get accountTypeEquity => 'មូលធន';

  @override
  String get accountTypeRevenue => 'ចំណូល';

  @override
  String get accountTypeExpense => 'ចំណាយ';

  @override
  String get accountDetailTitle => 'គណនី';

  @override
  String get accountDetailNoTransactions =>
      'មិនទាន់មានប្រតិបត្តិការត្រូវបានបញ្ជូលនៅក្នុងគណនីនេះទេ។';

  @override
  String accountDetailNotFound(String accountId) {
    return 'យើងរកមិនឃើញគណនីដែលមានលេខសម្គាល់ \"$accountId\" ទេ។';
  }

  @override
  String accountDetailError(String message) {
    return 'មិនអាចផ្ទុកគណនីនេះ៖ $message';
  }

  @override
  String get invoiceListTitle => 'វិក្កយបត្រ';

  @override
  String get invoiceListSearchHint => 'ស្វែងរកតាមលេខ ឬឈ្មោះអតិថិជន';

  @override
  String get invoiceListSortTooltip => 'តម្រៀប';

  @override
  String get invoiceListEmpty => 'មិនមានវិក្កយបត្រត្រូវនឹងតម្រងរបស់អ្នកទេ។';

  @override
  String invoiceListError(String message) {
    return 'មិនអាចផ្ទុកវិក្កយបត្រ៖ $message';
  }

  @override
  String invoiceListDueLabel(String date) {
    return 'ដល់កំណត់ $date';
  }

  @override
  String get invoiceStatusDraft => 'ព្រាង';

  @override
  String get invoiceStatusPendingApproval => 'កំពុងរង់ចាំការអនុម័ត';

  @override
  String get invoiceStatusApproved => 'បានអនុម័ត';

  @override
  String get invoiceStatusRejected => 'បានបដិសេធ';

  @override
  String get invoiceSortIssuedDesc => 'ចេញ (ថ្មីបំផុត)';

  @override
  String get invoiceSortIssuedAsc => 'ចេញ (ចាស់បំផុត)';

  @override
  String get invoiceSortDueAsc => 'ដល់កំណត់ (ឆាប់បំផុត)';

  @override
  String get invoiceSortAmountDesc => 'ចំនួន (ច្រើនបំផុត)';

  @override
  String get invoiceSortNumberAsc => 'លេខវិក្កយបត្រ';

  @override
  String get invoiceDetailTitle => 'វិក្កយបត្រ';

  @override
  String get invoiceDetailIssuedLabel => 'ចេញ';

  @override
  String get invoiceDetailDueLabel => 'ដល់កំណត់';

  @override
  String get invoiceDetailLinesHeading => 'បន្ទាត់សារពើ';

  @override
  String get invoiceDetailSubtotalLabel => 'សរុបរង';

  @override
  String get invoiceDetailTaxLabel => 'ពន្ធ';

  @override
  String get invoiceDetailTotalLabel => 'សរុប';

  @override
  String get invoiceDetailNotesHeading => 'កំណត់ចំណាំ';

  @override
  String get invoiceDetailPdfHeading => 'បង្ហាញ PDF';

  @override
  String get invoiceDetailPdfPlaceholder =>
      'ការបង្ហាញ PDF នឹងមកដល់ជាមួយម៉ាស៊ីនមេ។';

  @override
  String invoiceDetailNotFound(String invoiceId) {
    return 'យើងរកមិនឃើញវិក្កយបត្រដែលមានលេខសម្គាល់ \"$invoiceId\" ទេ។';
  }

  @override
  String invoiceDetailError(String message) {
    return 'មិនអាចផ្ទុកវិក្កយបត្រនេះ៖ $message';
  }

  @override
  String get invoiceApproveAction => 'អនុម័ត';

  @override
  String get invoiceRejectAction => 'បដិសេធ';

  @override
  String get invoiceSubmitAction => 'ដាក់ស្នើដើម្បីអនុម័ត';

  @override
  String get invoiceReopenAction => 'បើកដើម្បីកែសម្រួល';

  @override
  String get invoiceActionCancel => 'បោះបង់';

  @override
  String get invoiceApproveSheetTitle => 'អនុម័តវិក្កយបត្រនេះ?';

  @override
  String invoiceApproveSheetBody(String invoiceNumber) {
    return 'អ្នកនឹងអនុម័ត $invoiceNumber។ វិក្កយបត្រនឹងត្រូវចាក់សោបន្ទាប់ពីការអនុម័ត។';
  }

  @override
  String get invoiceRejectSheetTitle => 'បដិសេធវិក្កយបត្រនេះ?';

  @override
  String invoiceRejectSheetBody(String invoiceNumber) {
    return '$invoiceNumber នឹងត្រូវបញ្ជូនត្រឡប់ទៅអ្នកស្នើជាមួយមូលហេតុខាងក្រោម។';
  }

  @override
  String get invoiceRejectReasonLabel => 'មូលហេតុ';

  @override
  String get invoiceRejectReasonHint => 'ហេតុអ្វីបានជាបដិសេធវិក្កយបត្រនេះ?';

  @override
  String get invoiceRejectReasonRequired => 'សូមបញ្ចូលមូលហេតុ។';

  @override
  String invoiceActionSuccess(String status) {
    return 'បានសម្គាល់វិក្កយបត្រជា $status។';
  }

  @override
  String get invoiceActionForbidden =>
      'អ្នកមិនមានសិទ្ធិធ្វើសកម្មភាពលើវិក្កយបត្រនេះទេ។';

  @override
  String get invoiceActionNotFound => 'វិក្កយបត្រនេះមិនមានទៀតទេ។';

  @override
  String get invoiceActionInvalidState =>
      'វិក្កយបត្រនេះត្រូវបានធ្វើសកម្មភាពរួចហើយ។';

  @override
  String get invoiceActionUnauthorized =>
      'ការចូលរបស់អ្នកបានផុតកំណត់ — សូមចូលម្ដងទៀត។';

  @override
  String invoiceActionGenericError(String message) {
    return 'មិនអាចធ្វើសកម្មភាពលើវិក្កយបត្រ៖ $message';
  }

  @override
  String get invoiceAuditApprovedHeading => 'បានអនុម័ត';

  @override
  String get invoiceAuditRejectedHeading => 'បានបដិសេធ';

  @override
  String invoiceAuditActorLine(String userId) {
    return 'ដោយ $userId';
  }

  @override
  String invoiceAuditWhenLine(String when) {
    return 'នៅ $when';
  }

  @override
  String invoiceAuditReasonLine(String reason) {
    return 'មូលហេតុ៖ $reason';
  }

  @override
  String get invoiceFormCreateTitle => 'វិក្កយបត្រថ្មី';

  @override
  String get invoiceFormEditTitle => 'កែវិក្កយបត្រ';

  @override
  String get invoiceFormSaveTooltip => 'រក្សាទុក';

  @override
  String get invoiceFormSaveAction => 'រក្សាទុកវិក្កយបត្រ';

  @override
  String get invoiceFormSavedSnack => 'បានរក្សាទុកវិក្កយបត្រ។';

  @override
  String get invoiceFormCustomerLabel => 'អតិថិជន';

  @override
  String get invoiceFormIssuedLabel => 'កាលបរិច្ឆេទចេញ';

  @override
  String get invoiceFormDueLabel => 'កាលបរិច្ឆេទដល់កំណត់';

  @override
  String get invoiceFormLineHeading => 'បន្ទាត់សារពើ';

  @override
  String get invoiceFormLineDescriptionLabel => 'ពិពណ៌នា';

  @override
  String get invoiceFormLineQuantityLabel => 'បរិមាណ';

  @override
  String get invoiceFormLineUnitPriceLabel => 'តម្លៃឯកតា';

  @override
  String get validatorRequired => 'ត្រូវការ';

  @override
  String get validatorInvalidNumber => 'ត្រូវតែជាលេខ';

  @override
  String get validatorMustBePositive => 'ត្រូវតែធំជាង 0';

  @override
  String get validatorMustBeNonNegative => 'មិនអាចជាលេខអវិជ្ជមានទេ';

  @override
  String get validatorDueBeforeIssued =>
      'កាលបរិច្ឆេទដល់កំណត់ត្រូវតែស្មើ ឬក្រោយកាលបរិច្ឆេទចេញ';

  @override
  String get journalEntriesTitle => 'ធាតុសៀវភៅ';

  @override
  String get journalEntriesEmpty => 'មិនមានធាតុសៀវភៅក្នុងរយៈពេលនេះទេ។';

  @override
  String get journalEntryDetailTitle => 'ធាតុសៀវភៅ';

  @override
  String journalEntryNotFound(String id) {
    return 'មិនមានធាតុសៀវភៅ \"$id\" ទេ។';
  }

  @override
  String get journalEntryAccountColumn => 'គណនី';

  @override
  String get journalEntryDebitColumn => 'ឥណពន្ធ';

  @override
  String get journalEntryCreditColumn => 'ឥណទាន';

  @override
  String get journalEntryTotalLabel => 'សរុប';

  @override
  String get trialBalanceTitle => 'តារាងតុល្យភាពសាកល្បង';

  @override
  String get trialBalanceEmpty => 'មិនទាន់មានគណនីដែលមានសមតុល្យមិនសូន្យទេ។';

  @override
  String get trialBalanceColumnCode => 'លេខ';

  @override
  String get trialBalanceColumnName => 'គណនី';

  @override
  String get trialBalanceColumnDebit => 'ឥណពន្ធ';

  @override
  String get trialBalanceColumnCredit => 'ឥណទាន';

  @override
  String trialBalancePageOf(int current, int total) {
    return 'ទំព័រ $current នៃ $total';
  }

  @override
  String get trialBalanceExportCsvTooltip => 'នាំចេញ CSV';

  @override
  String trialBalanceExportSuccess(String path) {
    return 'បានរក្សាទុក CSV នៅ $path';
  }

  @override
  String trialBalanceExportError(String message) {
    return 'ការនាំចេញ CSV បានបរាជ័យ៖ $message';
  }

  @override
  String get validatorInvalidEmail => 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ';

  @override
  String get prListTitle => 'សំណើទិញ';

  @override
  String get prListNewTooltip => 'សំណើថ្មី';

  @override
  String get prListSearchHint => 'ស្វែងរកតាមលេខ អ្នកស្នើ ឬមជ្ឈមណ្ឌលថ្លៃ';

  @override
  String get prListSortTooltip => 'តម្រៀប';

  @override
  String get prListEmpty => 'គ្មានសំណើទិញដែលត្រូវនឹងតម្រងរបស់អ្នកទេ។';

  @override
  String prListError(String message) {
    return 'មិនអាចផ្ទុកសំណើទិញ៖ $message';
  }

  @override
  String get prStatusDraft => 'ព្រាង';

  @override
  String get prStatusSubmitted => 'បានដាក់ស្នើ';

  @override
  String get prStatusApproved => 'បានអនុម័ត';

  @override
  String get prStatusRejected => 'បានបដិសេធ';

  @override
  String get prStatusConverted => 'បានបម្លែង';

  @override
  String get prSortCreatedDesc => 'បង្កើត (ថ្មីបំផុត)';

  @override
  String get prSortCreatedAsc => 'បង្កើត (ចាស់បំផុត)';

  @override
  String get prSortTotalDesc => 'សរុប (ច្រើនបំផុត)';

  @override
  String get prSortNumberAsc => 'លេខសំណើ';

  @override
  String get prFormCreateTitle => 'សំណើទិញថ្មី';

  @override
  String get prFormSaveTooltip => 'ដាក់ស្នើ';

  @override
  String get prFormSubmitAction => 'ដាក់ស្នើសំណើ';

  @override
  String get prFormSavedSnack => 'បានដាក់ស្នើសំណើទិញ។';

  @override
  String prFormSaveFailed(String message) {
    return 'មិនអាចដាក់ស្នើសំណើ៖ $message';
  }

  @override
  String get prFormRequesterLabel => 'អ្នកស្នើ';

  @override
  String get prFormCostCenterLabel => 'មជ្ឈមណ្ឌលថ្លៃ';

  @override
  String get prFormApproverLabel => 'អ្នកអនុម័ត';

  @override
  String get prFormJustificationLabel => 'ការបង្ហាញហេតុផល (ស្រេចចិត្ត)';

  @override
  String get prFormLinesHeading => 'បន្ទាត់ទំនិញ';

  @override
  String prFormLineHeading(int index) {
    return 'បន្ទាត់ $index';
  }

  @override
  String get prFormAddLineAction => 'បន្ថែមបន្ទាត់';

  @override
  String get prFormRemoveLineTooltip => 'លុបបន្ទាត់';

  @override
  String get prFormLineDescriptionLabel => 'ការពិពណ៌នា';

  @override
  String get prFormLineQuantityLabel => 'ចំនួន';

  @override
  String get prFormLineUnitPriceLabel => 'ថ្លៃឯកតា';

  @override
  String get prDetailTitle => 'សំណើទិញ';

  @override
  String prDetailNotFound(String prId) {
    return 'យើងរកមិនឃើញសំណើទិញដែលមាន id \"$prId\" ទេ។';
  }

  @override
  String prDetailError(String message) {
    return 'មិនអាចផ្ទុកសំណើទិញនេះ៖ $message';
  }

  @override
  String get prDetailRequesterLabel => 'អ្នកស្នើ';

  @override
  String get prDetailCostCenterLabel => 'មជ្ឈមណ្ឌលថ្លៃ';

  @override
  String get prDetailApproverLabel => 'អ្នកអនុម័ត';

  @override
  String get prDetailCreatedLabel => 'បង្កើត';

  @override
  String get prDetailJustificationHeading => 'ការបង្ហាញហេតុផល';

  @override
  String get prDetailLinesHeading => 'បន្ទាត់ទំនិញ';

  @override
  String get prDetailTotalLabel => 'សរុប';

  @override
  String get prApproveAction => 'អនុម័ត';

  @override
  String get prRejectAction => 'បដិសេធ';

  @override
  String get prSubmitAction => 'ដាក់ស្នើ';

  @override
  String get prConvertAction => 'បម្លែងទៅ PO';

  @override
  String get prSubmittedSnack => 'បានដាក់ស្នើសំណើទិញ។';

  @override
  String prApprovedSnack(String status) {
    return 'បានសម្គាល់សំណើទិញជា $status។';
  }

  @override
  String get prRejectedSnack => 'បានបដិសេធសំណើទិញ។';

  @override
  String get prConvertedSnack => 'បានបង្កើតបញ្ជាទិញ។';

  @override
  String prApprovalNotAllowed(String action) {
    return 'មិនអាច$actionសំណើនេះពីស្ថានភាពបច្ចុប្បន្នបានទេ។';
  }

  @override
  String prApprovalFailed(String message) {
    return 'មិនអាចធ្វើបច្ចុប្បន្នភាពសំណើ៖ $message';
  }

  @override
  String get prRejectDialogTitle => 'បដិសេធសំណើ';

  @override
  String get prRejectReasonLabel => 'មូលហេតុ';

  @override
  String get prRejectReasonHint => 'ហេតុអ្វីបានជាបដិសេធសំណើនេះ?';

  @override
  String get prRejectReasonRequired => 'សូមបញ្ចូលមូលហេតុ។';

  @override
  String get prRejectCancel => 'បោះបង់';

  @override
  String get prRejectConfirm => 'បដិសេធសំណើ';

  @override
  String get prConvertDialogTitle => 'បម្លែងទៅបញ្ជាទិញ';

  @override
  String get prConvertVendorLabel => 'អ្នកផ្គត់ផ្គង់';

  @override
  String get prConvertExpectedLabel => 'កាលបរិច្ឆេទរំពឹងទុក';

  @override
  String get prConvertVendorRequired => 'សូមជ្រើសរើសអ្នកផ្គត់ផ្គង់។';

  @override
  String get prConvertConfirm => 'បង្កើត PO';

  @override
  String get prConvertCancel => 'បោះបង់';

  @override
  String get poListTitle => 'បញ្ជាទិញ';

  @override
  String get poListEmpty => 'មិនទាន់មានបញ្ជាទិញនៅឡើយទេ។';

  @override
  String poListExpectedLabel(String date) {
    return 'រំពឹងទុក $date';
  }

  @override
  String get poStatusOpen => 'បើក';

  @override
  String get poStatusPartial => 'មួយផ្នែក';

  @override
  String get poStatusFull => 'បានទទួល';

  @override
  String get poStatusClosed => 'បានបិទ';

  @override
  String get poStatusCancelled => 'បានលុបចោល';

  @override
  String get poDetailTitle => 'បញ្ជាទិញ';

  @override
  String poDetailNotFound(String poId) {
    return 'យើងរកមិនឃើញបញ្ជាទិញដែលមាន id \"$poId\" ទេ។';
  }

  @override
  String get poDetailCreatedLabel => 'បង្កើត';

  @override
  String get poDetailExpectedLabel => 'រំពឹងទុក';

  @override
  String get poDetailSourcePrLabel => 'PR ប្រភព';

  @override
  String get poDetailLinesHeading => 'បន្ទាត់ទំនិញ';

  @override
  String get poDetailTotalLabel => 'សរុប';

  @override
  String get poDetailReceiptsHeading => 'បង្កាន់ដៃទទួល';

  @override
  String get poDetailReceiptsEmpty => 'មិនទាន់មានបង្កាន់ដៃនៅឡើយទេ។';

  @override
  String poDetailReceiptItemsBadge(int count) {
    return '$count ធាតុ';
  }

  @override
  String get poDetailRecordReceiptAction => 'កត់ត្រាការទទួលទំនិញ';

  @override
  String poLineOrderedLabel(String qty) {
    return 'បានបញ្ជា $qty';
  }

  @override
  String poLineReceivedLabel(String qty) {
    return 'បានទទួល $qty';
  }

  @override
  String poLineOutstandingLabel(String qty) {
    return 'នៅសល់ $qty';
  }

  @override
  String get goodsReceiptFormTitle => 'ការទទួលទំនិញ';

  @override
  String goodsReceiptFormForPo(String number) {
    return 'កំពុងទទួលប្រឆាំងនឹង $number';
  }

  @override
  String get goodsReceiptReceivedByLabel => 'ទទួលដោយ';

  @override
  String get goodsReceiptNoteLabel => 'កំណត់ចំណាំ (ស្រេចចិត្ត)';

  @override
  String get goodsReceiptLinesHeading => 'ចំនួនបានទទួល';

  @override
  String get goodsReceiptQuantityLabel => 'ទទួលឥឡូវនេះ';

  @override
  String get goodsReceiptSubmitAction => 'កត់ត្រាបង្កាន់ដៃ';

  @override
  String get goodsReceiptSavedSnack => 'បានកត់ត្រាបង្កាន់ដៃទំនិញ។';

  @override
  String goodsReceiptSaveFailed(String message) {
    return 'មិនអាចកត់ត្រាបង្កាន់ដៃ៖ $message';
  }

  @override
  String get goodsReceiptErrorPoClosed =>
      'PO នេះត្រូវបានបិទ — មិនអាចទទួលទៀតបានទេ។';

  @override
  String get goodsReceiptErrorNoLines =>
      'សូមបញ្ចូលចំនួនយ៉ាងហោចណាស់សម្រាប់បន្ទាត់មួយ។';

  @override
  String get goodsReceiptErrorNonPositive => 'ចំនួនត្រូវតែធំជាង 0។';

  @override
  String get goodsReceiptErrorUnknownLine =>
      'បន្ទាត់មួយមិនជាកម្មសិទ្ធិរបស់ PO នេះទេ។';

  @override
  String get goodsReceiptErrorExceedsOutstanding =>
      'មិនអាចទទួលលើសពីចំនួននៅសល់បានទេ។';

  @override
  String get vendorListTitle => 'អ្នកផ្គត់ផ្គង់';

  @override
  String get vendorListEmpty => 'មិនទាន់មានអ្នកផ្គត់ផ្គង់នៅឡើយទេ។';

  @override
  String get vendorListNewTooltip => 'បន្ថែមអ្នកផ្គត់ផ្គង់';

  @override
  String get vendorStatusActive => 'សកម្ម';

  @override
  String get vendorStatusOnHold => 'ផ្អាក';

  @override
  String get vendorStatusArchived => 'បានទុក';

  @override
  String get vendorDetailTitle => 'អ្នកផ្គត់ផ្គង់';

  @override
  String vendorDetailNotFound(String vendorId) {
    return 'យើងរកមិនឃើញអ្នកផ្គត់ផ្គង់ដែលមាន id \"$vendorId\" ទេ។';
  }

  @override
  String get vendorDetailTaxIdLabel => 'លេខពន្ធ';

  @override
  String get vendorDetailOnboardedLabel => 'បានចុះបញ្ជី';

  @override
  String get vendorDetailContactHeading => 'ទំនាក់ទំនង';

  @override
  String get vendorDetailContactPersonLabel => 'បុគ្គលទំនាក់ទំនង';

  @override
  String get vendorDetailEmailLabel => 'អ៊ីមែល';

  @override
  String get vendorDetailPhoneLabel => 'ទូរស័ព្ទ';

  @override
  String get vendorDetailAddressLabel => 'អាសយដ្ឋាន';

  @override
  String get vendorDetailNotesHeading => 'កំណត់ចំណាំ';

  @override
  String get vendorDetailScorecardAction => 'មើលកាតសម្គាល់ការអនុវត្ត';

  @override
  String get vendorFormTitle => 'ចុះបញ្ជីអ្នកផ្គត់ផ្គង់';

  @override
  String get vendorFormSaveTooltip => 'រក្សាទុក';

  @override
  String get vendorFormSaveAction => 'រក្សាទុកអ្នកផ្គត់ផ្គង់';

  @override
  String get vendorFormSavedSnack => 'បានចុះបញ្ជីអ្នកផ្គត់ផ្គង់។';

  @override
  String vendorFormSaveFailed(String message) {
    return 'មិនអាចរក្សាទុកអ្នកផ្គត់ផ្គង់៖ $message';
  }

  @override
  String get vendorFormNameLabel => 'ឈ្មោះអ្នកផ្គត់ផ្គង់';

  @override
  String get vendorFormTaxIdLabel => 'លេខពន្ធ';

  @override
  String get vendorFormEmailLabel => 'អ៊ីមែល';

  @override
  String get vendorFormPhoneLabel => 'ទូរស័ព្ទ';

  @override
  String get vendorFormAddressLabel => 'អាសយដ្ឋាន';

  @override
  String get vendorFormContactPersonLabel => 'បុគ្គលទំនាក់ទំនង (ស្រេចចិត្ត)';

  @override
  String get vendorFormNotesLabel => 'កំណត់ចំណាំ (ស្រេចចិត្ត)';

  @override
  String get vendorScorecardTitle => 'កាតសម្គាល់អ្នកផ្គត់ផ្គង់';

  @override
  String get vendorScorecardCompositeLabel => 'ពិន្ទុរួម';

  @override
  String get vendorScorecardOnTimeLabel => 'ដឹកជញ្ជូនទាន់ពេល';

  @override
  String get vendorScorecardDefectLabel => 'អត្រាខូច';

  @override
  String get vendorScorecardDisputesLabel => 'ជម្លោះបើកចំហ';

  @override
  String get vendorScorecardSpendLabel => 'ការចំណាយសរុប';

  @override
  String get inventoryItemsTitle => 'ទំនិញស្តុក';

  @override
  String get inventoryScanTooltip => 'ស្កែនបាកូដ';

  @override
  String get inventoryLowStockAlertsTooltip => 'ការជូនដំណឹងស្តុកទាប';

  @override
  String get inventoryItemsSearchHint => 'ស្វែងរកតាម SKU, ឈ្មោះ, ទីតាំង, បាកូដ';

  @override
  String get inventoryItemsSortTooltip => 'តម្រៀប';

  @override
  String get inventoryItemsEmpty => 'គ្មានទំនិញត្រូវនឹងតម្រងបច្ចុប្បន្នទេ។';

  @override
  String inventoryItemsError(String message) {
    return 'មិនអាចផ្ទុកស្តុក៖ $message';
  }

  @override
  String inventoryItemsOnHand(String qty) {
    return 'មាន $qty';
  }

  @override
  String inventoryReorderBadge(String qty) {
    return 'បញ្ជាក់ឡើងវិញនៅ $qty';
  }

  @override
  String get inventoryLowStockChip => 'តែស្តុកទាប';

  @override
  String get inventorySortNameAsc => 'ឈ្មោះ (A–Z)';

  @override
  String get inventorySortSkuAsc => 'SKU';

  @override
  String get inventorySortOnHandAsc => 'ស្តុក (ទាបមុន)';

  @override
  String get inventorySortOnHandDesc => 'ស្តុក (ខ្ពស់មុន)';

  @override
  String get inventoryItemDetailTitle => 'ទំនិញ';

  @override
  String inventoryItemNotFound(String itemId) {
    return 'យើងរកមិនឃើញទំនិញដែលមាន id \"$itemId\" ទេ។';
  }

  @override
  String get inventoryDetailWarehouseLabel => 'ឃ្លាំង';

  @override
  String get inventoryDetailLocationLabel => 'ទីតាំង';

  @override
  String get inventoryDetailReorderLabel => 'ចំណុចបញ្ជាឡើងវិញ';

  @override
  String get inventoryDetailUnitCostLabel => 'តម្លៃឯកតា';

  @override
  String get inventoryDetailBarcodeLabel => 'បាកូដ';

  @override
  String get inventoryDetailMovementsHeading => 'ប្រវត្តិចលនា';

  @override
  String get inventoryDetailMovementsEmpty => 'មិនទាន់មានចលនាទេ។';

  @override
  String get inventoryMovementTypeReceipt => 'ទទួលទំនិញ';

  @override
  String get inventoryMovementTypeIssue => 'ចេញទំនិញ';

  @override
  String get inventoryMovementTypeTransfer => 'ផ្ទេរ';

  @override
  String get inventoryMovementTypeAdjustment => 'កែតម្រូវ';

  @override
  String inventoryMovementRunningLabel(String qty) {
    return 'សមតុល្យ $qty';
  }

  @override
  String get inventoryIssueAction => 'ចេញ';

  @override
  String get inventoryReceiptAction => 'ទទួល';

  @override
  String get inventoryTransferAction => 'ផ្ទេរ';

  @override
  String get inventoryLowStockTitle => 'ស្តុកទាប';

  @override
  String get inventoryLowStockEmpty => 'ទំនិញទាំងអស់ខ្ពស់ជាងចំណុចបញ្ជាឡើងវិញ។';

  @override
  String get inventoryScannerTitle => 'ស្កែនបាកូដ';

  @override
  String get inventoryScannerEmpty => 'សូមស្កែនឬបញ្ចូលលេខកូដ។';

  @override
  String inventoryScannerUnknown(String code) {
    return 'គ្មានទំនិញត្រូវនឹង \"$code\" ទេ។';
  }

  @override
  String inventoryScannerError(String message) {
    return 'កំហុសម៉ាស៊ីនស្កែន៖ $message';
  }

  @override
  String get inventoryScannerNoCamera =>
      'មិនមានកាមេរ៉ាសម្រាប់វេទិកានេះ — សូមប្រើការបញ្ចូលដោយដៃខាងក្រោម។';

  @override
  String get inventoryScannerManualHeading => 'ការបញ្ចូលដោយដៃ';

  @override
  String get inventoryScannerManualLabel => 'បាកូដ';

  @override
  String get inventoryScannerManualHint => 'វាយឬបិទភ្ជាប់លេខកូដ';

  @override
  String get inventoryScannerManualUseAction => 'ប្រើ';

  @override
  String get inventoryScannerBrowseFallback => 'មើលកាតាឡុកជំនួស';

  @override
  String get inventoryReceiptFormTitle => 'ទទួលស្តុក';

  @override
  String get inventoryIssueFormTitle => 'ចេញស្តុក';

  @override
  String get inventoryReceiptSuccessSnack => 'បានទទួលស្តុក។';

  @override
  String get inventoryIssueSuccessSnack => 'បានចេញស្តុក។';

  @override
  String get inventoryMovementGenericSuccess => 'បានកត់ត្រាចលនា។';

  @override
  String inventoryMovementFailed(String message) {
    return 'មិនអាចកត់ត្រាចលនា៖ $message';
  }

  @override
  String inventoryFormCurrentOnHand(String qty) {
    return 'ស្តុកបច្ចុប្បន្ន៖ $qty';
  }

  @override
  String get inventoryFormQuantityLabel => 'បរិមាណ';

  @override
  String get inventoryFormReferenceLabel => 'ឯកសារយោង (ស្រេចចិត្ត)';

  @override
  String get inventoryFormReferenceReceiptHint => 'ឧ. PO-2026-001';

  @override
  String get inventoryFormReferenceIssueHint => 'ឧ. SO-2026-014';

  @override
  String get inventoryFormNoteLabel => 'កំណត់ចំណាំ';

  @override
  String get inventoryQtyExceedsOnHand => 'បរិមាណលើសពីស្តុកបច្ចុប្បន្ន។';

  @override
  String get inventoryTransferFormTitle => 'ផ្ទេរស្តុក';

  @override
  String get inventoryTransferSourceHeading => 'ពី';

  @override
  String get inventoryTransferDestinationLabel => 'ទីតាំងគោលដៅ';

  @override
  String get inventoryTransferNoDestinations =>
      'គ្មានទីតាំងគោលដៅសកម្មសម្រាប់ SKU នេះទេ។';

  @override
  String get inventoryTransferReferenceHint => 'កំណត់ចំណាំការផ្ទេរផ្ទៃក្នុង';

  @override
  String get inventoryTransferPickDestination => 'សូមជ្រើសរើសទីតាំងគោលដៅ។';

  @override
  String get inventoryTransferSuccess => 'បានផ្ទេរស្តុក។';

  @override
  String get inventoryCycleCountTitle => 'ការរាប់វដ្ត';

  @override
  String get inventoryCycleNoItems => 'គ្មានទំនិញត្រូវរាប់ទេ។';

  @override
  String get inventoryCycleAllWarehouses => 'ឃ្លាំងទាំងអស់';

  @override
  String inventoryCycleExpectedLabel(String qty) {
    return 'រំពឹង $qty';
  }

  @override
  String get inventoryCycleCountedLabel => 'បានរាប់';

  @override
  String get inventoryCycleEmpty =>
      'សូមបញ្ចូលបរិមាណដែលបានរាប់សម្រាប់យ៉ាងហោចណាស់មួយ។';

  @override
  String get inventoryCycleSubmitAction => 'ដាក់ស្នើការរាប់';

  @override
  String inventoryCycleSuccess(int count, String variance) {
    return 'បានបង្ហោះការកែតម្រូវ $count ដង; ភាពខុសគ្នា $variance។';
  }

  @override
  String get salesCustomersTitle => 'អតិថិជន';

  @override
  String get salesAnalyticsTooltip => 'ការវិភាគ';

  @override
  String get salesCustomersSearchHint => 'ស្វែងរកតាមឈ្មោះ អ៊ីមែល ឧស្សាហកម្ម';

  @override
  String get salesCustomersSortTooltip => 'តម្រៀប';

  @override
  String get salesCustomersEmpty => 'គ្មានអតិថិជនត្រូវនឹងតម្រងរបស់អ្នកទេ។';

  @override
  String salesCustomersError(String message) {
    return 'មិនអាចផ្ទុកអតិថិជន៖ $message';
  }

  @override
  String salesCustomersOnboardedLabel(String date) {
    return 'ចាប់ពី $date';
  }

  @override
  String get salesCustomersSortName => 'ឈ្មោះ (A–Z)';

  @override
  String get salesCustomersSortLtv => 'តម្លៃពេញមួយជីវិត';

  @override
  String get salesCustomersSortRecent => 'បានបន្ថែមថ្មីៗ';

  @override
  String get salesStatusProspect => 'អនាគត';

  @override
  String get salesStatusActive => 'សកម្ម';

  @override
  String get salesStatusOnHold => 'ផ្អាក';

  @override
  String get salesStatusChurned => 'ចេញ';

  @override
  String get salesSegmentSmb => 'SMB';

  @override
  String get salesSegmentMidMarket => 'ទីផ្សារកណ្តាល';

  @override
  String get salesSegmentEnterprise => 'សហគ្រាស';

  @override
  String get salesCustomerDetailTitle => 'អតិថិជន';

  @override
  String salesCustomerNotFound(String customerId) {
    return 'យើងរកមិនឃើញអតិថិជនដែលមាន id \"$customerId\" ទេ។';
  }

  @override
  String get salesCustomerDetailEmailLabel => 'អ៊ីមែល';

  @override
  String get salesCustomerDetailPhoneLabel => 'ទូរស័ព្ទ';

  @override
  String get salesCustomerDetailAddressLabel => 'អាសយដ្ឋានវិក្កយបត្រ';

  @override
  String get salesCustomerDetailLifetimeValueLabel => 'តម្លៃពេញមួយជីវិត';

  @override
  String get salesCustomerDetailSinceLabel => 'អតិថិជនចាប់ពី';

  @override
  String get salesCustomerDetailNotesHeading => 'កំណត់ចំណាំ';

  @override
  String get salesCustomerDetailContactsHeading => 'ទំនាក់ទំនង';

  @override
  String get salesCustomerDetailContactsEmpty =>
      'មិនទាន់មានទំនាក់ទំនងភ្ជាប់ទេ។';

  @override
  String get salesCustomerDetailTimelineHeading => 'សកម្មភាព';

  @override
  String get salesCustomerDetailTimelineEmpty => 'មិនទាន់មានសកម្មភាពទេ។';

  @override
  String get salesContactAddAction => 'បន្ថែមទំនាក់ទំនង';

  @override
  String get salesContactEditAction => 'កែសម្រួល';

  @override
  String get salesContactDeleteAction => 'លុប';

  @override
  String get salesContactPrimaryBadge => 'ចម្បង';

  @override
  String get salesContactNewTitle => 'ទំនាក់ទំនងថ្មី';

  @override
  String get salesContactEditTitle => 'កែសម្រួលទំនាក់ទំនង';

  @override
  String get salesContactNameLabel => 'ឈ្មោះ';

  @override
  String get salesContactRoleLabel => 'តួនាទី';

  @override
  String get salesContactEmailLabel => 'អ៊ីមែល';

  @override
  String get salesContactPhoneLabel => 'ទូរស័ព្ទ';

  @override
  String get salesContactPrimaryToggle => 'ទំនាក់ទំនងចម្បង';

  @override
  String get salesContactPrimaryDescription =>
      'បង្ហាញទំនាក់ទំនងនេះនៅក្បាលអតិថិជន។';

  @override
  String get salesContactSaveAction => 'រក្សាទុកទំនាក់ទំនង';

  @override
  String get salesContactSavedSnack => 'បានរក្សាទុកទំនាក់ទំនង។';

  @override
  String salesContactSaveFailed(String message) {
    return 'មិនអាចរក្សាទុកទំនាក់ទំនង៖ $message';
  }

  @override
  String get salesContactDeleteTitle => 'លុបទំនាក់ទំនង?';

  @override
  String get salesContactDeleteBody => 'ទំនាក់ទំនងនឹងត្រូវយកចេញពីអតិថិជននេះ។';

  @override
  String get salesContactDeleteConfirm => 'លុប';

  @override
  String get salesContactDeletedSnack => 'បានយកទំនាក់ទំនងចេញ។';

  @override
  String get salesActivityLogAction => 'កត់ត្រាសកម្មភាព';

  @override
  String get salesActivityFormTitle => 'កត់ត្រាសកម្មភាព';

  @override
  String get salesActivityTypeLabel => 'ប្រភេទ';

  @override
  String get salesActivitySummaryLabel => 'សង្ខេប';

  @override
  String get salesActivityActorLabel => 'កត់ត្រាដោយ';

  @override
  String get salesActivitySaveAction => 'រក្សាទុកសកម្មភាព';

  @override
  String get salesActivitySavedSnack => 'បានកត់ត្រាសកម្មភាព។';

  @override
  String salesActivitySaveFailed(String message) {
    return 'មិនអាចកត់ត្រាសកម្មភាព៖ $message';
  }

  @override
  String get salesActivityTypeNote => 'កំណត់ចំណាំ';

  @override
  String get salesActivityTypeCall => 'ការហៅ';

  @override
  String get salesActivityTypeMeeting => 'ការប្រជុំ';

  @override
  String get salesActivityTypeEmail => 'អ៊ីមែល';

  @override
  String get salesActivityTypeQuotation => 'វិក្កយបត្ររបង់';

  @override
  String get salesActivityTypeOrder => 'ការបញ្ជាទិញ';

  @override
  String get salesActivityTypePayment => 'ការបង់ប្រាក់';

  @override
  String get salesQuotationListTitle => 'វិក្កយបត្ររបង់';

  @override
  String get salesQuotationNewTooltip => 'វិក្កយបត្ររបង់ថ្មី';

  @override
  String get salesQuotationSearchHint => 'ស្វែងរកតាមលេខឬអតិថិជន';

  @override
  String get salesQuotationSortTooltip => 'តម្រៀប';

  @override
  String get salesQuotationListEmpty => 'គ្មានវិក្កយបត្ររបង់ត្រូវនឹងតម្រងទេ។';

  @override
  String salesQuotationValidUntilLabel(String date) {
    return 'សុពលភាពដល់ $date';
  }

  @override
  String get salesQuotationSortCreatedDesc => 'បង្កើត (ថ្មីបំផុត)';

  @override
  String get salesQuotationSortCreatedAsc => 'បង្កើត (ចាស់បំផុត)';

  @override
  String get salesQuotationSortTotalDesc => 'សរុប (ច្រើនបំផុត)';

  @override
  String get salesQuotationSortValidity => 'ផុតកំណត់បន្ទាប់';

  @override
  String get salesQuotationStatusDraft => 'ព្រាង';

  @override
  String get salesQuotationStatusSent => 'បានផ្ញើ';

  @override
  String get salesQuotationStatusAccepted => 'បានទទួលយក';

  @override
  String get salesQuotationStatusRejected => 'បានបដិសេធ';

  @override
  String get salesQuotationStatusExpired => 'ផុតកំណត់';

  @override
  String get salesQuotationStatusConverted => 'បានបម្លែង';

  @override
  String get salesQuotationNewTitle => 'វិក្កយបត្ររបង់ថ្មី';

  @override
  String get salesQuotationCustomerLabel => 'អតិថិជន';

  @override
  String get salesQuotationValidUntilField => 'សុពលភាពដល់';

  @override
  String get salesQuotationLinesHeading => 'បន្ទាត់ទំនិញ';

  @override
  String salesQuotationLineHeading(int index) {
    return 'បន្ទាត់ $index';
  }

  @override
  String get salesQuotationAddLineAction => 'បន្ថែមបន្ទាត់';

  @override
  String get salesQuotationRemoveLineTooltip => 'លុបបន្ទាត់';

  @override
  String get salesQuotationLineDescriptionLabel => 'ការពិពណ៌នា';

  @override
  String get salesQuotationLineQuantityLabel => 'ចំនួន';

  @override
  String get salesQuotationLineUnitPriceLabel => 'តម្លៃឯកតា';

  @override
  String get salesQuotationSaveAction => 'រក្សាទុក';

  @override
  String get salesQuotationSavedSnack => 'បានរក្សាទុកវិក្កយបត្ររបង់។';

  @override
  String salesQuotationSaveFailed(String message) {
    return 'មិនអាចរក្សាទុក៖ $message';
  }

  @override
  String get salesQuotationPickCustomer => 'សូមជ្រើសរើសអតិថិជន។';

  @override
  String get salesQuotationDetailTitle => 'វិក្កយបត្ររបង់';

  @override
  String salesQuotationNotFound(String quotationId) {
    return 'យើងរកមិនឃើញវិក្កយបត្ររបង់ដែលមាន id \"$quotationId\" ទេ។';
  }

  @override
  String get salesQuotationCreatedLabel => 'បង្កើត';

  @override
  String get salesQuotationValidUntilLabel2 => 'សុពលភាពដល់';

  @override
  String get salesQuotationDetailLinesHeading => 'បន្ទាត់ទំនិញ';

  @override
  String get salesQuotationTotalLabel => 'សរុប';

  @override
  String get salesQuotationNotesHeading => 'កំណត់ចំណាំ';

  @override
  String get salesQuotationSendAction => 'ផ្ញើទៅអតិថិជន';

  @override
  String get salesQuotationAcceptAction => 'សម្គាល់ថាបានទទួលយក';

  @override
  String get salesQuotationRejectAction => 'សម្គាល់ថាបានបដិសេធ';

  @override
  String get salesQuotationConvertAction => 'បម្លែងទៅការបញ្ជាទិញ';

  @override
  String get salesQuotationStatusUpdated =>
      'បានធ្វើបច្ចុប្បន្នភាពវិក្កយបត្ររបង់។';

  @override
  String get salesQuotationConvertedSnack => 'បានបង្កើតការបញ្ជាទិញ។';

  @override
  String salesQuotationActionFailed(String message) {
    return 'មិនអាចធ្វើបច្ចុប្បន្នភាព៖ $message';
  }

  @override
  String get salesQuotationConvertNotAccepted =>
      'មានតែវិក្កយបត្ររបង់ដែលបានទទួលយកអាចបម្លែងបាន។';

  @override
  String get salesQuotationConvertAlready =>
      'វិក្កយបត្ររបង់នេះត្រូវបានបម្លែងរួចហើយ។';

  @override
  String get salesQuotationConvertExpired => 'វិក្កយបត្ររបង់នេះផុតកំណត់ហើយ។';

  @override
  String get salesOrderListTitle => 'ការបញ្ជាទិញ';

  @override
  String get salesOrderListEmpty => 'មិនទាន់មានការបញ្ជាទិញទេ។';

  @override
  String get salesOrderStatusPending => 'កំពុងរង់ចាំ';

  @override
  String get salesOrderStatusPacking => 'កំពុងវេចខ្ចប់';

  @override
  String get salesOrderStatusShipped => 'បានដឹកជញ្ជូន';

  @override
  String get salesOrderStatusDelivered => 'បានដឹកដល់';

  @override
  String get salesOrderStatusCancelled => 'បានលុបចោល';

  @override
  String get salesOrderDetailTitle => 'ការបញ្ជាទិញ';

  @override
  String salesOrderNotFound(String orderId) {
    return 'យើងរកមិនឃើញការបញ្ជាទិញដែលមាន id \"$orderId\" ទេ។';
  }

  @override
  String get salesOrderCreatedLabel => 'បង្កើត';

  @override
  String get salesOrderSourceQuotationLabel => 'វិក្កយបត្ររបង់ប្រភព';

  @override
  String get salesOrderShippedAtLabel => 'បានដឹកជញ្ជូន';

  @override
  String get salesOrderDeliveredAtLabel => 'បានដឹកដល់';

  @override
  String get salesOrderTrackingLabel => 'តាមដាន';

  @override
  String get salesOrderDetailLinesHeading => 'បន្ទាត់ទំនិញ';

  @override
  String get salesOrderCancelAction => 'បោះបង់';

  @override
  String get salesOrderStartPackingAction => 'ចាប់ផ្តើមវេចខ្ចប់';

  @override
  String get salesOrderShipAction => 'ដឹកជញ្ជូន';

  @override
  String get salesOrderMarkDeliveredAction => 'សម្គាល់ថាបានដឹកដល់';

  @override
  String get salesOrderTrackingDialogTitle => 'ឯកសារយោងតាមដាន';

  @override
  String get salesOrderTrackingConfirm => 'បញ្ជាក់';

  @override
  String get salesOrderTrackingRequired =>
      'ត្រូវការឯកសារយោងតាមដានដើម្បីដឹកជញ្ជូន។';

  @override
  String salesOrderAdvancedSnack(String status) {
    return 'បានសម្គាល់ការបញ្ជាទិញជា $status។';
  }

  @override
  String salesOrderAdvanceFailed(String message) {
    return 'មិនអាចធ្វើបច្ចុប្បន្នភាពការបញ្ជាទិញ៖ $message';
  }

  @override
  String get salesAnalyticsTitle => 'ការវិភាគការលក់';

  @override
  String get salesAnalyticsRevenueHeading => 'ចំណូល';

  @override
  String get salesAnalyticsRevenueEmpty =>
      'មិនមានចំណូលក្នុងបង្អួចដែលបានជ្រើសរើស។';

  @override
  String get salesAnalyticsPeriodWeekly => 'ប្រចាំសប្តាហ៍';

  @override
  String get salesAnalyticsPeriodMonthly => 'ប្រចាំខែ';

  @override
  String get salesAnalyticsTopCustomersHeading => 'អតិថិជនកំពូល';

  @override
  String get salesAnalyticsTopCustomersEmpty =>
      'មិនទាន់មានចំណូលអតិថិជនដើម្បីចាត់ថ្នាក់ទេ។';

  @override
  String get salesAnalyticsTopProductsHeading => 'ផលិតផលកំពូល';

  @override
  String get salesAnalyticsTopProductsEmpty =>
      'មិនទាន់មានចំណូលផលិតផលដើម្បីចាត់ថ្នាក់ទេ។';

  @override
  String get salesAnalyticsLeaderboardHeading => 'តារាងចំណាត់ថ្នាក់អ្នកលក់';

  @override
  String get salesAnalyticsLeaderboardEmpty => 'មិនទាន់មានអ្នកលក់ទេ។';

  @override
  String salesAnalyticsLeaderboardDealsLabel(String count) {
    return 'បានបិទ $count កិច្ច';
  }

  @override
  String salesAnalyticsLeaderboardAttainmentLabel(String pct, String target) {
    return '$pct% នៃ $target';
  }

  @override
  String get errorBoundaryGenericMessage => 'មានបញ្ហាមួយបានកើតឡើង';

  @override
  String get commonEmailLabel => 'អ៊ីមែល';

  @override
  String get loginWelcomeSubtitle => 'សូមស្វាគមន៍មកវិញ! សូមចូលគណនីដើម្បីបន្ត។';

  @override
  String get loginPasswordLabel => 'ពាក្យសម្ងាត់';

  @override
  String get loginForgotPasswordAction => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get loginSignInAction => 'ចូលគណនី';

  @override
  String get loginOrSecureWith => 'ឬចូលដោយសុវត្ថិភាព';

  @override
  String get loginUseBiometricsAction => 'ប្រើជីវមាត្រ';

  @override
  String get loginValidatorEmailRequired => 'សូមបញ្ចូលអ៊ីមែលរបស់អ្នក';

  @override
  String get loginValidatorEmailInvalid => 'សូមបញ្ចូលអ៊ីមែលដែលត្រឹមត្រូវ';

  @override
  String get loginValidatorPasswordRequired => 'សូមបញ្ចូលពាក្យសម្ងាត់របស់អ្នក';

  @override
  String get loginValidatorPasswordTooShort =>
      'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ';

  @override
  String get loginNoAccountPrompt => 'មិនទាន់មានគណនី?';

  @override
  String get loginCreateAccountAction => 'បង្កើតមួយ';

  @override
  String get registerWelcomeTitle => 'បង្កើតគណនីរបស់អ្នក';

  @override
  String get registerWelcomeSubtitle =>
      'ចាប់ផ្ដើមគ្រប់គ្រងអាជីវកម្មរបស់អ្នកក្នុងរយៈពេលប៉ុន្មាននាទី។';

  @override
  String get registerFullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get registerFullNameHint => 'Jane Doe';

  @override
  String get registerPhoneHint => '096 506 0999';

  @override
  String get registerValidatorPhoneRequired => 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក';

  @override
  String get registerValidatorPhoneInvalid =>
      'សូមបញ្ចូលលេខទូរស័ព្ទដែលត្រឹមត្រូវ';

  @override
  String get registerConfirmPasswordLabel => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get registerTermsPrefix => 'ដោយចុច បង្កើតគណនី អ្នកយល់ព្រមនឹង ';

  @override
  String get registerTermsLink => 'លក្ខខណ្ឌ';

  @override
  String get registerTermsAnd => ' និង ';

  @override
  String get registerPrivacyLink => 'គោលការណ៍ឯកជនភាព';

  @override
  String get registerTermsSuffix => '។';

  @override
  String get registerSubmitAction => 'បង្កើតគណនី';

  @override
  String get registerHaveAccountPrompt => 'មានគណនីរួចហើយ?';

  @override
  String get registerSignInAction => 'ចូលគណនី';

  @override
  String get registerValidatorFullNameRequired => 'សូមបញ្ចូលឈ្មោះពេញរបស់អ្នក';

  @override
  String get registerValidatorPasswordsMismatch => 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ';

  @override
  String get registerValidatorAcceptTermsRequired =>
      'សូមទទួលយកលក្ខខណ្ឌដើម្បីបន្ត';

  @override
  String get registerAcceptTermsLabel =>
      'ខ្ញុំទទួលយកលក្ខខណ្ឌ និងគោលការណ៍ឯកជនភាព';

  @override
  String get authGenericErrorFallback =>
      'មានបញ្ហាបានកើតឡើង។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get authNetworkErrorFallback =>
      'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនបម្រើបានទេ។ សូមពិនិត្យការតភ្ជាប់ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get forgotPasswordTitle => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get forgotPasswordSubtitle =>
      'បញ្ចូលអាសយដ្ឋានអ៊ីមែលរបស់អ្នក រួចយើងនឹងផ្ញើតំណភ្ជាប់ដើម្បីកំណត់ពាក្យសម្ងាត់ឡើងវិញ។';

  @override
  String get forgotPasswordValidatorEmailRequired => 'បញ្ចូលអ៊ីមែល';

  @override
  String get forgotPasswordSendResetAction => 'ផ្ញើតំណកំណត់ឡើងវិញ';

  @override
  String get forgotPasswordSentTitle => 'បានផ្ញើអ៊ីមែលហើយ!';

  @override
  String get forgotPasswordSentSubtitle =>
      'សូមពិនិត្យប្រអប់សំបុត្ររបស់អ្នកសម្រាប់ការណែនាំក្នុងការកំណត់ពាក្យសម្ងាត់ឡើងវិញ។';

  @override
  String get forgotPasswordBackToLoginAction => 'ត្រឡប់ទៅចូលគណនី';

  @override
  String get biometricPageTitle => 'ដោះសោដោយជីវមាត្រ';

  @override
  String get biometricAuthenticatingTitle => 'កំពុងផ្ទៀងផ្ទាត់...';

  @override
  String get biometricHoldFingerSubtitle =>
      'សូមដាក់ម្រាមដៃរបស់អ្នកលើឧបករណ៍ចាប់';

  @override
  String get biometricUseFingerprintSubtitle =>
      'ប្រើស្នាមម្រាមដៃ ឬមុខរបស់អ្នកដើម្បីបន្ត';

  @override
  String get biometricUnlockNowAction => 'ដោះសោឥឡូវនេះ';

  @override
  String get biometricUsePasswordInsteadAction => 'ប្រើពាក្យសម្ងាត់ជំនួសវិញ';

  @override
  String get otpResendCodeAction => 'ផ្ញើកូដម្តងទៀត (៣០វិ)';

  @override
  String get splashTagline => 'ឧត្តមភាពអាជីវកម្ម';

  @override
  String get dashboardGreeting => 'អរុណសួស្តី,';

  @override
  String get dashboardUserNamePlaceholder => 'អ្នកអនុម័តសាកល្បង';

  @override
  String get dashboardQuickAccessSection => 'ចូលដំណើរការរហ័ស';

  @override
  String get dashboardSimulatePushAction => 'សាកល្បងផ្ញើព័ត៌មាន';

  @override
  String get dashboardRoutedPushAction => 'ផ្ញើដោយផ្លូវ';

  @override
  String get dashboardKpiRevenueLabel => 'ចំណូល (ខែនេះ)';

  @override
  String get dashboardKpiOpenInvoicesLabel => 'វិក្កយបត្របើក';

  @override
  String get dashboardKpiAvgFulfilmentLabel => 'មធ្យមបំពេញ (ថ្ងៃ)';

  @override
  String get accountDetailTransactionsHeading => 'ប្រតិបត្តិការ';

  @override
  String get accountDetailCurrentBalanceLabel => 'សមតុល្យបច្ចុប្បន្ន';

  @override
  String invoiceDetailRejectionReasonLabel(String reason) {
    return 'មូលហេតុ៖ $reason';
  }

  @override
  String invoiceListIssuedDateLabel(String date) {
    return 'ចេញ៖ $date';
  }

  @override
  String journalEntryListReferenceLabel(String reference, String date) {
    return 'យោង៖ $reference · $date';
  }

  @override
  String commonSkuLabel(String sku) {
    return 'កូដផលិតផល៖ $sku';
  }

  @override
  String prListCreatedDateLabel(String date) {
    return 'បានបង្កើត៖ $date';
  }

  @override
  String prListDepartmentLabel(String dept) {
    return 'នាយកដ្ឋាន៖ $dept';
  }

  @override
  String inventorySkuLocationCompound(String sku, String loc) {
    return 'កូដផលិតផល៖ $sku · ទីតាំង៖ $loc';
  }

  @override
  String inventoryWarehouseLocationLabel(String wh, String loc) {
    return 'ឃ្លាំង៖ $wh · ទីតាំង៖ $loc';
  }

  @override
  String get inventoryCurrentStockLabel => 'ស្តុកបច្ចុប្បន្ន';

  @override
  String get inventoryAvailableToTransferLabel => 'បរិមាណអាចផ្ទេរ';

  @override
  String get customerFormCompanyOrPersonNameLabel => 'ឈ្មោះក្រុមហ៊ុន ឬបុគ្គល';

  @override
  String get customerFormIndustryOptionalLabel => 'ឧស្សាហកម្ម (ស្រេចចិត្ត)';

  @override
  String get commonPhoneNumberLabel => 'លេខទូរស័ព្ទ';

  @override
  String get commonPhoneLabel => 'ទូរស័ព្ទ';

  @override
  String get customerFormBillingAddressLabel => 'អាសយដ្ឋានវិក្កយបត្រ';

  @override
  String get customerFormNotesRemarksOptionalLabel => 'កំណត់ចំណាំ (ស្រេចចិត្ត)';

  @override
  String customerFormSaveFailureSnack(String error) {
    return 'បរាជ័យក្នុងការរក្សាទុកអតិថិជន៖ $error';
  }

  @override
  String get customerListNewCustomerAction => 'អតិថិជនថ្មី';

  @override
  String get commonCancelAction => 'បោះបង់';

  @override
  String get commonRetryAction => 'ព្យាយាមម្ដងទៀត';

  @override
  String get commonLoadFailedFallback => 'មិនអាចផ្ទុកបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get assignmentsPageTitle => 'កំណត់សិទ្ធិ និងតួនាទី';

  @override
  String get assignmentsRolesTab => 'តួនាទី → សិទ្ធិ';

  @override
  String get assignmentsUsersTab => 'អ្នកប្រើ → តួនាទី';

  @override
  String get assignmentsPickRolePrompt => 'ជ្រើសរើសតួនាទីដើម្បីកែសម្រួលសិទ្ធិ';

  @override
  String get assignmentsPickUserPrompt =>
      'ជ្រើសរើសអ្នកប្រើដើម្បីកែសម្រួលតួនាទី';

  @override
  String get assignmentsPermissionsSectionTitle => 'សិទ្ធិ';

  @override
  String get assignmentsRolesSectionTitle => 'តួនាទី';

  @override
  String assignmentsCountSuffix(int count) {
    return 'បានជ្រើស $count';
  }

  @override
  String get assignmentsSaveAction => 'រក្សាទុកការផ្លាស់ប្ដូរ';

  @override
  String get assignmentsNoChangesYet => 'មិនមានការផ្លាស់ប្ដូរ';

  @override
  String get assignmentsSavedSnack => 'បានរក្សាទុក';

  @override
  String get assignmentsSaveFailedSnack => 'មិនអាចរក្សាទុកបានទេ';

  @override
  String get assignmentsForbiddenMessage =>
      'អ្នកគ្មានសិទ្ធិធ្វើការផ្លាស់ប្ដូរនៅទីនេះទេ។';

  @override
  String get assignmentsSuperAdminOnlyTitle =>
      'សម្រាប់អ្នកគ្រប់គ្រងជាន់ខ្ពស់ប៉ុណ្ណោះ';

  @override
  String get assignmentsSuperAdminOnlyMessage =>
      'មានតែអ្នកគ្រប់គ្រងជាន់ខ្ពស់ប៉ុណ្ណោះ ដែលអាចកំណត់តួនាទី និងសិទ្ធិបាន។ សូមចូលគណនីជាអ្នកគ្រប់គ្រងជាន់ខ្ពស់ ដើម្បីប្រើទំព័រនេះ។';

  @override
  String get assignmentsUsersSearchHint => 'ស្វែងរកអ្នកប្រើ...';

  @override
  String get assignmentsSearchPermissionsHint => 'ស្វែងរកសិទ្ធិ...';

  @override
  String get assignmentsRolePickerLabel => 'តួនាទី';

  @override
  String get assignmentsSystemRoleBadge => 'ប្រព័ន្ធ';

  @override
  String get assignmentsSystemRoleLockedMessage =>
      'តួនាទីប្រព័ន្ធគឺអាចមើលបានតែប៉ុណ្ណោះ។ បង្កើតតួនាទីផ្ទាល់ខ្លួនដើម្បីកំណត់សិទ្ធិផ្សេង។';

  @override
  String get assignmentsLoadMoreAction => 'ផ្ទុកបន្ថែម';

  @override
  String get assignmentsEmptyUsers => 'មិនមានអ្នកប្រើនៅឡើយទេ។';

  @override
  String get assignmentsNoUserSelected =>
      'ជ្រើសរើសអ្នកប្រើពីបញ្ជី ដើម្បីកំណត់តួនាទី។';

  @override
  String get assignmentsNoRoleSelected =>
      'ជ្រើសរើសតួនាទីខាងលើ ដើម្បីចាប់ផ្ដើមកំណត់សិទ្ធិ។';

  @override
  String get assignmentsAssignSubtitle =>
      'ជ្រើសរើសតួនាទីមួយ បន្ទាប់មកជ្រើសរើសអ្នកប្រើដែលត្រូវកំណត់។ អ្នកប្រើម្នាក់មានតួនាទីតែមួយប៉ុណ្ណោះ។';

  @override
  String assignmentsSaveActionAssign(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#នាក់',
    );
    return 'កំណត់តួនាទីដល់ $_temp0';
  }

  @override
  String get assignmentsUserFieldLabel => 'អ្នកប្រើ';

  @override
  String get assignmentsRoleFieldLabel => 'តួនាទី';

  @override
  String get assignmentsModeFieldLabel => 'របៀប';

  @override
  String get assignmentsRoleHelperPickUserFirst =>
      'សូមជ្រើសរើសអ្នកប្រើយ៉ាងតិចម្នាក់ ដើម្បីបើកការកំណត់តួនាទី។';

  @override
  String get assignmentsRoleHelperCurrentRole =>
      'តួនាទីដែលជ្រើសរើសនឹងត្រូវអនុវត្តចំពោះអ្នកប្រើទាំងអស់ដែលបានជ្រើសរើស។';

  @override
  String get assignmentsPickUsersPrompt => 'ជ្រើសរើសអ្នកប្រើ…';

  @override
  String assignmentsUsersSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'បានជ្រើសរើស #នាក់',
    );
    return '$_temp0';
  }

  @override
  String assignmentsUsersSelectedSummary(String first, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '#នាក់ផ្សេងទៀត',
    );
    return '$first +$_temp0';
  }

  @override
  String get assignmentsModeAdd => 'បន្ថែម';

  @override
  String get assignmentsModeReplace => 'ជំនួស';

  @override
  String get assignmentsModeRemove => 'លុបចេញ';

  @override
  String get assignmentsModeHelperAdd =>
      'បន្ថែមតួនាទីនេះទៅលើតួនាទីដែលអ្នកប្រើមានរួចហើយ។';

  @override
  String get assignmentsModeHelperReplace =>
      'ជំនួសតួនាទីទាំងអស់របស់អ្នកប្រើដោយតួនាទីដែលជ្រើសរើស។';

  @override
  String get assignmentsModeHelperRemove =>
      'លុបតួនាទីដែលជ្រើសរើសចេញពីអ្នកប្រើ (តួនាទីផ្សេងនៅដដែល)។';

  @override
  String assignmentsSaveActionBulk(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#នាក់',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#នាក់',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#នាក់',
    );
    String _temp3 = intl.Intl.selectLogic(mode, {
      'add': 'បន្ថែមតួនាទីដល់ $_temp0',
      'replace': 'ជំនួសតួនាទីលើ $_temp1',
      'remove': 'លុបតួនាទីពី $_temp2',
      'other': 'រក្សាទុក',
    });
    return '$_temp3';
  }

  @override
  String get assignmentsSelectAllAction => 'ជ្រើសរើសទាំងអស់';

  @override
  String get assignmentsClearSelectionAction => 'សម្អាត';

  @override
  String get assignmentsConfirmDoneAction => 'រួចរាល់';

  @override
  String get assignmentsUserNoRoleBadge => 'មិនមានតួនាទី';

  @override
  String assignmentsUserRolesMore(int count) {
    return '+$count';
  }

  @override
  String get assignmentsFilterAll => 'ទាំងអស់';

  @override
  String get assignmentsFilterHasRole => 'មានតួនាទី';

  @override
  String get assignmentsFilterNoRole => 'មិនមានតួនាទី';

  @override
  String get commonApproveAction => 'អនុម័ត';

  @override
  String get commonRejectAction => 'បដិសេធ';

  @override
  String get hrEmployeeDetailNotFoundTitle => 'រកមិនឃើញនិយោជិក';

  @override
  String hrEmployeeDetailNotFoundBody(String employeeId) {
    return 'មិនមាននិយោជិកដែលមាន ID \"$employeeId\" ទេ។';
  }

  @override
  String get hrEmployeeDetailOfficeLocationLabel => 'ទីតាំងការិយាល័យ';

  @override
  String get hrEmployeeDetailDepartmentLabel => 'នាយកដ្ឋាន';

  @override
  String get hrEmployeeDetailPositionTitleLabel => 'មុខតំណែង';

  @override
  String get hrEmployeeDetailHireDateLabel => 'កាលបរិច្ឆេទចូលបម្រើការ';

  @override
  String get hrEmployeeDetailMonthlySalaryLabel => 'ប្រាក់ខែ';

  @override
  String get hrEmployeeDetailManagerIdLabel => 'ID អ្នកគ្រប់គ្រង';

  @override
  String get hrEmployeeDetailTabAttendance => 'វត្តមាន';

  @override
  String get hrEmployeeDetailTabPayslips => 'ប័ណ្ណប្រាក់ខែ';

  @override
  String get hrEmployeeDetailTabLeaves => 'ការឈប់សម្រាក';

  @override
  String get hrEmployeeDetailTabOrgChart => 'តារាងស្ថាប័ន';

  @override
  String get hrEmployeeListOrgChartTooltip => 'តារាងស្ថាប័ន';

  @override
  String get hrEmployeeListSortTooltip => 'តម្រៀប';

  @override
  String get hrEmployeeListSortNameAz => 'ឈ្មោះ (ក-អ)';

  @override
  String get hrEmployeeListSortRecentlyHired => 'ទើបជួលថ្មីៗ';

  @override
  String get hrEmployeeListSortDepartment => 'នាយកដ្ឋាន';

  @override
  String get hrEmployeeListErrorLoading => 'មានបញ្ហាក្នុងការផ្ទុកបញ្ជី';

  @override
  String get hrEmployeeListSearchHint => 'ស្វែងរកឈ្មោះ អ៊ីមែល មុខតំណែង...';

  @override
  String get hrEmployeeListEmptyTitle => 'មិនមាននិយោជិកដែលស្របគ្នាទេ';

  @override
  String get hrEmployeeListEmptySubtitle =>
      'សូមកែសម្រួលលក្ខណៈស្វែងរក ឬតម្រងរបស់អ្នក';

  @override
  String get hrLeaveApprovalRejectReasonTitle => 'មូលហេតុនៃការបដិសេធ';

  @override
  String get hrLeaveApprovalConfirmRejectionAction => 'បញ្ជាក់ការបដិសេធ';

  @override
  String get hrLeaveApprovalConfirmApprovalTitle => 'អនុម័តសំណើឈប់សម្រាកនេះ?';

  @override
  String get hrLeaveApprovalNoteHint => 'បន្ថែមកំណត់ចំណាំ (ស្រេចចិត្ត)';

  @override
  String get hrLeaveApprovalNoYearlyBalance => 'មិនមានសមតុល្យប្រចាំឆ្នាំទេ';

  @override
  String get hrLeaveApprovalFromLabel => 'ចាប់ពី';

  @override
  String get hrLeaveApprovalToLabel => 'ដល់';

  @override
  String hrLeaveApprovalSubmittedAt(String timestamp) {
    return 'បានដាក់ស្នើ $timestamp';
  }

  @override
  String get hrLeaveApprovalIfApprovedLabel => 'បើអនុម័ត';

  @override
  String get hrLeaveApprovalIfRejectedLabel => 'បើបដិសេធ';

  @override
  String get hrLeaveRequestsTabAll => 'ទាំងអស់';

  @override
  String get hrLeaveRequestsTabPending => 'កំពុងរង់ចាំ';

  @override
  String get hrLeaveRequestsTabMine => 'របស់ខ្ញុំ';

  @override
  String get hrLeaveRequestsNewRequestTooltip => 'សំណើថ្មី';

  @override
  String get hrLeaveRequestsEmptyTitle => 'មិនមានសំណើឈប់សម្រាកទេ';

  @override
  String get hrLeaveRequestsEmptySubtitle => 'មិនមានសំណើដែលស្របនឹងតម្រងនេះទេ។';

  @override
  String get hrLeaveRequestsApprovedSnack => 'សំណើឈប់សម្រាកត្រូវបានអនុម័ត។';

  @override
  String get hrLeaveRequestsRejectDialogTitle => 'បដិសេធសំណើឈប់សម្រាក';

  @override
  String get hrLeaveRequestsRejectedSnack => 'សំណើឈប់សម្រាកត្រូវបានបដិសេធ។';

  @override
  String get hrLeaveRequestsRejectionReasonRequiredSnack =>
      'ត្រូវផ្តល់មូលហេតុនៃការបដិសេធ។';

  @override
  String get hrLeaveFormSubmittedSnack =>
      'សំណើឈប់សម្រាកត្រូវបានដាក់ស្នើដោយជោគជ័យ។';

  @override
  String get hrLeaveFormPreferencesSection => 'ចំណូលចិត្តការឈប់សម្រាក';

  @override
  String get hrLeaveFormDurationSection => 'ជ្រើសរើសរយៈពេល';

  @override
  String get hrLeaveFormAttachmentsSection => 'ឯកសារភ្ជាប់ និងភស្តុតាង';

  @override
  String get hrLeaveFormJustificationSection => 'មូលហេតុ';

  @override
  String get hrLeaveFormSubmitAction => 'ដាក់ស្នើសំណើឈប់សម្រាក';

  @override
  String get hrLeaveFormUploadingAttachment => 'កំពុងផ្ទុកឯកសារភ្ជាប់...';

  @override
  String get hrLeaveFormReadyToUpload => 'ត្រៀមបង្ហោះ';

  @override
  String get hrLeaveFormRemoveAttachmentTooltip => 'លុបចេញ';

  @override
  String get hrLeaveFormTapToUploadDocument => 'ចុចដើម្បីបង្ហោះឯកសារ';

  @override
  String get hrLeaveFormUploadSupportedFormats =>
      'គាំទ្រ PDF, PNG, JPG រហូតដល់ 10MB (វិញ្ញាបនបត្រវេជ្ជសាស្ត្រ ។ល។)';

  @override
  String get hrLeaveBalanceHistoryTooltip => 'ប្រវត្តិការឈប់សម្រាក';

  @override
  String get hrLeaveBalanceRequestLeaveTooltip => 'ស្នើសុំឈប់សម្រាក';

  @override
  String get hrLeaveBalanceNoEntitlements => 'មិនមានសិទ្ធិទេ';

  @override
  String get hrLeaveBalanceRemainingLabel => 'នៅសល់';

  @override
  String get hrLeaveBalanceTakenLabel => 'បានយក';

  @override
  String get hrLeaveBalanceTotalLabel => 'សរុប';

  @override
  String get hrLeaveBalanceBreakdownHeading => 'បំបែកសិទ្ធិ';

  @override
  String get hrAttendanceRecentEntriesHeading => 'ការចូលថ្មីៗ';

  @override
  String get hrAttendanceEmptyMessage => 'មិនទាន់មានកំណត់ត្រាវត្តមានទេ';

  @override
  String get hrPayslipsEmpty => 'មិនមានប័ណ្ណប្រាក់ខែទេ';

  @override
  String get hrPayslipsArchiveHeading => 'បណ្ណាល័យប័ណ្ណប្រាក់ខែ';

  @override
  String get hrPayslipsAggregateSummaryHeading => 'សេចក្តីសង្ខេបសរុប';

  @override
  String hrPayslipsNetPayLabel(String amount) {
    return 'សុទ្ធ៖ $amount';
  }

  @override
  String hrPayslipsGrossPayLabel(String amount) {
    return 'សរុប៖ $amount';
  }

  @override
  String hrPayslipDetailNotFound(String payslipId) {
    return 'មិនមានប័ណ្ណប្រាក់ខែដែលមាន ID \"$payslipId\" ទេ។';
  }

  @override
  String get hrPayslipDetailNetPayoutLabel => 'ប្រាក់សុទ្ធ';

  @override
  String get hrPayslipDetailBreakdownHeading => 'បំបែកធាតុ';

  @override
  String get hrOrgChartPageTitle => 'តារាងស្ថាប័ន';

  @override
  String get hrOrgChartEmptyTitle => 'រកមិនឃើញនិយោជិកទេ';

  @override
  String get hrOrgChartEmptySubtitle => 'បន្ថែមនិយោជិកដើម្បីមើលឋានានុក្រម។';

  @override
  String get hrAttendancePageTitle => 'កំណត់ត្រាវត្តមាន';

  @override
  String get hrEmployeeDetailPageTitle => 'ប្រវត្តិរូបនិយោជិក';

  @override
  String get hrEmployeeDetailSectionQuickActions => 'សកម្មភាពរហ័ស';

  @override
  String get hrEmployeeDetailSectionContact => 'ព័ត៌មានទំនាក់ទំនង';

  @override
  String get hrEmployeeDetailSectionEmployment => 'ព័ត៌មានការងារ';

  @override
  String get hrEmployeeListPageTitle => 'បញ្ជីនិយោជិក';

  @override
  String get hrLeaveApprovalPageTitle => 'សំណើឈប់សម្រាក';

  @override
  String get hrLeaveBalancePageTitle => 'សមតុល្យឈប់សម្រាក';

  @override
  String get hrLeaveRequestsPageTitle => 'សំណើឈប់សម្រាក';

  @override
  String get hrLeaveFormPageTitle => 'សំណើឈប់សម្រាកថ្មី';

  @override
  String get hrPayslipsPageTitle => 'ប្រវត្តិប័ណ្ណប្រាក់ខែ';

  @override
  String get hrPayslipDetailPageTitle => 'ព័ត៌មានលម្អិតប័ណ្ណប្រាក់ខែ';

  @override
  String get projectBoardPageTitle => 'ក្ដារកិច្ចការ';

  @override
  String get projectBoardNewTaskAction => 'កិច្ចការថ្មី';

  @override
  String get projectBoardDropZoneHint => 'ទម្លាក់កិច្ចការនៅទីនេះ';

  @override
  String get projectDetailPageTitle => 'ព័ត៌មានគម្រោង';

  @override
  String get projectDetailOpenBoardTooltip => 'បើកក្ដារ';

  @override
  String get projectDetailEditProjectTooltip => 'កែសម្រួលគម្រោង';

  @override
  String projectDetailNotFound(String projectId) {
    return 'មិនមានគម្រោងដែលមាន ID \"$projectId\" ទេ។';
  }

  @override
  String projectDetailProjectIdLabel(String code) {
    return 'ID គម្រោង៖ $code';
  }

  @override
  String get projectDetailDescriptionHeading => 'ការពិពណ៌នា';

  @override
  String get projectDetailTasksHeading => 'កិច្ចការគម្រោង';

  @override
  String get projectDetailNoTasks => 'មិនទាន់មានកិច្ចការដែលបានកំណត់ទេ។';

  @override
  String get projectFormNameLabel => 'ឈ្មោះគម្រោង';

  @override
  String get projectFormCodeLabel => 'កូដគម្រោង';

  @override
  String get projectFormDescriptionLabel => 'ការពិពណ៌នា';

  @override
  String get projectFormStartLabel => 'ចាប់ផ្ដើម';

  @override
  String get projectFormEndLabel => 'បញ្ចប់';

  @override
  String projectFormDurationLabel(String duration) {
    return 'រយៈពេល៖ $duration';
  }

  @override
  String get projectFormBudgetLabel => 'ថវិកា (ទម្រង់)';

  @override
  String get projectFormPickEmployeeAction => 'ជ្រើសរើសនិយោជិក';

  @override
  String get projectListPageTitle => 'គម្រោង';

  @override
  String get projectListTimesheetsTooltip => 'តារាងម៉ោងធ្វើការ';

  @override
  String get projectListSortTooltip => 'តម្រៀប';

  @override
  String get projectListSortNameAz => 'ឈ្មោះ (ក-អ)';

  @override
  String get projectListSortRecentlyStarted => 'ទើបចាប់ផ្ដើមថ្មីៗ';

  @override
  String get projectListSortDueSoonest => 'ផុតកំណត់ឆាប់ៗ';

  @override
  String projectListErrorMessage(String message) {
    return 'បញ្ហា៖ $message';
  }

  @override
  String get projectListViewListAction => 'ទិដ្ឋភាពបញ្ជី';

  @override
  String get projectListViewGanttAction => 'តារាង Gantt';

  @override
  String get projectListSearchHint => 'ស្វែងរកឈ្មោះ កូដ ម្ចាស់...';

  @override
  String get projectListEmpty => 'មិនមានគម្រោងស្របទេ។';

  @override
  String get projectListNewProjectAction => 'គម្រោងថ្មី';

  @override
  String projectListCodeOwnerSubtitle(String code, String owner) {
    return 'កូដ៖ $code • ម្ចាស់៖ $owner';
  }

  @override
  String get taskAssignPageTitle => 'ផ្ដល់កិច្ចការ';

  @override
  String get taskAssignErrorLoading => 'មិនអាចផ្ទុកនិយោជិកបានទេ';

  @override
  String taskAssignSuccessSnack(String name) {
    return 'បានផ្ដល់ទៅ $name';
  }

  @override
  String taskAssignFailureSnack(String error) {
    return 'ការផ្ដល់បរាជ័យ៖ $error';
  }

  @override
  String get taskAssignCurrentlyLabel => 'បច្ចុប្បន្ន៖ ';

  @override
  String get taskAssignSearchHint => 'ស្វែងរកតាមឈ្មោះ តួនាទី ឬនាយកដ្ឋាន...';

  @override
  String get taskAssignClearTooltip => 'សម្អាត';

  @override
  String get taskAssignNoteHint =>
      'បន្ថែមកំណត់ចំណាំទៅអ្នកទទួល… (ឧ. \"បរិបទនៅ #project-alpha\")';

  @override
  String get taskAssignEmpty => 'មិនមាននិយោជិកស្របនឹងការស្វែងរកនេះទេ។';

  @override
  String get taskDetailPageTitle => 'ព័ត៌មានកិច្ចការ';

  @override
  String get taskDetailMoreTooltip => 'បន្ថែម';

  @override
  String get taskDetailEditTaskAction => 'កែសម្រួលកិច្ចការ';

  @override
  String get taskDetailReassignAction => 'ផ្ដល់ឡើងវិញ';

  @override
  String taskDetailNotFound(String taskId) {
    return 'មិនមានកិច្ចការដែលមាន ID \"$taskId\" ទេ។';
  }

  @override
  String get taskDetailDescriptionHeading => 'ការពិពណ៌នា';

  @override
  String get taskDetailCommentsHeading => 'មតិយោបល់';

  @override
  String get taskDetailNoComments => 'មិនទាន់មានមតិយោបល់ទេ។';

  @override
  String get taskDetailAddCommentHint => 'បន្ថែមមតិយោបល់...';

  @override
  String get taskFormPageTitleEdit => 'កែសម្រួលកិច្ចការ';

  @override
  String get taskFormPageTitleNew => 'កិច្ចការថ្មី';

  @override
  String get taskFormTitleRequiredValidator => 'ត្រូវការចំណងជើង';

  @override
  String get taskFormTitleHint => 'តើត្រូវធ្វើអ្វី?';

  @override
  String get taskFormDescriptionHint => 'បន្ថែមការពិពណ៌នា...';

  @override
  String get taskFormStatusLabel => 'ស្ថានភាព';

  @override
  String get taskFormPriorityLabel => 'អាទិភាព';

  @override
  String get taskFormAssigneeLabel => 'អ្នកទទួល';

  @override
  String get taskFormUnassignedLabel => 'មិនបានផ្ដល់';

  @override
  String get taskFormDueDateLabel => 'កាលបរិច្ឆេទផុតកំណត់';

  @override
  String get taskFormClearDueDateTooltip => 'សម្អាតកាលបរិច្ឆេទផុតកំណត់';

  @override
  String get taskFormAddDueDateAction => 'បន្ថែមកាលបរិច្ឆេទផុតកំណត់';

  @override
  String get taskFormAssignToAction => 'ផ្ដល់ទៅ...';

  @override
  String get taskFormUnassignAction => 'ដក​ការ​ផ្ដល់';

  @override
  String get timesheetsPageTitle => 'តារាងម៉ោងធ្វើការ';

  @override
  String get timesheetsUtilizationTooltip => 'ការប្រើប្រាស់';

  @override
  String get timesheetsTabMine => 'របស់ខ្ញុំ';

  @override
  String get timesheetsTabApprovals => 'ការអនុម័ត';

  @override
  String get timesheetsTabAll => 'ទាំងអស់';

  @override
  String get timesheetsEmpty => 'មិនមានធាតុតារាងម៉ោងធ្វើការទេ។';

  @override
  String get timesheetsLogTimeAction => 'កត់ត្រាម៉ោង';

  @override
  String timesheetsTaskLabel(String title) {
    return 'កិច្ចការ៖ $title';
  }

  @override
  String timesheetsRejectionNoteLabel(String note) {
    return 'កំណត់ចំណាំបដិសេធ៖ $note';
  }

  @override
  String get timesheetsSubmitForApprovalAction => 'ដាក់ស្នើដើម្បីអនុម័ត';

  @override
  String get timesheetsReopenAsDraftAction => 'បើកឡើងវិញជាសេចក្ដីព្រាង';

  @override
  String get timesheetsApprovedSnack => 'តារាងម៉ោងបានអនុម័ត។';

  @override
  String get timesheetsRejectDialogTitle => 'បដិសេធតារាងម៉ោង';

  @override
  String get timesheetsRejectedSnack => 'តារាងម៉ោងត្រូវបានបដិសេធ។';

  @override
  String get timesheetsReasonRequiredSnack => 'ត្រូវផ្ដល់មូលហេតុ។';

  @override
  String get timesheetsSubmittedSnack => 'បានដាក់ស្នើដើម្បីអនុម័ត។';

  @override
  String get timesheetsReopenedSnack => 'បានបើកឡើងវិញជាសេចក្ដីព្រាង។';

  @override
  String get timesheetFormPageTitle => 'កត់ត្រាម៉ោង';

  @override
  String get timesheetFormSubmitToggleLabel => 'ដាក់ស្នើដើម្បីអនុម័តភ្លាមៗ';

  @override
  String get timesheetFormSubmitToggleHint =>
      'បើមិនបាន វានឹងត្រូវរក្សាទុកជាសេចក្ដីព្រាងដែលអ្នកអាចកែសម្រួលក្រោយ។';

  @override
  String get timesheetFormSaveAction => 'រក្សាទុកតារាងម៉ោង';

  @override
  String get utilizationPageTitle => 'ការប្រើប្រាស់';

  @override
  String get utilizationThisWeekToggle => 'សប្ដាហ៍នេះ';

  @override
  String get utilizationThisMonthToggle => 'ខែនេះ';

  @override
  String get utilizationApprovedHoursHeading => 'ម៉ោងបានអនុម័តធៀបនឹងគោលដៅ';

  @override
  String get utilizationNoHoursInWindow =>
      'មិនមានម៉ោងបានអនុម័តក្នុងរយៈពេលនេះទេ។';

  @override
  String get ganttChartNoProjects => 'មិនមានគម្រោងក្នុងរយៈពេលនេះទេ។';

  @override
  String get settingsHomePageTitle => 'ការកំណត់';

  @override
  String get settingsHomeAccountSection => 'គណនី';

  @override
  String get settingsHomeMyProfileTitle => 'ប្រវត្តិរូបរបស់ខ្ញុំ';

  @override
  String get settingsHomeMyProfileSubtitle =>
      'ទំនាក់ទំនង ផ្ទាល់ខ្លួន សុវត្ថិភាព';

  @override
  String get settingsHomeMyRolesTitle => 'តួនាទី និងសិទ្ធិរបស់ខ្ញុំ';

  @override
  String get settingsHomeMyRolesSubtitle =>
      'អ្វីដែលអ្នកអាចធ្វើបាននៅក្នុងកម្មវិធី';

  @override
  String get settingsHomePreferencesSection => 'ចំណូលចិត្ត';

  @override
  String get settingsHomeAppearanceTitle => 'រូបរាង';

  @override
  String get settingsHomeAppearanceSubtitle => 'ភ្លឺ ងងឹត ឬតាមប្រព័ន្ធ';

  @override
  String get settingsHomeLanguageTitle => 'ភាសា';

  @override
  String get settingsHomeLanguageSubtitle => 'English / ខ្មែរ';

  @override
  String get settingsHomeNotificationsTitle => 'ការជូនដំណឹង';

  @override
  String get settingsHomeNotificationsSubtitle => 'ផ្ញើ + អ៊ីមែលតាមប្រភេទ';

  @override
  String get settingsHomeSecuritySection => 'សុវត្ថិភាព និងការចូលប្រើ';

  @override
  String get settingsHomeActiveDevicesTitle => 'ឧបករណ៍សកម្ម';

  @override
  String get settingsHomeActiveDevicesSubtitle => 'សម័យដែលអ្នកអាចលុបបាន';

  @override
  String get settingsHomeAuditLogTitle => 'កំណត់ហេតុសវនកម្ម';

  @override
  String get settingsHomeAuditLogSubtitle => 'អ្នកណាបានធ្វើអ្វី និងពេលណា';

  @override
  String get settingsHomeAppLockTitle => 'ការចាក់សោកម្មវិធី';

  @override
  String get settingsHomeAppLockSubtitle => 'PIN + ការផ្ទៀងផ្ទាត់ជីវមាត្រ';

  @override
  String get settingsHomeAdminSection => 'រដ្ឋបាល';

  @override
  String get settingsHomeUserMgmtTitle => 'ការគ្រប់គ្រងអ្នកប្រើ';

  @override
  String get settingsHomeUserMgmtSubtitle => 'អញ្ជើញ ផ្អាក ផ្ដល់តួនាទី';

  @override
  String get settingsHomeRolesPermsTitle => 'តួនាទី និងសិទ្ធិ';

  @override
  String get settingsHomeRolesPermsSubtitle =>
      'កម្មវិធីកែសម្រួលសម្រាប់តួនាទីតាមតម្រូវការ';

  @override
  String get settingsHomeApiConfigTitle => 'ការកំណត់រចនាសម្ព័ន្ធ API';

  @override
  String get settingsHomeApiConfigSubtitle => 'ប្ដូរបរិស្ថាន / អ្នកជួល';

  @override
  String get settingsHomeSignOutAction => 'ចេញ';

  @override
  String get settingsHomeSignOutConfirmTitle => 'ចេញពីគណនី?';

  @override
  String get settingsHomeSignOutConfirmMessage =>
      'អ្នកនឹងត្រូវចូលគណនីម្ដងទៀត ដើម្បីប្រើទិន្នន័យរបស់អ្នកនៅលើឧបករណ៍នេះ។';

  @override
  String get settingsHomeSignOutErrorSnack =>
      'មិនអាចចេញពីគណនីបានល្អទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get appearancePageTitle => 'រូបរាង';

  @override
  String get appearanceChooseThemeHeading => 'ជ្រើសរើសរបៀបស្បែក';

  @override
  String get appearanceModeSystem => 'តាមប្រព័ន្ធ';

  @override
  String get appearanceModeLight => 'របៀបភ្លឺ';

  @override
  String get appearanceModeDark => 'របៀបងងឹត';

  @override
  String get appearanceSubtitleSystem => 'តាមការកំណត់រូបរាងរបស់ប្រព័ន្ធ';

  @override
  String get appearanceSubtitleLight => 'តែងតែប្រើពណ៌ភ្លឺ';

  @override
  String get appearanceSubtitleDark => 'តែងតែប្រើពណ៌ងងឹត';

  @override
  String get languagePageTitle => 'ភាសា';

  @override
  String get languageSelectPreferredHeading => 'ជ្រើសរើសភាសាដែលពេញចិត្ត';

  @override
  String get languageDemoLaunchNote =>
      'ការផ្លាស់ប្ដូរភាសានឹងមានប្រសិទ្ធភាពនៅពេលបើកកម្មវិធីបន្ទាប់ក្នុងកំណែសាកល្បងនេះ។';

  @override
  String get languageEnglishLabel => 'អង់គ្លេស';

  @override
  String get languageKhmerLabel => 'ខ្មែរ';

  @override
  String get languageEnglishNative => 'United Kingdom';

  @override
  String get languageKhmerNative => 'ភាសាខ្មែរ';

  @override
  String get notificationPrefsPageTitle => 'ការជូនដំណឹង';

  @override
  String get notificationPrefsChannelsHeading => 'ប៉ុស្តិ៍ជូនដំណឹង';

  @override
  String get notificationPrefsPushTitle => 'ការផ្ញើព័ត៌មាន';

  @override
  String get notificationPrefsEmailTitle => 'បច្ចុប្បន្នភាពអ៊ីមែល';

  @override
  String get notificationPrefsChannelApprovals => 'ការអនុម័ត';

  @override
  String get notificationPrefsChannelMentions => 'ការនិយាយឈ្មោះ និងមតិយោបល់';

  @override
  String get notificationPrefsChannelSystemAlerts => 'ការជូនដំណឹងពីប្រព័ន្ធ';

  @override
  String get notificationPrefsChannelMarketing => 'ការផ្សព្វផ្សាយ និងព័ត៌មាន';

  @override
  String get notificationPrefsChannelApprovalsDescription =>
      'វិក្កយបត្រ សំណើច្បាប់ឈប់ ឈ្នួលរង់ចាំសកម្មភាព';

  @override
  String get notificationPrefsChannelMentionsDescription =>
      'មាននរណាម្នាក់បាន @ឈ្មោះអ្នកនៅលើកិច្ចការ ឬមតិយោបល់';

  @override
  String get notificationPrefsChannelSystemAlertsDescription =>
      'បរាជ័យធ្វើសមកាលកម្ម រយៈពេលផ្អាក ព្រឹត្តិការណ៍សុវត្ថិភាព';

  @override
  String get notificationPrefsChannelMarketingDescription =>
      'ព័ត៌មានផលិតផល ការណែនាំ និងការប្រកាសមុខងារ';

  @override
  String get sessionsPageTitle => 'ឧបករណ៍សកម្ម';

  @override
  String get sessionsSignOutOthersSnack => 'ឧបករណ៍ផ្សេងទៀតបានចេញ។';

  @override
  String get sessionsSignOutOthersAction => 'ចេញពីឧបករណ៍ផ្សេងទៀតទាំងអស់';

  @override
  String get sessionsEmpty => 'មិនមានសម័យសកម្មទេ។';

  @override
  String get sessionsThisDeviceLabel => 'ឧបករណ៍នេះ';

  @override
  String get sessionsRevokeAccessAction => 'ដកសិទ្ធិចូលប្រើ';

  @override
  String get sessionsLastActiveLabel => 'សកម្មចុងក្រោយ';

  @override
  String get sessionsSignedInLabel => 'បានចូល';

  @override
  String get sessionsLocationLabel => 'ទីតាំង';

  @override
  String get sessionsIpAddressLabel => 'អាសយដ្ឋាន IP';

  @override
  String sessionsRevokedSnack(String device) {
    return '$device បានចេញ។';
  }

  @override
  String get auditLogPageTitle => 'កំណត់ហេតុសវនកម្ម';

  @override
  String get auditLogSearchHint => 'ស្វែងរកអ្នកធ្វើ គោលដៅ ឬព័ត៌មានលម្អិត...';

  @override
  String get auditLogEmpty => 'មិនមានកំណត់ត្រាស្របនឹងតម្រងទេ។';

  @override
  String get auditLogDetailDialogTitle => 'ព័ត៌មានលម្អិតកំណត់ហេតុ';

  @override
  String get auditLogAdditionalMetadataLabel => 'មេតាដាតាបន្ថែម៖';

  @override
  String get auditLogCloseAction => 'បិទ';

  @override
  String get auditLogActorIdLabel => 'ID អ្នកធ្វើ';

  @override
  String get auditLogActorNameLabel => 'ឈ្មោះអ្នកធ្វើ';

  @override
  String get auditLogActionVerbLabel => 'សកម្មភាព';

  @override
  String get auditLogTargetTypeLabel => 'ប្រភេទគោលដៅ';

  @override
  String get auditLogTargetIdLabel => 'ID គោលដៅ';

  @override
  String get auditLogTargetLabelLabel => 'ស្លាកគោលដៅ';

  @override
  String get auditLogTimestampLabel => 'ពេលវេលា';

  @override
  String get appLockPageTitle => 'ការកំណត់ការចាក់សោកម្មវិធី';

  @override
  String get appLockDeviceProtectionHeading => 'ការការពារឧបករណ៍';

  @override
  String get appLockPinTitle => 'PIN ចាក់សោកម្មវិធី';

  @override
  String get appLockPinSubtitle => 'ត្រូវការ PIN សុវត្ថិភាព ៤–៨ ខ្ទង់នៅពេលបន្ត';

  @override
  String get appLockBiometricTitle => 'ការផ្ទៀងផ្ទាត់ជីវមាត្រ';

  @override
  String get appLockBiometricSubtitle =>
      'ប្រើ Face ID / ស្នាមម្រាមដៃជំនួសការបញ្ចូល PIN';

  @override
  String get appLockTimeoutHeading => 'ការកំណត់រយៈពេលផុតកំណត់';

  @override
  String get appLockAutoLockDurationTitle => 'រយៈពេលចាក់សោដោយស្វ័យប្រវត្តិ';

  @override
  String get appLockChangePinTitle => 'ផ្លាស់ប្ដូរ PIN ចាក់សោ';

  @override
  String get appLockChangePinSubtitle => 'ជំនួសកូដចូលសុវត្ថិភាពដែលមានស្រាប់';

  @override
  String get appLockPinUpdatedSnack => 'PIN បានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ។';

  @override
  String get appLockSetSecurePinAction => 'កំណត់ PIN សុវត្ថិភាព';

  @override
  String get appLockSavePinAction => 'រក្សាទុក PIN';

  @override
  String get appLockCannotEnableFallback => 'មិនអាចបើកដំណើរការបានទេ។';

  @override
  String get appLockLockImmediatelySubtitle => 'ចាក់សោភ្លាមៗពេលបិទផ្ទៃ';

  @override
  String appLockMinutesAfterBackgroundSubtitle(int count) {
    return '$count នាទីបន្ទាប់ពីបិទផ្ទៃ';
  }

  @override
  String get appLockRequiresPinSubtitle =>
      'ត្រូវការ App Lock PIN ឱ្យបើកដំណើរការ';

  @override
  String get appLockFootnote =>
      'PIN និងព័ត៌មានជីវមាត្ររបស់អ្នកមានសុវត្ថិភាព។ កូនសោត្រូវបានរក្សាទុកនៅក្នុង Keystore / Keychain ដែលគាំទ្រដោយផ្នែករឹង OS។ ការដកកម្មវិធី ឬលុបទិន្នន័យ នឹងកំណត់ឡើងវិញនូវការកំណត់ការចាក់សោ។';

  @override
  String get appLockAutoLockSheetSubtitle =>
      'ជ្រើសរើសរយៈពេលអនុគ្រោះមុនពេលកម្មវិធីចាក់សោ';

  @override
  String get appLockHeaderEnabledTitle => 'ការការពារកម្មវិធីបានបើក';

  @override
  String get appLockHeaderDisabledTitle => 'ការការពារកម្មវិធីបានបិទ';

  @override
  String get appLockHeaderEnabledSubtitle =>
      'ការកំណត់ឧបករណ៍របស់អ្នកតម្រូវឱ្យមានចំណុចត្រួតពិនិត្យសុវត្ថិភាពពេលចាប់ផ្ដើមឡើងវិញ។';

  @override
  String get appLockHeaderDisabledSubtitle =>
      'កំណត់ PIN សុវត្ថិភាពខាងក្រោម ដើម្បីការពារទិន្នន័យបរិស្ថាន ERP របស់អ្នក។';

  @override
  String get appLockOptionImmediately => 'ភ្លាមៗ';

  @override
  String appLockOptionMinute(int count) {
    return '$count នាទី';
  }

  @override
  String appLockOptionMinutes(int count) {
    return '$count នាទី';
  }

  @override
  String get appLockOptionImmediatelySubtitle =>
      'ចាក់សោកម្មវិធីភ្លាមៗពេលផ្លាស់ទៅផ្ទៃខាងក្រោយ';

  @override
  String appLockOptionMinuteSubtitle(int count) {
    return 'ចាក់សោកម្មវិធីបន្ទាប់ពី $count នាទីនៅផ្ទៃខាងក្រោយ';
  }

  @override
  String appLockOptionMinutesSubtitle(int count) {
    return 'ចាក់សោកម្មវិធីបន្ទាប់ពី $count នាទីនៅផ្ទៃខាងក្រោយ';
  }

  @override
  String get appLockPinFieldLabel => 'PIN (4–8 ខ្ទង់)';

  @override
  String get appLockConfirmPinLabel => 'បញ្ជាក់ PIN';

  @override
  String get apiConfigPageTitle => 'ការកំណត់រចនាសម្ព័ន្ធ API';

  @override
  String get apiConfigClustersHeading => 'ក្រុមបរិស្ថានដែលអាចប្រើបាន';

  @override
  String apiConfigSwitchedSnack(String name) {
    return 'បានប្ដូរក្រុមបរិស្ថានទៅ \"$name\"។';
  }

  @override
  String get apiConfigAddClusterAction => 'បន្ថែមក្រុម';

  @override
  String get apiConfigAddCustomClusterTitle => 'បន្ថែមក្រុមតាមតម្រូវការ';

  @override
  String get apiConfigBuiltInBadge => 'មានស្រាប់';

  @override
  String apiConfigDeletedSnack(String name) {
    return 'បានលុបក្រុមបរិស្ថាន \"$name\"។';
  }

  @override
  String get apiConfigClusterNameLabel => 'ឈ្មោះក្រុម';

  @override
  String get apiConfigClusterNameHint => 'ឧ. Asia Pacific Staging';

  @override
  String get apiConfigBaseUrlLabel => 'URL មូលដ្ឋាន';

  @override
  String get apiConfigBaseUrlHint => 'https://api-apac.tenant.example.com';

  @override
  String get apiConfigBannerWarning =>
      'ការប្ដូរក្រុមបរិស្ថាននឹងចាកចេញពីសម័យអ្នកជួលបច្ចុប្បន្ន ដើម្បីការពារកុំឱ្យបញ្ជាក់សិទ្ធិចូលឆ្លងគ្នា។';

  @override
  String get apiConfigCannotDeleteFallback => 'មិនអាចលុបបានទេ។';

  @override
  String get roleEditorPageTitle => 'តួនាទី និងសិទ្ធិ';

  @override
  String get roleEditorNewRoleAction => 'តួនាទីថ្មី';

  @override
  String get roleEditorCreateCustomRoleTitle => 'បង្កើតតួនាទីតាមតម្រូវការ';

  @override
  String get roleEditorRoleNameLabel =>
      'ឈ្មោះតួនាទី (ឧ. អ្នកគ្រប់គ្រងហិរញ្ញវត្ថុ)';

  @override
  String get roleEditorDescriptionLabel => 'ការពិពណ៌នា';

  @override
  String get roleEditorAssignScopesHeading => 'ផ្ដល់វិសាលភាពសិទ្ធិ';

  @override
  String get roleEditorCreateRoleAction => 'បង្កើតតួនាទី';

  @override
  String get roleEditorSystemBadge => 'ប្រព័ន្ធ';

  @override
  String get roleEditorPermissionScopesHeading => 'វិសាលភាពសិទ្ធិ';

  @override
  String get roleEditorDeleteRoleAction => 'លុបតួនាទី';

  @override
  String roleEditorUpdateFailedSnack(String error) {
    return 'មិនអាចធ្វើបច្ចុប្បន្នភាពសិទ្ធិបានទេ៖ $error';
  }

  @override
  String roleEditorDeleteConfirmTitle(String name) {
    return 'លុប \"$name\"?';
  }

  @override
  String get roleEditorDeleteConfirmMessage =>
      'សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ ហើយនឹងដកសិទ្ធិចេញពីអ្នកប្រើដែលបានកំណត់ទាំងអស់។';

  @override
  String get roleEditorCannotDeleteFallback => 'មិនអាចលុបបានទេ។';

  @override
  String get roleEditorDeleteAction => 'លុប';

  @override
  String get userMgmtPageTitle => 'ការគ្រប់គ្រងអ្នកប្រើ';

  @override
  String get userMgmtEmpty => 'មិនមានអ្នកប្រើស្របនឹងស្ថានភាពដែលជ្រើសរើសទេ។';

  @override
  String get userMgmtInviteUserAction => 'អញ្ជើញអ្នកប្រើ';

  @override
  String get userMgmtInviteSheetTitle => 'អញ្ជើញអ្នកប្រើថ្មី';

  @override
  String get userMgmtAssignRolesLabel => 'ផ្ដល់តួនាទី';

  @override
  String userMgmtInvitedSnack(String email) {
    return 'បានអញ្ជើញ $email';
  }

  @override
  String get userMgmtSendInvitationAction => 'ផ្ញើការអញ្ជើញ';

  @override
  String get userMgmtYouBadge => 'អ្នក';

  @override
  String get userMgmtActivateUserAction => 'ធ្វើឱ្យសកម្ម';

  @override
  String get userMgmtSuspendUserAction => 'ផ្អាកអ្នកប្រើ';

  @override
  String userMgmtStatusSetSnack(String status) {
    return 'ស្ថានភាពត្រូវបានកំណត់ទៅ $status។';
  }

  @override
  String get userMgmtFilterAll => 'ទាំងអស់';

  @override
  String get userMgmtFilterActive => 'សកម្ម';

  @override
  String get userMgmtFilterInvited => 'បានអញ្ជើញ';

  @override
  String get userMgmtFilterSuspended => 'ត្រូវបានផ្អាក';

  @override
  String get userMgmtNewUserPlaceholder => 'អ្នកប្រើថ្មី';

  @override
  String get userMgmtEmailAddressLabel => 'អាសយដ្ឋានអ៊ីមែល';

  @override
  String get userMgmtFullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get userMgmtCannotApplyFallback => 'មិនអាចអនុវត្តបានទេ។';

  @override
  String get userMgmtStatusActive => 'សកម្ម';

  @override
  String get userMgmtStatusInvited => 'បានអញ្ជើញ';

  @override
  String get userMgmtStatusSuspended => 'ត្រូវបានផ្អាក';

  @override
  String get myRolesPageTitle => 'តួនាទី និងសិទ្ធិរបស់ខ្ញុំ';

  @override
  String get myRolesGrantedTitle => 'បានផ្ដល់';

  @override
  String get myRolesNotGrantedTitle => 'មិនបានផ្ដល់';

  @override
  String get myRolesAssignedRolesLabel => 'តួនាទីដែលបានផ្ដល់';

  @override
  String myRolesSyncedAtLabel(String timestamp) {
    return 'ធ្វើសមកាលកម្ម $timestamp';
  }

  @override
  String get myRolesSearchHint => 'ស្វែងរកសិទ្ធិ...';

  @override
  String get myProfilePageTitle => 'ប្រវត្តិរូបរបស់ខ្ញុំ';

  @override
  String get myProfileUpdatedSnack => 'ប្រវត្តិរូបបានធ្វើបច្ចុប្បន្នភាព។';

  @override
  String get myProfileEditAction => 'កែសម្រួល';

  @override
  String get myProfileContactSection => 'ទំនាក់ទំនង';

  @override
  String get myProfilePersonalSection => 'ផ្ទាល់ខ្លួន';

  @override
  String get myProfileAccountSecuritySection => 'សុវត្ថិភាពគណនី';

  @override
  String get myProfilePhotoLocalSheetSubtitle =>
      'រូបថតផ្លាស់ប្ដូរតែលើឧបករណ៍នេះប៉ុណ្ណោះ។';

  @override
  String get myProfileImageReadErrorSnack =>
      'មិនអាចអានរូបភាពដែលបានជ្រើសរើសបានទេ។';

  @override
  String myProfileImagePickErrorSnack(String error) {
    return 'មិនអាចជ្រើសរូបបាន៖ $error';
  }

  @override
  String get myProfileEmployeeRowLabel => 'និយោជិក';

  @override
  String get myProfileTenureRowLabel => 'រយៈពេលបម្រើការ';

  @override
  String get myProfileLastLoginRowLabel => 'ការចូលចុងក្រោយ';

  @override
  String get myProfileEmployeeIdLabel => 'ID និយោជិក';

  @override
  String get myProfileHireDateLabel => 'កាលបរិច្ឆេទចូលបម្រើការ';

  @override
  String get myProfileBirthdateLabel => 'ថ្ងៃខែឆ្នាំកំណើត';

  @override
  String get myProfileAddressLabel => 'អាសយដ្ឋាន';

  @override
  String get myProfileEmergencyContactLabel => 'ទំនាក់ទំនងបន្ទាន់';

  @override
  String get myProfileEmergencyPhoneLabel => 'ទូរស័ព្ទបន្ទាន់';

  @override
  String get myProfileFullNameLabel => 'ឈ្មោះពេញ';

  @override
  String get myProfileSaveChangesAction => 'រក្សាទុកការផ្លាស់ប្ដូរ';

  @override
  String get myProfileChangePasswordTitle => 'ផ្លាស់ប្ដូរពាក្យសម្ងាត់';

  @override
  String get myProfileChangePasswordSubtitle =>
      'ត្រូវការពាក្យសម្ងាត់បច្ចុប្បន្ន';

  @override
  String get myProfileChangePinTitle => 'ផ្លាស់ប្ដូរ PIN';

  @override
  String get myProfileChangePinSubtitle => 'កំណត់ ឬជំនួស PIN ដោះសោរបស់អ្នក';

  @override
  String get myProfileEnableBiometricTitle => 'បើកជីវមាត្រ';

  @override
  String myProfileLastLoginAtLabel(String date) {
    return 'ការចូលចុងក្រោយ៖ $date';
  }

  @override
  String get myProfileReAuthBadge => 'ផ្ទៀងផ្ទាត់ឡើងវិញ';

  @override
  String get myProfileBiometricUnlockTitle => 'ដោះសោជីវមាត្រ';

  @override
  String get myProfileConfirmAction => 'បញ្ជាក់';

  @override
  String myProfileSaveErrorSnack(String error) {
    return 'មិនអាចរក្សាទុកការផ្លាស់ប្ដូរបានទេ៖ $error';
  }

  @override
  String get myProfileChangePhotoSheetTitle => 'ផ្លាស់ប្ដូររូបប្រវត្តិរូប';

  @override
  String get myProfileAddPhotoSheetTitle => 'បន្ថែមរូបប្រវត្តិរូប';

  @override
  String get myProfileEmailRequiresVerificationHelper =>
      'ត្រូវការការផ្ទៀងផ្ទាត់នៅអាសយដ្ឋានថ្មី';

  @override
  String get myProfilePhoneRequiresVerificationHelper =>
      'ត្រូវការការផ្ទៀងផ្ទាត់តាម SMS នៅលេខថ្មី';

  @override
  String get myProfileManagedByHrBadge => 'គ្រប់គ្រងដោយ HR';

  @override
  String get myProfileChangePasswordReAuthMessage =>
      'បញ្ចូលពាក្យសម្ងាត់បច្ចុប្បន្នឡើងវិញ ដើម្បីបញ្ជាក់ការផ្លាស់ប្ដូរនេះ។';

  @override
  String get myProfileChangePinReAuthMessage =>
      'ផ្ទៀងផ្ទាត់ឡើងវិញ មុនពេលផ្លាស់ប្ដូរ PIN។';

  @override
  String get myProfileEnableBiometricReAuthMessage =>
      'ផ្ទៀងផ្ទាត់ឡើងវិញ ដើម្បីភ្ជាប់ជីវមាត្ររបស់ឧបករណ៍ទៅកម្មវិធីនេះ។';

  @override
  String get myProfileCannotToggleBiometricFallback =>
      'មិនអាចបិទ-បើកជីវមាត្របានទេ';

  @override
  String get myProfilePasswordChangeStubSnack =>
      'ដំណើរការផ្លាស់ប្ដូរពាក្យសម្ងាត់នឹងបើកនៅទីនេះ។';

  @override
  String get myProfileCurrentPasswordLabel => 'ពាក្យសម្ងាត់បច្ចុប្បន្ន';

  @override
  String get myProfileBiometricEnabledSubtitle =>
      'ប៉ះដើម្បីបិទ — មិនត្រូវការផ្ទៀងផ្ទាត់ឡើងវិញទេ';

  @override
  String get myProfileBiometricDisabledSubtitle =>
      'ត្រូវការផ្ទៀងផ្ទាត់ឡើងវិញដើម្បីបើក';

  @override
  String get myProfileNameFieldHumanLabel => 'ឈ្មោះ';

  @override
  String get myProfileEmailFieldHumanLabel => 'អ៊ីមែល';

  @override
  String get myProfilePhoneFieldHumanLabel => 'ទូរស័ព្ទ';

  @override
  String get myProfileRelativeToday => 'ថ្ងៃនេះ';

  @override
  String get myProfileRelativeYesterday => 'ម្សិលមិញ';

  @override
  String myProfileRelativeDaysAgo(int count) {
    return '$countថ្ងៃមុន';
  }

  @override
  String myProfileRelativeWeeksAgo(int count) {
    return '$countសប្ដាហ៍មុន';
  }

  @override
  String myProfileRelativeMonthsAgo(int count) {
    return '$countខែមុន';
  }

  @override
  String myProfileRelativeYearsAgo(int count) {
    return '$countឆ្នាំមុន';
  }

  @override
  String get myProfileTenureLessThanMonth => '<1 ខែ';

  @override
  String myProfileTenureMonths(int count) {
    return '$count ខែ';
  }

  @override
  String myProfileTenureYear(int count) {
    return '$count ឆ្នាំ';
  }

  @override
  String myProfileTenureYears(int count) {
    return '$count ឆ្នាំ';
  }

  @override
  String myProfileTenureYearsMonths(int years, int months) {
    return '$yearsឆ្នាំ $monthsខែ';
  }
}
