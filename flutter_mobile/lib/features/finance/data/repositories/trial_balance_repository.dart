import '../../entities/account.dart';
import '../../entities/trial_balance_row.dart';
import 'accounts_repository.dart';

/// Builds a trial balance report off the chart-of-accounts seed
/// (Slice 3.3.2). Flat MVVM: single concrete repo — no abstract
/// interface. The pure pagination helpers ([`paginate`] / [`pageCount`])
/// live as free top-level functions at the bottom of this file.
///
/// **Why composes the accounts repo instead of seeding fresh**: keeps
/// the demo numbers consistent — an account's `formattedBalance` shown
/// in the tree view (Slice 3.1.1) matches its row in the report.
/// Real impl will hit a server-side aggregator that respects period
/// boundaries.
///
/// **Stub-backed**: no drift table yet — when one lands, swap the
/// internal accounts-roll-up for a DAO call and keep this class's
/// public shape.
class TrialBalanceRepository {
  TrialBalanceRepository({required AccountsRepository accounts})
      : _accounts = accounts;

  final AccountsRepository _accounts;

  Future<List<TrialBalanceRow>> getReport() async {
    final all = await _accounts.getAll();
    final rows = <TrialBalanceRow>[];
    // Roll up only leaf accounts (those with a formatted balance).
    // Roll-ups would aggregate children — out of scope for the stub.
    for (final a in all) {
      final bal = a.formattedBalance;
      if (bal == null) continue;
      final isDebitNormal = a.type == AccountType.asset ||
          a.type == AccountType.expense;
      rows.add(TrialBalanceRow(
        accountId: a.id,
        accountCode: a.code,
        accountName: a.name,
        accountType: a.type,
        debit: isDebitNormal ? bal : r'$0.00',
        credit: isDebitNormal ? r'$0.00' : bal,
      ));
    }
    rows.sort((x, y) => x.accountCode.compareTo(y.accountCode));
    return rows;
  }
}

// ── Pure pagination helpers ──────────────────────────────────────────
//
// Pulled in from the former `domain/usecases/paginate.dart`. Used by
// the trial balance page (Slice 3.3.2) — the only call site in the
// app, so keeping it module-internal here is fine.

/// Pure-Dart pagination slicer (Slice 3.3.2).
///
/// Returns the page-sized slice of [items] for the given 0-indexed
/// [pageIndex]. Out-of-range pages return empty (not an error) so the
/// UI can degrade gracefully when the user lingers on the last page
/// while the underlying list shrinks.
///
/// **Why not `items.skip(...).take(...)`**: the eager `toList` fixes
/// the result to a non-growable view, which is what the renderer wants.
List<T> paginate<T>(List<T> items, {required int pageIndex, required int pageSize}) {
  if (pageSize <= 0) {
    throw ArgumentError.value(pageSize, 'pageSize', 'must be > 0');
  }
  if (pageIndex < 0) {
    throw ArgumentError.value(pageIndex, 'pageIndex', 'must be >= 0');
  }
  final start = pageIndex * pageSize;
  if (start >= items.length) return const [];
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

/// Total number of pages required to fit [totalItems] at [pageSize].
/// Always at least 1 (so a "page 1 of 1" header still renders for
/// empty lists).
int pageCount({required int totalItems, required int pageSize}) {
  if (pageSize <= 0) {
    throw ArgumentError.value(pageSize, 'pageSize', 'must be > 0');
  }
  if (totalItems <= 0) return 1;
  return (totalItems + pageSize - 1) ~/ pageSize;
}
