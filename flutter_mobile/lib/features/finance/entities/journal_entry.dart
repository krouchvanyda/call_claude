import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';

/// One line on a journal entry — debit OR credit against an account
/// (Slice 3.3.1).
@freezed
class JournalEntryLine with _$JournalEntryLine {
  const factory JournalEntryLine({
    required String accountId,
    required String accountCode,
    required String accountName,

    /// Pre-formatted; exactly one side is non-null per line.
    String? debit,
    String? credit,
  }) = _JournalEntryLine;
}

/// Journal entry header + lines (Slice 3.3.1).
///
/// **Balance invariant**: sum(debits) == sum(credits) for any well-
/// formed entry. The server enforces this; the client only displays
/// totals (computed by [JournalEntry.totals]).
@freezed
class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String reference,
    required DateTime postedAt,
    required String description,
    required List<JournalEntryLine> lines,

    /// Pre-formatted total — string at the boundary, same locale-stable
    /// pattern as the rest of the finance entities.
    required String formattedTotal,
  }) = _JournalEntry;
}
