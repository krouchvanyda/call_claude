import '../entities/activity_event.dart';
import '../entities/contact.dart';
import '../entities/customer.dart';
import '../entities/sales_order.dart';
import '../entities/sales_quotation.dart';
import '../entities/sales_rep.dart';

/// Single source of demo data for Module 6 (Sales & CRM).
class SalesSeed {
  static final List<Customer> customers = <Customer>[
    Customer(
      id: 'cust-001',
      name: 'Acme Corp',
      email: 'ap@acme-corp.example',
      phone: '+855 23 555 0101',
      billingAddress: '12 Russian Blvd, Phnom Penh',
      segment: CustomerSegment.enterprise,
      status: CustomerStatus.active,
      onboardedAt: DateTime.utc(2024, 6, 12),
      lifetimeValue: r'$184,200.00',
      industry: 'Manufacturing',
    ),
    Customer(
      id: 'cust-002',
      name: 'Globex',
      email: 'ar@globex.example',
      phone: '+855 23 555 0202',
      billingAddress: '88 Norodom Blvd, Phnom Penh',
      segment: CustomerSegment.midMarket,
      status: CustomerStatus.active,
      onboardedAt: DateTime.utc(2025, 2, 4),
      lifetimeValue: r'$48,500.00',
      industry: 'Software',
    ),
    Customer(
      id: 'cust-003',
      name: 'Initech',
      email: 'billing@initech.example',
      phone: '+855 12 555 0303',
      billingAddress: '7 Sothearos Blvd, Phnom Penh',
      segment: CustomerSegment.smb,
      status: CustomerStatus.onHold,
      onboardedAt: DateTime.utc(2025, 6, 1),
      lifetimeValue: r'$12,300.00',
      industry: 'Consulting',
      notes: 'Past-due on INV-016 — collections in progress.',
    ),
    Customer(
      id: 'cust-004',
      name: 'Soylent Inc',
      email: 'orders@soylent.example',
      phone: '+855 78 555 0404',
      billingAddress: '102 Monivong Blvd, Phnom Penh',
      segment: CustomerSegment.midMarket,
      status: CustomerStatus.prospect,
      onboardedAt: DateTime.utc(2026, 4, 28),
      lifetimeValue: r'$0.00',
      industry: 'Food & Bev',
    ),
    Customer(
      id: 'cust-005',
      name: 'Wonka Industries',
      email: 'ar@wonka.example',
      phone: '+855 17 555 0505',
      billingAddress: '5 Independence Monument, Phnom Penh',
      segment: CustomerSegment.smb,
      status: CustomerStatus.churned,
      onboardedAt: DateTime.utc(2023, 1, 10),
      lifetimeValue: r'$9,800.00',
      industry: 'Retail',
      notes: 'Contract ended 2025-12-31, no renewal.',
    ),
  ];

  static final List<CustomerContact> contacts = <CustomerContact>[
    CustomerContact(
      id: 'ct-001',
      customerId: 'cust-001',
      name: 'Sokha Tep',
      role: 'Head of Procurement',
      email: 'sokha.tep@acme-corp.example',
      phone: '+855 92 555 0111',
      isPrimary: true,
    ),
    CustomerContact(
      id: 'ct-002',
      customerId: 'cust-001',
      name: 'Dara Nuon',
      role: 'Accounts Payable',
      email: 'dara.nuon@acme-corp.example',
      phone: '+855 92 555 0112',
    ),
    CustomerContact(
      id: 'ct-003',
      customerId: 'cust-002',
      name: 'Pisey Chan',
      role: 'CFO',
      email: 'pisey.chan@globex.example',
      phone: '+855 12 555 0222',
      isPrimary: true,
    ),
    CustomerContact(
      id: 'ct-004',
      customerId: 'cust-003',
      name: 'Bopha Lim',
      role: 'Office Manager',
      email: 'bopha.lim@initech.example',
      phone: '+855 78 555 0331',
      isPrimary: true,
    ),
  ];

