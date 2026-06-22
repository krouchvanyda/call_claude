import 'dart:ui';
import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/sales_orders_repository.dart';
import '../../entities/sales_order.dart';
import 'sales_order_list_page.dart'
    show SalesOrderStatusBadge, salesOrderStatusLabel;

/// Sales order detail (Slice 6.2.1 + 6.2.3 fulfillment advance).
class SalesOrderDetailPage extends StatefulWidget {
  const SalesOrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<SalesOrderDetailPage> createState() => _SalesOrderDetailPageState();
}

class _SalesOrderDetailPageState extends State<SalesOrderDetailPage> {
  late Future<SalesOrder?> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<SalesOrdersRepository>().findById(widget.orderId);
  }

  void _reload() {
    setState(() {
      _future = getIt<SalesOrdersRepository>().findById(widget.orderId);
    });
  }

  Future<void> _advanceTo(
    SalesOrder order,
    SalesOrderStatus next, {
    String? tracking,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = getIt<SalesOrdersRepository>();
      final updated = repo.advanceFulfillment(
        order,
        to: next,
        now: DateTime.now().toUtc(),
        trackingReference: tracking,
      );
      await repo.setStatus(
        order.id,
        updated.status,
        shippedAt: updated.shippedAt,
        deliveredAt: updated.deliveredAt,
        trackingReference: updated.trackingReference,
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesOrderAdvancedSnack(
            salesOrderStatusLabel(l10n, updated.status),
          )),
          behavior: SnackBarBehavior.floating,
        ));
      _reload();
    } on ValidationFailure {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesOrderTrackingRequired),
          behavior: SnackBarBehavior.floating,
        ));
    } on Failure catch (f) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesOrderAdvanceFailed(f.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesOrderAdvanceFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<String?> _promptTracking() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: AppLabel(
          text: l10n.salesOrderTrackingDialogTitle,
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.salesOrderTrackingLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: AppLabel(
              text: l10n.invoiceActionCancel,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: AppLabel(
              text: l10n.salesOrderTrackingConfirm,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.salesOrderDetailTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas Gradient
            AppBackgroundGradient(),
            FutureBuilder<SalesOrder?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final order = snap.data;
                if (order == null) {
                  return Center(
                    child: AppLabel(
                      text: l10n.salesOrderNotFound(widget.orderId),
                      fontSize: AppFontSize.value14,
                    ),
                  );
                }
                return _Body(order: order);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: FutureBuilder<SalesOrder?>(
        future: _future,
        builder: (context, snap) {
          final order = snap.data;
          if (order == null) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: _ActionBar(
                order: order,
                onAdvance: (next) async {
                  String? tracking;
                  if (next == SalesOrderStatus.shipped) {
                    tracking = await _promptTracking();
                    if (tracking == null) return;
                  }
                  await _advanceTo(order, next, tracking: tracking);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.order, required this.onAdvance});
  final SalesOrder order;
  final ValueChanged<SalesOrderStatus> onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    switch (order.status) {
      case SalesOrderStatus.pending:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAdvance(SalesOrderStatus.cancelled),
                  icon: const Icon(Icons.close),
                  label: AppLabel(
                    text: l10n.salesOrderCancelAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onAdvance(SalesOrderStatus.packing),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: AppLabel(
                    text: l10n.salesOrderStartPackingAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      case SalesOrderStatus.packing:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAdvance(SalesOrderStatus.cancelled),
                  icon: const Icon(Icons.close),
                  label: AppLabel(
                    text: l10n.salesOrderCancelAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onAdvance(SalesOrderStatus.shipped),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: AppLabel(
                    text: l10n.salesOrderShipAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      case SalesOrderStatus.shipped:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: () => onAdvance(SalesOrderStatus.delivered),
            icon: const Icon(Icons.check_circle_outline),
            label: AppLabel(
              text: l10n.salesOrderMarkDeliveredAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      case SalesOrderStatus.delivered:
      case SalesOrderStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.order});
  final SalesOrder order;
  static final _date = DateFormat('yyyy-MM-dd');
  static final _stamp = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding + 12,
        left: 16,
        right: 16,
        bottom: 40,
      ),
      children: [
        // Order Header Card
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabel(
                            text: order.number,
                            fontSize: AppFontSize.value16,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4),
                          AppLabel(
                            text: order.customerName,
                            fontSize: AppFontSize.value14,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    SalesOrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _MetaChip(
                      label: l10n.salesOrderCreatedLabel,
                      value: _date.format(order.createdAt.toLocal()),
                    ),
                    if (order.sourceQuotationId != null)
                      _MetaChip(
                        label: l10n.salesOrderSourceQuotationLabel,
                        value: order.sourceQuotationId!,
                      ),
                    if (order.shippedAt != null)
                      _MetaChip(
                        label: l10n.salesOrderShippedAtLabel,
                        value: _stamp.format(order.shippedAt!.toLocal()),
                      ),
                    if (order.deliveredAt != null)
                      _MetaChip(
                        label: l10n.salesOrderDeliveredAtLabel,
                        value: _stamp.format(order.deliveredAt!.toLocal()),
                      ),
                    if (order.trackingReference != null)
                      _MetaChip(
                        label: l10n.salesOrderTrackingLabel,
                        value: order.trackingReference!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
        const SizedBox(height: 16),
        // Line Items Card
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.format_list_bulleted, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    AppLabel(
                      text: l10n.salesOrderDetailLinesHeading,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.lineItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (_, index) {
                  final line = order.lineItems[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: AppLabel(
                      text: line.description,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.bold,
                    ),
                    subtitle: line.sku == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: AppLabel(
                              text: line.sku!,
                              fontSize: AppFontSize.value12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppLabel(
                          text: '${line.quantity} × ${line.unitPrice}',
                          fontSize: AppFontSize.value12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 2),
                        AppLabel(
                          text: line.lineTotal,
                          fontSize: AppFontSize.value14,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    AppLabel(
                      text: l10n.salesQuotationTotalLabel,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.bold,
                    ),
                    const Spacer(),
                    AppLabel(
                      text: order.totalAmount,
                      fontSize: AppFontSize.value20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLabel(
            text: label,
            fontSize: AppFontSize.value11,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 2),
          AppLabel(
            text: value,
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
