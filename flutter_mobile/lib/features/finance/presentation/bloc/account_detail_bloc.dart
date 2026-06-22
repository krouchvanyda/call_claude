import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../entities/account.dart';
import '../../entities/transaction.dart';
import 'account_detail_event.dart';
import 'account_detail_state.dart';

/// Bloc behind [`AccountDetailPage`] (Slice 3.1.2).
///
/// **Two parallel watch streams** (account + transactions) feed
/// internal events. The bloc reconciles them in [_emitLoaded] — both
/// sides must have produced at least once before we leave the
/// `loading` state. After that, either side emitting bumps a fresh
/// `loaded` with the latest pair.
///
/// **Account-id swap support**: a second `Started` with a different
/// id cancels both subscriptions and starts fresh. Lets the same
/// page navigate between accounts without rebuilding the bloc (a
/// future "next account" arrow on the detail header would use this).
///
/// **NotFound vs Failure**: a watch emit of `null` for the account
/// means the id is genuinely absent (deleted, typo'd in the URL).
/// A stream `onError` is a transport / cache crash and surfaces as
/// `failure`.
class AccountDetailBloc
    extends Bloc<AccountDetailEvent, AccountDetailState> {
  AccountDetailBloc({
    required AccountsRepository accountsRepository,
    required TransactionsRepository transactionsRepository,
  })  : _accountsRepository = accountsRepository,
        _transactionsRepository = transactionsRepository,
        super(const AccountDetailState.initial()) {
    on<AccountDetailStarted>(_onStarted);
    on<AccountDetailAccountUpdated>(_onAccountUpdated);
    on<AccountDetailTransactionsUpdated>(_onTransactionsUpdated);
    on<AccountDetailFailed>(_onFailed);
  }

  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;

  String? _activeId;
  StreamSubscription<List<Account>>? _accountSub;
  StreamSubscription<List<LedgerTransaction>>? _txnSub;

  // Latest values from each watch — null until first emission. Both
  // must be non-null (or `_account == null` after first emit, meaning
  // not-found) before we can transition out of `loading`.
  Account? _account;
  bool _accountSeen = false;
  List<LedgerTransaction>? _transactions;

  Future<void> _onStarted(
    AccountDetailStarted event,
    Emitter<AccountDetailState> emit,
  ) async {
    if (_activeId == event.accountId) return; // idempotent
    _activeId = event.accountId;
    _account = null;
    _accountSeen = false;
    _transactions = null;
    await _accountSub?.cancel();
    await _txnSub?.cancel();
    emit(const AccountDetailState.loading());

    // The accounts repo only exposes the full-list watch — narrow it
    // to the matching id (or null) here. Cheap given the seed size;
    // Slice 3.1.3 swaps in a per-id drift query.
    _accountSub = _accountsRepository.watchAll().listen(
      (all) {
        Account? hit;
        for (final a in all) {
          if (a.id == event.accountId) {
            hit = a;
            break;
          }
        }
        add(AccountDetailEvent.accountUpdated(hit));
      },
      onError: (Object e) =>
          add(AccountDetailEvent.failed(e.toString())),
    );

    _txnSub = _transactionsRepository
        .watchByAccount(event.accountId)
        .listen(
          (list) => add(AccountDetailEvent.transactionsUpdated(list)),
          onError: (Object e) =>
              add(AccountDetailEvent.failed(e.toString())),
        );
  }

  void _onAccountUpdated(
    AccountDetailAccountUpdated event,
    Emitter<AccountDetailState> emit,
  ) {
    _account = event.account;
    _accountSeen = true;
    _emitLoaded(emit);
  }

  void _onTransactionsUpdated(
    AccountDetailTransactionsUpdated event,
    Emitter<AccountDetailState> emit,
  ) {
    _transactions = event.transactions;
    _emitLoaded(emit);
  }

  void _onFailed(
    AccountDetailFailed event,
    Emitter<AccountDetailState> emit,
  ) {
    emit(AccountDetailState.failure(event.message));
  }

  /// Fold the latest pair into a `loaded` (or `notFound`). Skips
  /// emission until both watches have produced at least once so the
  /// header doesn't flash placeholder content while transactions are
  /// still loading (or vice versa).
  void _emitLoaded(Emitter<AccountDetailState> emit) {
    if (!_accountSeen) return;
    if (_account == null) {
      emit(AccountDetailState.notFound(_activeId ?? ''));
      return;
    }
    final txns = _transactions;
    if (txns == null) return;
    emit(AccountDetailState.loaded(account: _account!, transactions: txns));
  }

  @override
  Future<void> close() async {
    await _accountSub?.cancel();
    await _txnSub?.cancel();
    return super.close();
  }
}
