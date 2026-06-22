import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/purchase_orders_repository.dart';
import '../../entities/purchase_order.dart';
import 'po_detail_page.dart';

class PurchaseOrderListPage extends StatelessWidget {
  const PurchaseOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<PurchaseOrdersRepository>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.poListTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<List<PurchaseOrder>>(
          future: repo.getAll(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final pos = snap.data ?? const <PurchaseOrder>[];
            if (pos.isEmpty) {
              return _CenteredMessage(text: l10n.poListEmpty, icon: Icons.inventory_2_outlined);
            }
            return ListView.builder(
              padding: EdgeInsets.only(
                top: context.dynamicAppBarPadding,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              itemCount: pos.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PurchaseOrderCard(po: pos[i])
                    .animate()
                    .fadeIn(delay: (i * 30).ms)
                    .slideY(begin: 0.05, end: 0),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({required this.po});
  final PurchaseOrder po;
  static final _date = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = poStatusColor(theme, po.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          PurchaseOrderDetailPage(poId: po.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_rounded, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: po.number,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        const SizedBox(height: 2),
                        AppLabel(
                          text: po.vendorName,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PurchaseOrderStatusBadge(status: po.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLabel(
                        text: l10n.poListExpectedLabel(_date.format(po.expectedAt)).toUpperCase(),
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  AppLabel(
                    text: po.totalAmount,
                    fontSize: AppFontSize.value24,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PurchaseOrderStatusBadge extends StatelessWidget {
  const PurchaseOrderStatusBadge({super.key, required this.status});
  final PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = poStatusColor(theme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppLabel(
        text: poStatusLabel(l10n, status).toUpperCase(),
        fontSize: AppFontSize.value9,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), shape: BoxShape.circle),
              child: Icon(icon ?? Icons.inventory_2_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value16,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

String poStatusLabel(AppLocalizations l10n, PurchaseOrderStatus s) {
  return switch (s) {
    PurchaseOrderStatus.open => l10n.poStatusOpen,
    PurchaseOrderStatus.partiallyReceived => l10n.poStatusPartial,
    PurchaseOrderStatus.fullyReceived => l10n.poStatusFull,
    PurchaseOrderStatus.closed => l10n.poStatusClosed,
    PurchaseOrderStatus.cancelled => l10n.poStatusCancelled,
  };
}

Color poStatusColor(ThemeData theme, PurchaseOrderStatus s) {
  return switch (s) {
    PurchaseOrderStatus.open => theme.colorScheme.primary,
    PurchaseOrderStatus.partiallyReceived => theme.colorScheme.tertiary,
    PurchaseOrderStatus.fullyReceived => theme.colorScheme.tertiary,
    PurchaseOrderStatus.closed => theme.colorScheme.outline,
    PurchaseOrderStatus.cancelled => theme.colorScheme.error,
  };
}