  static final List<ActivityEvent> activities = <ActivityEvent>[
    ActivityEvent(
      id: 'act-001',
      customerId: 'cust-001',
      type: ActivityEventType.order,
      occurredAt: DateTime.utc(2026, 5, 12, 9, 30),
      summary: 'Placed order — 4 monitors + 10 cables',
      actor: 'Sokha Tep',
      amount: r'$8,400.00',
      reference: 'SO-2026-014',
    ),
    ActivityEvent(
      id: 'act-002',
      customerId: 'cust-001',
      type: ActivityEventType.payment,
      occurredAt: DateTime.utc(2026, 5, 14, 14, 0),
      summary: 'Payment received against INV-014',
      actor: 'Dara Nuon',
      amount: r'$8,400.00',
      reference: 'INV-014',
    ),
    ActivityEvent(
      id: 'act-003',
      customerId: 'cust-001',
      type: ActivityEventType.meeting,
      occurredAt: DateTime.utc(2026, 5, 9, 11, 0),
      summary: 'Q3 forecast review — interested in 50-unit rollout',
      actor: 'Demo Approver',
    ),
    ActivityEvent(
      id: 'act-004',
      customerId: 'cust-002',
      type: ActivityEventType.quotation,
      occurredAt: DateTime.utc(2026, 5, 10, 15, 45),
      summary: 'Quotation sent for Gizmo subscription renewal',
      actor: 'Demo Approver',
      amount: r'$3,200.00',
      reference: 'QT-2026-008',
    ),
    ActivityEvent(
      id: 'act-005',
      customerId: 'cust-002',
      type: ActivityEventType.order,
      occurredAt: DateTime.utc(2026, 5, 11, 10, 20),
      summary: 'Quotation accepted → SO-2026-015 created',
      actor: 'Pisey Chan',
      amount: r'$3,200.00',
      reference: 'SO-2026-015',
    ),
    ActivityEvent(
      id: 'act-006',
      customerId: 'cust-003',
      type: ActivityEventType.call,
      occurredAt: DateTime.utc(2026, 5, 8, 14, 15),
      summary: 'Collections call — committed to pay by 2026-05-20',
      actor: 'Demo Approver',
    ),
    ActivityEvent(
      id: 'act-007',
      customerId: 'cust-004',
      type: ActivityEventType.email,
      occurredAt: DateTime.utc(2026, 5, 13, 8, 0),
      summary: 'Sent intro deck + service catalog',
      actor: 'Demo Approver',
    ),
  ];

  static final List<SalesQuotation> quotations = <SalesQuotation>[
    SalesQuotation(
      id: 'qt-001',
      number: 'QT-2026-008',
      customerId: 'cust-002',
      customerName: 'Globex',
      createdAt: DateTime.utc(2026, 5, 10, 15, 45),
      validUntil: DateTime.utc(2026, 6, 10),
      status: QuotationStatus.converted,
      totalAmount: r'$3,200.00',
      lineItems: const [
        SalesLineItem(
          id: 'qt-001-li-1',
          description: 'Gizmo subscription — Q2',
          sku: 'GIZ-SUB-Q',
          quantity: 1,
          unitPrice: r'$3,000.00',
          lineTotal: r'$3,000.00',
        ),
        SalesLineItem(
          id: 'qt-001-li-2',
          description: 'Onboarding hours',
          quantity: 2,
          unitPrice: r'$100.00',
          lineTotal: r'$200.00',
        ),
      ],
    ),
    SalesQuotation(
      id: 'qt-002',
      number: 'QT-2026-009',
      customerId: 'cust-001',
      customerName: 'Acme Corp',
      createdAt: DateTime.utc(2026, 5, 11, 11, 0),
      validUntil: DateTime.utc(2026, 6, 11),
      status: QuotationStatus.sent,
      totalAmount: r'$16,000.00',
      lineItems: const [
        SalesLineItem(
          id: 'qt-002-li-1',
          description: 'Dell P2422H 24" monitor',
          sku: 'MON-DELL-24',
          quantity: 50,
          unitPrice: r'$320.00',
          lineTotal: r'$16,000.00',
        ),
      ],
      notes: 'Rollout pricing — bulk discount applied.',
    ),
    SalesQuotation(
      id: 'qt-003',
      number: 'QT-2026-010',
      customerId: 'cust-004',
      customerName: 'Soylent Inc',
      createdAt: DateTime.utc(2026, 5, 13, 9, 30),
      validUntil: DateTime.utc(2026, 6, 13),
      status: QuotationStatus.draft,
      totalAmount: r'$2,400.00',
      lineItems: const [
        SalesLineItem(
          id: 'qt-003-li-1',
          description: 'Service catalog setup',
          quantity: 1,
          unitPrice: r'$2,400.00',
          lineTotal: r'$2,400.00',
        ),
      ],
    ),
    SalesQuotation(
      id: 'qt-004',
      number: 'QT-2026-007',
      customerId: 'cust-003',
      customerName: 'Initech',
      createdAt: DateTime.utc(2026, 3, 15, 10, 0),
      validUntil: DateTime.utc(2026, 4, 15),
      status: QuotationStatus.expired,
      totalAmount: r'$5,200.00',
      lineItems: const [
        SalesLineItem(
          id: 'qt-004-li-1',
          description: 'Q1 retainer',
          quantity: 1,
          unitPrice: r'$5,200.00',
          lineTotal: r'$5,200.00',
        ),
      ],
    ),
  ];

