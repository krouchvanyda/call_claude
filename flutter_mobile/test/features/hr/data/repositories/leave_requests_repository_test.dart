import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/hr/data/repositories/leave_requests_repository.dart';
import 'package:erp_mobile/features/hr/entities/leave_request.dart';
import 'package:test/test.dart';

LeaveRequest _pending() => LeaveRequest(
      id: 'lv-1',
      employeeId: 'emp-1',
      employeeName: 'A',
      type: LeaveType.annual,
      fromDate: DateTime.utc(2026, 5, 16),
      toDate: DateTime.utc(2026, 5, 17),
      reason: 'r',
      status: LeaveRequestStatus.pending,
      requestedAt: DateTime.utc(2026, 5, 14),
    );

LeaveBalance _b(LeaveType t, {int total = 14, int used = 0}) =>
    LeaveBalance(
      employeeId: 'emp-1',
      type: t,
      totalDays: total,
      usedDays: used,
    );

LeaveRequest _req({
  String employeeId = 'emp-1',
  LeaveType type = LeaveType.annual,
  required DateTime from,
  required DateTime to,
  LeaveRequestStatus status = LeaveRequestStatus.approved,
}) =>
    LeaveRequest(
      id: 'r-${from.day}',
      employeeId: employeeId,
      employeeName: 'A',
      type: type,
      fromDate: from,
      toDate: to,
      reason: 'r',
      status: status,
      requestedAt: from,
    );

