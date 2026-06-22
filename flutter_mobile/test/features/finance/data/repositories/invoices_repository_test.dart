import 'dart:convert';

import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/database/sync_queue_dao.dart';
import 'package:erp_mobile/features/finance/data/datasources/invoices_dao.dart';
import 'package:erp_mobile/features/finance/data/invoice_seed.dart';
import 'package:erp_mobile/features/finance/data/repositories/invoices_repository.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late InvoicesDao dao;
  late SyncQueueDao syncQueue;
  late InvoicesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.invoicesDao;
    syncQueue = db.syncQueueDao;
    repo = InvoicesRepository(dao: dao, syncQueue: syncQueue);
  });

  tearDown(() => db.close());

  group('lazy seed', () {
    test(
        'first read writes the InvoiceSeed.headers when the table is empty',
        () async {
      expect(await dao.countInvoices(), 0);

      final all = await repo.getAll();
      expect(all, hasLength(InvoiceSeed.headers.length));

      // Audit fields from the seed survive the round-trip.
      final approved = all.firstWhere((i) => i.id == 'inv-014');
      expect(approved.status, InvoiceStatus.approved);
      expect(approved.approvedBy, 'user-seed-mgr');
      expect(approved.actionedAt, isNotNull);

      final rejected = all.firstWhere((i) => i.id == 'inv-013');
      expect(rejected.status, InvoiceStatus.rejected);
      expect(rejected.rejectedReason, isNotNull);
    });

    test('second read does NOT re-seed (idempotent bootstrap)', () async {
      await repo.getAll();
      final firstCount = await dao.countInvoices();

      await repo.getAll();
      expect(await dao.countInvoices(), firstCount);
    });

    test('non-empty table on first read skips seeding entirely', () async {
      // Pre-populate with a single different row.
      await dao.upsertWithDetail(
        header: Invoice(
          id: 'inv-existing',
          invoiceNumber: 'EXISTING',
          customerName: 'X',
          issuedAt: DateTime.utc(2026, 5, 1),
          dueAt: DateTime.utc(2026, 6, 1),
          status: InvoiceStatus.draft,
          totalAmount: r'$1',
        ),
      );
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'inv-existing');
    });
  });

  group('findDetailById', () {
    test('seeded invoice with lines returns the cached lines', () async {
      final d = await repo.findDetailById('inv-014');
      expect(d, isNotNull);
      expect(d!.lineItems, isNotEmpty);
      expect(d.subtotal, r'$8,000.00');
      expect(d.notes, isNotNull);
    });

    test(
        'seeded invoice WITHOUT lines synthesises a single-line detail '
        '(fallback for inv-016 etc)',
        () async {
      final d = await repo.findDetailById('inv-016');
      expect(d, isNotNull);
      expect(d!.lineItems, hasLength(1));
      expect(d.lineItems.single.lineTotal, d.header.totalAmount);
    });

    test('unknown id → null', () async {
      expect(await repo.findDetailById('nope'), isNull);
    });
  });

  group('approve / reject / SyncQueue enqueue', () {
    test('approve writes audit fields AND enqueues a PATCH sync op',
        () async {
      final t = DateTime.utc(2026, 5, 13, 10);
      final out = await repo.approve(
        invoiceId: 'inv-015',
        approverId: 'u-99',
        actionedAt: t,
      );
      expect(out.status, InvoiceStatus.approved);
      expect(out.approvedBy, 'u-99');
      // Drift normalises to epoch seconds → local-flagged DateTime on
      // read; same instant, just not isUtc.
      expect(out.actionedAt!.isAtSameMomentAs(t), isTrue);

      // SyncQueue captured the PATCH.
      final pending = await syncQueue.pendingReady();
      expect(pending, hasLength(1));
      final op = pending.single;
      expect(op.entityType, 'invoice');
      expect(op.entityId, 'inv-015');
      expect(op.endpointMethod, 'PATCH');
      expect(op.endpointPath, '/invoices/inv-015/approve');
      expect(jsonDecode(op.payloadJson)['approver_id'], 'u-99');
    });

    test('reject enqueues PATCH with the reason in payload', () async {
      final out = await repo.reject(
        invoiceId: 'inv-015',
        approverId: 'u-99',
        reason: 'over budget',
        actionedAt: DateTime.utc(2026, 5, 13),
      );
      expect(out.status, InvoiceStatus.rejected);

      final pending = await syncQueue.pendingReady();
      expect(pending, hasLength(1));
      final payload = jsonDecode(pending.single.payloadJson) as Map;
      expect(payload['reason'], 'over budget');
      expect(payload['approver_id'], 'u-99');
    });

    test('submit + reopen do NOT enqueue (no privileged action)', () async {
      await repo.submitForApproval(
        invoiceId: 'inv-017',
        actionedAt: DateTime.utc(2026, 5, 13),
      );
      await repo.reject(
        invoiceId: 'inv-017',
        approverId: 'u',
        reason: 'try again',
        actionedAt: DateTime.utc(2026, 5, 14),
      );
      // Snapshot before reopen — only the reject is enqueued.
      final before = (await syncQueue.pendingReady()).length;

      await repo.reopen(
        invoiceId: 'inv-017',
        actionedAt: DateTime.utc(2026, 5, 15),
      );
      final after = (await syncQueue.pendingReady()).length;
      expect(after, before,
          reason: 'reopen is not a privileged action and shouldn\'t '
              'hit the sync queue');
    });

    test('watchAll re-emits after a mutation', () async {
      final emitted = <List<Invoice>>[];
      final sub = repo.watchAll().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await repo.approve(
        invoiceId: 'inv-016',
        approverId: 'u',
        actionedAt: DateTime.utc(2026, 5, 13),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted.length, greaterThanOrEqualTo(2));
      final approvedAfter = emitted.last
          .where((i) => i.id == 'inv-016' && i.status == InvoiceStatus.approved)
          .length;
      expect(approvedAfter, 1);
      await sub.cancel();
    });
  });
}
