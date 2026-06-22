import 'package:erp_mobile/features/projects/data/repositories/projects_repository.dart';
import 'package:erp_mobile/features/projects/entities/project.dart';
import 'package:test/test.dart';

Project _p(String id, DateTime start, DateTime end) => Project(
      id: id,
      code: id,
      name: id,
      description: '',
      startDate: start,
      endDate: end,
      status: ProjectStatus.active,
      ownerId: 'o',
      ownerName: 'O',
      budget: r'$0',
    );

void main() {
  group('computeGanttLayout', () {
    test('project fully inside window — full width, offset from start', () {
      final rows = computeGanttLayout(
        projects: [
          _p('p1', DateTime.utc(2026, 5, 5), DateTime.utc(2026, 5, 10)),
        ],
        windowStart: DateTime.utc(2026, 5, 1),
        windowEnd: DateTime.utc(2026, 5, 31),
      );
      expect(rows, hasLength(1));
      expect(rows.single.startOffsetDays, 4);
      expect(rows.single.widthDays, 6);
    });

    test('project starting before window — clipped to start', () {
      final rows = computeGanttLayout(
        projects: [
          _p('p1', DateTime.utc(2026, 4, 1), DateTime.utc(2026, 5, 10)),
        ],
        windowStart: DateTime.utc(2026, 5, 1),
        windowEnd: DateTime.utc(2026, 5, 31),
      );
      expect(rows.single.startOffsetDays, 0);
      expect(rows.single.widthDays, 10);
    });

    test('project ending after window — clipped to end', () {
      final rows = computeGanttLayout(
        projects: [
          _p('p1', DateTime.utc(2026, 5, 28), DateTime.utc(2026, 6, 30)),
        ],
        windowStart: DateTime.utc(2026, 5, 1),
        windowEnd: DateTime.utc(2026, 5, 31),
      );
      expect(rows.single.startOffsetDays, 27);
      expect(rows.single.widthDays, 4);
    });

    test('project entirely outside window is dropped', () {
      final rows = computeGanttLayout(
        projects: [
          _p('p1', DateTime.utc(2026, 1, 1), DateTime.utc(2026, 1, 10)),
          _p('p2', DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 10)),
        ],
        windowStart: DateTime.utc(2026, 5, 1),
        windowEnd: DateTime.utc(2026, 5, 31),
      );
      expect(rows, isEmpty);
    });

    test('rows sort by start offset, then width desc', () {
      final rows = computeGanttLayout(
        projects: [
          _p('late', DateTime.utc(2026, 5, 10), DateTime.utc(2026, 5, 12)),
          _p('long', DateTime.utc(2026, 5, 5), DateTime.utc(2026, 5, 25)),
          _p('short',
              DateTime.utc(2026, 5, 5), DateTime.utc(2026, 5, 7)),
        ],
        windowStart: DateTime.utc(2026, 5, 1),
        windowEnd: DateTime.utc(2026, 5, 31),
      );
      expect(rows.map((r) => r.project.id).toList(),
          ['long', 'short', 'late']);
    });

    test('inverted window returns empty', () {
      expect(
        computeGanttLayout(
          projects: [
            _p('p1', DateTime.utc(2026, 5, 5), DateTime.utc(2026, 5, 10)),
          ],
          windowStart: DateTime.utc(2026, 6, 1),
          windowEnd: DateTime.utc(2026, 5, 1),
        ),
        isEmpty,
      );
    });
  });

  group('windowDays', () {
    test('counts inclusively', () {
      expect(
        windowDays(DateTime.utc(2026, 5, 1), DateTime.utc(2026, 5, 31)),
        31,
      );
    });

    test('inverted bounds → 0', () {
      expect(
        windowDays(DateTime.utc(2026, 5, 31), DateTime.utc(2026, 5, 1)),
        0,
      );
    });
  });
}
