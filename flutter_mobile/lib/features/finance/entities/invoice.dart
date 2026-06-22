import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';

/// Lifecycle states of an invoice in the **approval workflow**
/// (Slice 3.2.4 spec).
///
/// State machine:
/// ```
/// draft → pendingApproval → approved
///                         → rejected → draft        (re-open for revision)
///                                       └→ pendingApproval (re-submitted)
/// ```
///
/// **Note**: the collection-side lifecycle (sent-to-customer / paid /
/// overdue / voided) is a *separate* state machine layered on top of
/// `approved` and isn't modelled here yet — those states arrive in a
/// follow-up slice when AR collection lands.
enum InvoiceStatus { draft, pendingApproval, approved, rejected }

/// One AR invoice header (Slice 3.2.1 + Slice 3.2.4 audit fields).
///
/// **Pure data**: no Flutter, no drift. Pre-formatted [totalAmount]
/// keeps the entity locale-stable; the widget never formats numbers.
/// Line items live in [`InvoiceDetail`] — the list view only needs
/// the header.
///
/// **Audit fields** (Slice 3.2.4 guardrail — "audit trail"):
/// - [approvedBy] / [rejectedBy] — `User.id` of the actioning user
/// - [rejectedReason] — mandatory rationale captured at reject time
/// - [actionedAt] — when the latest workflow transition happened
///
/// These are populated by the approve/reject UseCases and persist
/// alongside the row so Slice 9.3.2 (audit log viewer) can read them
/// even offline.
@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String invoiceNumber,
    required String customerName,
    required DateTime issuedAt,
    required DateTime dueAt,
    required InvoiceStatus status,

    /// Pre-formatted (e.g. `r'$1,234.56'`).
    required String totalAmount,

    /// ISO 4217 — exposed to the detail page for formatting consistency.
    @Default('USD') String currency,

    /// `User.id` of the approver. Set only when [status] is `approved`.
    String? approvedBy,

    /// `User.id` of the rejector. Set only when [status] is `rejected`.
    String? rejectedBy,

    /// Free-text rationale captured at reject time. Mandatory at the
    /// UseCase layer — never `null` once a reject has fired.
    String? rejectedReason,

    /// Timestamp of the latest approve/reject/reopen transition. Used
    /// by the audit log viewer.
    DateTime? actionedAt,
  }) = _Invoice;
}
