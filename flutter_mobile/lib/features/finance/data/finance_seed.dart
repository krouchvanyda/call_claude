import '../entities/account.dart';
import '../entities/transaction.dart';

/// Single source of seed data for both the legacy stub repos and the
/// drift cache bootstrap (Slice 3.1.3). Extracted so adding a new
/// account doesn't require touching two files.
class FinanceSeed {
  static final List<Account> accounts = <Account>[
    // ── Assets (1xxx) ────────────────────────────────────────────
    Account(id: 'a-1000', code: '1000', name: 'Assets', type: AccountType.asset),
    Account(
        id: 'a-1100',
        code: '1100',
        name: 'Cash & cash equivalents',
        type: AccountType.asset,
        parentId: 'a-1000'),
    Account(
        id: 'a-1110',
        code: '1110',
        name: 'Operating bank',
        type: AccountType.asset,
        parentId: 'a-1100',
        formattedBalance: r'$48,210.00'),
    Account(
        id: 'a-1120',
        code: '1120',
        name: 'Petty cash',
        type: AccountType.asset,
        parentId: 'a-1100',
        formattedBalance: r'$420.00'),
    Account(
        id: 'a-1200',
        code: '1200',
        name: 'Accounts receivable',
        type: AccountType.asset,
        parentId: 'a-1000',
        formattedBalance: r'$12,800.00'),
    Account(
        id: 'a-1300',
        code: '1300',
        name: 'Inventory',
        type: AccountType.asset,
        parentId: 'a-1000',
        formattedBalance: r'$31,540.00'),

    // ── Liabilities (2xxx) ───────────────────────────────────────
    Account(
        id: 'a-2000',
        code: '2000',
        name: 'Liabilities',
        type: AccountType.liability),
    Account(
        id: 'a-2100',
        code: '2100',
        name: 'Accounts payable',
        type: AccountType.liability,
        parentId: 'a-2000',
        formattedBalance: r'$8,460.00'),
    Account(
        id: 'a-2200',
        code: '2200',
        name: 'Accrued expenses',
        type: AccountType.liability,
        parentId: 'a-2000',
        formattedBalance: r'$2,150.00'),

    // ── Equity (3xxx) ────────────────────────────────────────────
    Account(id: 'a-3000', code: '3000', name: 'Equity', type: AccountType.equity),
    Account(
        id: 'a-3100',
        code: '3100',
        name: 'Retained earnings',
        type: AccountType.equity,
        parentId: 'a-3000',
        formattedBalance: r'$58,000.00'),

    // ── Revenue (4xxx) ───────────────────────────────────────────
    Account(
        id: 'a-4000', code: '4000', name: 'Revenue', type: AccountType.revenue),
    Account(
        id: 'a-4100',
        code: '4100',
        name: 'Product sales',
        type: AccountType.revenue,
        parentId: 'a-4000',
        formattedBalance: r'$84,210.00'),
    Account(
        id: 'a-4200',
        code: '4200',
        name: 'Service revenue',
        type: AccountType.revenue,
        parentId: 'a-4000',
        formattedBalance: r'$12,400.00'),

    // ── Expenses (5xxx) ──────────────────────────────────────────
    Account(
        id: 'a-5000',
        code: '5000',
        name: 'Expenses',
        type: AccountType.expense),
    Account(
        id: 'a-5100',
        code: '5100',
        name: 'Payroll',
        type: AccountType.expense,
        parentId: 'a-5000',
        formattedBalance: r'$28,400.00'),
    Account(
        id: 'a-5200',
        code: '5200',
        name: 'Rent',
        type: AccountType.expense,
        parentId: 'a-5000',
        formattedBalance: r'$6,000.00'),
    Account(
        id: 'a-5300',
        code: '5300',
        name: 'Utilities',
        type: AccountType.expense,
        parentId: 'a-5000',
        formattedBalance: r'$840.00'),
  ];

  static final List<LedgerTransaction> transactions = <LedgerTransaction>[
    // a-1110 (Operating bank)
    LedgerTransaction(
        id: 't-1110-3',
        accountId: 'a-1110',
        postedAt: DateTime.utc(2026, 5, 12, 14, 22),
        description: 'Customer payment INV-014',
        debit: r'$8,400.00',
        runningBalance: r'$48,210.00',
        reference: 'INV-014'),
    LedgerTransaction(
        id: 't-1110-2',
        accountId: 'a-1110',
        postedAt: DateTime.utc(2026, 5, 8, 9, 5),
        description: 'Vendor payment — Acme Supplies',
        credit: r'$2,150.00',
        runningBalance: r'$39,810.00',
        reference: 'PMT-0091'),
    LedgerTransaction(
        id: 't-1110-1',
        accountId: 'a-1110',
        postedAt: DateTime.utc(2026, 5, 1),
        description: 'Opening balance',
        debit: r'$41,960.00',
        runningBalance: r'$41,960.00'),

    // a-1120 (Petty cash)
    LedgerTransaction(
        id: 't-1120-1',
        accountId: 'a-1120',
        postedAt: DateTime.utc(2026, 5, 9),
        description: 'Office supplies — coffee + stationery',
        credit: r'$80.00',
        runningBalance: r'$420.00'),

    // a-1200 (A/R)
    LedgerTransaction(
        id: 't-1200-2',
        accountId: 'a-1200',
        postedAt: DateTime.utc(2026, 5, 10),
        description: 'Invoice INV-015 issued',
        debit: r'$3,200.00',
        runningBalance: r'$12,800.00',
        reference: 'INV-015'),
    LedgerTransaction(
        id: 't-1200-1',
        accountId: 'a-1200',
        postedAt: DateTime.utc(2026, 5, 12),
        description: 'Receipt against INV-014',
        credit: r'$8,400.00',
        runningBalance: r'$9,600.00',
        reference: 'INV-014'),

    // a-2100 (A/P)
    LedgerTransaction(
        id: 't-2100-1',
        accountId: 'a-2100',
        postedAt: DateTime.utc(2026, 5, 8),
        description: 'Vendor bill — Acme Supplies',
        credit: r'$2,150.00',
        runningBalance: r'$8,460.00',
        reference: 'BILL-0091'),

    // a-4100 (Product sales)
    LedgerTransaction(
        id: 't-4100-2',
        accountId: 'a-4100',
        postedAt: DateTime.utc(2026, 5, 12),
        description: 'INV-014 — Widget shipment',
        credit: r'$8,400.00',
        runningBalance: r'$84,210.00',
        reference: 'INV-014'),
    LedgerTransaction(
        id: 't-4100-1',
        accountId: 'a-4100',
        postedAt: DateTime.utc(2026, 5, 10),
        description: 'INV-015 — Gizmo subscription',
        credit: r'$3,200.00',
        runningBalance: r'$75,810.00',
        reference: 'INV-015'),

    // a-5100 (Payroll)
    LedgerTransaction(
        id: 't-5100-1',
        accountId: 'a-5100',
        postedAt: DateTime.utc(2026, 5, 1),
        description: 'May payroll run',
        debit: r'$28,400.00',
        runningBalance: r'$28,400.00',
        reference: 'PAYRUN-2026-05'),
  ];
}