void main() {
  group('LeaveRequestsRepository.submit', () {
    final repo = LeaveRequestsRepository();
    final now = DateTime.utc(2026, 5, 15);

    test('accepts a well-formed request', () {
      final r = repo.submit(
        employeeId: 'emp-001',
        employeeName: 'Alice',
        type: LeaveType.annual,
        fromDate: DateTime.utc(2026, 5, 16),
        toDate: DateTime.utc(2026, 5, 20),
        reason: 'Family wedding',
        now: now,
      );
      expect(r.status, LeaveRequestStatus.pending);
      expect(r.id, isEmpty); // assigned by repo
      expect(r.days, 5);
      expect(r.reason, 'Family wedding');
    });

    test('strips time of day from from/to', () {
      final r = repo.submit(
        employeeId: 'emp-001',
        employeeName: 'Alice',
        type: LeaveType.sick,
        fromDate: DateTime.utc(2026, 5, 16, 10, 30),
        toDate: DateTime.utc(2026, 5, 16, 14, 0),
        reason: 'cold',
        now: now,
      );
      expect(r.fromDate, DateTime.utc(2026, 5, 16));
      expect(r.toDate, DateTime.utc(2026, 5, 16));
      expect(r.days, 1);
    });

    test('rejects past start date', () {
      expect(
        () => repo.submit(
          employeeId: 'emp-001',
          employeeName: 'Alice',
          type: LeaveType.annual,
          fromDate: DateTime.utc(2026, 5, 14),
          toDate: DateTime.utc(2026, 5, 16),
          reason: 'r',
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('fromDate', isNotEmpty),
        )),
      );
    });

    test('rejects to-before-from', () {
      expect(
        () => repo.submit(
          employeeId: 'emp-001',
          employeeName: 'Alice',
          type: LeaveType.annual,
          fromDate: DateTime.utc(2026, 5, 20),
          toDate: DateTime.utc(2026, 5, 18),
          reason: 'r',
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('toDate', isNotEmpty),
        )),
      );
    });

    test('rejects empty employee id and reason', () {
      expect(
        () => repo.submit(
          employeeId: '',
          employeeName: 'Alice',
          type: LeaveType.annual,
          fromDate: DateTime.utc(2026, 5, 16),
          toDate: DateTime.utc(2026, 5, 17),
          reason: '   ',
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          allOf(
            containsPair('employeeId', isNotEmpty),
            containsPair('reason', isNotEmpty),
          ),
        )),
      );
    });
  });

  group('LeaveRequestsRepository.approve', () {
    final repo = LeaveRequestsRepository();

    test('stamps approver + actionedAt and flips to approved', () {
      final r = repo.approve(
        request: _pending(),
        approverId: 'mgr-1',
        now: DateTime.utc(2026, 5, 15, 10),
      );
      expect(r.status, LeaveRequestStatus.approved);
      expect(r.approvedBy, 'mgr-1');
      expect(r.actionedAt, DateTime.utc(2026, 5, 15, 10));
    });

    test('throws ConflictFailure if already approved', () {
      final already = _pending().copyWith(status: LeaveRequestStatus.approved);
      expect(
        () => repo.approve(
          request: already,
          approverId: 'mgr-1',
          now: DateTime.utc(2026, 5, 15),
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('LeaveRequestsRepository.reject', () {
    final repo = LeaveRequestsRepository();

    test('records the reason verbatim (trimmed)', () {
      final r = repo.reject(
        request: _pending(),
        approverId: 'mgr-1',
        now: DateTime.utc(2026, 5, 15),
        reason: '  No coverage  ',
      );
      expect(r.status, LeaveRequestStatus.rejected);
      expect(r.decisionNote, 'No coverage');
    });

    test('throws ValidationFailure when reason is empty', () {
      expect(
        () => repo.reject(
          request: _pending(),
          approverId: 'mgr-1',
          now: DateTime.utc(2026, 5, 15),
          reason: '   ',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('throws ConflictFailure when not pending', () {
      final already = _pending().copyWith(status: LeaveRequestStatus.rejected);
      expect(
        () => repo.reject(
          request: already,
          approverId: 'mgr-1',
          now: DateTime.utc(2026, 5, 15),
          reason: 'r',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('LeaveRequestsRepository.cancel', () {
    final repo = LeaveRequestsRepository();

    test('flips to cancelled', () {
      final r = repo.cancel(
        request: _pending(),
        now: DateTime.utc(2026, 5, 15),
      );
      expect(r.status, LeaveRequestStatus.cancelled);
    });

    test('throws ConflictFailure once decided', () {
      final approved =
          _pending().copyWith(status: LeaveRequestStatus.approved);
      expect(
        () => repo.cancel(
          request: approved,
          now: DateTime.utc(2026, 5, 15),
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('computeEffectiveBalances', () {
    test('approved requests deduct from baseline', () {
      final out = computeEffectiveBalances(
        baselines: [_b(LeaveType.annual, total: 14, used: 2)],
        requests: [
          _req(
            from: DateTime.utc(2026, 5, 16),
            to: DateTime.utc(2026, 5, 18),
          ), // 3 days
        ],
        employeeId: 'emp-1',
      );
      expect(out.single.usedDays, 5);
      expect(out.single.remainingDays, 9);
    });

    test('pending / rejected / cancelled requests do NOT deduct', () {
      final out = computeEffectiveBalances(
        baselines: [_b(LeaveType.annual, total: 10, used: 0)],
        requests: [
          _req(
            from: DateTime.utc(2026, 5, 16),
            to: DateTime.utc(2026, 5, 17),
            status: LeaveRequestStatus.pending,
          ),
          _req(
            from: DateTime.utc(2026, 5, 18),
            to: DateTime.utc(2026, 5, 19),
            status: LeaveRequestStatus.rejected,
          ),
          _req(
            from: DateTime.utc(2026, 5, 20),
            to: DateTime.utc(2026, 5, 20),
            status: LeaveRequestStatus.cancelled,
          ),
        ],
        employeeId: 'emp-1',
      );
      expect(out.single.usedDays, 0);
    });

    test('different leave types are bucketed independently', () {
      final out = computeEffectiveBalances(
        baselines: [
          _b(LeaveType.annual, total: 14, used: 0),
          _b(LeaveType.sick, total: 10, used: 0),
        ],
        requests: [
          _req(
            from: DateTime.utc(2026, 5, 16),
            to: DateTime.utc(2026, 5, 16),
            type: LeaveType.sick,
          ),
        ],
        employeeId: 'emp-1',
      );
      final byType = {for (final b in out) b.type: b};
      expect(byType[LeaveType.annual]!.usedDays, 0);
      expect(byType[LeaveType.sick]!.usedDays, 1);
    });

    test('other employees are ignored', () {
      final out = computeEffectiveBalances(
        baselines: [_b(LeaveType.annual)],
        requests: [
          _req(
            employeeId: 'emp-2',
            from: DateTime.utc(2026, 5, 16),
            to: DateTime.utc(2026, 5, 18),
          ),
        ],
        employeeId: 'emp-1',
      );
      expect(out.single.usedDays, 0);
    });

    test('remainingDays clamps at 0 when over-used', () {
      final out = computeEffectiveBalances(
        baselines: [_b(LeaveType.annual, total: 3, used: 0)],
        requests: [
          _req(
            from: DateTime.utc(2026, 5, 16),
            to: DateTime.utc(2026, 5, 25),
          ), // 10 days
        ],
        employeeId: 'emp-1',
      );
      expect(out.single.remainingDays, 0);
    });
  });
}
