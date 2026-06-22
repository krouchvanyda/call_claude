import 'package:drift/drift.dart';

/// Drift table for the offline invoice header cache (Slice 3.2.4).
///
/// **Mirrors the [`Invoice`] domain entity 1:1** with two extra
/// `nullable` columns — `subtotal`, `tax`, `notes` — that surface on
/// the detail page but aren't part of the list row. Storing them here
/// avoids a separate "details" round-trip when the user drills in.
///
/// **Audit columns** are spec-mandated (CLAUDE.md → Slice 3.2.4):
/// `approved_by`, `rejected_by`, `rejected_reason`, `actioned_at`.
/// They round-trip alongside the workflow status so the audit log
/// viewer (Slice 9.3.2) reads them straight from drift, offline.
///
/// **Status** is stored as the enum *name* (`draft`, `pendingApproval`,
/// `approved`, `rejected`) — keeps the wire format readable for
/// migration scripts and forces a deliberate textEnum rename rather
/// than silent integer-index drift.
@DataClassName('CachedInvoiceRow')
class CachedInvoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text()();
  TextColumn get customerName => text()();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get dueAt => dateTime()();

  /// Approval workflow status — see [`InvoiceStatus`].
  TextColumn get status => text()();

  /// Pre-formatted total (e.g. `r'$1,234.56'`).
  TextColumn get totalAmount => text()();

  TextColumn get currency => text().withDefault(const Constant('USD'))();

  // ── Optional detail columns ───────────────────────────────────
  TextColumn get subtotal => text().nullable()();
  TextColumn get tax => text().nullable()();
  TextColumn get notes => text().nullable()();

  // ── Audit columns (Slice 3.2.4 spec) ─────────────────────────
  TextColumn get approvedBy => text().nullable()();
  TextColumn get rejectedBy => text().nullable()();
  TextColumn get rejectedReason => text().nullable()();
  DateTimeColumn get actionedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
