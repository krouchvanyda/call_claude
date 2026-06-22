import 'package:erp_mobile/features/hr/data/repositories/employees_repository.dart';
import 'package:erp_mobile/features/hr/entities/employee.dart';
import 'package:test/test.dart';

Employee _e({
  required String id,
  required String name,
  String email = 'x@erp.example',
  String department = 'Sales',
  String position = 'Account Executive',
  EmploymentStatus status = EmploymentStatus.active,
  DateTime? hiredAt,
  String? managerId,
}) =>
    Employee(
      id: id,
      name: name,
      email: email,
      phone: '+855 12 345 678',
      department: department,
      position: position,
      hiredAt: hiredAt ?? DateTime.utc(2024, 1, 1),
      status: status,
      monthlySalary: r'$1,000.00',
      managerId: managerId,
    );

Employee _node(String id, String name, {String? managerId}) => Employee(
      id: id,
      name: name,
      email: '$id@erp.example',
      phone: '+855',
      department: 'X',
      position: 'P',
      hiredAt: DateTime.utc(2024, 1, 1),
      status: EmploymentStatus.active,
      monthlySalary: r'$1,000.00',
      managerId: managerId,
    );

void main() {
  group('applyEmployeeQuery', () {
    final all = [
      _e(id: '1', name: 'Alice', department: 'Sales',
          hiredAt: DateTime.utc(2025, 6, 1)),
      _e(id: '2', name: 'Bob', department: 'Engineering',
          hiredAt: DateTime.utc(2024, 1, 15)),
      _e(id: '3', name: 'Charlie', department: 'Sales',
          status: EmploymentStatus.terminated,
          hiredAt: DateTime.utc(2023, 5, 1)),
      _e(id: '4', name: 'Diana', department: 'Finance', position: 'CFO',
          hiredAt: DateTime.utc(2022, 9, 9)),
    ];

    test('default sort is name ascending', () {
      final out = applyEmployeeQuery(all);
      expect(out.map((e) => e.name).toList(),
          ['Alice', 'Bob', 'Charlie', 'Diana']);
    });

    test('department filter narrows the list', () {
      final out = applyEmployeeQuery(all, departmentFilter: {'Sales'});
      expect(out.map((e) => e.id).toSet(), {'1', '3'});
    });

    test('status filter narrows the list', () {
      final out =
          applyEmployeeQuery(all, statusFilter: {EmploymentStatus.terminated});
      expect(out.single.id, '3');
    });

    test('search hits name, email, position case-insensitively', () {
      // Name match.
      expect(applyEmployeeQuery(all, searchQuery: 'AL').map((e) => e.id),
          ['1']);
      // Position match.
      expect(applyEmployeeQuery(all, searchQuery: 'cfo').single.id, '4');
    });

    test('recently hired sorts most-recent first', () {
      final out = applyEmployeeQuery(all, sort: EmployeeSort.recentlyHired);
      expect(out.first.name, 'Alice'); // 2025-06-01
      expect(out.last.name, 'Diana');  // 2022-09-09
    });

    test('department sort is stable on name within department', () {
      final out = applyEmployeeQuery(all, sort: EmployeeSort.departmentAsc);
      expect(out.map((e) => e.name).toList(),
          ['Bob', 'Diana', 'Alice', 'Charlie']);
    });

    test('empty input → empty output regardless of filters', () {
      expect(applyEmployeeQuery(const []), isEmpty);
      expect(
        applyEmployeeQuery(const [], departmentFilter: {'Sales'}),
        isEmpty,
      );
    });
  });

  group('extractDepartments', () {
    test('returns unique sorted department names', () {
      final out = extractDepartments([
        _e(id: '1', name: 'A', department: 'Sales'),
        _e(id: '2', name: 'B', department: 'Engineering'),
        _e(id: '3', name: 'C', department: 'Sales'),
        _e(id: '4', name: 'D', department: 'Finance'),
      ]);
      expect(out, ['Engineering', 'Finance', 'Sales']);
    });

    test('empty input → empty list', () {
      expect(extractDepartments(const []), isEmpty);
    });
  });

  group('buildOrgChart', () {
    test('null managerId becomes a root', () {
      final roots = buildOrgChart([_node('a', 'Alice')]);
      expect(roots, hasLength(1));
      expect(roots.single.depth, 0);
      expect(roots.single.reports, isEmpty);
    });

    test('children attach to their manager and depth increments', () {
      final roots = buildOrgChart([
        _node('a', 'Alice'),
        _node('b', 'Bob', managerId: 'a'),
        _node('c', 'Carol', managerId: 'b'),
      ]);
      expect(roots, hasLength(1));
      expect(roots.single.employee.id, 'a');
      expect(roots.single.reports, hasLength(1));
      expect(roots.single.reports.single.depth, 1);
      expect(roots.single.reports.single.reports.single.depth, 2);
    });

    test('unknown managerId promotes to root rather than dropping the node',
        () {
      final roots = buildOrgChart([
        _node('a', 'Alice', managerId: 'ghost'), // ghost not in set
      ]);
      expect(roots, hasLength(1));
      expect(roots.single.employee.id, 'a');
    });

    test('siblings sort by name', () {
      final roots = buildOrgChart([
        _node('a', 'Alice'),
        _node('z', 'Zach', managerId: 'a'),
        _node('m', 'Mary', managerId: 'a'),
      ]);
      final reportNames =
          roots.single.reports.map((n) => n.employee.name).toList();
      expect(reportNames, ['Mary', 'Zach']);
    });

    test('cycle does not infinite-loop; each employee appears once', () {
      // a → b → a (synthetic cycle)
      final roots = buildOrgChart([
        _node('a', 'Alice', managerId: 'b'),
        _node('b', 'Bob', managerId: 'a'),
      ]);
      final flat = flattenOrgChart(roots);
      expect(flat.map((n) => n.employee.id).toSet(), {'a', 'b'});
    });

    test('flattenOrgChart visits parent before children depth-first', () {
      final roots = buildOrgChart([
        _node('a', 'Alice'),
        _node('b', 'Bob', managerId: 'a'),
        _node('c', 'Carol', managerId: 'a'),
      ]);
      final flat = flattenOrgChart(roots);
      expect(flat.map((n) => n.employee.name).toList(),
          ['Alice', 'Bob', 'Carol']);
    });
  });
}
