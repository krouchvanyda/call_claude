import 'dart:convert';

import '../../../../core/database/sync_queue_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_op_type.dart';
import '../../../../core/utils/clock.dart';
import '../../../auth/entities/permission.dart';
import '../../../auth/permission_gate.dart';
import '../../entities/invoice.dart';
import '../../entities/invoice_detail.dart';
import '../../entities/invoice_line_item.dart';
import '../datasources/invoices_dao.dart';
import '../invoice_seed.dart';

/// Permission token required to approve (or reject) an invoice
/// (Slice 3.2.4 spec). Approve and reject deliberately share the same
/// scope — an approver can also reject.
const kFinanceApprovePermission = 'finance.approve';

/// Drift-backed invoices repository (Slices 3.2.1 / 3.2.2 / 3.2.4).
/// Flat MVVM: single concrete repo — no abstract interface. The four
/// invoice-workflow use cases (approve / reject / submit / reopen) and
/// the pure filter pipeline ([`applyInvoiceQuery`]) live as free
/// top-level functions at the bottom of this file — same precedent as
/// `convertQuotationToOrder` in sales and the workflow fns in
/// inventory's `stock_movements_repository`.
///
/// **Lazy seed**: on first call, if `cached_invoices` is empty, the
/// bootstrap writes [`InvoiceSeed.headers`] + the detail seed. Same
/// pattern as [`AccountsRepository`].
///
/// **SyncQueue integration**: every approve/reject also enqueues a
/// sync op via the injected [`SyncQueueDao`]. The queue is the real
/// thing now (drift-backed), so the SyncEngine retry path can later
/// replay these against `PATCH /invoices/{id}/approve` when the
/// backend lands.
///
/// **Optimistic update** (per spec): the local drift write completes
/// before [approve] / [reject] return. If a later sync attempt fails,
/// the SyncEngine's dead-letter path surfaces it; the UI sees the
/// new status immediately.
class InvoicesRepository {
  InvoicesRepository({
    required InvoicesDao dao,
    required SyncQueueDao syncQueue,
  })  : _dao = dao,
        _syncQueue = syncQueue;

  final InvoicesDao _dao;
  final SyncQueueDao _syncQueue;
  Future<void>? _bootstrap;

  Future<void> _ensureBootstrapped() {
    return _bootstrap ??= _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    final count = await _dao.countInvoices();
    if (count > 0) return;
    final detailSeed = InvoiceSeed.details();
    for (final header in InvoiceSeed.headers) {
      await _dao.upsertWithDetail(
        header: header,
        detail: detailSeed[header.id],
      );
    }
  }

  Future<List<Invoice>> getAll() async {
    await _ensureBootstrapped();
    return _dao.getAllInvoices();
  }

  Stream<List<Invoice>> watchAll() async* {
    await _ensureBootstrapped();
    yield* _dao.watchAllInvoices();
  }

  Future<Invoice?> findById(String id) async {
    await _ensureBootstrapped();
    return _dao.findInvoiceById(id);
  }

  /// Full record — header + line items + totals. `null` when unknown.
  Future<InvoiceDetail?> findDetailById(String id) async {
    await _ensureBootstrapped();
    final detail = await _dao.findDetailById(id);
    if (detail == null) return null;
    // Cached headers without lines fall back to a single synthetic
    // line so the detail page still has *something* to render (mirrors
    // the stub's behavior for inv-016/017/018/013).
    if (detail.lineItems.isNotEmpty) return detail;
    return InvoiceDetail(
      header: detail.header,
      subtotal: detail.header.totalAmount,
      tax: r'$0.00',
      lineItems: [
        InvoiceLineItem(
          id: 'li-${detail.header.id}',
          description: detail.header.invoiceNumber,
          quantity: 1,
          unitPrice: detail.header.totalAmount,
          lineTotal: detail.header.totalAmount,
        ),
      ],
    );
  }

  /// Persists an `approved` transition (Slice 3.2.4). Optimistic local
  /// write happens immediately; the data layer also enqueues a sync op
  /// for the eventual `PATCH /invoices/{id}/approve` call.
  ///
  /// Returns the updated [Invoice]. Throws `StateError` when the id is
  /// unknown — caller (the [approveInvoice] free fn) pre-validates
  /// state transitions so the repo can stay dumb.
  Future<Invoice> approve({
    required String invoiceId,
    required String approverId,
    required DateTime actionedAt,
  }) async {
    await _ensureBootstrapped();
    final updated = await _dao.approve(
      invoiceId: invoiceId,
      approverId: approverId,
      actionedAt: actionedAt,
    );
    await _enqueueSyncOp(
      invoiceId: invoiceId,
      endpointPath: '/invoices/$invoiceId/approve',
      payload: {'approver_id': approverId},
    );
    return updated;
  }

