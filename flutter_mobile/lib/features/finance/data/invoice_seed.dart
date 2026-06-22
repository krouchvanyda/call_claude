import '../entities/invoice.dart';
import '../entities/invoice_detail.dart';
import '../entities/invoice_line_item.dart';

/// Single source of seed data for invoices (Slice 3.2.4). Mirrors the
/// [`FinanceSeed`] pattern for accounts so the drift bootstrap and any
/// future stub repos read from one place.
///
/// **Status mapping** from the original 5-state demo data:
///   - `paid`     → [`InvoiceStatus.approved`]   (with audit fields populated)
///   - `sent`     → [`InvoiceStatus.pendingApproval`]
///   - `overdue`  → [`InvoiceStatus.pendingApproval`] (still pending past due)
///   - `draft`    → [`InvoiceStatus.draft`]
///   - `voided`   → [`InvoiceStatus.rejected`]   (with audit fields populated)
class InvoiceSeed {
  /// Header records (the columns that live on `cached_invoices`).
  /// [details] keys into this by `id`.
  static final List<Invoice> headers = <Invoice>[
    Invoice(
      id: 'inv-014',
      invoiceNumber: 'INV-014',
      customerName: 'Acme Corp',
      issuedAt: DateTime.utc(2026, 5, 5),
      dueAt: DateTime.utc(2026, 6, 4),
      status: InvoiceStatus.approved,
      totalAmount: r'$8,400.00',
      approvedBy: 'user-seed-mgr',
      actionedAt: DateTime.utc(2026, 5, 6, 9, 30),
    ),
    Invoice(
      id: 'inv-015',
      invoiceNumber: 'INV-015',
      customerName: 'Globex',
      issuedAt: DateTime.utc(2026, 5, 10),
      dueAt: DateTime.utc(2026, 6, 9),
      status: InvoiceStatus.pendingApproval,
      totalAmount: r'$3,200.00',
    ),
    Invoice(
      id: 'inv-016',
      invoiceNumber: 'INV-016',
      customerName: 'Initech',
      issuedAt: DateTime.utc(2026, 4, 1),
      dueAt: DateTime.utc(2026, 5, 1),
      status: InvoiceStatus.pendingApproval,
      totalAmount: r'$12,000.00',
    ),
    Invoice(
      id: 'inv-017',
      invoiceNumber: 'INV-017',
      customerName: 'Soylent Inc',
      issuedAt: DateTime.utc(2026, 5, 12),
      dueAt: DateTime.utc(2026, 6, 11),
      status: InvoiceStatus.draft,
      totalAmount: r'$640.00',
    ),
    Invoice(
      id: 'inv-018',
      invoiceNumber: 'INV-018',
      customerName: 'Acme Corp',
      issuedAt: DateTime.utc(2026, 5, 13),
      dueAt: DateTime.utc(2026, 6, 12),
      status: InvoiceStatus.draft,
      totalAmount: r'$1,950.00',
    ),
    Invoice(
      id: 'inv-013',
      invoiceNumber: 'INV-013',
      customerName: 'Wonka Industries',
      issuedAt: DateTime.utc(2026, 4, 22),
      dueAt: DateTime.utc(2026, 5, 22),
      status: InvoiceStatus.rejected,
      totalAmount: r'$220.00',
      rejectedBy: 'user-seed-mgr',
      rejectedReason: 'Wrong PO referenced — please reissue against PO-44.',
      actionedAt: DateTime.utc(2026, 4, 24, 14, 15),
    ),
  ];

  /// Per-id seed of detail records. Only populated for a couple of
  /// invoices — drift fallback synthesises a one-line detail for the
  /// rest so every list row still drills into something renderable.
  static Map<String, InvoiceDetail> details() {
    return {
      'inv-014': InvoiceDetail(
        header: headers.firstWhere((i) => i.id == 'inv-014'),
        subtotal: r'$8,000.00',
        tax: r'$400.00',
        notes: 'Thanks for your business — payment due net 30.',
        lineItems: const [
          InvoiceLineItem(
            id: 'li-1',
            description: 'Widget — model A',
            sku: 'WID-A',
            quantity: 40,
            unitPrice: r'$200.00',
            lineTotal: r'$8,000.00',
          ),
        ],
      ),
      'inv-015': InvoiceDetail(
        header: headers.firstWhere((i) => i.id == 'inv-015'),
        subtotal: r'$3,000.00',
        tax: r'$200.00',
        lineItems: const [
          InvoiceLineItem(
            id: 'li-2',
            description: 'Gizmo subscription — Q2',
            sku: 'GIZ-SUB',
            quantity: 1,
            unitPrice: r'$3,000.00',
            lineTotal: r'$3,000.00',
          ),
          InvoiceLineItem(
            id: 'li-3',
            description: 'Onboarding hours',
            quantity: 2,
            unitPrice: r'$100.00',
            lineTotal: r'$200.00',
          ),
        ],
      ),
    };
  }
}
