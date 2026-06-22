import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/finance/data/datasources/accounts_dao.dart';
import 'package:erp_mobile/features/finance/entities/account.dart';
import 'package:erp_mobile/features/finance/entities/transaction.dart';
import 'package:test/test.dart';

const _root = Account(
  id: 'a-1000',
  code: '1000',
  name: 'Assets',
  type: AccountType.asset,
);

const _child = Account(
  id: 'a-1110',
  code: '1110',
  name: 'Operating bank',
  type: AccountType.asset,
  parentId: 'a-1000',
  formattedBalance: r'$48,210.00',
);

LedgerTransaction _txn(String id, {String accountId = 'a-1110'}) =>
    LedgerTransaction(
      id: id,
      accountId: accountId,
      postedAt: DateTime.utc(2026, 5, 12),
      description: 't-$id',
      debit: r'$100.00',
      runningBalance: r'$100.00',
    );

void main() {
  late AppDatabase db;
  late AccountsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.accountsDao;
  });

  tearDown(() => db.close());

  group('upsertAccounts + getAllAccounts', () {
    test('round-trips every field including AccountType enum + parentId',
        () async {
      await dao.upsertAccounts([_root, _child]);

      final all = await dao.getAllAccounts();
      expect(all, hasLength(2));
      final child = all.firstWhere((a) => a.id == 'a-1110');
      expect(child.code, '1110');
      expect(child.type, AccountType.asset);
      expect(child.parentId, 'a-1000');
      expect(child.formattedBalance, r'$48,210.00');
    });

    test('upsert by id replaces an existing row in place', () async {
      await dao.upsertAccounts([_root]);
      await dao.upsertAccounts([
        _root.copyWith(name: 'Assets — renamed'),
      ]);
      final all = await dao.getAllAccounts();
      expect(all, hasLength(1));
      expect(all.single.name, 'Assets — renamed');
    });

    test('countAccounts returns 0 on a fresh table', () async {
      expect(await dao.countAccounts(), 0);
      await dao.upsertAccounts([_root, _child]);
      expect(await dao.countAccounts(), 2);
    });

    test('findAccountById returns null for unknown id', () async {
      await dao.upsertAccounts([_root]);
      expect(await dao.findAccountById('phantom'), isNull);
      expect((await dao.findAccountById('a-1000'))?.code, '1000');
    });
  });

  group('watchAllAccounts', () {
    test('emits a fresh snapshot on each write', () async {
      final emitted = <List<Account>>[];
      final sub = dao.watchAllAccounts().listen(emitted.add);

      await pumpEventQueue();
      await dao.upsertAccounts([_root]);
      await pumpEventQueue();
      await dao.upsertAccounts([_child]);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.first, isEmpty);
      expect(emitted.last, hasLength(2));
    });
  });

  group('transactions', () {
    test('upsert + watch emits newest-first ordering', () async {
      await dao.upsertAccounts([_root, _child]);

      // Older + newer in mixed insertion order — the query must sort.
      final older = LedgerTransaction(
        id: 'older',
        accountId: 'a-1110',
        postedAt: DateTime.utc(2026, 5, 1),
        description: 'older',
        debit: r'$1.00',
        runningBalance: r'$1.00',
      );
      final newer = LedgerTransaction(
        id: 'newer',
        accountId: 'a-1110',
        postedAt: DateTime.utc(2026, 5, 12),
        description: 'newer',
        credit: r'$2.00',
        runningBalance: r'$3.00',
      );
      await dao.upsertTransactions([older, newer]);

      final list = await dao.getTransactionsByAccount('a-1110');
      expect(list.map((t) => t.id), ['newer', 'older']);
    });

    test('watch is per-account — other accounts do not appear', () async {
      const sibling = Account(
        id: 'a-1120',
        code: '1120',
        name: 'Petty cash',
        type: AccountType.asset,
        parentId: 'a-1100',
      );
      await dao.upsertAccounts([_root, _child, sibling]);
      await dao.upsertTransactions([
        _txn('on-target', accountId: 'a-1110'),
        _txn('off-target', accountId: 'a-1120'),
      ]);

      expect(
        (await dao.getTransactionsByAccount('a-1110')).map((t) => t.id),
        ['on-target'],
      );
    });

    test('CASCADE delete: wipeAll clears both tables', () async {
      await dao.upsertAccounts([_root, _child]);
      await dao.upsertTransactions([_txn('t1')]);

      await dao.wipeAll();

      expect(await dao.getAllAccounts(), isEmpty);
      expect(
        await dao.getTransactionsByAccount('a-1110'),
        isEmpty,
      );
    });
  });
}
