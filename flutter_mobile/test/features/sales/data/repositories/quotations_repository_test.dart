import 'package:erp_mobile/features/sales/data/repositories/quotations_repository.dart';
import 'package:erp_mobile/features/sales/entities/sales_order.dart';
import 'package:erp_mobile/features/sales/entities/sales_quotation.dart';
import 'package:test/test.dart';

SalesQuotation _q({
  QuotationStatus status = QuotationStatus.accepted,
  List<SalesLineItem> lines = const [
    SalesLineItem(
      id: 'qt-li-1',
      description: 'Widget',
      sku: 'WID',
      quantity: 5,
      unitPrice: r'$10.00',
      lineTotal: r'$50.00',
    ),
  ],
}) =>
    SalesQuotation(
      id: 'qt-1',
      number: 'QT-2026-001',
      customerId: 'cust-1',
      customerName: 'Acme',
      createdAt: DateTime.utc(2026, 5, 1),
      validUntil: DateTime.utc(2026, 6, 1),
      status: status,
      totalAmount: r'$50.00',
      lineItems: lines,
    );

void main() {
  final fixed = DateTime.utc(2026, 5, 13, 10);

  group('convertQuotationToOrder', () {
    test('non-accepted refuses with notAccepted', () {
      for (final s in [
        QuotationStatus.draft,
        QuotationStatus.sent,
        QuotationStatus.rejected,
      ]) {
        final out = convertQuotationToOrder(_q(status: s), now: fixed);
        expect(out.result, ConvertQuotationResult.notAccepted);
        expect(out.draftOrder, isNull);
        expect(out.updatedQuotation, isNull);
      }
    });

    test('already-converted short-circuits', () {
      final out = convertQuotationToOrder(
        _q(status: QuotationStatus.converted),
        now: fixed,
      );
      expect(out.result, ConvertQuotationResult.alreadyConverted);
    });

    test('expired refuses', () {
      final out = convertQuotationToOrder(
        _q(status: QuotationStatus.expired),
        now: fixed,
      );
      expect(out.result, ConvertQuotationResult.expired);
    });

    test('happy path — produces a pending order + flips quotation', () {
      final q = _q();
      final out = convertQuotationToOrder(q, now: fixed);
      expect(out.result, ConvertQuotationResult.ok);
      expect(out.draftOrder!.status, SalesOrderStatus.pending);
      expect(out.draftOrder!.customerId, q.customerId);
      expect(out.draftOrder!.customerName, q.customerName);
      expect(out.draftOrder!.sourceQuotationId, q.id);
      expect(out.draftOrder!.createdAt, fixed);
      expect(out.draftOrder!.lineItems, hasLength(1));
      expect(out.draftOrder!.lineItems.first.quantity, 5);
      expect(out.draftOrder!.totalAmount, q.totalAmount);
      expect(out.updatedQuotation!.status, QuotationStatus.converted);
    });

    test('does not mutate the source quotation', () {
      final q = _q();
      convertQuotationToOrder(q, now: fixed);
      expect(q.status, QuotationStatus.accepted);
    });
  });
}
