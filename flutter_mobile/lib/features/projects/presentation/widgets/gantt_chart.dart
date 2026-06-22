import 'package:flutter/material.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/projects_repository.dart';
import '../../entities/project.dart';

/// Slice 8.1.1 — custom-painter Gantt timeline.
///
/// **Why a CustomPainter, not a chart package**: the Gantt is the only
/// place we need this geometry, and pulling in another chart package
/// for one screen would bloat the binary. The painter renders bars at
/// pixel-perfect day-width and stays cheap to repaint.
///
/// Tap detection is intentionally simple: each row is a fixed-height
/// strip; we map the tap Y to a row index and look up the project.
class GanttChart extends StatelessWidget {
  const GanttChart({
    super.key,
    required this.rows,
    required this.windowStart,
    required this.windowEnd,
    this.rowHeight = 44,
    this.onTap,
  });

  final List<GanttRow> rows;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double rowHeight;
  final void Function(Project project)? onTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: AppLabel(
          text: AppLocalizations.of(context).ganttChartNoProjects,
          fontSize: AppFontSize.value14,
        ),
      );
    }
    final totalDays = windowDays(windowStart, windowEnd);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve a left gutter for the project label, then split the
        // remaining width across the day window.
        const labelWidth = 140.0;
        final timelineWidth =
            (constraints.maxWidth - labelWidth).clamp(80.0, double.infinity);
        final dayWidth = totalDays == 0 ? 0.0 : timelineWidth / totalDays;
        final height = rows.length * rowHeight + 32; // +header
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: GestureDetector(
            onTapUp: (details) {
              if (onTap == null) return;
              final dy = details.localPosition.dy - 32; // skip header
              if (dy < 0) return;
              final idx = (dy ~/ rowHeight).clamp(0, rows.length - 1);
              onTap!(rows[idx].project);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _GanttPainter(
                rows: rows,
                labelWidth: labelWidth,
                dayWidth: dayWidth,
                rowHeight: rowHeight,
                windowStart: windowStart,
                totalDays: totalDays,
                textColor: Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.black87,
                gridColor: Theme.of(context).dividerColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GanttPainter extends CustomPainter {
  _GanttPainter({
    required this.rows,
    required this.labelWidth,
    required this.dayWidth,
    required this.rowHeight,
    required this.windowStart,
    required this.totalDays,
    required this.textColor,
    required this.gridColor,
  });

  final List<GanttRow> rows;
  final double labelWidth;
  final double dayWidth;
  final double rowHeight;
  final DateTime windowStart;
  final int totalDays;
  final Color textColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final headerHeight = 32.0;
    final timelineLeft = labelWidth;
    final timelineWidth = size.width - labelWidth;

    // Header row — month markers across the timeline.
    final headerPaint = Paint()..color = gridColor.withValues(alpha: 0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, headerHeight),
      headerPaint,
    );

    // Walk the window day by day, marking the 1st of each month with
    // a vertical guide + label.
    for (var i = 0; i <= totalDays; i++) {
      final d = DateTime.utc(
        windowStart.year,
        windowStart.month,
        windowStart.day + i,
      );
      if (d.day == 1) {
        final x = timelineLeft + i * dayWidth;
        final guide = Paint()
          ..color = gridColor.withValues(alpha: 0.5)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(x, headerHeight),
          Offset(x, size.height),
          guide,
        );
        final label = _monthLabel(d);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(color: textColor, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 80);
        tp.paint(canvas, Offset(x + 4, 8));
      }
    }

    // Bars + labels.
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final y = headerHeight + i * rowHeight;
      final centerY = y + rowHeight / 2;

      // Row background (alternating zebra).
      if (i.isOdd) {
        final zebra = Paint()..color = gridColor.withValues(alpha: 0.08);
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, rowHeight),
          zebra,
        );
      }

      // Project label on the left gutter.
      final labelTp = TextPainter(
        text: TextSpan(
          text: row.project.code,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelWidth - 8);
      labelTp.paint(
        canvas,
        Offset(8, centerY - labelTp.height / 2),
      );

      // Bar.
      final barLeft = timelineLeft + row.startOffsetDays * dayWidth;
      final barWidth = (row.widthDays * dayWidth).clamp(2.0, timelineWidth);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, y + 8, barWidth, rowHeight - 16),
        const Radius.circular(4),
      );
      final barPaint = Paint()
        ..color = _barColor(row.project);
      canvas.drawRRect(barRect, barPaint);

      // Bar overlay text — project name (truncated to bar width).
      if (barWidth > 40) {
        final nameTp = TextPainter(
          text: TextSpan(
            text: row.project.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: barWidth - 8);
        nameTp.paint(
          canvas,
          Offset(barLeft + 4, centerY - nameTp.height / 2),
        );
      }
    }
  }

  Color _barColor(Project p) {
    if (p.color != null && p.color!.length == 6) {
      return Color(int.parse('FF${p.color}', radix: 16));
    }
    return Colors.indigo;
  }

  String _monthLabel(DateTime d) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[d.month - 1];
  }

  @override
  bool shouldRepaint(covariant _GanttPainter old) =>
      rows != old.rows ||
      windowStart != old.windowStart ||
      totalDays != old.totalDays ||
      dayWidth != old.dayWidth;
}
