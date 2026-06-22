import 'package:erp_mobile/features/procurement/data/repositories/purchase_orders_repository.dart';
import 'package:erp_mobile/features/procurement/entities/goods_receipt.dart';
import 'package:erp_mobile/features/procurement/entities/purchase_order.dart';
import 'package:test/test.dart';

PurchaseOrder _po({
  PurchaseOrderStatus status = PurchaseOrderStatus.open,
  num ordered = 10,
  num received = 0,
}) =>
    PurchaseOrder(
      id: 'po-1',
      number: 'PO-1',
      vendorId: 'v',
      vendorName: 'v',
      createdAt: DateTime.utc(2026, 5, 1),
      expectedAt: DateTime.utc(2026, 6, 1),
      status: status,
      totalAmount: r'$100',
      lineItems: [
        PurchaseOrderLine(
          id: 'l1',
          description: 'X',
          orderedQuantity: ordered,
          receivedQuantity: received,
          unitPrice: r'$10',
          lineTotal: r'$100',
        ),
      ],
    );

GoodsReceipt _gr(
        {String poId = 'po-1', List<GoodsReceiptLine> lines = const []}) =>
    GoodsReceipt(
      id: 'gr-1',
      purchaseOrderId: poId,
      receivedAt: DateTime.utc(2026, 5, 5),
      receivedBy: 'me',
      lines: lines,
    );

void main() {
  test('valid receipt → null', () {
    final ok = validateGoodsReceipt(
      _gr(lines: const [GoodsReceiptLine(purchaseOrderLineId: 'l1', quantity: 5)]),
      _po(),
    );
    expect(ok, isNull);
  });

  test('PO closed / cancelled / fully received → poClosed', () {
    for (final s in [
      PurchaseOrderStatus.closed,
      PurchaseOrderStatus.cancelled,
      PurchaseOrderStatus.fullyReceived,
    ]) {
      final r = validateGoodsReceipt(
        _gr(lines: const [GoodsReceiptLine(purchaseOrderLineId: 'l1', quantity: 1)]),
        _po(status: s),
      );
      expect(r, GoodsReceiptError.poClosed);
    }
  });

  test('empty lines → noLines', () {
    expect(
      validateGoodsReceipt(_gr(), _po()),
      GoodsReceiptError.noLines,
    );
  });

  test('non-positive quantity → nonPositiveQuantity', () {
    expect(
      validateGoodsReceipt(
        _gr(lines: const [
          GoodsReceiptLine(purchaseOrderLineId: 'l1', quantity: 0)
        ]),
        _po(),
      ),
      GoodsReceiptError.nonPositiveQuantity,
    );
  });

  test('unknown line id → unknownLineId', () {
    expect(
      validateGoodsReceipt(
        _gr(lines: const [
          GoodsReceiptLine(purchaseOrderLineId: 'nope', quantity: 1)
        ]),
        _po(),
      ),
      GoodsReceiptError.unknownLineId,
    );
  });

  test('over-receipt → exceedsOutstanding', () {
    expect(
      validateGoodsReceipt(
        _gr(lines: const [
          GoodsReceiptLine(purchaseOrderLineId: 'l1', quantity: 11)
        ]),
        _po(),
      ),
      GoodsReceiptError.exceedsOutstanding,
    );
    // also fails when prior receipts already filled outstanding
    expect(
      validateGoodsReceipt(
        _gr(lines: const [
          GoodsReceiptLine(purchaseOrderLineId: 'l1', quantity: 4)
        ]),
        _po(received: 7), // outstanding = 3
      ),
      GoodsReceiptError.exceedsOutstanding,
    );
  });
}
