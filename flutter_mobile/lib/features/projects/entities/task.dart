/// Slice 8.1.2 — Kanban columns. Order in the enum is the column
/// order on the board.
enum TaskStatus { todo, inProgress, inReview, done }

/// Slice 8.1.2 — visual priority chip on the card.
enum TaskPriority { low, medium, high, urgent }

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.assigneeId,
    this.assigneeName,
    this.dueDate,
    this.estimatedHours,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final String? assigneeId;
  final String? assigneeName;
  final DateTime? dueDate;
  final num? estimatedHours;

  /// True iff the task has a due date that has already passed AND is
  /// still open (not done).
  bool get isOverdue {
    if (status == TaskStatus.done || dueDate == null) return false;
    final today = DateTime.now();
    final due = DateTime.utc(dueDate!.year, dueDate!.month, dueDate!.day);
    final cmp = DateTime.utc(today.year, today.month, today.day);
    return due.isBefore(cmp);
  }

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    String? assigneeId,
    String? assigneeName,
    DateTime? dueDate,
    num? estimatedHours,
  }) =>
      ProjectTask(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
        assigneeId: assigneeId ?? this.assigneeId,
        assigneeName: assigneeName ?? this.assigneeName,
        dueDate: dueDate ?? this.dueDate,
        estimatedHours: estimatedHours ?? this.estimatedHours,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTask &&
          other.id == id &&
          other.projectId == projectId &&
          other.title == title &&
          other.description == description &&
          other.status == status &&
          other.priority == priority &&
          other.createdAt == createdAt &&
          other.assigneeId == assigneeId &&
          other.assigneeName == assigneeName &&
          other.dueDate == dueDate &&
          other.estimatedHours == estimatedHours;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        title,
        description,
        status,
        priority,
        createdAt,
        assigneeId,
        assigneeName,
        dueDate,
        estimatedHours,
      );
}

/// Slice 8.1.3 — task comment thread.
class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.postedAt,
  });

  final String id;
  final String taskId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime postedAt;

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? authorId,
    String? authorName,
    String? body,
    DateTime? postedAt,
  }) =>
      TaskComment(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        body: body ?? this.body,
        postedAt: postedAt ?? this.postedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskComment &&
          other.id == id &&
          other.taskId == taskId &&
          other.authorId == authorId &&
          other.authorName == authorName &&
          other.body == body &&
          other.postedAt == postedAt;

  @override
  int get hashCode =>
      Object.hash(id, taskId, authorId, authorName, body, postedAt);
}
