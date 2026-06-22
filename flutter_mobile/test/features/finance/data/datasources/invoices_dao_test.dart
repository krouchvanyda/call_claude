import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/finance/data/datasources/invoices_dao.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:erp_mobile/features/finance/entities/invoice_detail.dart';
import 'package:erp_mobile/features/finance/entities/invoice_line_item.dart';
import 'package:test/test.dart';

Invoice _header({
  String id = 'inv-1',
  InvoiceStatus status = InvoiceStatus.pendingApproval,
  DateTime? issuedAt,
  String totalAmount = r'$100.00',
  String? approvedBy,
  String? rejectedBy,
  String? rejectedReason,
  DateTime? actionedAt,
}) =>
    Invoice(
      id: id,
      invoiceNumber: id.toUpperCase(),
      customerName: 'Acme',
      issuedAt: issuedAt ?? DateTime.utc(2026, 5, 1),
      dueAt: DateTime.utc(2026, 6, 1),
      status: status,
      totalAmount: totalAmount,
      approvedBy: approvedBy,
      rejectedBy: rejectedBy,
      rejectedReason: rejectedReason,
      actionedAt: actionedAt,
    );

InvoiceDetail _detail(Invoice header, {List<InvoiceLineItem>? lines}) =>
    InvoiceDetail(
      header: header,
      subtotal: r'$80.00',
      tax: r'$20.00',
      notes: 'Net 30',
      lineItems: lines ??
          const [
            InvoiceLineItem(
              id: 'li-a',
              description: 'Widget',
              sku: 'WID',
              quantity: 2,
              unitPrice: r'$40.00',
              lineTotal: r'$80.00',
            ),
          ],
    );

