/// Pure-Dart row packer (Slice 2.2.2) — turns a sequence of column
/// spans into row-by-row indexes the [DashboardGrid] then renders.
///
/// Algorithm: a single left-to-right pass with a running width counter.
/// When the next slot would exceed [maxCols], close the current row and
/// start a new one with the slot. Slots whose declared span exceeds
/// [maxCols] are clamped down to [maxCols] and get their own row — the
/// engine will resize them to fit.
///
/// **Why pure Dart**: keeps the layout invariants (order preservation,
/// clamping, never-zero-cols) unit-testable without spinning up a
/// widget tree. The Flutter widget that consumes the result is a thin
/// renderer.
List<List<int>> packIntoRows(List<int> spans, int maxCols) {
  if (maxCols < 1) {
    throw ArgumentError.value(maxCols, 'maxCols', 'must be ≥ 1');
  }
  final rows = <List<int>>[];
  if (spans.isEmpty) return rows;

  var current = <int>[];
  var currentWidth = 0;

  for (var i = 0; i < spans.length; i++) {
    // Clamp oversize spans down — never assume the caller checked.
    final span = spans[i].clamp(1, maxCols);
    if (currentWidth + span > maxCols) {
      // Wrap: commit the in-progress row (if any) and start fresh.
      if (current.isNotEmpty) rows.add(current);
      current = <int>[];
      currentWidth = 0;
    }
    current.add(i);
    currentWidth += span;
  }
  if (current.isNotEmpty) rows.add(current);

  return rows;
}

/// Returns the effective span of slot [i] under [maxCols] — the same
/// clamp the packer applies internally. Exposed so the renderer can
/// size each cell without re-implementing the rule.
int effectiveSpan(int rawSpan, int maxCols) =>
    rawSpan.clamp(1, maxCols);
