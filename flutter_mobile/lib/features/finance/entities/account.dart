import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

/// Top-level chart-of-accounts classification (Slice 3.1.1).
///
/// Drives icon / colour selection in the tree view and the sign of the
/// balance in summary widgets (assets / expenses are debit-normal;
/// liabilities / equity / revenue are credit-normal — the report layer
/// formats accordingly when it lands).
enum AccountType { asset, liability, equity, revenue, expense }

/// One ledger account — a node in the chart of accounts hierarchy.
///
/// **Pure data**: no Flutter, no drift. The repository maps drift rows
/// (Slice 3.1.3) and the future API DTO to this domain entity at the
/// boundary; the bloc + UI work with this type alone.
///
/// **Hierarchy**: [parentId] is `null` for roots. Cycles + orphans are
/// the tree builder's problem, not this entity's — the data layer
/// surfaces whatever the source supplies and lets `buildAccountTree`
/// decide how to absorb malformed input.
@freezed
class Account with _$Account {
  const factory Account({
    /// Server / drift PK. Stable across renames.
    required String id,

    /// Human-readable account code (e.g. `'1100'`, `'1100-01'`).
    /// Sort order within a level is by [code], not [name], so a typo
    /// in the localised name doesn't reshuffle the tree on locale change.
    required String code,

    required String name,

    required AccountType type,

    /// `null` for roots. Multiple roots per type are normal (one root
    /// per account category, sometimes more in deeply nested CoAs).
    String? parentId,

    /// Pre-formatted current balance string with currency symbol +
    /// locale separators applied at the data layer. The widget never
    /// formats numbers — keeps the entity locale-stable.
    String? formattedBalance,
  }) = _Account;
}
