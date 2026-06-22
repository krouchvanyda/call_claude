import 'package:flutter/widgets.dart';

import '../../../shared/widgets/kpi/kpi_card.dart';
import '../../../shared/widgets/kpi/kpi_data.dart';
import '../dashboard_widget.dart';

/// Adapter that lets a [KpiCard] (Slice 2.2.1) participate in the
/// dashboard layout engine (Slice 2.2.2).
///
/// **Why an adapter and not "make `KpiCard` a `DashboardWidget` itself"**:
/// `KpiCard` stays a generic, reusable widget — usable in places that
/// have nothing to do with the dashboard (a finance summary page,
/// a customer detail header). The adapter is the dashboard-specific
/// shim that contributes `id` / `colSpan` / `heightDp` metadata.
class KpiDashboardWidget extends DashboardWidget {
  const KpiDashboardWidget({
    required this.id,
    required this.data,
    this.colSpan = 1,
    this.heightDp = 140,
    this.onTap,
  });

  @override
  final String id;

  @override
  final int colSpan;

  @override
  final double? heightDp;

  /// The actual KPI payload — fed straight to the underlying card.
  final KpiData data;

  /// Forwarded to [KpiCard.onTap].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => KpiCard(data: data, onTap: onTap);
}
