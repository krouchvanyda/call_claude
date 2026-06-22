import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../entities/account.dart';

/// Maps an [AccountType] to its on-screen icon + localised label
/// (Slice 3.1.1).
///
/// **Why a function not a method on the enum**: keeps the domain enum
/// Flutter-free (`IconData` is a Flutter type). The widget calls this
/// at the boundary; tests assert the icon's `codePoint` is distinct
/// per type without dragging the broken local SDK in via the enum.
IconData accountTypeIcon(AccountType type) {
  return switch (type) {
    AccountType.asset => Icons.savings_outlined,
    AccountType.liability => Icons.credit_card_outlined,
    AccountType.equity => Icons.account_balance_outlined,
    AccountType.revenue => Icons.trending_up,
    AccountType.expense => Icons.trending_down,
  };
}

/// Localised label — used in the tree tile's category chip and the
/// future account-detail header.
String accountTypeLabel(AppLocalizations l10n, AccountType type) {
  return switch (type) {
    AccountType.asset => l10n.accountTypeAsset,
    AccountType.liability => l10n.accountTypeLiability,
    AccountType.equity => l10n.accountTypeEquity,
    AccountType.revenue => l10n.accountTypeRevenue,
    AccountType.expense => l10n.accountTypeExpense,
  };
}
