import 'package:freezed_annotation/freezed_annotation.dart';

import 'account.dart';

part 'trial_balance_row.freezed.dart';

/// One line of the trial balance report (Slice 3.3.2).
///
/// Server-shaped — debit / credit are pre-formatted, exactly one is
/// non-zero (the natural side for the account type). Rows where both
/// would be zero are excluded by the report builder.
@freezed
class TrialBalanceRow with _$TrialBalanceRow {
  const factory TrialBalanceRow({
    required String accountId,
    required String accountCode,
    required String accountName,
    required AccountType accountType,
    required String debit,
    required String credit,
  }) = _TrialBalanceRow;
}
