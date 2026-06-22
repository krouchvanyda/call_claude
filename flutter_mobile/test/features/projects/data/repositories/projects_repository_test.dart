import 'package:erp_mobile/features/projects/data/repositories/projects_repository.dart';
import 'package:erp_mobile/features/projects/entities/project.dart';
import 'package:test/test.dart';

Project _p({
  required String id,
  required String name,
  String code = 'CODE',
  ProjectStatus status = ProjectStatus.active,
  DateTime? startDate,
  DateTime? endDate,
  String ownerName = 'Owner',
}) =>
    Project(
      id: id,
      code: code,
      name: name,
      description: 'desc',
      startDate: startDate ?? DateTime.utc(2026, 1, 1),
      endDate: endDate ?? DateTime.utc(2026, 6, 30),
      status: status,
      ownerId: 'o',
      ownerName: ownerName,
      budget: r'$10,000.00',
    );

void main() {
  group('applyProjectQuery', () {
    final all = [
      _p(id: '1', name: 'Alpha', code: 'A', status: ProjectStatus.active,
          startDate: DateTime.utc(2026, 5, 1)),
      _p(id: '2', name: 'Beta', code: 'B', status: ProjectStatus.completed,
          startDate: DateTime.utc(2026, 1, 15)),
      _p(id: '3', name: 'Charlie', code: 'C', status: ProjectStatus.planning,
          startDate: DateTime.utc(2026, 6, 1),
          endDate: DateTime.utc(2026, 9, 30)),
      _p(id: '4', name: 'Delta', code: 'D', status: ProjectStatus.onHold,
          startDate: DateTime.utc(2026, 3, 1),
          endDate: DateTime.utc(2026, 4, 30)),
    ];

    test('default sort is name ascending', () {
      final out = applyProjectQuery(all);
      expect(out.map((p) => p.name).toList(),
          ['Alpha', 'Beta', 'Charlie', 'Delta']);
    });

    test('status filter narrows the list', () {
      final out = applyProjectQuery(all,
          statusFilter: {ProjectStatus.active, ProjectStatus.planning});
      expect(out.map((p) => p.id).toSet(), {'1', '3'});
    });

    test('search hits name, code, owner case-insensitively', () {
      // Code match.
      expect(applyProjectQuery(all, searchQuery: 'b').map((p) => p.id),
          ['2']);
      // Name match.
      expect(applyProjectQuery(all, searchQuery: 'CHAR').single.id, '3');
    });

    test('recently started sorts most-recent first', () {
      final out = applyProjectQuery(all, sort: ProjectSort.recentlyStarted);
      expect(out.first.id, '3'); // 2026-06-01
      expect(out.last.id, '2');  // 2026-01-15
    });

    test('due soonest sorts earliest end first', () {
      final out = applyProjectQuery(all, sort: ProjectSort.dueSoonest);
      expect(out.first.id, '4'); // 2026-04-30
      expect(out.last.id, '3');  // 2026-09-30
    });

    test('empty input → empty output', () {
      expect(applyProjectQuery(const []), isEmpty);
    });
  });
}
