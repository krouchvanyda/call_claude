/// Slice 8.2.2 — approval state machine for a timesheet line.
///
/// ```
/// draft → submitted → approved
///                  → rejected → draft (re-edit and resubmit)
/// ```
enum TimesheetStatus { draft, submitted, approved, rejected }

/// One time-entry line: who, what project, what task (optional), how
/// long, on what day.
class TimesheetEntry {
  const TimesheetEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.projectId,
    required this.projectName,
    required this.date,
    required this.hours,
    required this.description,
    required this.status,
    this.taskId,
    this.taskTitle,
    this.approverId,
    this.actionedAt,
    this.decisionNote,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String projectId;
  final String projectName;

  /// Calendar date the work was performed (UTC midnight).
  final DateTime date;

  /// Decimal hours (0.25 = 15 min). Capped at 24 by the validator.
  final num hours;
  final String description;
  final TimesheetStatus status;
  final String? taskId;
  final String? taskTitle;
  final String? approverId;
  final DateTime? actionedAt;
  final String? decisionNote;

  TimesheetEntry copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? projectId,
    String? projectName,
    DateTime? date,
    num? hours,
    String? description,
    TimesheetStatus? status,
    String? taskId,
    String? taskTitle,
    String? approverId,
    DateTime? actionedAt,
    String? decisionNote,
  }) =>
      TimesheetEntry(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        employeeName: employeeName ?? this.employeeName,
        projectId: projectId ?? this.projectId,
        projectName: projectName ?? this.projectName,
        date: date ?? this.date,
        hours: hours ?? this.hours,
        description: description ?? this.description,
        status: status ?? this.status,
        taskId: taskId ?? this.taskId,
        taskTitle: taskTitle ?? this.taskTitle,
        approverId: approverId ?? this.approverId,
        actionedAt: actionedAt ?? this.actionedAt,
        decisionNote: decisionNote ?? this.decisionNote,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimesheetEntry &&
          other.id == id &&
          other.employeeId == employeeId &&
          other.employeeName == employeeName &&
          other.projectId == projectId &&
          other.projectName == projectName &&
          other.date == date &&
          other.hours == hours &&
          other.description == description &&
          other.status == status &&
          other.taskId == taskId &&
          other.taskTitle == taskTitle &&
          other.approverId == approverId &&
          other.actionedAt == actionedAt &&
          other.decisionNote == decisionNote;

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        employeeName,
        projectId,
        projectName,
        date,
        hours,
        description,
        status,
        taskId,
        taskTitle,
        approverId,
        actionedAt,
        decisionNote,
      );
}
