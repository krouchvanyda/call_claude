import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/projects/data/repositories/tasks_repository.dart';
import 'package:erp_mobile/features/projects/entities/task.dart';
import 'package:test/test.dart';

ProjectTask _t({
  String id = 't',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
}) =>
    ProjectTask(
      id: id,
      projectId: 'p',
      title: id,
      description: '',
      status: status,
      priority: priority,
      createdAt: DateTime.utc(2026, 5, 1),
      dueDate: dueDate,
    );

void main() {
  group('TasksRepository.move', () {
    final repo = TasksRepository();

    test('no-op when target equals current status', () {
      final t = _t(status: TaskStatus.inProgress);
      expect(repo.move(task: t, toStatus: TaskStatus.inProgress), same(t));
    });

    test('free movement between active stages', () {
      // todo → inReview (skip middle)
      expect(
        repo.move(
          task: _t(status: TaskStatus.todo),
          toStatus: TaskStatus.inReview,
        ).status,
        TaskStatus.inReview,
      );
      // inReview → todo (drag back)
      expect(
        repo.move(
          task: _t(status: TaskStatus.inReview),
          toStatus: TaskStatus.todo,
        ).status,
        TaskStatus.todo,
      );
    });

    test('any active → done is allowed', () {
      for (final s in [
        TaskStatus.todo,
        TaskStatus.inProgress,
        TaskStatus.inReview,
      ]) {
        expect(
          repo.move(task: _t(status: s), toStatus: TaskStatus.done).status,
          TaskStatus.done,
        );
      }
    });

    test('done → inProgress allowed (re-open)', () {
      expect(
        repo.move(
          task: _t(status: TaskStatus.done),
          toStatus: TaskStatus.inProgress,
        ).status,
        TaskStatus.inProgress,
      );
    });

    test('done → todo throws ConflictFailure', () {
      expect(
        () => repo.move(
          task: _t(status: TaskStatus.done),
          toStatus: TaskStatus.todo,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('done → inReview throws ConflictFailure', () {
      expect(
        () => repo.move(
          task: _t(status: TaskStatus.done),
          toStatus: TaskStatus.inReview,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('groupTasksByStatus', () {
    test('returns all four columns even when empty', () {
      final groups = groupTasksByStatus(const []);
      expect(groups.keys.toSet(), TaskStatus.values.toSet());
      for (final list in groups.values) {
        expect(list, isEmpty);
      }
    });

    test('priority desc sorts urgent first within a column', () {
      final groups = groupTasksByStatus([
        _t(id: 'low', priority: TaskPriority.low),
        _t(id: 'urgent', priority: TaskPriority.urgent),
        _t(id: 'high', priority: TaskPriority.high),
      ]);
      expect(
        groups[TaskStatus.todo]!.map((t) => t.id).toList(),
        ['urgent', 'high', 'low'],
      );
    });

    test('within same priority, soonest dueDate first; nulls last', () {
      final groups = groupTasksByStatus([
        _t(id: 'no-date'),
        _t(id: 'late', dueDate: DateTime.utc(2026, 5, 30)),
        _t(id: 'early', dueDate: DateTime.utc(2026, 5, 10)),
      ]);
      expect(
        groups[TaskStatus.todo]!.map((t) => t.id).toList(),
        ['early', 'late', 'no-date'],
      );
    });
  });
}