void main() {
  late AppDatabase db;
  late InvoicesDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.invoicesDao;
  });

  tearDown(() => db.close());

  group('upsertWithDetail + reads', () {
    test('round-trips every header field including audit columns', () async {
      final h = _header(
        id: 'inv-1',
        status: InvoiceStatus.approved,
        approvedBy: 'u-mgr',
        actionedAt: DateTime.utc(2026, 5, 10, 12),
      );
      await dao.upsertWithDetail(header: h);

      final found = await dao.findInvoiceById('inv-1');
      expect(found, isNotNull);
      expect(found!.status, InvoiceStatus.approved);
      expect(found.approvedBy, 'u-mgr');
      // Drift stores DateTimes as epoch seconds and returns a local
      // DateTime — compare by moment, not isUtc.
      expect(
        found.actionedAt!.isAtSameMomentAs(DateTime.utc(2026, 5, 10, 12)),
        isTrue,
      );
      expect(found.rejectedBy, isNull);
      expect(found.rejectedReason, isNull);
    });

    test('round-trips reject audit fields independently', () async {
      final h = _header(
        id: 'inv-r',
        status: InvoiceStatus.rejected,
        rejectedBy: 'u-mgr',
        rejectedReason: 'over budget',
        actionedAt: DateTime.utc(2026, 5, 10),
      );
      await dao.upsertWithDetail(header: h);
      final got = (await dao.findInvoiceById('inv-r'))!;
      expect(got.rejectedReason, 'over budget');
      expect(got.rejectedBy, 'u-mgr');
      expect(got.approvedBy, isNull);
    });

    test('getAllInvoices orders newest issuedAt first', () async {
      await dao.upsertWithDetail(
        header: _header(id: 'old', issuedAt: DateTime.utc(2026, 4, 1)),
      );
      await dao.upsertWithDetail(
        header: _header(id: 'new', issuedAt: DateTime.utc(2026, 6, 1)),
      );
      final all = await dao.getAllInvoices();
      expect(all.map((i) => i.id), ['new', 'old']);
    });

    test('findDetailById returns header + lines + subtotal/tax/notes',
        () async {
      final h = _header();
      await dao.upsertWithDetail(header: h, detail: _detail(h));

      final got = await dao.findDetailById('inv-1');
      expect(got, isNotNull);
      expect(got!.subtotal, r'$80.00');
      expect(got.tax, r'$20.00');
      expect(got.notes, 'Net 30');
      expect(got.lineItems, hasLength(1));
      expect(got.lineItems.single.description, 'Widget');
    });

    test('upserting with a new detail wipes prior lines (no leaks)', () async {
      final h = _header();
      await dao.upsertWithDetail(header: h, detail: _detail(h));

      // Replace with a single-line, different-sku detail.
      await dao.upsertWithDetail(
        header: h,
        detail: _detail(h, lines: const [
          InvoiceLineItem(
            id: 'li-z',
            description: 'Replacement',
            quantity: 1,
            unitPrice: r'$50.00',
            lineTotal: r'$50.00',
          ),
        ]),
      );
      final got = await dao.findDetailById('inv-1');
      expect(got!.lineItems.map((l) => l.id), ['li-z']);
    });

    test('lines preserve [position] order regardless of insert order',
        () async {
      final h = _header();
      await dao.upsertWithDetail(
        header: h,
        detail: _detail(h, lines: const [
          InvoiceLineItem(
            id: 'li-3',
            description: 'C',
            quantity: 1,
            unitPrice: r'$1',
            lineTotal: r'$1',
          ),
          InvoiceLineItem(
            id: 'li-1',
            description: 'A',
            quantity: 1,
            unitPrice: r'$1',
            lineTotal: r'$1',
          ),
          InvoiceLineItem(
            id: 'li-2',
            description: 'B',
            quantity: 1,
            unitPrice: r'$1',
            lineTotal: r'$1',
          ),
        ]),
      );
      final got = await dao.findDetailById('inv-1');
      expect(got!.lineItems.map((l) => l.description), ['C', 'A', 'B']);
    });

    test('findInvoiceById returns null for unknown id', () async {
      expect(await dao.findInvoiceById('nope'), isNull);
    });

    test('countInvoices returns 0 on a fresh table', () async {
      expect(await dao.countInvoices(), 0);
    });
  });

  group('workflow mutations', () {
    setUp(() async {
      // Start each test with a pendingApproval seed.
      await dao.upsertWithDetail(
        header: _header(id: 'inv-1', status: InvoiceStatus.pendingApproval),
      );
    });

    test('approve flips status + writes approvedBy + actionedAt', () async {
      final t = DateTime.utc(2026, 5, 13, 10);
      final out = await dao.approve(
        invoiceId: 'inv-1',
        approverId: 'u-mgr',
        actionedAt: t,
      );
      expect(out.status, InvoiceStatus.approved);
      expect(out.approvedBy, 'u-mgr');
      expect(out.actionedAt!.isAtSameMomentAs(t), isTrue);
      expect(out.rejectedBy, isNull);
      expect(out.rejectedReason, isNull);
    });

    test('reject writes reason + rejectedBy + actionedAt; clears approvedBy',
        () async {
      // first approve, then reject — proves the reject clears approvedBy.
      await dao.approve(
        invoiceId: 'inv-1',
        approverId: 'u',
        actionedAt: DateTime.utc(2026, 5, 10),
      );
      // Reset to pendingApproval so reject is semantically valid in
      // isolation (the DAO doesn't enforce state transitions — the
      // UseCase does — but the audit fields are what's under test).
      await dao.submitForApproval(
        invoiceId: 'inv-1',
        actionedAt: DateTime.utc(2026, 5, 11),
      );

      final t = DateTime.utc(2026, 5, 13);
      final out = await dao.reject(
        invoiceId: 'inv-1',
        approverId: 'u-mgr',
        reason: 'over budget',
        actionedAt: t,
      );
      expect(out.status, InvoiceStatus.rejected);
      expect(out.rejectedBy, 'u-mgr');
      expect(out.rejectedReason, 'over budget');
      expect(out.actionedAt!.isAtSameMomentAs(t), isTrue);
      expect(out.approvedBy, isNull);
    });

    test('reopen clears all audit fields', () async {
      await dao.reject(
        invoiceId: 'inv-1',
        approverId: 'u',
        reason: 'no',
        actionedAt: DateTime.utc(2026, 5, 10),
      );
      final out = await dao.reopen(
        invoiceId: 'inv-1',
        actionedAt: DateTime.utc(2026, 5, 12),
      );
      expect(out.status, InvoiceStatus.draft);
      expect(out.approvedBy, isNull);
      expect(out.rejectedBy, isNull);
      expect(out.rejectedReason, isNull);
    });

    test('submitForApproval flips draft → pendingApproval', () async {
      // Reopen first to land on draft.
      await dao.reopen(
        invoiceId: 'inv-1',
        actionedAt: DateTime.utc(2026, 5, 12),
      );
      final out = await dao.submitForApproval(
        invoiceId: 'inv-1',
        actionedAt: DateTime.utc(2026, 5, 13),
      );
      expect(out.status, InvoiceStatus.pendingApproval);
    });

    test('approve on unknown id → StateError', () async {
      await expectLater(
        dao.approve(
          invoiceId: 'nope',
          approverId: 'u',
          actionedAt: DateTime.utc(2026, 5, 13),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('observation + cleanup', () {
    test('watchAllInvoices re-emits after every mutation', () async {
      final emitted = <int>[];
      final sub = dao.watchAllInvoices().listen(
            (rows) => emitted.add(rows.length),
          );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await dao.upsertWithDetail(header: _header(id: 'a'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await dao.upsertWithDetail(header: _header(id: 'b'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, contains(0));
      expect(emitted.last, 2);
      await sub.cancel();
    });

    test('wipeAll empties both tables', () async {
      final h = _header();
      await dao.upsertWithDetail(header: h, detail: _detail(h));
      expect(await dao.countInvoices(), 1);

      await dao.wipeAll();
      expect(await dao.countInvoices(), 0);
      expect((await dao.findDetailById('inv-1')), isNull);
    });

    test('FK cascade — deleting a header wipes its lines', () async {
      final h = _header();
      await dao.upsertWithDetail(header: h, detail: _detail(h));

      // Direct delete on the header (simulating an admin wipe of one row).
      await (db.delete(db.cachedInvoices)
            ..where((r) => r.id.equals('inv-1')))
          .go();

      // Lines must be gone too.
      final lines = await db.select(db.cachedInvoiceLines).get();
      expect(lines, isEmpty);
    });
  });
}
