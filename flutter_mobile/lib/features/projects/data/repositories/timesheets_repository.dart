import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/timesheet_entry.dart';
import '../projects_seed.dart';

/// Slice 8.2.1 + 8.2.2 — timesheet entries.
class TimesheetsRepository {
  TimesheetsRepository();

  static final List<TimesheetEntry> _seed =
      List<TimesheetEntry>.of(ProjectsSeed.timesheets);

  final StreamController<List<TimesheetEntry>> _changes =
      StreamController<List<TimesheetEntry>>.broadcast();

  Future<List<TimesheetEntry>> getAll() async => List.unmodifiable(_seed);

  Stream<List<TimesheetEntry>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<List<TimesheetEntry>> getForEmployee(String employeeId) async {
    final out = _seed.where((e) => e.employeeId == employeeId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(out);
  }

  Stream<List<TimesheetEntry>> watchForEmployee(String employeeId) async* {
    yield await getForEmployee(employeeId);
    yield* _changes.stream.map((all) {
      final out = all.where((e) => e.employeeId == employeeId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return List<TimesheetEntry>.unmodifiable(out);
    });
  }

  Future<TimesheetEntry?> findById(String id) async {
    for (final e in _seed) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<TimesheetEntry> create(TimesheetEntry entry) async {
    final id = entry.id.isEmpty
        ? 'ts-${DateTime.now().microsecondsSinceEpoch}'
        : entry.id;
    final stamped = entry.copyWith(id: id);
    _seed.insert(0, stamped);
    _emit();
    return stamped;
  }

  /// Replace the row in-place. Callers wanting state-machine guards
  /// should use [submit] / [approve] / [reject] / [reopenRejected].
  Future<TimesheetEntry> update(TimesheetEntry entry) async {
    final idx = _seed.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      _seed.insert(0, entry);
    } else {
      _seed[idx] = entry;
    }
    _emit();
    return entry;
  }

  /// Slice 8.2.1 — validates a draft timesheet entry before it lands in
  /// the queue. Pure-Dart so the form bloc + the API receiver can both
  /// reuse it.
  TimesheetEntry validate({
    required String employeeId,
    required String employeeName,
    required String projectId,
    required String projectName,
    required DateTime date,
    required num hours,
    required String description,
    required DateTime now,
    String? taskId,
    String? taskTitle,
  }) {
    final errors = <String, List<String>>{};
    if (employeeId.isEmpty) {
      errors.putIfAbsent('employeeId', () => []).add('Required');
    }
    if (projectId.isEmpty) {
      errors.putIfAbsent('projectId', () => []).add('Required');
    }
    if (hours <= 0) {
      errors.putIfAbsent('hours', () => []).add('Must be greater than 0');
    }
    // Cap a single line at one calendar day; the rest gets entered as
    // separate lines (matches what Harvest / Toggl enforce).
    if (hours > 24) {
      errors.putIfAbsent('hours', () => []).add('Cannot exceed 24h');
    }
    if (description.trim().isEmpty) {
      errors.putIfAbsent('description', () => []).add('Required');
    }
    // Same date guard as the leave form: no time travel.
    final today = DateTime.utc(now.year, now.month, now.day);
    final d = DateTime.utc(date.year, date.month, date.day);
    if (d.isAfter(today)) {
      errors.putIfAbsent('date', () => []).add('Cannot log future days');
    }
    if (errors.isNotEmpty) {
      throw ValidationFailure(fieldErrors: errors);
    }

    return TimesheetEntry(
      id: '', // assigned by repo
      employeeId: employeeId,
      employeeName: employeeName,
      projectId: projectId,
      projectName: projectName,
      date: d,
      hours: hours,
      description: description.trim(),
      status: TimesheetStatus.draft,
      taskId: taskId,
      taskTitle: taskTitle,
    );
  }

  /// Slice 8.2.2 — promote a draft to submitted (locks the entry from
  /// further edits while it sits in the approval queue).
  TimesheetEntry submit(TimesheetEntry entry) {
    if (entry.status != TimesheetStatus.draft) {
      throw ConflictFailure(message: 'Only drafts can be submitted');
    }
    return entry.copyWith(status: TimesheetStatus.submitted);
  }

  /// Slice 8.2.2 — manager approves a submitted entry.
  ///
  /// State-machine guard: throws [ConflictFailure] when the entry is
  /// not currently `submitted`. Mirrors the leave-request decide use
  /// cases for shape consistency.
  TimesheetEntry approve({
    required TimesheetEntry entry,
    required String approverId,
    required DateTime now,
    String? note,
  }) {
    if (entry.status != TimesheetStatus.submitted) {
      throw ConflictFailure(message: 'Already ${entry.status.name}');
    }
    return entry.copyWith(
      status: TimesheetStatus.approved,
      approverId: approverId,
      actionedAt: now,
      decisionNote: note,
    );
  }

  /// Slice 8.2.2 — manager rejects a submitted entry. Reason is
  /// mandatory.
  TimesheetEntry reject({
    required TimesheetEntry entry,
    required String approverId,
    required DateTime now,
    required String reason,
  }) {
    if (entry.status != TimesheetStatus.submitted) {
      throw ConflictFailure(message: 'Already ${entry.status.name}');
    }
    if (reason.trim().isEmpty) {
      throw ValidationFailure(fieldErrors: {
        'reason': ['Required'],
      });
    }
    return entry.copyWith(
      status: TimesheetStatus.rejected,
      approverId: approverId,
      actionedAt: now,
      decisionNote: reason.trim(),
    );
  }

  /// Employee re-edits a rejected entry → drops back to draft so the
  /// form unlocks. Approved entries cannot be re-opened from this path
  /// (would require an admin reversal — not in the demo scope).
  ///
  /// **Why we construct directly**: `copyWith` collapses nulls to "no
  /// change" via `??`, so passing `approverId: null` would silently
  /// preserve the rejecter's id. Building a fresh instance is the
  /// readable way to clear those fields.
  TimesheetEntry reopenRejected(TimesheetEntry entry) {
    if (entry.status != TimesheetStatus.rejected) {
      throw ConflictFailure(message: 'Only rejected entries can be reopened');
    }
    return TimesheetEntry(
      id: entry.id,
      employeeId: entry.employeeId,
      employeeName: entry.employeeName,
      projectId: entry.projectId,
      projectName: entry.projectName,
      date: entry.date,
      hours: entry.hours,
      description: entry.description,
      status: TimesheetStatus.draft,
      taskId: entry.taskId,
      taskTitle: entry.taskTitle,
    );
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

/// Slice 8.2.3 — bucketed utilization for the report chart.
///
/// `loggedHours` is the sum of approved time entries inside `[from, to]`.
/// `targetHours` defaults to 8 hours/day × number of weekdays in the
/// window, which is what the chart uses as the 100% baseline. The
/// caller can override `hoursPerDay` for orgs on a different schedule.
class UtilizationBucket {
  const UtilizationBucket({
    required this.employeeId,
    required this.employeeName,
    required this.loggedHours,
    required this.targetHours,
  });

  final String employeeId;
  final String employeeName;
  final double loggedHours;
  final double targetHours;

  /// Percent of target. Capped at 0 when target is zero so the bar
  /// chart never blows up on a holiday-only window.
  double get utilizationPct =>
      targetHours <= 0 ? 0 : (loggedHours / targetHours) * 100.0;
}

List<UtilizationBucket> computeUtilization({
  required List<TimesheetEntry> entries,
  required DateTime from,
  required DateTime to,
  double hoursPerDay = 8.0,
  bool approvedOnly = true,
}) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  if (end.isBefore(start)) return const [];

  // Sum hours per employee inside the window.
  final byEmployee = <String, ({String name, double hours})>{};
  for (final e in entries) {
    if (approvedOnly && e.status != TimesheetStatus.approved) continue;
    final d = DateTime.utc(e.date.year, e.date.month, e.date.day);
    if (d.isBefore(start) || d.isAfter(end)) continue;
    final prior = byEmployee[e.employeeId];
    byEmployee[e.employeeId] = (
      name: e.employeeName,
      hours: (prior?.hours ?? 0) + e.hours.toDouble(),
    );
  }

  final target = countWeekdays(start, end) * hoursPerDay;

  final out = <UtilizationBucket>[];
  for (final entry in byEmployee.entries) {
    out.add(UtilizationBucket(
      employeeId: entry.key,
      employeeName: entry.value.name,
      loggedHours: entry.value.hours,
      targetHours: target,
    ));
  }
  // Highest utilization first — same convention as the sales rep
  // leaderboard (Slice 6.3.3).
  out.sort((a, b) => b.utilizationPct.compareTo(a.utilizationPct));
  return out;
}

/// Mon–Fri count between [start, end] inclusive.
int countWeekdays(DateTime start, DateTime end) {
  var count = 0;
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) {
      count++;
    }
  }
  return count;
}
