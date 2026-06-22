import 'dart:async';

import '../../entities/sales_order.dart';
import '../../entities/sales_quotation.dart';
import '../sales_seed.dart';

/// Slice 6.2.1 / 6.2.2 — sales quotations.
class QuotationsRepository {
  QuotationsRepository();

  static final List<SalesQuotation> _seed =
      List<SalesQuotation>.of(SalesSeed.quotations);
  static int _idCounter = 100;

  final StreamController<List<SalesQuotation>> _changes =
      StreamController<List<SalesQuotation>>.broadcast();

  Future<List<SalesQuotation>> getAll() async => List.unmodifiable(_seed);

  Stream<List<SalesQuotation>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<SalesQuotation?> findById(String id) async {
    for (final q in _seed) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Persists a new quotation (Slice 6.2.1 form submit). Returns the
  /// persisted row (the repo assigns id + number).
  Future<SalesQuotation> create(SalesQuotation draft) async {
    _idCounter++;
    final id = 'qt-${_idCounter.toString().padLeft(3, '0')}';
    final number = 'QT-2026-${_idCounter.toString().padLeft(3, '0')}';
    final persisted = draft.copyWith(id: id, number: number);
    _seed.insert(0, persisted);
    _changes.add(List.unmodifiable(_seed));
    return persisted;
  }

  /// Flips status without touching line items (Slice 6.2.2 marks a
  /// quotation as `converted`).
  Future<SalesQuotation> setStatus(
      String id, QuotationStatus next) async {
    final idx = _seed.indexWhere((q) => q.id == id);
    if (idx == -1) throw StateError('Quotation "$id" not found');
    _seed[idx] = _seed[idx].copyWith(status: next);
    _changes.add(List.unmodifiable(_seed));
    return _seed[idx];
  }
}

/// Pure filter + sort over a quotation list (Slice 6.2.1).
List<SalesQuotation> applyQuotationQuery(
  List<SalesQuotation> all, {
  Set<QuotationStatus> statusFilter = const {},
  String searchQuery = '',
  QuotationSort sort = QuotationSort.createdDesc,
}) {
  Iterable<SalesQuotation> result = all;

  if (statusFilter.isNotEmpty) {
    result = result.where((q) => statusFilter.contains(q.status));
  }
  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((qu) =>
        qu.number.toLowerCase().contains(q) ||
        qu.customerName.toLowerCase().contains(q));
  }
  final list = result.toList();
  switch (sort) {
    case QuotationSort.createdDesc:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case QuotationSort.createdAsc:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case QuotationSort.totalDesc:
      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    case QuotationSort.validityAsc:
      list.sort((a, b) => a.validUntil.compareTo(b.validUntil));
  }
  return list;
}

/// Result codes for [convertQuotationToOrder] (Slice 6.2.2).
enum ConvertQuotationResult { ok, notAccepted, alreadyConverted, expired }

/// Pure conversion from a [SalesQuotation] to a [SalesOrder] draft
/// (Slice 6.2.2). Mirrors [`convertPurchaseRequestToOrder`] in shape:
/// line items map 1:1; the repo layer assigns the order id + number
/// on persistence.
///
/// **Placement note**: kept as a free function (not a method on either
/// repo) because the original behavior is cross-repo orchestration —
/// the caller takes the produced draft to [SalesOrdersRepository.create]
/// and the updated quotation status to [QuotationsRepository.setStatus]
/// in two separate calls. Folding the orchestration into either repo
/// would change behavior (and force one repo to depend on the other).
///
/// **Invariants**:
///   - Quotation status must be `accepted`. `draft` / `sent` /
///     `rejected` / `expired` refuse; `converted` short-circuits.
///   - Caller passes the actioning timestamp so the produced order
///     uses a deterministic `createdAt` (helps tests + audit).
({
  ConvertQuotationResult result,
  SalesOrder? draftOrder,
  SalesQuotation? updatedQuotation,
}) convertQuotationToOrder(
  SalesQuotation quotation, {
  required DateTime now,
}) {
  if (quotation.status == QuotationStatus.converted) {
    return (
      result: ConvertQuotationResult.alreadyConverted,
      draftOrder: null,
      updatedQuotation: null,
    );
  }
  if (quotation.status == QuotationStatus.expired) {
    return (
      result: ConvertQuotationResult.expired,
      draftOrder: null,
      updatedQuotation: null,
    );
  }
  if (quotation.status != QuotationStatus.accepted) {
    return (
      result: ConvertQuotationResult.notAccepted,
      draftOrder: null,
      updatedQuotation: null,
    );
  }

  final lines = <SalesLineItem>[
    for (var i = 0; i < quotation.lineItems.length; i++)
      SalesLineItem(
        id: 'tmp-li-${i + 1}',
        description: quotation.lineItems[i].description,
        sku: quotation.lineItems[i].sku,
        quantity: quotation.lineItems[i].quantity,
        unitPrice: quotation.lineItems[i].unitPrice,
        lineTotal: quotation.lineItems[i].lineTotal,
      ),
  ];

  final draft = SalesOrder(
    id: 'tmp', // overwritten on persist
    number: 'SO-tmp', // overwritten on persist
    customerId: quotation.customerId,
    customerName: quotation.customerName,
    createdAt: now,
    status: SalesOrderStatus.pending,
    totalAmount: quotation.totalAmount,
    lineItems: lines,
    sourceQuotationId: quotation.id,
  );

  return (
    result: ConvertQuotationResult.ok,
    draftOrder: draft,
    updatedQuotation:
        quotation.copyWith(status: QuotationStatus.converted),
  );
}
