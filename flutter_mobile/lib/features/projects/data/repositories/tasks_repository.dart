import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/task.dart';
import '../projects_seed.dart';

/// Slice 8.1.2 — Kanban tasks per project.
class TasksRepository {
  TasksRepository();

  static final List<ProjectTask> _seed =
      List<ProjectTask>.of(ProjectsSeed.tasks);

  final StreamController<List<ProjectTask>> _changes =
      StreamController<List<ProjectTask>>.broadcast();

  Future<List<ProjectTask>> getForProject(String projectId) async =>
      List.unmodifiable(_seed.where((t) => t.projectId == projectId));

  /// Slice 8.1.6 — workload-aware picker reads everyone's open tasks
  /// to render the "X open tasks" badge per candidate assignee.
  Future<List<ProjectTask>> getAll() async => List.unmodifiable(_seed);

  Stream<List<ProjectTask>> watchForProject(String projectId) async* {
    yield await getForProject(projectId);
    yield* _changes.stream
        .map((all) => all.where((t) => t.projectId == projectId).toList());
  }

  Future<ProjectTask?> findById(String taskId) async {
    for (final t in _seed) {
      if (t.id == taskId) return t;
    }
    return null;
  }

  /// Replace the row in-place. Callers wanting the Kanban state-machine
  /// guard should use [move] instead.
  Future<ProjectTask> update(ProjectTask task) async {
    final idx = _seed.indexWhere((t) => t.id == task.id);
    if (idx == -1) {
      _seed.insert(0, task);
    } else {
      _seed[idx] = task;
    }
    _emit();
    return task;
  }

  Future<ProjectTask> create(ProjectTask task) async {
    final id = task.id.isEmpty
        ? 'task-${DateTime.now().microsecondsSinceEpoch}'
        : task.id;
    final stamped = task.copyWith(id: id);
    _seed.insert(0, stamped);
    _emit();
    return stamped;
  }

  /// Slice 8.1.2 — Kanban move with a state machine guard.
  ///
  /// **Allowed transitions** (the rest throw [ConflictFailure]):
  /// ```
  /// todo        ↔ inProgress
  /// inProgress  ↔ inReview
  /// inReview    ↔ done
  /// any non-done ↔ any other non-done   (drag freedom inside the active stages)
  /// done        → inProgress             (re-open path; no jump straight back to todo)
  /// ```
  ///
  /// **Why this shape**: lets a developer drag a card freely between the
  /// three working columns (todo/inProgress/inReview) without policy
  /// drama, but keeps "done → todo" off the table — re-opening is rare
  /// enough that it should be a deliberate "back to active" move.
  ProjectTask move({
    required ProjectTask task,
    required TaskStatus toStatus,
  }) {
    if (task.status == toStatus) return task;

    final from = task.status;
    final to = toStatus;

    bool active(TaskStatus s) =>
        s == TaskStatus.todo ||
        s == TaskStatus.inProgress ||
        s == TaskStatus.inReview;

    // Free movement between active stages.
    if (active(from) && active(to)) return task.copyWith(status: to);

    // Active → done (close).
    if (active(from) && to == TaskStatus.done) {
      return task.copyWith(status: to);
    }

    // Done → inProgress (re-open).
    if (from == TaskStatus.done && to == TaskStatus.inProgress) {
      return task.copyWith(status: to);
    }

    throw ConflictFailure(
      message: 'Illegal transition: ${from.name} → ${to.name}',
    );
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

/// Bucketed view for the Kanban columns (Slice 8.1.2).
///
/// Returns a map keyed by [TaskStatus]. Each column is sorted by
/// priority desc then dueDate asc so the most urgent items float to
/// the top — same heuristic Asana / Linear default to.
Map<TaskStatus, List<ProjectTask>> groupTasksByStatus(
    List<ProjectTask> tasks) {
  final out = <TaskStatus, List<ProjectTask>>{
    for (final s in TaskStatus.values) s: <ProjectTask>[],
  };
  for (final t in tasks) {
    out[t.status]!.add(t);
  }
  for (final list in out.values) {
    list.sort((a, b) {
      // Priority desc — urgent first.
      final byPrio = b.priority.index.compareTo(a.priority.index);
      if (byPrio != 0) return byPrio;
      // Then due date asc — soonest first; nulls last.
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
  }
  return out;
}

/// Slice 8.1.3 — task comment thread.
class TaskCommentsRepository {
  TaskCommentsRepository();

  static final List<TaskComment> _seed =
      List<TaskComment>.of(ProjectsSeed.comments);

  final StreamController<List<TaskComment>> _changes =
      StreamController<List<TaskComment>>.broadcast();

  Future<List<TaskComment>> getForTask(String taskId) async {
    final out = _seed.where((c) => c.taskId == taskId).toList()
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));
    return List.unmodifiable(out);
  }

  Stream<List<TaskComment>> watchForTask(String taskId) async* {
    yield await getForTask(taskId);
    yield* _changes.stream.map((all) {
      final out = all.where((c) => c.taskId == taskId).toList()
        ..sort((a, b) => a.postedAt.compareTo(b.postedAt));
      return List<TaskComment>.unmodifiable(out);
    });
  }

  /// Append a comment. Repo assigns the id when blank.
  Future<TaskComment> create(TaskComment comment) async {
    final id = comment.id.isEmpty
        ? 'cmt-${DateTime.now().microsecondsSinceEpoch}'
        : comment.id;
    final stamped = comment.copyWith(id: id);
    _seed.add(stamped);
    _emit();
    return stamped;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}
