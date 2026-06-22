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
import '../../data/repositories/items_repository.dart';
import '../../data/repositories/stock_movements_repository.dart';
import '../../entities/inventory_item.dart';
import '../../entities/stock_movement.dart';
import 'items_list_page.dart' show inventoryStatusColor;
import 'stock_movement_form_page.dart';
import 'stock_transfer_page.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late ItemsRepository _itemsRepo;
  late StockMovementsRepository _movementsRepo;
  late Future<_Bundle> _future;

  @override
  void initState() {
    super.initState();
    _itemsRepo = getIt<ItemsRepository>();
    _movementsRepo = getIt<StockMovementsRepository>();
    _future = _load();
  }

  Future<_Bundle> _load() async {
    final item = await _itemsRepo.findById(widget.itemId);
    if (item == null) return const _Bundle(item: null, movements: []);
    final movements = await _movementsRepo.forItem(widget.itemId);
    return _Bundle(item: item, movements: movements);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.inventoryItemDetailTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<_Bundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final bundle = snap.data;
            if (bundle == null || bundle.item == null) {
              return _CenteredMessage(text: l10n.inventoryItemNotFound(widget.itemId), icon: Icons.search_off_rounded);
            }
            return _Body(bundle: bundle);
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<_Bundle>(
        future: _future,
        builder: (context, snap) {
          final item = snap.data?.item;
          if (item == null) return const SizedBox.shrink();
          return Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            // Three actions in a single row — wrapped with Flexible
            // labels so the localised text can ellipsise instead of
            // overflowing the Expanded slot on narrow phones (the
            // built-in `*Button.icon` constructor doesn't make the
            // label flexible, which is why it overflowed by ~71 px).
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ConfigRouter.pushPageAnimation(
                        context,
                        StockMovementFormPage(
                          itemId: item.id,
                          type: StockMovementType.issue,
                        ),
                      );
                      if (mounted) _reload();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    child: _ActionLabel(icon: Icons.outbox_rounded, text: l10n.inventoryIssueAction),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ConfigRouter.pushPageAnimation(
                        context,
                        StockMovementFormPage(
                          itemId: item.id,
                          type: StockMovementType.receipt,
                        ),
                      );
                      if (mounted) _reload();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    child: _ActionLabel(icon: Icons.inbox_rounded, text: l10n.inventoryReceiptAction),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await ConfigRouter.pushPageAnimation(
                        context,
                        StockTransferPage(sourceItemId: item.id),
                      );
                      if (mounted) _reload();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    child: _ActionLabel(icon: Icons.swap_horiz_rounded, text: l10n.inventoryTransferAction),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms);
        },
      ),
    );
  }
}

class _Bundle {
  const _Bundle({required this.item, required this.movements});
  final InventoryItem? item;
  final List<StockMovement> movements;
}

