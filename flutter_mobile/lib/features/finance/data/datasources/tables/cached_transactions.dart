import 'package:drift/drift.dart';

import 'cached_accounts.dart';

/// Drift table for ledger transaction lines (Slice 3.1.3).
///
/// `account_id` is a real FK so cascading delete on account wipe works
/// without a separate hand-written cleanup pass.
@DataClassName('CachedTransactionRow')
class CachedTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId =>
      text().references(CachedAccounts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get postedAt => dateTime()();
  TextColumn get description => text()();
  TextColumn get debit => text().nullable()();
  TextColumn get credit => text().nullable()();
  TextColumn get runningBalance => text()();
  TextColumn get reference => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
