import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../entities/inventory_item.dart';
import '../bloc/items_list_bloc.dart';
import '../bloc/items_list_event.dart';
import '../bloc/items_list_state.dart';
import 'item_detail_page.dart';
import 'low_stock_alerts_page.dart';
import 'scanner_page.dart';

class ItemsListPage extends StatelessWidget {
  const ItemsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemsListBloc>(
      create: (_) => getIt<ItemsListBloc>()..add(const ItemsListStarted()),
      child: const _ListView(),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.inventoryItemsTitle,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.inventoryScanTooltip,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => ConfigRouter.pushPageAnimation(context, const ScannerPage()),
          ),
          IconButton(
            tooltip: l10n.inventoryLowStockAlertsTooltip,
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () => ConfigRouter.pushPageAnimation(context, const LowStockAlertsPage()),
          ),
          _SortAction(),
        ],
      ),
      body: DynamicStatusBar(
        child: Column(
          children: [
            const _Toolbar(),
            const Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

class _SortAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ItemsListBloc, ItemsListState>(
      buildWhen: (a, b) => a.sort != b.sort,
      builder: (context, state) => PopupMenuButton<InventoryItemSort>(
        tooltip: l10n.inventoryItemsSortTooltip,
        icon: const Icon(Icons.sort_rounded),
        initialValue: state.sort,
        onSelected: (s) => context.read<ItemsListBloc>().add(ItemsListSortChanged(s)),
        itemBuilder: (_) => [
          for (final s in InventoryItemSort.values)
            PopupMenuItem(
              value: s,
              child: AppLabel(
                text: _sortLabel(l10n, s),
                fontSize: AppFontSize.value14,
              ),
            ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ItemsListBloc>();
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                hintText: l10n.inventoryItemsSearchHint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (q) => bloc.add(ItemsListSearchChanged(q)),
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          BlocBuilder<ItemsListBloc, ItemsListState>(
            buildWhen: (a, b) => a.warehouseFilter != b.warehouseFilter || a.onlyLowStock != b.onlyLowStock || a.availableWarehouses.length != b.availableWarehouses.length,
            builder: (context, state) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(Icons.warning_amber_rounded, size: 18, color: state.onlyLowStock ? theme.colorScheme.error : null),
                      label: AppLabel(
                        text: l10n.inventoryLowStockChip,
                        fontSize: AppFontSize.value13,
                      ),
                      selected: state.onlyLowStock,
                      onSelected: (v) => bloc.add(ItemsListLowStockToggled(v)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                      selectedColor: theme.colorScheme.error.withValues(alpha: 0.2),
                      checkmarkColor: theme.colorScheme.error,
                      labelStyle: TextStyle(
                        color: state.onlyLowStock ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                        fontWeight: state.onlyLowStock ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  for (final wh in state.availableWarehouses)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: AppLabel(
                          text: wh,
                          fontSize: AppFontSize.value13,
                        ),
                        selected: state.warehouseFilter.contains(wh),
                        onSelected: (_) => bloc.add(ItemsListWarehouseToggled(wh)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: state.warehouseFilter.contains(wh) ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          fontWeight: state.warehouseFilter.contains(wh) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ItemsListBloc, ItemsListState>(
      builder: (context, state) {
        if (state.isLoading && state.source.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.source.isEmpty) {
          return _CenteredMessage(text: l10n.inventoryItemsError(state.errorMessage!), icon: Icons.error_outline_rounded);
        }
        if (state.visible.isEmpty) {
          return _CenteredMessage(text: l10n.inventoryItemsEmpty, icon: Icons.inventory_2_rounded);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: state.visible.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ItemCard(item: state.visible[i])
                .animate()
                .fadeIn(delay: (i * 30).ms)
                .slideY(begin: 0.05, end: 0),
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lowStock = item.isLowStock;
    final statusColor = inventoryStatusColor(theme, item);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: lowStock ? theme.colorScheme.error.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: lowStock ? [BoxShadow(color: theme.colorScheme.error.withValues(alpha: 0.1), blurRadius: 10)] : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          ItemDetailPage(itemId: item.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(lowStock ? Icons.warning_rounded : Icons.inventory_2_rounded, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(
                      text: item.name,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AppLabel(
                      text: l10n.commonSkuLabel(item.sku),
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    const SizedBox(height: 2),
                    AppLabel(
                      text: l10n.inventoryWarehouseLocationLabel(item.warehouseCode, item.locationCode),
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (lowStock ? theme.colorScheme.error : theme.colorScheme.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: AppLabel(
                      text: l10n.inventoryItemsOnHand(item.onHandQty.toString()),
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w900,
                      color: lowStock
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (lowStock) ...[
                    const SizedBox(height: 4),
                    AppLabel(
                      text: l10n.inventoryReorderBadge(item.reorderPoint.toString()).toUpperCase(),
                      fontSize: AppFontSize.value9,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w900,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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

Color inventoryStatusColor(ThemeData theme, InventoryItem item) {
  if (item.status == InventoryItemStatus.discontinued) {
    return theme.colorScheme.outline;
  }
  if (item.status == InventoryItemStatus.blocked) {
    return theme.colorScheme.error;
  }
  if (item.isLowStock) return theme.colorScheme.error;
  return theme.colorScheme.primary;
}

String _sortLabel(AppLocalizations l10n, InventoryItemSort s) {
  return switch (s) {
    InventoryItemSort.nameAsc => l10n.inventorySortNameAsc,
    InventoryItemSort.skuAsc => l10n.inventorySortSkuAsc,
    InventoryItemSort.onHandAsc => l10n.inventorySortOnHandAsc,
    InventoryItemSort.onHandDesc => l10n.inventorySortOnHandDesc,
  };
}