  static final List<SalesOrder> orders = <SalesOrder>[
    SalesOrder(
      id: 'so-2026-014',
      number: 'SO-2026-014',
      customerId: 'cust-001',
      customerName: 'Acme Corp',
      createdAt: DateTime.utc(2026, 5, 12, 9, 30),
      status: SalesOrderStatus.delivered,
      totalAmount: r'$8,400.00',
      trackingReference: 'TR-WX-44182',
      shippedAt: DateTime.utc(2026, 5, 13, 14, 20),
      deliveredAt: DateTime.utc(2026, 5, 14, 11, 5),
      lineItems: const [
        SalesLineItem(
          id: 'so-014-li-1',
          description: 'Dell P2422H 24" monitor',
          sku: 'MON-DELL-24',
          quantity: 20,
          unitPrice: r'$320.00',
          lineTotal: r'$6,400.00',
        ),
        SalesLineItem(
          id: 'so-014-li-2',
          description: 'HDMI cable — 10m',
          sku: 'HDM-10M',
          quantity: 50,
          unitPrice: r'$40.00',
          lineTotal: r'$2,000.00',
        ),
      ],
    ),
    SalesOrder(
      id: 'so-2026-015',
      number: 'SO-2026-015',
      customerId: 'cust-002',
      customerName: 'Globex',
      createdAt: DateTime.utc(2026, 5, 11, 10, 20),
      status: SalesOrderStatus.shipped,
      totalAmount: r'$3,200.00',
      sourceQuotationId: 'qt-001',
      trackingReference: 'TR-WX-44199',
      shippedAt: DateTime.utc(2026, 5, 12, 16, 0),
      lineItems: const [
        SalesLineItem(
          id: 'so-015-li-1',
          description: 'Gizmo subscription — Q2',
          sku: 'GIZ-SUB-Q',
          quantity: 1,
          unitPrice: r'$3,000.00',
          lineTotal: r'$3,000.00',
        ),
        SalesLineItem(
          id: 'so-015-li-2',
          description: 'Onboarding hours',
          quantity: 2,
          unitPrice: r'$100.00',
          lineTotal: r'$200.00',
        ),
      ],
    ),
    SalesOrder(
      id: 'so-2026-016',
      number: 'SO-2026-016',
      customerId: 'cust-001',
      customerName: 'Acme Corp',
      createdAt: DateTime.utc(2026, 5, 13, 8, 0),
      status: SalesOrderStatus.packing,
      totalAmount: r'$2,400.00',
      lineItems: const [
        SalesLineItem(
          id: 'so-016-li-1',
          description: 'Network switch — 24 port',
          sku: 'NET-SW24',
          quantity: 2,
          unitPrice: r'$850.00',
          lineTotal: r'$1,700.00',
        ),
        SalesLineItem(
          id: 'so-016-li-2',
          description: 'Cat6 patch — 10m bundle',
          quantity: 1,
          unitPrice: r'$700.00',
          lineTotal: r'$700.00',
        ),
      ],
    ),
    SalesOrder(
      id: 'so-2026-013',
      number: 'SO-2026-013',
      customerId: 'cust-005',
      customerName: 'Wonka Industries',
      createdAt: DateTime.utc(2025, 12, 5, 14, 0),
      status: SalesOrderStatus.cancelled,
      totalAmount: r'$680.00',
      lineItems: const [
        SalesLineItem(
          id: 'so-013-li-1',
          description: 'Apple TV 4K',
          sku: 'TV-APL-4K',
          quantity: 4,
          unitPrice: r'$170.00',
          lineTotal: r'$680.00',
        ),
      ],
    ),
  ];

  /// Sales reps for the leaderboard (Slice 6.3.3).
  ///
  /// **Name match** with the `actor` field on [`activities`] is how
  /// orders attribute to a rep. `Demo Approver` is the default
  /// signed-in user so they appear at the top of the demo run.
  static final List<SalesRep> reps = <SalesRep>[
    SalesRep(
      id: 'rep-001',
      name: 'Demo Approver',
      targetAmount: r'$30,000.00',
    ),
    SalesRep(
      id: 'rep-002',
      name: 'Pisey Chan',
      targetAmount: r'$25,000.00',
    ),
    SalesRep(
      id: 'rep-003',
      name: 'Sokha Tep',
      targetAmount: r'$40,000.00',
    ),
    SalesRep(
      id: 'rep-004',
      name: 'Dara Nuon',
      targetAmount: r'$20,000.00',
    ),
    SalesRep(
      id: 'rep-005',
      name: 'Bopha Lim',
      targetAmount: r'$15,000.00',
    ),
  ];
}
