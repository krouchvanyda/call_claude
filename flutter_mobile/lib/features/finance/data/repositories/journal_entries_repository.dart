import '../../entities/journal_entry.dart';

/// In-memory journal entries (Slice 3.3.1). Flat MVVM: single concrete
/// repo — no abstract interface. Each entry mirrors a finance event
/// from the seed transactions so the GL view tells the same story as
/// the chart of accounts.
///
/// **Stub-backed**: no drift table yet — when one lands, swap the
/// internal `_seed` for DAO calls and keep this class's public shape.
class JournalEntriesRepository {
  JournalEntriesRepository();

  static final List<JournalEntry> _seed = <JournalEntry>[
    JournalEntry(
      id: 'je-001',
      reference: 'INV-014',
      postedAt: DateTime.utc(2026, 5, 12, 14, 22),
      description: 'Customer payment INV-014',
      formattedTotal: r'$8,400.00',
      lines: const [
        JournalEntryLine(
          accountId: 'a-1110',
          accountCode: '1110',
          accountName: 'Operating bank',
          debit: r'$8,400.00',
        ),
        JournalEntryLine(
          accountId: 'a-1200',
          accountCode: '1200',
          accountName: 'Accounts receivable',
          credit: r'$8,400.00',
        ),
      ],
    ),
    JournalEntry(
      id: 'je-002',
      reference: 'INV-015',
      postedAt: DateTime.utc(2026, 5, 10),
      description: 'Invoice INV-015 issued',
      formattedTotal: r'$3,200.00',
      lines: const [
        JournalEntryLine(
          accountId: 'a-1200',
          accountCode: '1200',
          accountName: 'Accounts receivable',
          debit: r'$3,200.00',
        ),
        JournalEntryLine(
          accountId: 'a-4100',
          accountCode: '4100',
          accountName: 'Product sales',
          credit: r'$3,200.00',
        ),
      ],
    ),
    JournalEntry(
      id: 'je-003',
      reference: 'BILL-0091',
      postedAt: DateTime.utc(2026, 5, 8),
      description: 'Vendor bill — Acme Supplies',
      formattedTotal: r'$2,150.00',
      lines: const [
        JournalEntryLine(
          accountId: 'a-1110',
          accountCode: '1110',
          accountName: 'Operating bank',
          credit: r'$2,150.00',
        ),
        JournalEntryLine(
          accountId: 'a-2100',
          accountCode: '2100',
          accountName: 'Accounts payable',
          credit: r'$2,150.00',
        ),
      ],
    ),
    JournalEntry(
      id: 'je-004',
      reference: 'PAYRUN-2026-05',
      postedAt: DateTime.utc(2026, 5, 1),
      description: 'May payroll run',
      formattedTotal: r'$28,400.00',
      lines: const [
        JournalEntryLine(
          accountId: 'a-5100',
          accountCode: '5100',
          accountName: 'Payroll',
          debit: r'$28,400.00',
        ),
        JournalEntryLine(
          accountId: 'a-1110',
          accountCode: '1110',
          accountName: 'Operating bank',
          credit: r'$28,400.00',
        ),
      ],
    ),
  ];

  Future<List<JournalEntry>> getAll() async => List.unmodifiable(_seed);

  Stream<List<JournalEntry>> watchAll() async* {
    yield List.unmodifiable(_seed);
  }

  Future<JournalEntry?> findById(String id) async {
    for (final je in _seed) {
      if (je.id == id) return je;
    }
    return null;
  }
}
