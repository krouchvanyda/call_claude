import 'dart:async';

import '../../entities/purchase_order.dart';
import '../../entities/purchase_request.dart';

/// In-memory PR seed (Slice 4.1.1). Mirrors the `StubInvoicesRepository`
/// pattern so swapping in a drift-backed impl later is mechanical.
///
/// Now flat (Module 4 refactor): folds the former
/// `PurchaseRequestsRepository` abstract interface and the
/// `PurchaseRequestApprovalUseCase` (approve / reject / submit) directly
/// onto this class. The pure filter + sort helper lives as
/// [`applyPurchaseRequestQuery`] at the bottom of this file, and the
/// pure PR→PO converter lives as [`convertPurchaseRequestToOrder`] (also
/// here — see its dartdoc for the cross-repo placement note).
class PurchaseRequestsRepository {
  PurchaseRequestsRepository();

  static final List<PurchaseRequest> _seed = <PurchaseRequest>[
    PurchaseRequest(
      id: 'pr-001',
      number: 'PR-2026-001',
      requesterName: 'Sokha Tep',
      costCenter: 'CC-ENG-101',
      approverName: 'Vibol Chea',
      createdAt: DateTime.utc(2026, 5, 11, 9, 15),
      status: PurchaseRequestStatus.submitted,
      totalAmount: r'$2,450.00',
      lineItems: const [
        PurchaseRequestLine(
          id: 'pr-001-li-1',
          description: 'Dell P2422H 24" monitor',
          sku: 'DELL-P2422H',
          quantity: 5,
          unitPrice: r'$320.00',
          lineTotal: r'$1,600.00',
        ),
        PurchaseRequestLine(
          id: 'pr-001-li-2',
          description: 'Logitech MX Master 3S',
          sku: 'LOG-MX3S',
          quantity: 5,
          unitPrice: r'$170.00',
          lineTotal: r'$850.00',
        ),
      ],
      justification: 'Onboarding kit for the new platform team hires.',
    ),
    PurchaseRequest(
      id: 'pr-002',
      number: 'PR-2026-002',
      requesterName: 'Sothea Pich',
      costCenter: 'CC-OPS-204',
      approverName: 'Vibol Chea',
      createdAt: DateTime.utc(2026, 5, 9, 14, 5),
      status: PurchaseRequestStatus.approved,
      totalAmount: r'$890.00',
      lineItems: const [
        PurchaseRequestLine(
          id: 'pr-002-li-1',
          description: 'Office supplies (paper, pens, folders)',
          quantity: 1,
          unitPrice: r'$890.00',
          lineTotal: r'$890.00',
        ),
      ],
      justification: 'Quarterly stationery refill.',
    ),
    PurchaseRequest(
      id: 'pr-003',
      number: 'PR-2026-003',
      requesterName: 'Dara Nuon',
      costCenter: 'CC-MKT-305',
      approverName: 'Bopha Lim',
      createdAt: DateTime.utc(2026, 5, 7, 10, 40),
      status: PurchaseRequestStatus.draft,
      totalAmount: r'$5,200.00',
      lineItems: const [
        PurchaseRequestLine(
          id: 'pr-003-li-1',
          description: 'Trade show booth rental — Q3',
          quantity: 1,
          unitPrice: r'$5,200.00',
          lineTotal: r'$5,200.00',
        ),
      ],
    ),
    PurchaseRequest(
      id: 'pr-004',
      number: 'PR-2026-004',
      requesterName: 'Mara Sok',
      costCenter: 'CC-ENG-101',
      approverName: 'Vibol Chea',
      createdAt: DateTime.utc(2026, 5, 4, 11, 20),
      status: PurchaseRequestStatus.rejected,
      totalAmount: r'$12,800.00',
      lineItems: const [
        PurchaseRequestLine(
          id: 'pr-004-li-1',
          description: 'M2 Mac Studio (overspec for role)',
          sku: 'MAC-STD-M2',
          quantity: 4,
          unitPrice: r'$3,200.00',
          lineTotal: r'$12,800.00',
        ),
      ],
      justification: 'Workstation refresh.',
    ),
    PurchaseRequest(
      id: 'pr-005',
      number: 'PR-2026-005',
      requesterName: 'Sokha Tep',
      costCenter: 'CC-ENG-101',
      approverName: 'Vibol Chea',
      createdAt: DateTime.utc(2026, 5, 1, 16, 0),
      status: PurchaseRequestStatus.converted,
      totalAmount: r'$1,180.00',
      lineItems: const [
        PurchaseRequestLine(
          id: 'pr-005-li-1',
          description: 'Apple TV 4K (conference rooms)',
          sku: 'APL-TV4K',
          quantity: 4,
          unitPrice: r'$170.00',
          lineTotal: r'$680.00',
        ),
        PurchaseRequestLine(
          id: 'pr-005-li-2',
          description: 'HDMI cables (10m)',
          quantity: 10,
          unitPrice: r'$50.00',
          lineTotal: r'$500.00',
        ),
      ],
    ),
  ];

