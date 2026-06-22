import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../entities/account.dart';
import '../../entities/transaction.dart';
import 'tables/cached_accounts.dart';
import 'tables/cached_transactions.dart';

part 'accounts_dao.g.dart';

/// Drift DAO for the offline finance cache (Slice 3.1.3).
///
/// Owns both the accounts table AND the transactions table — they
/// share the FK + cascade delete relationship, and feature reads
/// usually combine the two.
@DriftAccessor(tables: [CachedAccounts, CachedTransactions])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  // ── Account writes / reads ────────────────────────────────────

  Future<void> upsertAccounts(Iterable<Account> accounts) {
    return batch((b) {
      for (final a in accounts) {
        b.insert(
          cachedAccounts,
          _accountToCompanion(a),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<Account>> getAllAccounts() async {
    final rows = await select(cachedAccounts).get();
    return rows.map(_accountFromRow).toList(growable: false);
  }

  Stream<List<Account>> watchAllAccounts() {
    return select(cachedAccounts).watch().map(
          (rows) => rows.map(_accountFromRow).toList(growable: false),
        );
  }

  Future<Account?> findAccountById(String id) async {
    final row = await (select(cachedAccounts)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _accountFromRow(row);
  }

  Future<int> countAccounts() async {
    final c = countAll();
    final query = selectOnly(cachedAccounts)..addColumns([c]);
    return (await query.map((r) => r.read(c) ?? 0).getSingle());
  }

  // ── Transaction writes / reads ────────────────────────────────

  Future<void> upsertTransactions(Iterable<LedgerTransaction> txns) {
    return batch((b) {
      for (final t in txns) {
        b.insert(
          cachedTransactions,
          _txnToCompanion(t),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<LedgerTransaction>> getTransactionsByAccount(String accountId) async {
    final rows = await (select(cachedTransactions)
          ..where((r) => r.accountId.equals(accountId))
          ..orderBy([(r) => OrderingTerm.desc(r.postedAt)]))
        .get();
    return rows.map(_txnFromRow).toList(growable: false);
  }

  Stream<List<LedgerTransaction>> watchTransactionsByAccount(String accountId) {
    final query = select(cachedTransactions)
      ..where((r) => r.accountId.equals(accountId))
      ..orderBy([(r) => OrderingTerm.desc(r.postedAt)]);
    return query.watch().map(
          (rows) => rows.map(_txnFromRow).toList(growable: false),
        );
  }

  /// Wipe everything — sign-out path. CASCADE on the txn FK takes
  /// care of children, so we only need to delete accounts.
  Future<void> wipeAll() async {
    await delete(cachedTransactions).go();
    await delete(cachedAccounts).go();
  }

  // ── Mapping ────────────────────────────────────────────────────

  static CachedAccountsCompanion _accountToCompanion(Account a) {
    return CachedAccountsCompanion(
      id: Value(a.id),
      code: Value(a.code),
      name: Value(a.name),
      type: Value(a.type.name),
      parentId: Value(a.parentId),
      formattedBalance: Value(a.formattedBalance),
    );
  }

  static Account _accountFromRow(CachedAccountRow r) {
    return Account(
      id: r.id,
      code: r.code,
      name: r.name,
      type: _typeFromString(r.type),
      parentId: r.parentId,
      formattedBalance: r.formattedBalance,
    );
  }

  /// Defensive parse — unrecognised type defaults to `asset` so a
  /// future server-side type addition doesn't crash the offline view.
  /// Logged at the call site if needed.
  static AccountType _typeFromString(String raw) {
    for (final t in AccountType.values) {
      if (t.name == raw) return t;
    }
    return AccountType.asset;
  }

  static CachedTransactionsCompanion _txnToCompanion(LedgerTransaction t) {
    return CachedTransactionsCompanion(
      id: Value(t.id),
      accountId: Value(t.accountId),
      postedAt: Value(t.postedAt),
      description: Value(t.description),
      debit: Value(t.debit),
      credit: Value(t.credit),
      runningBalance: Value(t.runningBalance),
      reference: Value(t.reference),
    );
  }

  static LedgerTransaction _txnFromRow(CachedTransactionRow r) {
    return LedgerTransaction(
      id: r.id,
      accountId: r.accountId,
      postedAt: r.postedAt,
      description: r.description,
      debit: r.debit,
      credit: r.credit,
      runningBalance: r.runningBalance,
      reference: r.reference,
    );
  }
}
