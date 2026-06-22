import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/attendance_entry.dart';
import '../hr_seed.dart';

/// Slice 7.3.1 — attendance log (clock in / clock out cycles).
class AttendanceRepository {
  AttendanceRepository();

  static final List<AttendanceEntry> _seed =
      List<AttendanceEntry>.of(HrSeed.attendance);

  final StreamController<List<AttendanceEntry>> _changes =
      StreamController<List<AttendanceEntry>>.broadcast();

  Future<List<AttendanceEntry>> getForEmployee(String employeeId) async {
    final out = _seed.where((e) => e.employeeId == employeeId).toList()
      ..sort((a, b) => b.clockIn.compareTo(a.clockIn));
    return List.unmodifiable(out);
  }

  Stream<List<AttendanceEntry>> watchForEmployee(String employeeId) async* {
    yield await getForEmployee(employeeId);
    yield* _changes.stream.map(
      (all) {
        final out = all.where((e) => e.employeeId == employeeId).toList()
          ..sort((a, b) => b.clockIn.compareTo(a.clockIn));
        return List<AttendanceEntry>.unmodifiable(out);
      },
    );
  }

  /// Latest entry for [employeeId] regardless of date. Used by the
  /// clock-in/out button to decide which action is legal next.
  Future<AttendanceEntry?> latestFor(String employeeId) async {
    AttendanceEntry? best;
    for (final e in _seed) {
      if (e.employeeId != employeeId) continue;
      if (best == null || e.clockIn.isAfter(best.clockIn)) best = e;
    }
    return best;
  }

  Future<AttendanceEntry> create(AttendanceEntry entry) async {
    _seed.insert(0, entry);
    _emit();
    return entry;
  }

  Future<AttendanceEntry> update(AttendanceEntry entry) async {
    final idx = _seed.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      _seed.insert(0, entry);
    } else {
      _seed[idx] = entry;
    }
    _emit();
    return entry;
  }

  /// Slice 7.3.1 — resolve the next clock action for [employeeId] given
  /// the current `now` clock. Returns a sum-type [ClockAction]:
  /// - [ClockInAction] — open a new entry (replaces any older closed one
  ///   for the same date when there is no open one).
  /// - [ClockOutAction] — close the existing open entry.
  ///
  /// The page invokes this with the most recent entry + "now" so the
  /// button text + colour follows whatever this method would do next
  /// — the page truth is this repo, not local UI state.
  ClockAction toggleClock({
    required AttendanceEntry? latest,
    required String employeeId,
    required DateTime now,
    required String Function() newId,
    String? note,
  }) {
    if (latest == null || !latest.isOpen) {
      // Fresh clock-in.
      final date = DateTime.utc(now.year, now.month, now.day);
      return ClockInAction(AttendanceEntry(
        id: newId(),
        employeeId: employeeId,
        date: date,
        clockIn: now,
        note: note,
      ));
    }
    // Defensive: server shouldn't return an open entry for a different
    // employee, but bail rather than corrupt their data.
    if (latest.employeeId != employeeId) {
      throw ConflictFailure(message: 'Open entry belongs to another employee');
    }
    if (now.isBefore(latest.clockIn)) {
      throw ValidationFailure(fieldErrors: {
        'clockOut': ['Cannot clock out before clock-in time'],
      });
    }
    return ClockOutAction(latest.copyWith(clockOut: now, note: note));
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

/// Slice 7.3.1 — sum-type result of a clock-in/out tap.
///
/// The bloc invokes [AttendanceRepository.toggleClock] with the most
/// recent entry + "now" and gets back exactly one of:
/// - [ClockInAction] — open a new entry (replaces any older closed one
///   for the same date when there is no open one).
/// - [ClockOutAction] — close the existing open entry.
sealed class ClockAction {
  const ClockAction();
}

class ClockInAction extends ClockAction {
  const ClockInAction(this.draft);
  final AttendanceEntry draft;
}

class ClockOutAction extends ClockAction {
  const ClockOutAction(this.updated);
  final AttendanceEntry updated;
}