  static int _idCounter = 100;

  // Broadcast channel so `watchAll` subscribers re-receive after any
  // mutation. Without this the bloc only sees the initial yield and a
  // newly-created PR never shows up in the list.
  static final StreamController<List<PurchaseRequest>> _changes =
      StreamController<List<PurchaseRequest>>.broadcast();

  static void _emit() => _changes.add(List.unmodifiable(_seed));

  Future<List<PurchaseRequest>> getAll() async => List.unmodifiable(_seed);

  Stream<List<PurchaseRequest>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<PurchaseRequest?> findById(String id) async {
    for (final p in _seed) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Persists a status transition (Slice 4.1.3 approval workflow,
  /// Slice 4.2.2 conversion). Throws [StateError] on unknown id so the
  /// caller can surface a "PR is gone" message.
  Future<void> setStatus(
    String id,
    PurchaseRequestStatus newStatus,
  ) async {
    final idx = _seed.indexWhere((p) => p.id == id);
    if (idx == -1) throw StateError('Purchase request "$id" not found');
    _seed[idx] = _seed[idx].copyWith(status: newStatus);
    _emit();
  }

  /// Adds a draft PR (Slice 4.1.2 form submit). Returns the persisted
  /// record (the repo assigns the id + number).
  Future<PurchaseRequest> create(PurchaseRequest draft) async {
    _idCounter++;
    final id = 'pr-$_idCounter';
    final number = 'PR-2026-${_idCounter.toString().padLeft(3, '0')}';
    final persisted = draft.copyWith(
      id: id,
      number: number,
      createdAt: DateTime.now().toUtc(),
    );
    _seed.insert(0, persisted);
    _emit();
    return persisted;
  }

  /// Slice 4.1.3 — approve a PR. Pure-Dart workflow (no I/O) returning a
  /// result enum + the (possibly unchanged) [PurchaseRequest]. The
  /// caller is expected to persist the new state via [setStatus].
  ///
  /// **Status transitions**: `submitted → approved`. Anything else
  /// returns [PurchaseRequestApprovalResult.notAllowedFromCurrentStatus]
  /// with the input PR unchanged.
  ({PurchaseRequestApprovalResult result, PurchaseRequest pr}) approve(
    PurchaseRequest p,
  ) {
    if (p.status != PurchaseRequestStatus.submitted) {
      return (
        result: PurchaseRequestApprovalResult.notAllowedFromCurrentStatus,
        pr: p,
      );
    }
    return (
      result: PurchaseRequestApprovalResult.ok,
      pr: p.copyWith(status: PurchaseRequestStatus.approved),
    );
  }

  /// Slice 4.1.3 — reject a PR. Reason is mandatory at the domain
  /// level. Returns a result enum + the (possibly unchanged) PR.
  ///
  /// **Status transitions**: `submitted → rejected`. Blank reason
  /// short-circuits with [PurchaseRequestApprovalResult.reasonRequired]
  /// and the PR is left untouched.
  ({PurchaseRequestApprovalResult result, PurchaseRequest pr}) reject(
    PurchaseRequest p, {
    required String reason,
  }) {
    if (reason.trim().isEmpty) {
      return (result: PurchaseRequestApprovalResult.reasonRequired, pr: p);
    }
    if (p.status != PurchaseRequestStatus.submitted) {
      return (
        result: PurchaseRequestApprovalResult.notAllowedFromCurrentStatus,
        pr: p,
      );
    }
    return (
      result: PurchaseRequestApprovalResult.ok,
      pr: p.copyWith(status: PurchaseRequestStatus.rejected),
    );
  }

  /// Slice 4.1.3 — promote a draft to `submitted`. Used by the form
  /// path when an explicit transition is wanted instead of
  /// create-as-submitted.
  ///
  /// **Status transitions**: `draft → submitted`. Anything else returns
  /// [PurchaseRequestApprovalResult.notAllowedFromCurrentStatus].
  ({PurchaseRequestApprovalResult result, PurchaseRequest pr}) submit(
    PurchaseRequest p,
  ) {
    if (p.status != PurchaseRequestStatus.draft) {
      return (
        result: PurchaseRequestApprovalResult.notAllowedFromCurrentStatus,
        pr: p,
      );
    }
    return (
      result: PurchaseRequestApprovalResult.ok,
      pr: p.copyWith(status: PurchaseRequestStatus.submitted),
    );
  }
}

/// Result of an attempted approve / reject (Slice 4.1.3). Mirrors the
/// shape of `InvoiceApprovalResult` so the UI layer can reuse the same
/// snackbar/dialog patterns.
enum PurchaseRequestApprovalResult {
  ok,
  notAllowedFromCurrentStatus,
  reasonRequired,
}

/// Pure filter + sort over a PR list (Slice 4.1.1).
///
/// Mirrors `applyInvoiceQuery` from Slice 3.2.1 — keeps the bloc thin
/// and the business logic exhaustively unit-testable.
List<PurchaseRequest> applyPurchaseRequestQuery(
  List<PurchaseRequest> all, {
  Set<PurchaseRequestStatus> statusFilter = const {},
  String searchQuery = '',
  PurchaseRequestSort sort = PurchaseRequestSort.createdDesc,
}) {
  Iterable<PurchaseRequest> result = all;

  if (statusFilter.isNotEmpty) {
    result = result.where((p) => statusFilter.contains(p.status));
  }

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((p) =>
        p.number.toLowerCase().contains(q) ||
        p.requesterName.toLowerCase().contains(q) ||
        p.costCenter.toLowerCase().contains(q));
  }

  final list = result.toList();
  switch (sort) {
    case PurchaseRequestSort.createdDesc:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case PurchaseRequestSort.createdAsc:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case PurchaseRequestSort.totalDesc:
      // Lexical sort on pre-formatted amounts is wrong for cross-currency
      // — but the seed is single-currency. When real money lands, store
      // a numeric `totalCents` alongside `totalAmount` and sort on that.
      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    case PurchaseRequestSort.numberAsc:
      list.sort((a, b) => a.number.compareTo(b.number));
  }
  return list;
}

/// Result of [convertPurchaseRequestToOrder]. Encodes the two ways
/// conversion can refuse: wrong status, or missing vendor binding.
enum ConvertPurchaseRequestResult { ok, notApproved, vendorMissing }

/// Pure-Dart conversion (Slice 4.2.2). Maps an approved PR's lines
/// 1:1 onto a freshly minted PO. The repo layer assigns the PO id +
/// number on persistence; this builder just produces the in-memory
/// draft + the next state for the source PR.
///
/// **Placement note**: kept as a free function (not a method on either
/// repo) because the original behavior is cross-repo orchestration —
/// the caller takes the produced draft to
/// [PurchaseOrdersRepository.create] and the updated PR status to
/// [PurchaseRequestsRepository.setStatus] in two separate calls.
/// Folding the orchestration into either repo would change behavior
/// (and force one repo to depend on the other). Mirrors the placement
/// of `convertQuotationToOrder` in the sales module.
({
  ConvertPurchaseRequestResult result,
  PurchaseOrder? draftPo,
  PurchaseRequest? updatedPr,
}) convertPurchaseRequestToOrder(
  PurchaseRequest pr, {
  required String vendorId,
  required String vendorName,
  required DateTime expectedAt,
}) {
  if (pr.status != PurchaseRequestStatus.approved) {
    return (
      result: ConvertPurchaseRequestResult.notApproved,
      draftPo: null,
      updatedPr: null,
    );
  }
  if (vendorId.trim().isEmpty || vendorName.trim().isEmpty) {
    return (
      result: ConvertPurchaseRequestResult.vendorMissing,
      draftPo: null,
      updatedPr: null,
    );
  }

  final lines = <PurchaseOrderLine>[
    for (var i = 0; i < pr.lineItems.length; i++)
      PurchaseOrderLine(
        id: 'tmp-li-${i + 1}',
        description: pr.lineItems[i].description,
        sku: pr.lineItems[i].sku,
        orderedQuantity: pr.lineItems[i].quantity,
        receivedQuantity: 0,
        unitPrice: pr.lineItems[i].unitPrice,
        lineTotal: pr.lineItems[i].lineTotal,
      ),
  ];

  final draftPo = PurchaseOrder(
    id: 'tmp', // overwritten on persist
    number: 'PO-tmp', // overwritten on persist
    vendorId: vendorId,
    vendorName: vendorName,
    createdAt: DateTime.now().toUtc(),
    expectedAt: expectedAt,
    status: PurchaseOrderStatus.open,
    totalAmount: pr.totalAmount,
    lineItems: lines,
    sourcePurchaseRequestId: pr.id,
  );

  return (
    result: ConvertPurchaseRequestResult.ok,
    draftPo: draftPo,
    updatedPr: pr.copyWith(status: PurchaseRequestStatus.converted),
  );
}
