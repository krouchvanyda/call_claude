import 'package:flutter/material.dart';

import '../layout/responsive_breakpoint.dart';
import 'dashboard_layout_packer.dart';
import 'dashboard_widget.dart';

/// Renders a [DashboardLayout] (Slice 2.2.2).
///
/// Picks the column count from the same `gridColumnsFor(WindowSizeClass)`
/// helper the Modules grid (2.1.2) uses — keeps tile density consistent
/// across the app and means any breakpoint change ripples through every
/// grid in one edit.
///
/// **Variable spans**: each [DashboardWidget] declares a `colSpan`
/// (clamped to the available column count). The packer fills rows
/// left-to-right, wrapping when the next slot would overflow.
///
/// **Heights**: a row's height is the max of its children's [heightDp]
/// values, with `null` meaning "let the child decide". Children inside
/// a row stretch to that row's height so cards align bottoms.
class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    super.key,
    required this.layout,
    this.spacing = 12,
  });

  final DashboardLayout layout;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (layout.isEmpty) return const SizedBox.shrink();

    final cols = gridColumnsFor(
      resolveWindowSizeClass(MediaQuery.sizeOf(context).width),
    );
    final spans = [for (final w in layout) w.colSpan];
    final rows = packIntoRows(spans, cols);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Available width minus N-1 inter-cell gaps, divided into N cells.
        final cellWidth =
            (constraints.maxWidth - (cols - 1) * spacing) / cols;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) ...[
              if (rowIdx > 0) SizedBox(height: spacing),
              _buildRow(context, rows[rowIdx], cellWidth, cols),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    List<int> rowIndexes,
    double cellWidth,
    int cols,
  ) {
    // Row height: tallest declared height in the row, or null (intrinsic)
    // when none of the children declared one.
    double? rowHeight;
    for (final i in rowIndexes) {
      final h = layout[i].heightDp;
      if (h != null && (rowHeight == null || h > rowHeight)) {
        rowHeight = h;
      }
    }

    final children = <Widget>[];
    for (var k = 0; k < rowIndexes.length; k++) {
      if (k > 0) children.add(SizedBox(width: spacing));
      final i = rowIndexes[k];
      final span = effectiveSpan(layout[i].colSpan, cols);
      // Width of a span-N cell: N base cells + (N-1) inter-cell gaps.
      final width = cellWidth * span + spacing * (span - 1);
      children.add(SizedBox(
        width: width,
        height: rowHeight,
        child: KeyedSubtree(
          key: ValueKey(layout[i].id),
          child: layout[i].build(context),
        ),
      ));
    }
    // Each child is already SizedBox-constrained (width × height) so
    // Row only needs to lay them out side-by-side. CrossAxisAlignment
    // stretch would demand the Row know its cross-axis (vertical)
    // size up-front — fine when nested in a bounded-height parent,
    // but the dashboard hosts this in a SingleChildScrollView where
    // vertical space is unbounded, which threw a layout-during-layout
    // assertion in `_ScaffoldLayout.performLayout`.
    return Row(children: children);
  }
}
