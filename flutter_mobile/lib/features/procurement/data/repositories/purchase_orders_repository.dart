import '../../entities/goods_receipt.dart';
import '../../entities/purchase_order.dart';

/// In-memory PO seed (Slice 4.2.1).
///
/// Now flat (Module 4 refactor): folds the former
/// `PurchaseOrdersRepository` abstract interface directly onto this
/// class. The pure goods-receipt validator lives as
/// [`validateGoodsReceipt`] at the bottom of this file (kept as a free
/// function — it's a pure form-side check with no I/O, paired
/// defence-in-depth with [recordGoodsReceipt]'s own throw on over-receipt).
class PurchaseOrdersRepository {
  PurchaseOrdersRepository();

  static final List<PurchaseOrder> _seed = <PurchaseOrder>[
    PurchaseOrder(
      id: 'po-2026-001',
      number: 'PO-2026-001',
      vendorId: 'v-001',
      vendorName: 'Acme Supplies',
      createdAt: DateTime.utc(2026, 5, 2, 10, 30),
      expectedAt: DateTime.utc(2026, 5, 16),
      status: PurchaseOrderStatus.partiallyReceived,
      totalAmount: r'$1,180.00',
      sourcePurchaseRequestId: 'pr-005',
      lineItems: const [
        PurchaseOrderLine(
          id: 'po-2026-001-li-1',
          description: 'Apple TV 4K',
          sku: 'APL-TV4K',
          orderedQuantity: 4,
          receivedQuantity: 4,
          unitPrice: r'$170.00',
          lineTotal: r'$680.00',
        ),
        PurchaseOrderLine(
          id: 'po-2026-001-li-2',
          description: 'HDMI cables (10m)',
          orderedQuantity: 10,
          receivedQuantity: 6,
          unitPrice: r'$50.00',
          lineTotal: r'$500.00',
        ),
      ],
    ),
    PurchaseOrder(
      id: 'po-2026-002',
      number: 'PO-2026-002',
      vendorId: 'v-002',
      vendorName: 'Globex Electronics',
      createdAt: DateTime.utc(2026, 4, 28, 15, 0),
      expectedAt: DateTime.utc(2026, 5, 12),
      status: PurchaseOrderStatus.fullyReceived,
      totalAmount: r'$2,550.00',
      lineItems: const [
        PurchaseOrderLine(
          id: 'po-2026-002-li-1',
          description: 'Network switch — 24 port',
          sku: 'NET-SW24',
          orderedQuantity: 3,
          receivedQuantity: 3,
          unitPrice: r'$850.00',
          lineTotal: r'$2,550.00',
        ),
      ],
    ),
    PurchaseOrder(
      id: 'po-2026-003',
      number: 'PO-2026-003',
      vendorId: 'v-003',
      vendorName: 'Initech Office',
      createdAt: DateTime.utc(2026, 5, 6, 9, 45),
      expectedAt: DateTime.utc(2026, 5, 20),
      status: PurchaseOrderStatus.open,
      totalAmount: r'$890.00',
      lineItems: const [
        PurchaseOrderLine(
          id: 'po-2026-003-li-1',
          description: 'Office stationery bundle',
          orderedQuantity: 1,
          receivedQuantity: 0,
          unitPrice: r'$890.00',
          lineTotal: r'$890.00',
        ),
      ],
    ),
  ];

  static final Map<String, List<GoodsReceipt>> _receipts = {
    'po-2026-001': [
      GoodsReceipt(
        id: 'gr-001',
        purchaseOrderId: 'po-2026-001',
        receivedAt: DateTime.utc(2026, 5, 8, 11, 0),
        receivedBy: 'Sokha Tep',
        lines: const [
          GoodsReceiptLine(
              purchaseOrderLineId: 'po-2026-001-li-1', quantity: 4),
          GoodsReceiptLine(
              purchaseOrderLineId: 'po-2026-001-li-2', quantity: 6),
        ],
        note: 'Cables short — 4 outstanding from Acme.',
      ),
    ],
    'po-2026-002': [
      GoodsReceipt(
        id: 'gr-002',
        purchaseOrderId: 'po-2026-002',
        receivedAt: DateTime.utc(2026, 5, 10, 14, 0),
        receivedBy: 'Sothea Pich',
        lines: const [
          GoodsReceiptLine(
              purchaseOrderLineId: 'po-2026-002-li-1', quantity: 3),
        ],
      ),
    ],
  };

  static int _idCounter = 100;

  Future<List<PurchaseOrder>> getAll() async => List.unmodifiable(_seed);

  Stream<List<PurchaseOrder>> watchAll() async* {
    yield List.unmodifiable(_seed);
  }

