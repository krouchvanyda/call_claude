import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:erp_mobile/features/finance/data/repositories/accounts_repository.dart';
import 'package:erp_mobile/features/finance/data/repositories/transactions_repository.dart';
import 'package:erp_mobile/features/finance/entities/account.dart';
import 'package:erp_mobile/features/finance/entities/transaction.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/account_detail_bloc.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/account_detail_event.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/account_detail_state.dart';
import 'package:test/test.dart';

class _FakeAccountsRepo implements AccountsRepository {
  final _ctrl = StreamController<List<Account>>.broadcast();

  void emit(List<Account> snapshot) => _ctrl.add(snapshot);
  void emitError(Object e) => _ctrl.addError(e);

  @override
  Stream<List<Account>> watchAll() => _ctrl.stream;

  @override
  Future<List<Account>> getAll() async => const [];

  @override
  Future<Account?> findById(String id) async => null;

  Future<void> close() => _ctrl.close();
}

class _FakeTxnsRepo implements TransactionsRepository {
  // Per-account broadcast controllers — created on first watch.
  final Map<String, StreamController<List<LedgerTransaction>>> _byAccount = {};

  StreamController<List<LedgerTransaction>> _ctrl(String accountId) =>
      _byAccount.putIfAbsent(
        accountId,
        () => StreamController<List<LedgerTransaction>>.broadcast(),
      );

  void emit(String accountId, List<LedgerTransaction> snapshot) =>
      _ctrl(accountId).add(snapshot);

  void emitError(String accountId, Object e) =>
      _ctrl(accountId).addError(e);

  @override
  Stream<List<LedgerTransaction>> watchByAccount(String accountId) =>
      _ctrl(accountId).stream;

  @override
  Future<List<LedgerTransaction>> getByAccount(String accountId) async =>
      const [];

  Future<void> close() async {
    for (final c in _byAccount.values) {
      if (!c.isClosed) await c.close();
    }
  }
}

const _account = Account(
  id: 'a-1110',
  code: '1110',
  name: 'Operating bank',
  type: AccountType.asset,
  parentId: 'a-1100',
  formattedBalance: r'$48,210.00',
);

LedgerTransaction _t(String id) => LedgerTransaction(
      id: id,
      accountId: 'a-1110',
      postedAt: DateTime.utc(2026, 5, 12),
      description: 't-$id',
      debit: r'$100.00',
      runningBalance: r'$100.00',
    );

void main() {
  late _FakeAccountsRepo accounts;
  late _FakeTxnsRepo txns;

  setUp(() {
    accounts = _FakeAccountsRepo();
    txns = _FakeTxnsRepo();
  });

  tearDown(() async {
    await accounts.close();
    await txns.close();
  });

  group('AccountDetailBloc', () {
    test('initial state is Initial', () {
      final bloc = AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      );
      expect(bloc.state, const AccountDetailState.initial());
    });

    blocTest<AccountDetailBloc, AccountDetailState>(
      'Started → Loading; Loaded only after BOTH watches have produced',
      build: () => AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      ),
      act: (bloc) async {
        bloc.add(const AccountDetailEvent.started('a-1110'));
        await Future<void>.delayed(Duration.zero);
        // Account watch emits first.
        accounts.emit([_account]);
        await Future<void>.delayed(Duration.zero);
        // Bloc must NOT emit Loaded yet — txns watch hasn't fired.
        // (locked by the expected list below)
        txns.emit('a-1110', [_t('1'), _t('2')]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountDetailState.loading(),
        // Single Loaded emit, after both sides have contributed.
        isA<AccountDetailLoaded>()
            .having((s) => s.account.id, 'account id', 'a-1110')
            .having((s) => s.transactions.length, 'txns', 2),
      ],
    );

    blocTest<AccountDetailBloc, AccountDetailState>(
      'account watch emits null (id absent) → NotFound, not Loaded',
      build: () => AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      ),
      act: (bloc) async {
        bloc.add(const AccountDetailEvent.started('a-phantom'));
        await Future<void>.delayed(Duration.zero);
        // Repo emits a list NOT containing the requested id.
        accounts.emit([_account]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountDetailState.loading(),
        isA<AccountDetailNotFound>()
            .having((s) => s.accountId, 'asked id', 'a-phantom'),
      ],
    );

    blocTest<AccountDetailBloc, AccountDetailState>(
      'transaction watch emits a fresh list → fresh Loaded with new txns',
      build: () => AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      ),
      act: (bloc) async {
        bloc.add(const AccountDetailEvent.started('a-1110'));
        await Future<void>.delayed(Duration.zero);
        accounts.emit([_account]);
        txns.emit('a-1110', [_t('1')]);
        await Future<void>.delayed(Duration.zero);
        // New txn arrives — bloc must re-emit.
        txns.emit('a-1110', [_t('1'), _t('2'), _t('3')]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountDetailState.loading(),
        isA<AccountDetailLoaded>()
            .having((s) => s.transactions.length, 'first', 1),
        isA<AccountDetailLoaded>()
            .having((s) => s.transactions.length, 'second', 3),
      ],
    );

    blocTest<AccountDetailBloc, AccountDetailState>(
      'either watch erroring → Failure (transport crash, distinct from NotFound)',
      build: () => AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      ),
      act: (bloc) async {
        bloc.add(const AccountDetailEvent.started('a-1110'));
        await Future<void>.delayed(Duration.zero);
        accounts.emitError(StateError('cache closed'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountDetailState.loading(),
        isA<AccountDetailFailure>()
            .having((s) => s.message, 'msg', contains('cache closed')),
      ],
    );

    blocTest<AccountDetailBloc, AccountDetailState>(
      'second Started with the SAME id is a no-op (idempotent)',
      build: () => AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      ),
      act: (bloc) async {
        bloc.add(const AccountDetailEvent.started('a-1110'));
        await Future<void>.delayed(Duration.zero);
        accounts.emit([_account]);
        txns.emit('a-1110', [_t('1')]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountDetailEvent.started('a-1110'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountDetailState.loading(),
        isA<AccountDetailLoaded>(),
        // No second Loading — the idempotency guard returns early.
      ],
    );

    blocTest<AccountDetailBloc, AccountDetailState>(
      'second Started with a DIFFERENT id resets to Loading',
      build: () => AccountDetailBloc(
        accountsRepository: accounts,
        transactionsRepository: txns,
      ),
      act: (bloc) async {
        bloc.add(const AccountDetailEvent.started('a-1110'));
        await Future<void>.delayed(Duration.zero);
        accounts.emit([_account]);
        txns.emit('a-1110', [_t('1')]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountDetailEvent.started('a-1200'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountDetailState.loading(),
        isA<AccountDetailLoaded>(),
        const AccountDetailState.loading(),
      ],
    );
  });
}
