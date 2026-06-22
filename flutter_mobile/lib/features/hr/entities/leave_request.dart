/// Slice 7.2.1 — request types. Mirrors common ERP leave categories.
enum LeaveType { annual, sick, personal, unpaid, maternity }

/// State machine for an individual request.
///
/// ```
/// pending → approved
///        → rejected
///        → cancelled  (only employee can cancel; only while pending)
/// ```
enum LeaveRequestStatus { pending, approved, rejected, cancelled }

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.approvedBy,
    this.actionedAt,
    this.decisionNote,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final LeaveType type;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveRequestStatus status;
  final DateTime requestedAt;

  /// Manager / approver user id; null while pending.
  final String? approvedBy;
  final DateTime? actionedAt;
  final String? decisionNote;

  /// Inclusive day count between [fromDate] and [toDate]. Days are
  /// counted on calendar dates only (no time-of-day arithmetic).
  int get days {
    final from = DateTime.utc(fromDate.year, fromDate.month, fromDate.day);
    final to = DateTime.utc(toDate.year, toDate.month, toDate.day);
    return to.difference(from).inDays + 1;
  }

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    LeaveType? type,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    LeaveRequestStatus? status,
    DateTime? requestedAt,
    String? approvedBy,
    DateTime? actionedAt,
    String? decisionNote,
  }) =>
      LeaveRequest(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        employeeName: employeeName ?? this.employeeName,
        type: type ?? this.type,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        reason: reason ?? this.reason,
        status: status ?? this.status,
        requestedAt: requestedAt ?? this.requestedAt,
        approvedBy: approvedBy ?? this.approvedBy,
        actionedAt: actionedAt ?? this.actionedAt,
        decisionNote: decisionNote ?? this.decisionNote,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveRequest &&
          other.id == id &&
          other.employeeId == employeeId &&
          other.employeeName == employeeName &&
          other.type == type &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.reason == reason &&
          other.status == status &&
          other.requestedAt == requestedAt &&
          other.approvedBy == approvedBy &&
          other.actionedAt == actionedAt &&
          other.decisionNote == decisionNote;

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        employeeName,
        type,
        fromDate,
        toDate,
        reason,
        status,
        requestedAt,
        approvedBy,
        actionedAt,
        decisionNote,
      );
}

/// Yearly balance per leave type (Slice 7.2.2). `total` and `used` are
/// raw integers (days) so the balance widget can do arithmetic without
/// re-parsing strings.
class LeaveBalance {
  const LeaveBalance({
    required this.employeeId,
    required this.type,
    required this.totalDays,
    required this.usedDays,
  });

  final String employeeId;
  final LeaveType type;
  final int totalDays;
  final int usedDays;

  int get remainingDays => (totalDays - usedDays).clamp(0, totalDays);

  LeaveBalance copyWith({
    String? employeeId,
    LeaveType? type,
    int? totalDays,
    int? usedDays,
  }) =>
      LeaveBalance(
        employeeId: employeeId ?? this.employeeId,
        type: type ?? this.type,
        totalDays: totalDays ?? this.totalDays,
        usedDays: usedDays ?? this.usedDays,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveBalance &&
          other.employeeId == employeeId &&
          other.type == type &&
          other.totalDays == totalDays &&
          other.usedDays == usedDays;

  @override
  int get hashCode => Object.hash(employeeId, type, totalDays, usedDays);
}
