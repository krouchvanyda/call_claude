import 'package:get_it/get_it.dart';

import '../../core/database/sync_queue_dao.dart';
import '../../core/router/permissions_snapshot.dart';
import '../../core/utils/logger/app_logger.dart';
import '../auth/permission_gate.dart';
import 'data/datasources/accounts_dao.dart';
import 'data/datasources/invoices_dao.dart';
import 'data/repositories/accounts_repository.dart';
import 'data/repositories/invoices_repository.dart';
import 'data/repositories/journal_entries_repository.dart';
import 'data/repositories/transactions_repository.dart';
import 'data/repositories/trial_balance_repository.dart';
import 'presentation/bloc/account_detail_bloc.dart';
import 'presentation/bloc/account_tree_bloc.dart';
import 'presentation/bloc/invoice_action_bloc.dart';
import 'presentation/bloc/invoice_list_bloc.dart';

/// Manual DI registration for Module 3 (Finance & Accounting).
///
/// Same pattern as Modules 1–2 and 4–9: avoids re-running build_runner
/// per repo tweak. Call once from `main.dart` after
/// `configureDependencies()` has wired the finance datasources (the
/// `AccountsDao` / `InvoicesDao` drift bindings, plus the upstream
/// `SyncQueueDao` and `PermissionsSnapshot`) via `register_module.dart`.
///
/// Flat MVVM: the four invoice-workflow operations (approve / reject /
/// submit / reopen) are free top-level functions living in
/// `invoices_repository.dart` — no use-case classes to register.
void registerFinanceModule(GetIt getIt) {
  // Slice 3.2.4 — wire the abstract [PermissionGate] (consumed by the
  // invoice action bloc + the workflow free fns) to the concrete
  // in-memory snapshot the router listens to. Keeps the workflow code
  // Flutter-free per the layering rule.
  if (!getIt.isRegistered<PermissionGate>()) {
    getIt.registerLazySingleton<PermissionGate>(
      () => getIt<PermissionsSnapshot>(),
    );
  }

  // Phase 3.1 — chart of accounts + transactions.
  if (!getIt.isRegistered<AccountsRepository>()) {
    getIt.registerLazySingleton<AccountsRepository>(
      () => AccountsRepository(dao: getIt<AccountsDao>()),
    );
  }
  if (!getIt.isRegistered<TransactionsRepository>()) {
    getIt.registerLazySingleton<TransactionsRepository>(
      () => TransactionsRepository(
        dao: getIt<AccountsDao>(),
        accountsRepository: getIt<AccountsRepository>(),
      ),
    );
  }

  // Phase 3.2 — invoices (header + approval workflow).
  if (!getIt.isRegistered<InvoicesRepository>()) {
    getIt.registerLazySingleton<InvoicesRepository>(
      () => InvoicesRepository(
        dao: getIt<InvoicesDao>(),
        syncQueue: getIt<SyncQueueDao>(),
      ),
    );
  }

  // Phase 3.3 — general ledger + trial balance (stub-backed for now).
  if (!getIt.isRegistered<JournalEntriesRepository>()) {
    getIt.registerLazySingleton<JournalEntriesRepository>(
      JournalEntriesRepository.new,
    );
  }
  if (!getIt.isRegistered<TrialBalanceRepository>()) {
    getIt.registerLazySingleton<TrialBalanceRepository>(
      () => TrialBalanceRepository(accounts: getIt<AccountsRepository>()),
    );
  }

  // ── Blocs (factories — fresh instance per page mount) ────────────
  if (!getIt.isRegistered<AccountTreeBloc>()) {
    getIt.registerFactory<AccountTreeBloc>(
      () => AccountTreeBloc(
        repository: getIt<AccountsRepository>(),
        logger: getIt<AppLogger>().child('accounts'),
      ),
    );
  }
  if (!getIt.isRegistered<AccountDetailBloc>()) {
    getIt.registerFactory<AccountDetailBloc>(
      () => AccountDetailBloc(
        accountsRepository: getIt<AccountsRepository>(),
        transactionsRepository: getIt<TransactionsRepository>(),
      ),
    );
  }
  if (!getIt.isRegistered<InvoiceListBloc>()) {
    getIt.registerFactory<InvoiceListBloc>(
      () => InvoiceListBloc(repository: getIt<InvoicesRepository>()),
    );
  }
  if (!getIt.isRegistered<InvoiceActionBloc>()) {
    getIt.registerFactory<InvoiceActionBloc>(
      () => InvoiceActionBloc(
        invoices: getIt<InvoicesRepository>(),
        permissions: getIt<PermissionGate>(),
      ),
    );
  }
}
