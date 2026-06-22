import 'package:erp_mobile/features/finance/data/repositories/invoices_repository.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:test/test.dart';

Invoice _i({
  required String id,
  String? num,
  String customer = 'Acme',
  DateTime? issued,
  DateTime? due,
  InvoiceStatus status = InvoiceStatus.pendingApproval,
  String amount = r'$100.00',
}) =>
    Invoice(
      id: id,
      invoiceNumber: num ?? id,
      customerName: customer,
      issuedAt: issued ?? DateTime.utc(2026, 5, 1),
      dueAt: due ?? DateTime.utc(2026, 6, 1),
      status: status,
      totalAmount: amount,
    );

void main() {
  group('applyInvoiceQuery', () {
    test('empty filter / empty search → all rows, default sort newest-first',
        () {
      final input = [
        _i(id: 'a', issued: DateTime.utc(2026, 5, 1)),
        _i(id: 'b', issued: DateTime.utc(2026, 5, 10)),
        _i(id: 'c', issued: DateTime.utc(2026, 4, 1)),
      ];
      final out = applyInvoiceQuery(input);
      expect(out.map((i) => i.id), ['b', 'a', 'c']);
    });

    test('status filter narrows the result', () {
      final input = [
        _i(id: 'a', status: InvoiceStatus.draft),
        _i(id: 'b', status: InvoiceStatus.pendingApproval),
        _i(id: 'c', status: InvoiceStatus.approved),
      ];
      final out = applyInvoiceQuery(
        input,
        statusFilter: {InvoiceStatus.pendingApproval, InvoiceStatus.approved},
      );
      expect(out.map((i) => i.id), unorderedEquals(['b', 'c']));
    });

    test('empty filter set is treated as "no filter" (returns all)', () {
      final input = [_i(id: 'a'), _i(id: 'b')];
      final out = applyInvoiceQuery(input, statusFilter: const {});
      expect(out, hasLength(2));
    });

    test('search matches invoice number (case-insensitive)', () {
      final input = [
        _i(id: '1', num: 'INV-001'),
        _i(id: '2', num: 'INV-002'),
      ];
      final out = applyInvoiceQuery(input, searchQuery: 'inv-001');
      expect(out.single.id, '1');
    });

    test('search matches customer name (case-insensitive)', () {
      final input = [
        _i(id: '1', customer: 'Acme Corp'),
        _i(id: '2', customer: 'Globex'),
      ];
      final out = applyInvoiceQuery(input, searchQuery: 'GLOBEX');
      expect(out.single.id, '2');
    });

    test('whitespace-only search is a no-op', () {
      final input = [_i(id: 'a'), _i(id: 'b')];
      expect(applyInvoiceQuery(input, searchQuery: '   '), hasLength(2));
    });

    test('amountDesc parses past currency symbols + thousands separators',
        () {
      final input = [
        _i(id: 'small', amount: r'$9.00'),
        _i(id: 'big', amount: r'$1,200.00'),
        _i(id: 'mid', amount: r'$120.00'),
      ];
      final out = applyInvoiceQuery(input, sort: InvoiceSort.amountDesc);
      expect(out.map((i) => i.id), ['big', 'mid', 'small']);
    });

    test('non-parseable amount sorts as zero (no crash)', () {
      final input = [
        _i(id: 'broken', amount: '???'),
        _i(id: 'real', amount: r'$50.00'),
      ];
      final out = applyInvoiceQuery(input, sort: InvoiceSort.amountDesc);
      expect(out.map((i) => i.id), ['real', 'broken']);
    });

    test('dueDateAsc sorts oldest due first', () {
      final input = [
        _i(id: 'late', due: DateTime.utc(2026, 7, 1)),
        _i(id: 'soon', due: DateTime.utc(2026, 5, 5)),
      ];
      final out = applyInvoiceQuery(input, sort: InvoiceSort.dueDateAsc);
      expect(out.map((i) => i.id), ['soon', 'late']);
    });

    test('numberAsc sorts lexicographically by invoiceNumber', () {
      final input = [
        _i(id: 'b', num: 'INV-002'),
        _i(id: 'a', num: 'INV-001'),
      ];
      final out = applyInvoiceQuery(input, sort: InvoiceSort.numberAsc);
      expect(out.map((i) => i.id), ['a', 'b']);
    });

    test('combined filter + search + sort applies in expected order', () {
      final input = [
        _i(id: 'a', customer: 'Acme', status: InvoiceStatus.approved,
            issued: DateTime.utc(2026, 5, 1)),
        _i(id: 'b', customer: 'Acme', status: InvoiceStatus.draft,
            issued: DateTime.utc(2026, 5, 10)),
        _i(id: 'c', customer: 'Globex', status: InvoiceStatus.approved,
            issued: DateTime.utc(2026, 5, 5)),
      ];
      final out = applyInvoiceQuery(
        input,
        statusFilter: {InvoiceStatus.approved},
        searchQuery: 'acme',
        sort: InvoiceSort.issuedDateAsc,
      );
      expect(out.map((i) => i.id), ['a']);
    });
  });
}
