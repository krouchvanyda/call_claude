import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/sales_orders_repository.dart';
import '../../entities/sales_order.dart';
import 'sales_order_detail_page.dart';

/// Sales order list (Slice 6.2.1 / 6.2.3).
class SalesOrderListPage extends StatelessWidget {
  const SalesOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<SalesOrdersRepository>();
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.salesOrderListTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<List<SalesOrder>>(
        future: repo.getAll(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data ?? const <SalesOrder>[];
          if (orders.isEmpty) {
            return Center(
              child: AppLabel(
                text: l10n.salesOrderListEmpty,
                fontSize: AppFontSize.value14,
              ),
            );
          }
          final sorted = List<SalesOrder>.of(orders)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) => _OrderTile(order: sorted[i]),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final SalesOrder order;
  static final _date = DateFormat('yyyy-MM-dd');
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = salesOrderStatusColor(theme, order.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      title: Row(
        children: [
          AppLabel(
            text: order.number,
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppLabel(
              text: order.customerName,
              fontSize: AppFontSize.value14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: AppLabel(
        text: _date.format(order.createdAt.toLocal()),
        fontSize: AppFontSize.value11,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLabel(
            text: order.totalAmount,
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          const SizedBox(height: 2),
          SalesOrderStatusBadge(status: order.status),
        ],
      ),
      onTap: () => ConfigRouter.pushPageAnimation(
        context,
        SalesOrderDetailPage(orderId: order.id),
      ),
    );
  }
}

class SalesOrderStatusBadge extends StatelessWidget {
  const SalesOrderStatusBadge({super.key, required this.status});
  final SalesOrderStatus status;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = salesOrderStatusColor(theme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppLabel(
        text: salesOrderStatusLabel(l10n, status),
        fontSize: AppFontSize.value11,
        color: color,
      ),
    );
  }
}

String salesOrderStatusLabel(AppLocalizations l10n, SalesOrderStatus s) {
  return switch (s) {
    SalesOrderStatus.pending => l10n.salesOrderStatusPending,
    SalesOrderStatus.packing => l10n.salesOrderStatusPacking,
    SalesOrderStatus.shipped => l10n.salesOrderStatusShipped,
    SalesOrderStatus.delivered => l10n.salesOrderStatusDelivered,
    SalesOrderStatus.cancelled => l10n.salesOrderStatusCancelled,
  };
}

Color salesOrderStatusColor(ThemeData theme, SalesOrderStatus s) {
  return switch (s) {
    SalesOrderStatus.pending => theme.colorScheme.secondary,
    SalesOrderStatus.packing => theme.colorScheme.primary,
    SalesOrderStatus.shipped => theme.colorScheme.tertiary,
    SalesOrderStatus.delivered => theme.colorScheme.tertiary,
    SalesOrderStatus.cancelled => theme.colorScheme.error,
  };
}
