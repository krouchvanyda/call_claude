/// Slice 8.1.1 — project lifecycle status.
enum ProjectStatus { planning, active, onHold, completed, archived }

/// Sort axes for the project list.
enum ProjectSort { nameAsc, recentlyStarted, dueSoonest }

/// Master record for a project.
///
/// **Pure data**: no Flutter, no drift. `budget` is pre-formatted so the
/// entity stays locale-stable; the utilization chart computes raw hours
/// from the timesheet ledger, not this string.
class Project {
  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    required this.budget,
    this.color,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final ProjectStatus status;
  final String ownerId;
  final String ownerName;

  /// Pre-formatted (e.g. `r'$120,000.00'`).
  final String budget;

  /// Optional 6-digit hex (without `#`) used to colour the Gantt bar.
  final String? color;

  /// Total elapsed days [startDate, endDate]. Inclusive.
  int get totalDays {
    final from =
        DateTime.utc(startDate.year, startDate.month, startDate.day);
    final to = DateTime.utc(endDate.year, endDate.month, endDate.day);
    return to.difference(from).inDays + 1;
  }

  Project copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    String? ownerId,
    String? ownerName,
    String? budget,
    String? color,
  }) =>
      Project(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        ownerId: ownerId ?? this.ownerId,
        ownerName: ownerName ?? this.ownerName,
        budget: budget ?? this.budget,
        color: color ?? this.color,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.description == description &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.status == status &&
          other.ownerId == ownerId &&
          other.ownerName == ownerName &&
          other.budget == budget &&
          other.color == color;

  @override
  int get hashCode => Object.hash(
        id,
        code,
        name,
        description,
        startDate,
        endDate,
        status,
        ownerId,
        ownerName,
        budget,
        color,
      );
}
