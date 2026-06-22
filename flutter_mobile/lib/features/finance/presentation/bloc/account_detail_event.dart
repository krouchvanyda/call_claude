import 'package:freezed_annotation/freezed_annotation.dart';

import '../../entities/account.dart';
import '../../entities/transaction.dart';

part 'account_detail_event.freezed.dart';

/// Inputs to [AccountDetailBloc] (Slice 3.1.2).
///
/// One public event (`Started`) — everything else is internal: the bloc
/// owns its account + transactions watch subscriptions and feeds itself
/// via the `Updated` / `Failed` events when those streams emit.
@freezed
sealed class AccountDetailEvent with _$AccountDetailEvent {
  /// Open the page for [accountId]. Idempotent — a second `Started`
  /// for the same id is a no-op; one with a different id swaps the
  /// active subscription so the same page can navigate between
  /// accounts without rebuilding the bloc.
  const factory AccountDetailEvent.started(String accountId) =
      AccountDetailStarted;

  /// Internal — the account watch emitted a fresh value. `null` means
  /// the id no longer exists in the cache (deleted server-side).
  const factory AccountDetailEvent.accountUpdated(Account? account) =
      AccountDetailAccountUpdated;

  /// Internal — the transactions watch emitted a fresh list.
  const factory AccountDetailEvent.transactionsUpdated(
    List<LedgerTransaction> transactions,
  ) = AccountDetailTransactionsUpdated;

  /// Internal — either watch errored.
  const factory AccountDetailEvent.failed(String message) =
      AccountDetailFailed;
}
