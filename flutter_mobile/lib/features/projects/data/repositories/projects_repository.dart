import 'dart:async';

import '../../entities/project.dart';
import '../projects_seed.dart';

/// Slice 8.1.1 — master project list.
class ProjectsRepository {
  ProjectsRepository();

  static final List<Project> _seed = List<Project>.of(ProjectsSeed.projects);

  final StreamController<List<Project>> _changes =
      StreamController<List<Project>>.broadcast();

  Future<List<Project>> getAll() async => List.unmodifiable(_seed);

  Stream<List<Project>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<Project?> findById(String id) async {
    for (final p in _seed) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Slice 8.1.4 — append a new project. ID is stamped here when blank.
  Future<Project> create(Project project) async {
    final id = project.id.isEmpty
        ? 'proj-${DateTime.now().microsecondsSinceEpoch}'
        : project.id;
    final stamped = project.copyWith(id: id);
    _seed.insert(0, stamped);
    _emit();
    return stamped;
  }

  /// Slice 8.1.4 — replace the row in place. Insert if not present so
  /// callers don't have to special-case create vs. update.
  Future<Project> update(Project project) async {
    final idx = _seed.indexWhere((p) => p.id == project.id);
    if (idx == -1) {
      _seed.insert(0, project);
    } else {
      _seed[idx] = project;
    }
    _emit();
    return project;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

/// One row of the Slice 8.1.1 Gantt timeline.
///
/// `startOffsetDays` is days from the timeline's left edge to the bar's
/// start (0 if the project starts on or before the window).
/// `widthDays` is the bar's clipped span (capped to the window).
class GanttRow {
  const GanttRow({
    required this.project,
    required this.startOffsetDays,
    required this.widthDays,
  });

  final Project project;
  final int startOffsetDays;
  final int widthDays;
}

/// Pure layout for the Gantt painter (Slice 8.1.1).
///
/// Clips each project to the window `[windowStart, windowEnd]` so a
/// long-running project still renders correctly when the user is
/// looking at "this quarter only." Projects that don't intersect the
/// window are dropped from the result.
///
/// Window dates are inclusive on both ends. Both bounds are normalised
/// to UTC-midnight so the offset arithmetic doesn't drift across DST
/// transitions on the device timezone.
List<GanttRow> computeGanttLayout({
  required List<Project> projects,
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  final ws = DateTime.utc(
      windowStart.year, windowStart.month, windowStart.day);
  final we =
      DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day);
  if (we.isBefore(ws)) return const [];

  final out = <GanttRow>[];
  for (final p in projects) {
    final ps = DateTime.utc(
        p.startDate.year, p.startDate.month, p.startDate.day);
    final pe =
        DateTime.utc(p.endDate.year, p.endDate.month, p.endDate.day);

    // Skip projects entirely outside the window.
    if (pe.isBefore(ws) || ps.isAfter(we)) continue;

    final clippedStart = ps.isBefore(ws) ? ws : ps;
    final clippedEnd = pe.isAfter(we) ? we : pe;
    final offset = clippedStart.difference(ws).inDays;
    final width = clippedEnd.difference(clippedStart).inDays + 1;
    out.add(GanttRow(
      project: p,
      startOffsetDays: offset,
      widthDays: width,
    ));
  }

  // Stable sort: earliest start first, longest first to break ties so
  // the bigger blocks read as the visual baseline.
  out.sort((a, b) {
    final byStart = a.startOffsetDays.compareTo(b.startOffsetDays);
    if (byStart != 0) return byStart;
    return b.widthDays.compareTo(a.widthDays);
  });
  return out;
}

/// Total day span of `[start, end]` inclusive — convenience for the
/// page so it can size the painter without re-doing the math.
int windowDays(DateTime start, DateTime end) {
  final s = DateTime.utc(start.year, start.month, start.day);
  final e = DateTime.utc(end.year, end.month, end.day);
  if (e.isBefore(s)) return 0;
  return e.difference(s).inDays + 1;
}

/// Pure filter + sort over the project list (Slice 8.1.1).
List<Project> applyProjectQuery(
  List<Project> all, {
  Set<ProjectStatus> statusFilter = const {},
  String searchQuery = '',
  ProjectSort sort = ProjectSort.nameAsc,
}) {
  Iterable<Project> result = all;

  if (statusFilter.isNotEmpty) {
    result = result.where((p) => statusFilter.contains(p.status));
  }

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.code.toLowerCase().contains(q) ||
        p.ownerName.toLowerCase().contains(q));
  }

  final list = result.toList();
  switch (sort) {
    case ProjectSort.nameAsc:
      list.sort((a, b) => a.name.compareTo(b.name));
    case ProjectSort.recentlyStarted:
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
    case ProjectSort.dueSoonest:
      list.sort((a, b) => a.endDate.compareTo(b.endDate));
  }
  return list;
}