class _Body extends StatelessWidget {
  const _Body({required this.bundle});
  final _Bundle bundle;
  static final _stamp = DateFormat('MMM dd, yyyy • HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final item = bundle.item!;
    final statusColor = inventoryStatusColor(theme, item);

    return ListView(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 120, // Space for bottom action bar
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(item.isLowStock ? Icons.warning_rounded : Icons.inventory_2_rounded, color: statusColor, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: item.name,
                          fontSize: AppFontSize.value24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        const SizedBox(height: 4),
                        AppLabel(
                          text: l10n.commonSkuLabel(item.sku),
                          fontSize: AppFontSize.value12,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: l10n.inventoryCurrentStockLabel,
                          fontSize: AppFontSize.value11,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AppLabel(
                              text: item.onHandQty.toString(),
                              fontSize: AppFontSize.value36,
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            const SizedBox(width: 4),
                            AppLabel(
                              text: 'units',
                              fontSize: AppFontSize.value12,
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (item.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadii.pill)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 4),
                          AppLabel(
                            text: l10n.inventoryReorderBadge(item.reorderPoint.toString()).toUpperCase(),
                            fontSize: AppFontSize.value11,
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _MetaItem(label: l10n.inventoryDetailWarehouseLabel, value: item.warehouseCode, icon: Icons.warehouse_rounded),
                  _MetaItem(label: l10n.inventoryDetailLocationLabel, value: item.locationCode, icon: Icons.location_on_rounded),
                  _MetaItem(label: l10n.inventoryDetailUnitCostLabel, value: item.unitCost, icon: Icons.payments_rounded),
                  if (item.barcode != null) _MetaItem(label: l10n.inventoryDetailBarcodeLabel, value: item.barcode!, icon: Icons.qr_code_2_rounded),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: AppLabel(
            text: l10n.inventoryDetailMovementsHeading.toUpperCase(),
            fontSize: AppFontSize.value11,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        if (bundle.movements.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                AppLabel(
                  text: l10n.inventoryDetailMovementsEmpty,
                  fontSize: AppFontSize.value14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0)
        else
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: bundle.movements.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              itemBuilder: (_, i) => _MovementRow(movement: bundle.movements[i], stampFmt: _stamp)
                  .animate()
                  .fadeIn(delay: (100 + i * 30).ms)
                  .slideX(begin: 0.05, end: 0),
            ),
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            AppLabel(
              text: label.toUpperCase(),
              fontSize: AppFontSize.value9,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.stampFmt});
  final StockMovement movement;
  final DateFormat stampFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _typeColor(theme, movement.type);
    final signed = _signedLabel(movement);
    final isPositive = movement.quantity > 0 || movement.type == StockMovementType.receipt;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(_typeIcon(movement.type), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: _typeLabel(l10n, movement.type).toUpperCase(),
                  fontSize: AppFontSize.value11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 4),
                AppLabel(
                  text: movement.reference == null
                      ? stampFmt.format(movement.postedAt.toLocal())
                      : '${stampFmt.format(movement.postedAt.toLocal())} • REF: ${movement.reference}',
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppLabel(
                text: signed,
                fontSize: AppFontSize.value16,
                color: isPositive ? theme.colorScheme.primary : theme.colorScheme.error,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              const SizedBox(height: 2),
              AppLabel(
                text: l10n.inventoryMovementRunningLabel(movement.runningQty.toString()).toUpperCase(),
                fontSize: AppFontSize.value9,
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _typeColor(ThemeData theme, StockMovementType t) {
    return switch (t) {
      StockMovementType.receipt => theme.colorScheme.primary, // Changed from tertiary to primary for better consistency
      StockMovementType.issue => theme.colorScheme.error, // Issues decrease stock, error color makes sense
      StockMovementType.transfer => theme.colorScheme.secondary,
      StockMovementType.adjustment => theme.colorScheme.tertiary,
    };
  }

  static IconData _typeIcon(StockMovementType t) {
    return switch (t) {
      StockMovementType.receipt => Icons.arrow_downward_rounded,
      StockMovementType.issue => Icons.arrow_upward_rounded,
      StockMovementType.transfer => Icons.sync_alt_rounded,
      StockMovementType.adjustment => Icons.tune_rounded,
    };
  }

  static String _typeLabel(AppLocalizations l10n, StockMovementType t) {
    return switch (t) {
      StockMovementType.receipt => l10n.inventoryMovementTypeReceipt,
      StockMovementType.issue => l10n.inventoryMovementTypeIssue,
      StockMovementType.transfer => l10n.inventoryMovementTypeTransfer,
      StockMovementType.adjustment => l10n.inventoryMovementTypeAdjustment,
    };
  }

  static String _signedLabel(StockMovement m) {
    final n = m.quantity;
    switch (m.type) {
      case StockMovementType.receipt:
        return '+${n.abs()}';
      case StockMovementType.issue:
        return '−${n.abs()}';
      case StockMovementType.transfer:
      case StockMovementType.adjustment:
        if (n >= 0) return '+$n';
        return '−${n.abs()}';
    }
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

/// Icon + uppercase label for the bottom action row. The label sits
/// inside a `Flexible` with `ellipsis` so a long localised string
/// (Khmer, etc.) clips cleanly instead of overflowing the parent
/// `Expanded` slot — which is what caused the ~71 px RenderFlex error
/// when the action labels rendered in full.
class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: AppLabel(
            text: text.toUpperCase(),
            fontSize: AppFontSize.value11,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
