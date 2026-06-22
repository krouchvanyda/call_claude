import 'package:flutter/material.dart';

import '../../../core/theme/app_font_size.dart';
import '../../../core/theme/app_label.dart';
import '../../../l10n/app_localizations.dart';
import 'kpi_data.dart';
import 'sparkline_geometry.dart';

/// One KPI tile (Slice 2.2.1) — label, primary value, trend chip,
/// inline sparkline.
///
/// Stateless and presentation-only — feature blocs (Module 2 dashboard,
/// Module 3 finance summary, etc.) build their own [KpiData] from
/// domain queries and hand it in. The card never formats numbers,
/// computes deltas, or talks to a repository.
///
/// **Sparkline implementation**: a thin [CustomPainter] that consumes
/// the pure-Dart geometry from [SparklineGeometry]. Slice 2.2.3 brings
/// in `fl_chart` for full charts; this lightweight painter avoids
/// pulling that dep in just for a 60×24-ish inline trace.
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.data, this.onTap});

  final KpiData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppLabel(
                      text: data.label.toUpperCase(),
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _TrendChip(trend: data.trend, delta: data.trendDelta),
                ],
              ),
              const Spacer(),
              AppLabel(
                text: data.value,
                fontSize: AppFontSize.value24,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (data.sparkline.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      points: data.sparkline,
                      color: _trendColor(theme, data.trend),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend, required this.delta});

  final KpiTrend trend;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _trendColor(theme, trend);
    final icon = switch (trend) {
      KpiTrend.up => Icons.trending_up,
      KpiTrend.down => Icons.trending_down,
      KpiTrend.flat => Icons.trending_flat,
    };
    final label = delta ?? _trendLabel(l10n, trend);
    return Tooltip(
      message: _trendTooltip(l10n, trend),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          AppLabel(
            text: label,
            fontSize: AppFontSize.value11,
            color: color,
          ),
        ],
      ),
    );
  }
}

Color _trendColor(ThemeData theme, KpiTrend trend) {
  return switch (trend) {
    // Material 3 doesn't ship a "success" colour; primary reads as
    // positive in the default scheme. Real branding overrides via
    // theme extension once it lands.
    KpiTrend.up => theme.colorScheme.primary,
    KpiTrend.down => theme.colorScheme.error,
    KpiTrend.flat => theme.colorScheme.onSurfaceVariant,
  };
}

String _trendLabel(AppLocalizations l10n, KpiTrend trend) {
  return switch (trend) {
    KpiTrend.up => l10n.kpiTrendUp,
    KpiTrend.down => l10n.kpiTrendDown,
    KpiTrend.flat => l10n.kpiTrendFlat,
  };
}

String _trendTooltip(AppLocalizations l10n, KpiTrend trend) {
  return switch (trend) {
    KpiTrend.up => l10n.kpiTrendUpTooltip,
    KpiTrend.down => l10n.kpiTrendDownTooltip,
    KpiTrend.flat => l10n.kpiTrendFlatTooltip,
  };
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = SparklineGeometry.normalise(
      points,
      width: size.width,
      height: size.height,
    );
    if (offsets.isEmpty) return;

    if (offsets.length == 1) {
      canvas.drawCircle(
        Offset(offsets.first.dx, offsets.first.dy),
        2,
        Paint()..color = color,
      );
      return;
    }

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.color != color ||
      old.points.length != points.length ||
      // Cheap-and-correct: the points list is small (<= ~30) so a
      // pointwise compare is fine and avoids needless repaints when
      // the data hasn't actually changed.
      !_listEquals(old.points, points);

  static bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
