import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/hr/data/repositories/attendance_repository.dart';
import 'package:erp_mobile/features/hr/entities/attendance_entry.dart';
import 'package:test/test.dart';

void main() {
  group('AttendanceRepository.toggleClock', () {
    final repo = AttendanceRepository();
    String idGen() => 'gen-id';

    test('null latest → ClockInAction at today\'s date', () {
      final action = repo.toggleClock(
        latest: null,
        employeeId: 'emp-1',
        now: DateTime.utc(2026, 5, 15, 8, 30),
        newId: idGen,
      );
      expect(action, isA<ClockInAction>());
      final draft = (action as ClockInAction).draft;
      expect(draft.id, 'gen-id');
      expect(draft.date, DateTime.utc(2026, 5, 15));
      expect(draft.clockIn, DateTime.utc(2026, 5, 15, 8, 30));
      expect(draft.clockOut, isNull);
    });

    test('latest closed → ClockInAction (new entry)', () {
      final closed = AttendanceEntry(
        id: 'old',
        employeeId: 'emp-1',
        date: DateTime.utc(2026, 5, 14),
        clockIn: DateTime.utc(2026, 5, 14, 8),
        clockOut: DateTime.utc(2026, 5, 14, 17),
      );
      final action = repo.toggleClock(
        latest: closed,
        employeeId: 'emp-1',
        now: DateTime.utc(2026, 5, 15, 8),
        newId: idGen,
      );
      expect(action, isA<ClockInAction>());
    });

    test('latest open → ClockOutAction stamping clockOut', () {
      final open = AttendanceEntry(
        id: 'open',
        employeeId: 'emp-1',
        date: DateTime.utc(2026, 5, 15),
        clockIn: DateTime.utc(2026, 5, 15, 8),
      );
      final action = repo.toggleClock(
        latest: open,
        employeeId: 'emp-1',
        now: DateTime.utc(2026, 5, 15, 17),
        newId: idGen,
      );
      expect(action, isA<ClockOutAction>());
      final updated = (action as ClockOutAction).updated;
      expect(updated.id, 'open');
      expect(updated.clockOut, DateTime.utc(2026, 5, 15, 17));
      expect(updated.workedMinutes, 9 * 60);
    });

    test('open entry from a different employee throws ConflictFailure', () {
      final open = AttendanceEntry(
        id: 'open',
        employeeId: 'emp-2',
        date: DateTime.utc(2026, 5, 15),
        clockIn: DateTime.utc(2026, 5, 15, 8),
      );
      expect(
        () => repo.toggleClock(
          latest: open,
          employeeId: 'emp-1',
          now: DateTime.utc(2026, 5, 15, 17),
          newId: idGen,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('clock-out before clock-in throws ValidationFailure', () {
      final open = AttendanceEntry(
        id: 'open',
        employeeId: 'emp-1',
        date: DateTime.utc(2026, 5, 15),
        clockIn: DateTime.utc(2026, 5, 15, 12),
      );
      expect(
        () => repo.toggleClock(
          latest: open,
          employeeId: 'emp-1',
          now: DateTime.utc(2026, 5, 15, 8),
          newId: idGen,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
