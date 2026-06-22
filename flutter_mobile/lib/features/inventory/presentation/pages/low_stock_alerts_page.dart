import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/low_stock_notifier.dart';
import '../../data/repositories/items_repository.dart';
import '../../entities/inventory_item.dart';
import 'item_detail_page.dart';

/// Slice 5.1.3 — surfaces the current low-stock items as a single
/// scrollable page. Re-uses the [`LowStockNotifier`]'s cached report
/// when available so the page paints instantly; otherwise it does a
/// one-shot scan.
class LowStockAlertsPage extends StatefulWidget {
  const LowStockAlertsPage({super.key});

  @override
  State<LowStockAlertsPage> createState() => _LowStockAlertsPageState();
}

class _LowStockAlertsPageState extends State<LowStockAlertsPage> {
  late Future<List<InventoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<InventoryItem>> _load() async {
    // Prefer the notifier's cached snapshot — it's always fresh because
    // it subscribes to the watch stream.
    if (getIt.isRegistered<LowStockNotifier>()) {
      final cached = getIt<LowStockNotifier>().latestReport.allLowStock;
      if (cached.isNotEmpty) return cached;
    }
    final items = await getIt<ItemsRepository>().getAll();
    return checkLowStock(items).allLowStock;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.inventoryLowStockTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<List<InventoryItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <InventoryItem>[];
          if (items.isEmpty) {
            return _Empty(text: l10n.inventoryLowStockEmpty);
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) => _AlertRow(item: items[i]),
          );
        },
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.item});
  final InventoryItem item;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.error.withValues(alpha: 0.15),
        foregroundColor: theme.colorScheme.error,
        child: const Icon(Icons.warning_amber_outlined),
      ),
      title: AppLabel(
        text: item.sku,
        fontSize: AppFontSize.value14,
        fontWeight: FontWeight.w600,
      ),
      subtitle: AppLabel(
        text: '${item.name} · ${item.warehouseCode}/${item.locationCode}',
        fontSize: AppFontSize.value11,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLabel(
            text: l10n.inventoryItemsOnHand(item.onHandQty.toString()),
            fontSize: AppFontSize.value14,
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          AppLabel(
            text: l10n.inventoryReorderBadge(item.reorderPoint.toString()),
            fontSize: AppFontSize.value11,
          ),
        ],
      ),
      onTap: () => ConfigRouter.pushPageAnimation(
        context,
        ItemDetailPage(itemId: item.id),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: theme.colorScheme.tertiary),
            const SizedBox(height: 12),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value14,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
