/// Slice 9.3.2 — categorical action type for the audit log.
///
/// Closed enum so the viewer's filter chips and the icon mapping stay
/// exhaustive; new actions on the API side need a corresponding enum
/// case here before they can be displayed.
enum AuditAction {
  signIn,
  signOut,
  approve,
  reject,
  create,
  update,
  delete,
  permissionChange,
  exportData,
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.occurredAt,
    this.detail,
  });

  final String id;
  final String actorId;
  final String actorName;
  final AuditAction action;
  final String targetType;
  final String targetId;
  final String targetLabel;
  final DateTime occurredAt;

  /// Human-readable extra context (e.g., "Reason: budget overrun").
  /// Optional — minor actions like sign-in skip this.
  final String? detail;

  AuditLogEntry copyWith({
    String? id,
    String? actorId,
    String? actorName,
    AuditAction? action,
    String? targetType,
    String? targetId,
    String? targetLabel,
    DateTime? occurredAt,
    String? detail,
  }) =>
      AuditLogEntry(
        id: id ?? this.id,
        actorId: actorId ?? this.actorId,
        actorName: actorName ?? this.actorName,
        action: action ?? this.action,
        targetType: targetType ?? this.targetType,
        targetId: targetId ?? this.targetId,
        targetLabel: targetLabel ?? this.targetLabel,
        occurredAt: occurredAt ?? this.occurredAt,
        detail: detail ?? this.detail,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogEntry &&
          other.id == id &&
          other.actorId == actorId &&
          other.actorName == actorName &&
          other.action == action &&
          other.targetType == targetType &&
          other.targetId == targetId &&
          other.targetLabel == targetLabel &&
          other.occurredAt == occurredAt &&
          other.detail == detail;

  @override
  int get hashCode => Object.hash(
        id,
        actorId,
        actorName,
        action,
        targetType,
        targetId,
        targetLabel,
        occurredAt,
        detail,
      );
}
