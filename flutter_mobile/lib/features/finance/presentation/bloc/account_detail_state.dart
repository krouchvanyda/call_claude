import 'package:freezed_annotation/freezed_annotation.dart';

import '../../entities/account.dart';
import '../../entities/transaction.dart';

part 'account_detail_state.freezed.dart';

/// State machine for [AccountDetailBloc] (Slice 3.1.2).
///
/// **Why a dedicated `notFound` state**: distinct from `failure` —
/// hitting `/finance/accounts/phantom` is a user-facing "this account
/// doesn't exist" condition, not a transport / cache crash. Lets the
/// UI render a friendly recovery hint instead of a stack-tracey error.
///
/// **`Loaded` carries both halves**: the account header AND the
/// transactions list. Either watch could emit independently, so the
/// state holds the latest of each; the bloc emits a fresh `Loaded`
/// each time either side changes.
@freezed
sealed class AccountDetailState with _$AccountDetailState {
  const factory AccountDetailState.initial() = AccountDetailInitial;

  const factory AccountDetailState.loading() = AccountDetailLoading;

  const factory AccountDetailState.loaded({
    required Account account,
    required List<LedgerTransaction> transactions,
  }) = AccountDetailLoaded;

  const factory AccountDetailState.notFound(String accountId) =
      AccountDetailNotFound;

  const factory AccountDetailState.failure(String message) =
      AccountDetailFailure;
}