  /// Persists a `rejected` transition (Slice 3.2.4). Same contract as
  /// [approve]; the [reason] is captured on the row for the audit log
  /// viewer (Slice 9.3.2).
  Future<Invoice> reject({
    required String invoiceId,
    required String approverId,
    required String reason,
    required DateTime actionedAt,
  }) async {
    await _ensureBootstrapped();
    final updated = await _dao.reject(
      invoiceId: invoiceId,
      approverId: approverId,
      reason: reason,
      actionedAt: actionedAt,
    );
    await _enqueueSyncOp(
      invoiceId: invoiceId,
      endpointPath: '/invoices/$invoiceId/reject',
      payload: {'approver_id': approverId, 'reason': reason},
    );
    return updated;
  }

  /// Submit a `draft` for approval (state machine helper). Used by the
  /// detail page's "Submit for approval" action when the invoice is
  /// still in `draft`. No audit fields written — the submit isn't a
  /// privileged action.
  Future<Invoice> submitForApproval({
    required String invoiceId,
    required DateTime actionedAt,
  }) async {
    await _ensureBootstrapped();
    return _dao.submitForApproval(
      invoiceId: invoiceId,
      actionedAt: actionedAt,
    );
  }

  /// Re-open a `rejected` invoice back to `draft` (state machine
  /// helper — spec calls this "re-open for revision"). Audit fields are
  /// cleared so the next approve/reject writes fresh.
  Future<Invoice> reopen({
    required String invoiceId,
    required DateTime actionedAt,
  }) async {
    await _ensureBootstrapped();
    return _dao.reopen(invoiceId: invoiceId, actionedAt: actionedAt);
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<void> _enqueueSyncOp({
    required String invoiceId,
    required String endpointPath,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _syncQueue.enqueue(
        entityType: 'invoice',
        entityId: invoiceId,
        operation: SyncOpType.update,
        payloadJson: jsonEncode(payload),
        endpointMethod: 'PATCH',
        endpointPath: endpointPath,
      );
    } catch (_) {
      // Best-effort — the local write already happened, the engine's
      // retry path owns recovery. Don't surface enqueue errors to the
      // user.
    }
  }
}

// ── Free-function workflow orchestrations ─────────────────────────────
//
// The four class-based use cases that used to live under
// `domain/usecases/` (approve / reject / submit / reopen) are now plain
// top-level functions, mirroring the precedent set by `recordStockMovement`
// in inventory. Each takes the repo + cross-cutting deps explicitly
// (PermissionGate / Clock) so we don't introduce a constructor-level
// coupling between them.

/// Approve an invoice (Slice 3.2.4).
///
/// **Invariants** (all enforced here — never trust the UI):
///   1. Signed-in user holds [`finance.approve`] permission.
///   2. Invoice exists.
///   3. Current status is [`InvoiceStatus.pendingApproval`] — approving
///      a `draft`/`approved`/`rejected` is a no-double-action guard.
///
/// **Failures** (all thrown as [`Failure`]):
///   - [`ForbiddenFailure`] — permission missing.
///   - [`NotFoundFailure`] — id unknown.
///   - [`ConflictFailure`] — wrong status. This is the spec's
///     "InvalidStateFailure" surfaced via the existing `conflict`
///     variant so we don't have to extend the sealed [`Failure`]
///     union (and re-run build_runner) for a single use site.
Future<Invoice> approveInvoice({
  required String invoiceId,
  required String approverId,
  required InvoicesRepository invoices,
  required PermissionGate gate,
  Clock? clock,
}) async {
  final tick = clock ?? DateTime.now;
  if (!gate.holds(const Permission(token: kFinanceApprovePermission))) {
    throw const Failure.forbidden(
      message: '$kFinanceApprovePermission required',
    );
  }
  final invoice = await invoices.findById(invoiceId);
  if (invoice == null) {
    throw Failure.notFound(message: 'invoice $invoiceId');
  }
  if (invoice.status != InvoiceStatus.pendingApproval) {
    throw Failure.conflict(
      message:
          'Cannot approve an invoice in status ${invoice.status.name}',
    );
  }
  return invoices.approve(
    invoiceId: invoiceId,
    approverId: approverId,
    actionedAt: tick(),
  );
}

/// Reject an invoice with a mandatory reason (Slice 3.2.4).
///
/// **Invariants**:
///   1. Signed-in user holds [`finance.approve`] permission (same gate
///      as approve — the spec deliberately bundles both verbs under one
///      scope so an approver can also reject).
///   2. Invoice exists.
///   3. Current status is [`InvoiceStatus.pendingApproval`].
///   4. [reason] is non-empty after trimming. The form validates this
///      first, but the workflow fn re-checks so the rule lives at the
///      domain boundary (spec: "mandatory at domain level").
Future<Invoice> rejectInvoice({
  required String invoiceId,
  required String approverId,
  required String reason,
  required InvoicesRepository invoices,
  required PermissionGate gate,
  Clock? clock,
}) async {
  final trimmedReason = reason.trim();
  if (trimmedReason.isEmpty) {
    throw const Failure.validation(
      fieldErrors: {
        'reason': ['required'],
      },
      message: 'Rejection reason is required',
    );
  }
  if (!gate.holds(const Permission(token: kFinanceApprovePermission))) {
    throw const Failure.forbidden(
      message: '$kFinanceApprovePermission required',
    );
  }
  final invoice = await invoices.findById(invoiceId);
  if (invoice == null) {
    throw Failure.notFound(message: 'invoice $invoiceId');
  }
  if (invoice.status != InvoiceStatus.pendingApproval) {
    throw Failure.conflict(
      message:
          'Cannot reject an invoice in status ${invoice.status.name}',
    );
  }
  final tick = clock ?? DateTime.now;
  return invoices.reject(
    invoiceId: invoiceId,
    approverId: approverId,
    reason: trimmedReason,
    actionedAt: tick(),
  );
}

/// `draft → pendingApproval` transition (Slice 3.2.4 state machine).
///
/// **No permission gate** — anyone who can edit a draft can also submit
/// it. The privileged step is the approve/reject decision, not the
/// submission.
Future<Invoice> submitInvoiceForApproval({
  required String invoiceId,
  required InvoicesRepository invoices,
  Clock? clock,
}) async {
  final invoice = await invoices.findById(invoiceId);
  if (invoice == null) {
    throw Failure.notFound(message: 'invoice $invoiceId');
  }
  if (invoice.status != InvoiceStatus.draft) {
    throw Failure.conflict(
      message:
          'Only draft invoices can be submitted (was ${invoice.status.name})',
    );
  }
  final tick = clock ?? DateTime.now;
  return invoices.submitForApproval(
    invoiceId: invoiceId,
    actionedAt: tick(),
  );
}

/// `rejected → draft` transition (Slice 3.2.4 spec — "re-open for
/// revision"). The originating user fixes whatever the rejector flagged
/// and re-submits.
Future<Invoice> reopenInvoice({
  required String invoiceId,
  required InvoicesRepository invoices,
  Clock? clock,
}) async {
  final invoice = await invoices.findById(invoiceId);
  if (invoice == null) {
    throw Failure.notFound(message: 'invoice $invoiceId');
  }
  if (invoice.status != InvoiceStatus.rejected) {
    throw Failure.conflict(
      message: 'Only rejected invoices can be re-opened '
          '(was ${invoice.status.name})',
    );
  }
  final tick = clock ?? DateTime.now;
  return invoices.reopen(
    invoiceId: invoiceId,
    actionedAt: tick(),
  );
}

// ── Pure filter / sort pipeline ──────────────────────────────────────

/// Sort axis for the invoice list (Slice 3.2.1).
enum InvoiceSort {
  issuedDateDesc,
  issuedDateAsc,
  dueDateAsc,
  amountDesc,
  numberAsc,
}

/// Pure-Dart filter + sort + search pipeline (Slice 3.2.1).
///
/// **Why pure**: keeps the matching rules unit-testable without a
/// bloc / widget context, and lets the same pipeline run on the
/// dashboard "open invoices" widget without building a second
/// implementation.
///
/// **Search match**: case-insensitive `contains` against
/// `invoiceNumber` AND `customerName`. Empty / whitespace-only
/// query is a no-op.
///
/// **Sort stability**: `List.sort` is stable in Dart, so equal-key
/// rows preserve insertion order — no jitter when two invoices
/// share an issued date.
List<Invoice> applyInvoiceQuery(
  List<Invoice> source, {
  Set<InvoiceStatus>? statusFilter,
  String? searchQuery,
  InvoiceSort sort = InvoiceSort.issuedDateDesc,
}) {
  Iterable<Invoice> result = source;

  if (statusFilter != null && statusFilter.isNotEmpty) {
    result = result.where((i) => statusFilter.contains(i.status));
  }

  final q = searchQuery?.trim().toLowerCase();
  if (q != null && q.isNotEmpty) {
    result = result.where((i) =>
        i.invoiceNumber.toLowerCase().contains(q) ||
        i.customerName.toLowerCase().contains(q));
  }

  final list = result.toList();
  list.sort(_comparatorFor(sort));
  return list;
}

int Function(Invoice, Invoice) _comparatorFor(InvoiceSort sort) {
  return switch (sort) {
    InvoiceSort.issuedDateDesc => (a, b) => b.issuedAt.compareTo(a.issuedAt),
    InvoiceSort.issuedDateAsc => (a, b) => a.issuedAt.compareTo(b.issuedAt),
    InvoiceSort.dueDateAsc => (a, b) => a.dueAt.compareTo(b.dueAt),
    // Lexicographic on the pre-formatted amount string is wrong
    // ($9.00 > $10.00). Strip non-digits and parse to an int of
    // cents; same locale assumption as the rest of the demo (USD).
    InvoiceSort.amountDesc => (a, b) =>
        _amountCents(b.totalAmount).compareTo(_amountCents(a.totalAmount)),
    InvoiceSort.numberAsc => (a, b) =>
        a.invoiceNumber.compareTo(b.invoiceNumber),
  };
}

/// Strip currency symbol + thousands separators + decimal point and
/// parse as cents. `r'$1,234.56'` → `123456`. Falls back to 0 on
/// non-parseable input rather than throwing — keeps the sort robust
/// to seed-data typos.
int _amountCents(String formatted) {
  final cleaned = formatted.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(cleaned) ?? 0;
}
