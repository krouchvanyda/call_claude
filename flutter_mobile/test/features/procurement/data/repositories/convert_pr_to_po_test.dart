import 'package:erp_mobile/features/procurement/data/repositories/purchase_requests_repository.dart';
import 'package:erp_mobile/features/procurement/entities/purchase_order.dart';
import 'package:erp_mobile/features/procurement/entities/purchase_request.dart';
import 'package:test/test.dart';

PurchaseRequest _pr({
  PurchaseRequestStatus status = PurchaseRequestStatus.approved,
  List<PurchaseRequestLine> lines = const [
    PurchaseRequestLine(
      id: 'li-1',
      description: 'Widget',
      sku: 'WID',
      quantity: 5,
      unitPrice: r'$10.00',
      lineTotal: r'$50.00',
    ),
    PurchaseRequestLine(
      id: 'li-2',
      description: 'Gizmo',
      quantity: 2,
      unitPrice: r'$20.00',
      lineTotal: r'$40.00',
    ),
  ],
}) =>
    PurchaseRequest(
      id: 'pr-x',
      number: 'PR-2026-099',
      requesterName: 'X',
      costCenter: 'CC-1',
      approverName: 'Y',
      createdAt: DateTime.utc(2026, 5, 1),
      status: status,
      totalAmount: r'$90.00',
      lineItems: lines,
    );

void main() {
  group('convertPurchaseRequestToOrder', () {
    test('non-approved PR refuses conversion', () {
      for (final s in [
        PurchaseRequestStatus.draft,
        PurchaseRequestStatus.submitted,
        PurchaseRequestStatus.rejected,
        PurchaseRequestStatus.converted,
      ]) {
        final out = convertPurchaseRequestToOrder(
          _pr(status: s),
          vendorId: 'v-1',
          vendorName: 'Acme',
          expectedAt: DateTime.utc(2026, 6, 1),
        );
        expect(out.result, ConvertPurchaseRequestResult.notApproved);
        expect(out.draftPo, isNull);
        expect(out.updatedPr, isNull);
      }
    });

    test('blank vendor → vendorMissing', () {
      final out = convertPurchaseRequestToOrder(
        _pr(),
        vendorId: '',
        vendorName: 'Acme',
        expectedAt: DateTime.utc(2026, 6, 1),
      );
      expect(out.result, ConvertPurchaseRequestResult.vendorMissing);
    });

    test('happy path — produces a PO draft + flips PR to converted', () {
      final pr = _pr();
      final out = convertPurchaseRequestToOrder(
        pr,
        vendorId: 'v-1',
        vendorName: 'Acme',
        expectedAt: DateTime.utc(2026, 6, 1),
      );
      expect(out.result, ConvertPurchaseRequestResult.ok);
      expect(out.draftPo!.status, PurchaseOrderStatus.open);
      expect(out.draftPo!.vendorName, 'Acme');
      expect(out.draftPo!.sourcePurchaseRequestId, pr.id);
      expect(out.draftPo!.lineItems, hasLength(2));
      expect(out.draftPo!.lineItems.first.orderedQuantity, 5);
      expect(out.draftPo!.lineItems.first.receivedQuantity, 0);
      expect(out.updatedPr!.status, PurchaseRequestStatus.converted);
    });

    test('preserves the original PR object (no mutation)', () {
      final pr = _pr();
      convertPurchaseRequestToOrder(
        pr,
        vendorId: 'v',
        vendorName: 'V',
        expectedAt: DateTime.utc(2026, 6, 1),
      );
      expect(pr.status, PurchaseRequestStatus.approved);
    });
  });
}
