import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/leave_request.dart';
import '../hr_seed.dart';

/// Slice 7.2.1 + 7.2.3 — leave requests with manager approval workflow.
class LeaveRequestsRepository {
  LeaveRequestsRepository();

  static final List<LeaveRequest> _seed =
      List<LeaveRequest>.of(HrSeed.leaveRequests);

  final StreamController<List<LeaveRequest>> _changes =
      StreamController<List<LeaveRequest>>.broadcast();

  Future<List<LeaveRequest>> getAll() async => List.unmodifiable(_seed);

  Stream<List<LeaveRequest>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<LeaveRequest?> findById(String id) async {
    for (final r in _seed) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Slice 7.2.1 — create a pending request.
  Future<LeaveRequest> create(LeaveRequest request) async {
    final id = request.id.isEmpty
        ? 'lv-${DateTime.now().microsecondsSinceEpoch}'
        : request.id;
    final stamped = request.copyWith(id: id);
    _seed.insert(0, stamped);
    _emit();
    return stamped;
  }

  /// Slice 7.2.3 — replaces in-place. Caller is responsible for valid
  /// state transitions (use [submit] / [approve] / [reject] / [cancel],
  /// not this directly).
  Future<LeaveRequest> update(LeaveRequest request) async {
    final idx = _seed.indexWhere((r) => r.id == request.id);
    if (idx == -1) {
      _seed.insert(0, request);
    } else {
      _seed[idx] = request;
    }
    _emit();
    return request;
  }

  /// Slice 7.2.1 — validates a draft request before it enters the
  /// "pending" queue. Pure-Dart so the form bloc + the API receiver can
  /// both reuse it.
  ///
  /// Throws [ValidationFailure] with field-level errors on bad input.
  /// Returns the canonical (status-stamped) [LeaveRequest] on success;
  /// the repository is responsible for assigning the id.
  LeaveRequest submit({
    required String employeeId,
    required String employeeName,
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required DateTime now,
  }) {
    final errors = <String, List<String>>{};
    if (employeeId.isEmpty) {
      errors.putIfAbsent('employeeId', () => []).add('Required');
    }
    // Strip time of day — leave is a calendar-date concept.
    final from = DateTime.utc(fromDate.year, fromDate.month, fromDate.day);
    final to = DateTime.utc(toDate.year, toDate.month, toDate.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    if (to.isBefore(from)) {
      errors.putIfAbsent('toDate', () => []).add('Must be on or after the start date');
    }
    if (from.isBefore(today)) {
      errors.putIfAbsent('fromDate', () => []).add('Cannot request past dates');
    }
    if (reason.trim().isEmpty) {
      errors.putIfAbsent('reason', () => []).add('Required');
    }
    if (errors.isNotEmpty) {
      throw ValidationFailure(fieldErrors: errors);
    }

    return LeaveRequest(
      id: '', // assigned by repo
      employeeId: employeeId,
      employeeName: employeeName,
      type: type,
      fromDate: from,
      toDate: to,
      reason: reason.trim(),
      status: LeaveRequestStatus.pending,
      requestedAt: now,
    );
  }

  /// Slice 7.2.3 — manager approves a pending request.
  ///
  /// State-machine guard: throws [ConflictFailure] when the request is
  /// no longer pending. The result is a new [LeaveRequest] stamped with
  /// the decision metadata so the repository can swap it in atomically.
  LeaveRequest approve({
    required LeaveRequest request,
    required String approverId,
    required DateTime now,
    String? note,
  }) {
    if (request.status != LeaveRequestStatus.pending) {
      throw ConflictFailure(message: 'Already ${request.status.name}');
    }
    return request.copyWith(
      status: LeaveRequestStatus.approved,
      approvedBy: approverId,
      actionedAt: now,
      decisionNote: note,
    );
  }

  /// Slice 7.2.3 — manager rejects a pending request. Reason is
  /// mandatory at the domain level (matches the procurement-side
  /// pattern — not just a form concern).
  LeaveRequest reject({
    required LeaveRequest request,
    required String approverId,
    required DateTime now,
    required String reason,
  }) {
    if (request.status != LeaveRequestStatus.pending) {
      throw ConflictFailure(message: 'Already ${request.status.name}');
    }
    if (reason.trim().isEmpty) {
      // Match the procurement-side pattern: rejection reason is mandatory
      // at the domain level, not just the form.
      throw ValidationFailure(fieldErrors: {
        'reason': ['Required'],
      });
    }
    return request.copyWith(
      status: LeaveRequestStatus.rejected,
      approvedBy: approverId,
      actionedAt: now,
      decisionNote: reason.trim(),
    );
  }

  /// Employee-side action — only the requester can cancel, and only while
  /// the request is still pending. We don't enforce "only the requester"
  /// here (that's a permissions concern) but the state guard is universal.
  LeaveRequest cancel({
    required LeaveRequest request,
    required DateTime now,
  }) {
    if (request.status != LeaveRequestStatus.pending) {
      throw ConflictFailure(message: 'Already ${request.status.name}');
    }
    return request.copyWith(
      status: LeaveRequestStatus.cancelled,
      actionedAt: now,
    );
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

/// Slice 7.2.2 — read-only baselines feed for the balance widget.
class LeaveBalancesRepository {
  LeaveBalancesRepository();

  static final List<LeaveBalance> _seed =
      List<LeaveBalance>.of(HrSeed.leaveBalances);

  final StreamController<List<LeaveBalance>> _changes =
      StreamController<List<LeaveBalance>>.broadcast();

  Future<List<LeaveBalance>> getForEmployee(String employeeId) async =>
      List.unmodifiable(_seed.where((b) => b.employeeId == employeeId));

  Stream<List<LeaveBalance>> watchForEmployee(String employeeId) async* {
    yield await getForEmployee(employeeId);
    yield* _changes.stream
        .map((all) => all.where((b) => b.employeeId == employeeId).toList());
  }
}

/// Slice 7.2.2 — derive an effective balance per leave type.
///
/// **Why a derivation, not a stored field**: the seed-provided
/// `usedDays` reflects what was booked at the start of the period, but
/// new requests can land between then and now. By layering approved
/// requests on top of the baseline we keep the widget honest without
/// rewriting the seed on every approval.
///
/// Only `approved` requests are counted. `pending` / `rejected` /
/// `cancelled` leave the balance untouched — surfacing pending balance
/// would lie about what the employee can actually book today.
List<LeaveBalance> computeEffectiveBalances({
  required List<LeaveBalance> baselines,
  required List<LeaveRequest> requests,
  required String employeeId,
}) {
  final approvedByType = <LeaveType, int>{};
  for (final r in requests) {
    if (r.employeeId != employeeId) continue;
    if (r.status != LeaveRequestStatus.approved) continue;
    approvedByType.update(r.type, (v) => v + r.days, ifAbsent: () => r.days);
  }

  final out = <LeaveBalance>[];
  // Preserve the order the baselines came in so the widget renders the
  // expected leave types even when usage is zero.
  for (final b in baselines) {
    if (b.employeeId != employeeId) continue;
    final extra = approvedByType[b.type] ?? 0;
    out.add(b.copyWith(usedDays: b.usedDays + extra));
  }
  return out;
}
