/// Kind of stock movement (Slice 5.1.2).
///
/// `receipt` and `issue` are the everyday GRN/GI; `transfer` is one
/// leg of a two-leg location move (Slice 5.2.3); `adjustment` is the
/// catch-all for cycle counts and one-off corrections (Slice 5.2.4).
enum StockMovementType { receipt, issue, transfer, adjustment }

/// One inventory ledger row. **Append-only**: a correction is a new
/// `adjustment` row, never a mutation of an existing record. That
/// keeps the audit trail intact and matches how warehouse staff
/// expect movement history to read.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.itemId,
    required this.postedAt,
    required this.type,
    required this.quantity,
    required this.runningQty,
    this.reference,
    this.note,
  });

  final String id;
  final String itemId;
  final DateTime postedAt;
  final StockMovementType type;

  /// Signed quantity in the direction of the movement type:
  /// `receipt` is positive (stock in), `issue` is positive (stock
  /// out — sign comes from the type, not the value), `adjustment`
  /// uses signed semantics so `-1` means "found one less than
  /// expected".
  final num quantity;

  /// Post-movement on-hand snapshot for the item. Used by the detail
  /// view to render a running balance column.
  final num runningQty;

  /// Source document reference (e.g. `PO-2026-001`, `SO-2026-014`,
  /// `CYCLE-2026-19`). Optional — adjustments may have no upstream.
  final String? reference;

  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          other.id == id &&
          other.itemId == itemId &&
          other.postedAt == postedAt &&
          other.type == type &&
          other.quantity == quantity &&
          other.runningQty == runningQty &&
          other.reference == reference &&
          other.note == note;

  @override
  int get hashCode => Object.hash(
        id,
        itemId,
        postedAt,
        type,
        quantity,
        runningQty,
        reference,
        note,
      );
}
