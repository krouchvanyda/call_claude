import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';

/// One ledger transaction line posted against an [`Account`] (Slice 3.1.2).
///
/// **Naming**: kept as `LedgerTransaction` (not bare `Transaction`) to
/// dodge collision with `dart:async`'s future-typed `Transaction` and
/// `package:drift`'s `Transaction` (which any data layer importer
/// already shadows). Domain code reads cleaner with the explicit name
/// anyway — there's more than one transaction concept in an ERP.
///
/// **Pre-formatted amounts**: `debit` / `credit` / `runningBalance` are
/// strings shaped at the data layer with the right currency + locale.
/// Keeps the entity locale-stable; the widget never formats numbers.
/// `null` means "this side of the entry is empty" — every line has
/// either a debit OR a credit, never both, never neither.
@freezed
class LedgerTransaction with _$LedgerTransaction {
  const factory LedgerTransaction({
    /// Server / drift PK. Stable across re-fetches.
    required String id,

    /// FK to [`Account.id`]. Drives the per-account watch query.
    required String accountId,

    /// Posting timestamp. Newest-first ordering in the detail view.
    required DateTime postedAt,

    /// Human-readable line description (e.g. "Invoice #INV-001 paid").
    required String description,

    /// Pre-formatted debit amount or `null` when this line is a credit.
    String? debit,

    /// Pre-formatted credit amount or `null` when this line is a debit.
    String? credit,

    /// Pre-formatted running balance after the line posted. Server-
    /// computed; we never derive client-side (sign + ordering rules
    /// vary by account type).
    required String runningBalance,

    /// Optional source-document handle (journal entry number, invoice
    /// id, etc.) — drives the "View source" deep link in a later slice.
    String? reference,
  }) = _LedgerTransaction;
}
