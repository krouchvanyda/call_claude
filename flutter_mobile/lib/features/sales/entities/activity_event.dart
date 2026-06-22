/// Kind of activity captured on the customer timeline (Slice 6.1.3).
enum ActivityEventType { note, call, meeting, email, quotation, order, payment }

/// One row on the customer activity timeline.
///
/// **Append-only** — corrections are new entries, not edits, so the
/// audit history stays trustworthy.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.customerId,
    required this.type,
    required this.occurredAt,
    required this.summary,
    required this.actor,
    this.amount,
    this.reference,
  });

  final String id;
  final String customerId;
  final ActivityEventType type;
  final DateTime occurredAt;
  final String summary;
  final String actor;

  /// Pre-formatted monetary amount when relevant (orders / payments).
  final String? amount;

  /// Originating document (e.g. `SO-2026-014`, `INV-014`).
  final String? reference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityEvent &&
          other.id == id &&
          other.customerId == customerId &&
          other.type == type &&
          other.occurredAt == occurredAt &&
          other.summary == summary &&
          other.actor == actor &&
          other.amount == amount &&
          other.reference == reference;

  @override
  int get hashCode => Object.hash(
        id,
        customerId,
        type,
        occurredAt,
        summary,
        actor,
        amount,
        reference,
      );
}
