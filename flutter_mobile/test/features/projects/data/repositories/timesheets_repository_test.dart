import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/projects/data/repositories/timesheets_repository.dart';
import 'package:erp_mobile/features/projects/entities/timesheet_entry.dart';
import 'package:test/test.dart';

TimesheetEntry _submitted() => TimesheetEntry(
      id: 'ts',
      employeeId: 'emp-1',
      employeeName: 'A',
      projectId: 'p',
      projectName: 'P',
      date: DateTime.utc(2026, 5, 14),
      hours: 4,
      description: 'r',
      status: TimesheetStatus.submitted,
    );

TimesheetEntry _e({
  String employeeId = 'emp-1',
  String name = 'Alice',
  required DateTime date,
  required num hours,
  TimesheetStatus status = TimesheetStatus.approved,
}) =>
    TimesheetEntry(
      id: 'e-${date.day}-$employeeId',
      employeeId: employeeId,
      employeeName: name,
      projectId: 'p',
      projectName: 'P',
      date: date,
      hours: hours,
      description: 'r',
      status: status,
    );

void main() {
  group('TimesheetsRepository.validate', () {
    final repo = TimesheetsRepository();
    final now = DateTime.utc(2026, 5, 15);

    test('accepts a well-formed entry as draft', () {
      final r = repo.validate(
        employeeId: 'emp-1',
        employeeName: 'Alice',
        projectId: 'proj-1',
        projectName: 'Alpha',
        date: DateTime.utc(2026, 5, 14),
        hours: 6.5,
        description: 'pair programming',
        now: now,
      );
      expect(r.status, TimesheetStatus.draft);
      expect(r.id, isEmpty);
      expect(r.hours, 6.5);
    });

    test('rejects future date', () {
      expect(
        () => repo.validate(
          employeeId: 'emp-1',
          employeeName: 'Alice',
          projectId: 'proj-1',
          projectName: 'Alpha',
          date: DateTime.utc(2026, 5, 16), // tomorrow
          hours: 4,
          description: 'r',
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('date', isNotEmpty),
        )),
      );
    });

    test('rejects zero or negative hours', () {
      expect(
        () => repo.validate(
          employeeId: 'emp-1',
          employeeName: 'Alice',
          projectId: 'proj-1',
          projectName: 'Alpha',
          date: DateTime.utc(2026, 5, 14),
          hours: 0,
          description: 'r',
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('hours', isNotEmpty),
        )),
      );
    });

    test('caps hours at 24 in a single line', () {
      expect(
        () => repo.validate(
          employeeId: 'emp-1',
          employeeName: 'Alice',
          projectId: 'proj-1',
          projectName: 'Alpha',
          date: DateTime.utc(2026, 5, 14),
          hours: 25,
          description: 'r',
          now: now,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('requires description and project', () {
      expect(
        () => repo.validate(
          employeeId: 'emp-1',
          employeeName: 'Alice',
          projectId: '',
          projectName: '',
          date: DateTime.utc(2026, 5, 14),
          hours: 4,
          description: '   ',
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          allOf(
            containsPair('projectId', isNotEmpty),
            containsPair('description', isNotEmpty),
          ),
        )),
      );
    });
  });

  group('TimesheetsRepository.submit', () {
    final repo = TimesheetsRepository();

    test('promotes draft to submitted', () {
      final draft = TimesheetEntry(
        id: 'ts',
        employeeId: 'emp-1',
        employeeName: 'A',
        projectId: 'p',
        projectName: 'P',
        date: DateTime.utc(2026, 5, 14),
        hours: 4,
        description: 'r',
        status: TimesheetStatus.draft,
      );
      expect(repo.submit(draft).status, TimesheetStatus.submitted);
    });

    test('throws when not draft', () {
      final approved = TimesheetEntry(
        id: 'ts',
        employeeId: 'emp-1',
        employeeName: 'A',
        projectId: 'p',
        projectName: 'P',
        date: DateTime.utc(2026, 5, 14),
        hours: 4,
        description: 'r',
        status: TimesheetStatus.approved,
      );
      expect(
        () => repo.submit(approved),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('TimesheetsRepository.approve', () {
    final repo = TimesheetsRepository();

    test('stamps approver and flips to approved', () {
      final r = repo.approve(
        entry: _submitted(),
        approverId: 'mgr-1',
        now: DateTime.utc(2026, 5, 15, 9),
      );
      expect(r.status, TimesheetStatus.approved);
      expect(r.approverId, 'mgr-1');
      expect(r.actionedAt, DateTime.utc(2026, 5, 15, 9));
    });

    test('throws when not submitted', () {
      final draft = _submitted().copyWith(status: TimesheetStatus.draft);
      expect(
        () => repo.approve(
          entry: draft,
          approverId: 'mgr-1',
          now: DateTime.utc(2026, 5, 15),
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('TimesheetsRepository.reject', () {
    final repo = TimesheetsRepository();

    test('records reason verbatim (trimmed)', () {
      final r = repo.reject(
        entry: _submitted(),
        approverId: 'mgr-1',
        now: DateTime.utc(2026, 5, 15),
        reason: '  Wrong project  ',
      );
      expect(r.status, TimesheetStatus.rejected);
      expect(r.decisionNote, 'Wrong project');
    });

    test('throws ValidationFailure when reason is empty', () {
      expect(
        () => repo.reject(
          entry: _submitted(),
          approverId: 'mgr-1',
          now: DateTime.utc(2026, 5, 15),
          reason: '   ',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('throws ConflictFailure when not submitted', () {
      final approved =
          _submitted().copyWith(status: TimesheetStatus.approved);
      expect(
        () => repo.reject(
          entry: approved,
          approverId: 'mgr-1',
          now: DateTime.utc(2026, 5, 15),
          reason: 'r',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('TimesheetsRepository.reopenRejected', () {
    final repo = TimesheetsRepository();

    test('rejected → draft (clears decision metadata)', () {
      final rejected = _submitted().copyWith(
        status: TimesheetStatus.rejected,
        approverId: 'mgr-1',
        actionedAt: DateTime.utc(2026, 5, 15),
        decisionNote: 'r',
      );
      final r = repo.reopenRejected(rejected);
      expect(r.status, TimesheetStatus.draft);
      expect(r.approverId, isNull);
      expect(r.actionedAt, isNull);
      expect(r.decisionNote, isNull);
    });

    test('throws when not rejected', () {
      expect(
        () => repo.reopenRejected(_submitted()),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('computeUtilization', () {
    test('sums approved hours per employee', () {
      final out = computeUtilization(
        entries: [
          _e(date: DateTime.utc(2026, 5, 11), hours: 4),
          _e(date: DateTime.utc(2026, 5, 12), hours: 4),
          _e(date: DateTime.utc(2026, 5, 13), hours: 6,
              employeeId: 'emp-2', name: 'Bob'),
        ],
        from: DateTime.utc(2026, 5, 11),
        to: DateTime.utc(2026, 5, 15),
      );
      final byId = {for (final b in out) b.employeeId: b};
      expect(byId['emp-1']!.loggedHours, 8);
      expect(byId['emp-2']!.loggedHours, 6);
    });

    test('non-approved entries excluded by default', () {
      final out = computeUtilization(
        entries: [
          _e(date: DateTime.utc(2026, 5, 11), hours: 4),
          _e(
              date: DateTime.utc(2026, 5, 12),
              hours: 100,
              status: TimesheetStatus.draft),
          _e(
              date: DateTime.utc(2026, 5, 13),
              hours: 100,
              status: TimesheetStatus.submitted),
        ],
        from: DateTime.utc(2026, 5, 11),
        to: DateTime.utc(2026, 5, 15),
      );
      expect(out.single.loggedHours, 4);
    });

    test('entries outside window are skipped', () {
      final out = computeUtilization(
        entries: [
          _e(date: DateTime.utc(2026, 5, 1), hours: 8),
          _e(date: DateTime.utc(2026, 5, 11), hours: 4),
        ],
        from: DateTime.utc(2026, 5, 11),
        to: DateTime.utc(2026, 5, 15),
      );
      expect(out.single.loggedHours, 4);
    });

    test('target is weekday-count × 8 by default', () {
      // 2026-05-11 (Mon) → 2026-05-15 (Fri) = 5 weekdays = 40h target.
      final out = computeUtilization(
        entries: [_e(date: DateTime.utc(2026, 5, 11), hours: 4)],
        from: DateTime.utc(2026, 5, 11),
        to: DateTime.utc(2026, 5, 15),
      );
      expect(out.single.targetHours, 40);
      expect(out.single.utilizationPct, 10);
    });

    test('utilizationPct is 0 when target is 0 (no NaN)', () {
      // Window is Sat–Sun only → 0 weekdays → target=0.
      final out = computeUtilization(
        entries: [
          _e(date: DateTime.utc(2026, 5, 16), hours: 4), // Saturday
        ],
        from: DateTime.utc(2026, 5, 16),
        to: DateTime.utc(2026, 5, 17),
      );
      expect(out.single.utilizationPct, 0);
    });

    test('sorts by utilizationPct descending', () {
      final out = computeUtilization(
        entries: [
          _e(date: DateTime.utc(2026, 5, 11), hours: 2),
          _e(
              date: DateTime.utc(2026, 5, 11),
              hours: 8,
              employeeId: 'emp-2',
              name: 'Bob'),
        ],
        from: DateTime.utc(2026, 5, 11),
        to: DateTime.utc(2026, 5, 15),
      );
      expect(out.first.employeeId, 'emp-2');
      expect(out.last.employeeId, 'emp-1');
    });

    test('inverted window returns empty', () {
      expect(
        computeUtilization(
          entries: [_e(date: DateTime.utc(2026, 5, 11), hours: 4)],
          from: DateTime.utc(2026, 5, 15),
          to: DateTime.utc(2026, 5, 11),
        ),
        isEmpty,
      );
    });
  });

  group('countWeekdays', () {
    test('Mon–Fri returns 5', () {
      expect(
        countWeekdays(DateTime.utc(2026, 5, 11), DateTime.utc(2026, 5, 15)),
        5,
      );
    });

    test('Mon–Sun returns 5', () {
      expect(
        countWeekdays(DateTime.utc(2026, 5, 11), DateTime.utc(2026, 5, 17)),
        5,
      );
    });

    test('Sat–Sun returns 0', () {
      expect(
        countWeekdays(DateTime.utc(2026, 5, 16), DateTime.utc(2026, 5, 17)),
        0,
      );
    });
  });
}
