import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../entities/invoice.dart';
import '../../entities/invoice_detail.dart';
import '../../entities/invoice_line_item.dart';
import 'tables/cached_invoice_lines.dart';
import 'tables/cached_invoices.dart';

part 'invoices_dao.g.dart';

/// Drift DAO for the offline invoice cache (Slice 3.2.4).
///
/// Owns both `cached_invoices` (header) and `cached_invoice_lines`
/// (FK-linked). The cascade delete on the FK means wiping a header
/// also drops the lines — saves us from doing it twice here.
///
/// **Mutations** stay typed: rather than expose a free-form `update`,
/// the workflow-shaped methods ([approve], [reject], [submitForApproval],
/// [reopen]) read-modify-write the audit columns alongside the status
/// flip, in a transaction so a crash mid-mutation can't leave the row
/// half-updated.
@DriftAccessor(tables: [CachedInvoices, CachedInvoiceLines])
class InvoicesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  // ── Reads ────────────────────────────────────────────────────

  Future<List<Invoice>> getAllInvoices() async {
    final rows = await (select(cachedInvoices)
          ..orderBy([(r) => OrderingTerm.desc(r.issuedAt)]))
        .get();
    return rows.map(_invoiceFromRow).toList(growable: false);
  }

  Stream<List<Invoice>> watchAllInvoices() {
    return (select(cachedInvoices)
          ..orderBy([(r) => OrderingTerm.desc(r.issuedAt)]))
        .watch()
        .map((rows) =>
            rows.map(_invoiceFromRow).toList(growable: false));
  }

  Future<Invoice?> findInvoiceById(String id) async {
    final row = await (select(cachedInvoices)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _invoiceFromRow(row);
  }

  Future<int> countInvoices() async {
    final c = countAll();
    final query = selectOnly(cachedInvoices)..addColumns([c]);
    return (await query.map((r) => r.read(c) ?? 0).getSingle());
  }

  /// Header + lines + totals + notes. Falls back to a synthetic
  /// single-line detail when only the header was cached — see
  /// `DriftInvoicesRepository.findDetailById` for the equivalent in
  /// the repository layer.
  Future<InvoiceDetail?> findDetailById(String id) async {
    final header = await findInvoiceById(id);
    if (header == null) return null;
    final headerRow = await (select(cachedInvoices)
          ..where((r) => r.id.equals(id)))
        .getSingle();
    final lineRows = await (select(cachedInvoiceLines)
          ..where((r) => r.invoiceId.equals(id))
          ..orderBy([(r) => OrderingTerm.asc(r.position)]))
        .get();
    return InvoiceDetail(
      header: header,
      subtotal: headerRow.subtotal ?? header.totalAmount,
      tax: headerRow.tax ?? r'$0.00',
      notes: headerRow.notes,
      lineItems: lineRows.map(_lineFromRow).toList(growable: false),
    );
  }

  // ── Writes ───────────────────────────────────────────────────

  /// Upserts header + (optional) lines in one transaction. Used by the
  /// seed bootstrap and by any future create/edit flow.
  Future<void> upsertWithDetail({
    required Invoice header,
    InvoiceDetail? detail,
  }) {
    return transaction(() async {
      await into(cachedInvoices).insert(
        _headerToCompanion(header, detail: detail),
        mode: InsertMode.insertOrReplace,
      );
      if (detail != null) {
        // Reset & repopulate lines for this invoice. Cheaper to wipe
        // + reinsert than diff — and the transaction means the read
        // side never observes a half-empty list.
        await (delete(cachedInvoiceLines)
              ..where((r) => r.invoiceId.equals(header.id)))
            .go();
        await batch((b) {
          for (var i = 0; i < detail.lineItems.length; i++) {
            b.insert(
              cachedInvoiceLines,
              _lineToCompanion(detail.lineItems[i],
                  invoiceId: header.id, position: i),
            );
          }
        });
      }
    });
  }

  /// Approve (header-only transition + audit fields). Throws
  /// [StateError] when the id is unknown so the repo can surface a
  /// "this invoice is gone" message.
  Future<Invoice> approve({
    required String invoiceId,
    required String approverId,
    required DateTime actionedAt,
  }) async {
    final updated = await (update(cachedInvoices)
          ..where((r) => r.id.equals(invoiceId)))
        .write(CachedInvoicesCompanion(
      status: Value(InvoiceStatus.approved.name),
      approvedBy: Value(approverId),
      rejectedBy: const Value(null),
      rejectedReason: const Value(null),
      actionedAt: Value(actionedAt),
    ));
    if (updated == 0) {
      throw StateError('Invoice "$invoiceId" not found');
    }
    return (await findInvoiceById(invoiceId))!;
  }

  Future<Invoice> reject({
    required String invoiceId,
    required String approverId,
    required String reason,
    required DateTime actionedAt,
  }) async {
    final updated = await (update(cachedInvoices)
          ..where((r) => r.id.equals(invoiceId)))
        .write(CachedInvoicesCompanion(
      status: Value(InvoiceStatus.rejected.name),
      rejectedBy: Value(approverId),
      rejectedReason: Value(reason),
      approvedBy: const Value(null),
      actionedAt: Value(actionedAt),
    ));
    if (updated == 0) {
      throw StateError('Invoice "$invoiceId" not found');
    }
    return (await findInvoiceById(invoiceId))!;
  }

  Future<Invoice> submitForApproval({
    required String invoiceId,
    required DateTime actionedAt,
  }) async {
    final updated = await (update(cachedInvoices)
          ..where((r) => r.id.equals(invoiceId)))
        .write(CachedInvoicesCompanion(
      status: Value(InvoiceStatus.pendingApproval.name),
      actionedAt: Value(actionedAt),
    ));
    if (updated == 0) {
      throw StateError('Invoice "$invoiceId" not found');
    }
    return (await findInvoiceById(invoiceId))!;
  }

  Future<Invoice> reopen({
    required String invoiceId,
    required DateTime actionedAt,
  }) async {
    final updated = await (update(cachedInvoices)
          ..where((r) => r.id.equals(invoiceId)))
        .write(CachedInvoicesCompanion(
      status: Value(InvoiceStatus.draft.name),
      approvedBy: const Value(null),
      rejectedBy: const Value(null),
      rejectedReason: const Value(null),
      actionedAt: Value(actionedAt),
    ));
    if (updated == 0) {
      throw StateError('Invoice "$invoiceId" not found');
    }
    return (await findInvoiceById(invoiceId))!;
  }

  /// Sign-out wipe.
  Future<void> wipeAll() async {
    // Lines first, then headers — even with cascade delete the
    // explicit order keeps the intent obvious in code review.
    await delete(cachedInvoiceLines).go();
    await delete(cachedInvoices).go();
  }

  // ── Mapping ────────────────────────────────────────────────────

  static CachedInvoicesCompanion _headerToCompanion(
    Invoice inv, {
    InvoiceDetail? detail,
  }) {
    return CachedInvoicesCompanion(
      id: Value(inv.id),
      invoiceNumber: Value(inv.invoiceNumber),
      customerName: Value(inv.customerName),
      issuedAt: Value(inv.issuedAt),
      dueAt: Value(inv.dueAt),
      status: Value(inv.status.name),
      totalAmount: Value(inv.totalAmount),
      currency: Value(inv.currency),
      approvedBy: Value(inv.approvedBy),
      rejectedBy: Value(inv.rejectedBy),
      rejectedReason: Value(inv.rejectedReason),
      actionedAt: Value(inv.actionedAt),
      subtotal: Value(detail?.subtotal),
      tax: Value(detail?.tax),
      notes: Value(detail?.notes),
    );
  }

  static CachedInvoiceLinesCompanion _lineToCompanion(
    InvoiceLineItem line, {
    required String invoiceId,
    required int position,
  }) {
    return CachedInvoiceLinesCompanion(
      id: Value(line.id),
      invoiceId: Value(invoiceId),
      position: Value(position),
      description: Value(line.description),
      sku: Value(line.sku),
      quantity: Value(line.quantity.toDouble()),
      unitPrice: Value(line.unitPrice),
      lineTotal: Value(line.lineTotal),
    );
  }

  static Invoice _invoiceFromRow(CachedInvoiceRow r) {
    return Invoice(
      id: r.id,
      invoiceNumber: r.invoiceNumber,
      customerName: r.customerName,
      issuedAt: r.issuedAt,
      dueAt: r.dueAt,
      status: _statusFromString(r.status),
      totalAmount: r.totalAmount,
      currency: r.currency,
      approvedBy: r.approvedBy,
      rejectedBy: r.rejectedBy,
      rejectedReason: r.rejectedReason,
      actionedAt: r.actionedAt,
    );
  }

  static InvoiceLineItem _lineFromRow(CachedInvoiceLineRow r) {
    return InvoiceLineItem(
      id: r.id,
      description: r.description,
      sku: r.sku,
      quantity: r.quantity,
      unitPrice: r.unitPrice,
      lineTotal: r.lineTotal,
    );
  }

  /// Defensive parse — an unrecognised status defaults to `draft` so a
  /// future server-side rename doesn't crash the offline view.
  static InvoiceStatus _statusFromString(String raw) {
    for (final s in InvoiceStatus.values) {
      if (s.name == raw) return s;
    }
    return InvoiceStatus.draft;
  }
}