  Future<PurchaseOrder?> findById(String id) async {
    for (final p in _seed) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Persists a freshly created PO (Slice 4.2.2 PR→PO conversion).
  /// Returns the persisted record (id assigned by the repo).
  Future<PurchaseOrder> create(PurchaseOrder draft) async {
    _idCounter++;
    final id = 'po-2026-${_idCounter.toString().padLeft(3, '0')}';
    final persisted = draft.copyWith(
      id: id,
      number: id.toUpperCase(),
      createdAt: DateTime.now().toUtc(),
    );
    _seed.insert(0, persisted);
    return persisted;
  }

  /// Records a goods receipt (Slice 4.2.3). The repo updates each
  /// line's `receivedQuantity` and recomputes the PO's status.
  /// Throws [StateError] if the PO is unknown or any receipt line
  /// over-receives (caller should pre-validate via
  /// [`validateGoodsReceipt`] for a UI-friendly error).
  Future<void> recordGoodsReceipt(GoodsReceipt receipt) async {
    final idx = _seed.indexWhere((p) => p.id == receipt.purchaseOrderId);
    if (idx == -1) {
      throw StateError('PO "${receipt.purchaseOrderId}" not found');
    }
    final po = _seed[idx];
    final qtyByLineId = {for (final l in receipt.lines) l.purchaseOrderLineId: l.quantity};
    final updatedLines = <PurchaseOrderLine>[];
    for (final line in po.lineItems) {
      final extra = qtyByLineId[line.id] ?? 0;
      if (extra == 0) {
        updatedLines.add(line);
        continue;
      }
      final newReceived = line.receivedQuantity + extra;
      if (newReceived > line.orderedQuantity) {
        throw StateError('Over-receipt on line "${line.id}"');
      }
      updatedLines.add(line.copyWith(receivedQuantity: newReceived));
    }
    final allFull =
        updatedLines.every((l) => l.receivedQuantity >= l.orderedQuantity);
    final anyReceived = updatedLines.any((l) => l.receivedQuantity > 0);
    final nextStatus = allFull
        ? PurchaseOrderStatus.fullyReceived
        : (anyReceived
            ? PurchaseOrderStatus.partiallyReceived
            : PurchaseOrderStatus.open);
    _seed[idx] =
        po.copyWith(lineItems: updatedLines, status: nextStatus);
    (_receipts[receipt.purchaseOrderId] ??= <GoodsReceipt>[]).add(receipt);
  }

  /// Receipt history for a PO. Empty list if none yet recorded.
  Future<List<GoodsReceipt>> receiptsFor(String purchaseOrderId) async {
    return List.unmodifiable(
        _receipts[purchaseOrderId] ?? const <GoodsReceipt>[]);
  }
}

/// Result codes for goods-receipt validation (Slice 4.2.3). The form
/// surfaces these as inline field errors before a submit hits the repo.
enum GoodsReceiptError {
  poClosed,
  noLines,
  nonPositiveQuantity,
  unknownLineId,
  exceedsOutstanding,
}

/// Pure validator for a goods receipt against a PO snapshot.
///
/// Returns `null` on valid, an error code otherwise. The repo also
/// throws on persist (defence-in-depth) but the form path uses this
/// for fast user feedback.
///
/// **Placement note**: kept as a free function (not a method on
/// [PurchaseOrdersRepository]) because it's a pure validator with no
/// I/O — the form runs it before submit to short-circuit the round
/// trip, and [PurchaseOrdersRepository.recordGoodsReceipt] re-throws
/// on the same over-receipt condition defence-in-depth. Folding it
/// onto the repo would tie a pure validator to the repo's lifecycle
/// for no gain.
GoodsReceiptError? validateGoodsReceipt(
  GoodsReceipt receipt,
  PurchaseOrder po,
) {
  if (po.status == PurchaseOrderStatus.closed ||
      po.status == PurchaseOrderStatus.cancelled ||
      po.status == PurchaseOrderStatus.fullyReceived) {
    return GoodsReceiptError.poClosed;
  }
  if (receipt.lines.isEmpty) return GoodsReceiptError.noLines;

  final byId = {for (final l in po.lineItems) l.id: l};
  for (final l in receipt.lines) {
    if (l.quantity <= 0) return GoodsReceiptError.nonPositiveQuantity;
    final poLine = byId[l.purchaseOrderLineId];
    if (poLine == null) return GoodsReceiptError.unknownLineId;
    if (l.quantity > poLine.outstandingQuantity) {
      return GoodsReceiptError.exceedsOutstanding;
    }
  }
  return null;
}
