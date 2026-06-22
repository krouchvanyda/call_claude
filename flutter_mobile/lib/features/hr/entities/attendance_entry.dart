/// One clock-in / clock-out cycle for an employee on a given calendar
/// date (Slice 7.3.1).
///
/// Demo policy: one entry per employee per date; a second clock-in on
/// the same date replaces the previous one if it is still open.
class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.clockIn,
    this.clockOut,
    this.note,
  });

  final String id;
  final String employeeId;

  /// Calendar date the entry belongs to (UTC midnight).
  final DateTime date;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? note;

  bool get isOpen => clockOut == null;

  /// Worked minutes between clockIn and clockOut. Zero while still open.
  int get workedMinutes =>
      clockOut == null ? 0 : clockOut!.difference(clockIn).inMinutes;

  AttendanceEntry copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    DateTime? clockIn,
    DateTime? clockOut,
    String? note,
  }) =>
      AttendanceEntry(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        date: date ?? this.date,
        clockIn: clockIn ?? this.clockIn,
        clockOut: clockOut ?? this.clockOut,
        note: note ?? this.note,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceEntry &&
          other.id == id &&
          other.employeeId == employeeId &&
          other.date == date &&
          other.clockIn == clockIn &&
          other.clockOut == clockOut &&
          other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, employeeId, date, clockIn, clockOut, note);
}
