import '../../entities/transaction.dart';
import '../datasources/accounts_dao.dart';
import '../finance_seed.dart';
import 'accounts_repository.dart';

/// Drift-backed ledger transactions repository (Slice 3.1.2 / 3.1.3).
/// Flat MVVM: single concrete repo — no abstract interface.
///
/// **Per-account watch as the primary read** — the detail page reads
/// only one account at a time, so a query indexed by `accountId` is
/// the cheap path. A future "all activity" inbox would add a separate
/// global watch rather than overload this one.
///
/// **Newest-first ordering** is the source's responsibility (drift
/// `ORDER BY postedAt DESC` in Slice 3.1.3); the bloc / page render
/// in the order received.
///
/// Same lazy-bootstrap pattern as [AccountsRepository]. Seeded from
/// [`FinanceSeed.transactions`] so the chart-of-accounts demo stays
/// populated across cold starts. The DAO's `account_id` FK requires the
/// accounts seed to land first — bootstrap forces that via a `getAll()`
/// on the injected [AccountsRepository].
class TransactionsRepository {
  TransactionsRepository({
    required AccountsDao dao,
    required AccountsRepository accountsRepository,
  })  : _dao = dao,
        _accountsRepository = accountsRepository;

  final AccountsDao _dao;
  final AccountsRepository _accountsRepository;
  Future<void>? _bootstrap;

  Future<void> _ensureBootstrapped() {
    return _bootstrap ??= _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    // Accounts must exist first — FK constraint.
    await _accountsRepository.getAll();
    // Reuse the dao's per-account query as a cheap "is the seed in?"
    // probe — we know one of the seed account ids has lines.
    final probe = await _dao.getTransactionsByAccount('a-1110');
    if (probe.isNotEmpty) return;
    await _dao.upsertTransactions(FinanceSeed.transactions);
  }

  /// One-shot snapshot of every line posted against [accountId].
  Future<List<LedgerTransaction>> getByAccount(String accountId) async {
    await _ensureBootstrapped();
    return _dao.getTransactionsByAccount(accountId);
  }

  /// Reactive variant — emits a fresh list whenever a line is posted /
  /// reversed / cached for [accountId]. Drives the detail page so a
  /// real-time push updates the table without manual refresh.
  Stream<List<LedgerTransaction>> watchByAccount(String accountId) async* {
    await _ensureBootstrapped();
    yield* _dao.watchTransactionsByAccount(accountId);
  }
}
