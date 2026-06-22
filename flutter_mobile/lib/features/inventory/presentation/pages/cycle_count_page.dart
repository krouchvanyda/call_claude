import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/items_repository.dart';
import '../../data/repositories/stock_movements_repository.dart';
import '../../entities/cycle_count.dart';
import '../../entities/inventory_item.dart';

class CycleCountPage extends StatefulWidget {
  const CycleCountPage({super.key});

  @override
  State<CycleCountPage> createState() => _CycleCountPageState();
}

class _CycleCountPageState extends State<CycleCountPage> {
  late Future<List<InventoryItem>> _itemsFuture;
  final Map<String, TextEditingController> _ctrls = {};
  String? _warehouseFilter;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = getIt<ItemsRepository>().getAll();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(InventoryItem item) {
    return _ctrls.putIfAbsent(
      item.id,
      () => TextEditingController(text: item.onHandQty.toString()),
    );
  }

  Future<void> _submit(List<InventoryItem> items) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final lines = <CycleCountLine>[];
    for (final item in items) {
      if (_warehouseFilter != null && item.warehouseCode != _warehouseFilter) {
        continue;
      }
      final raw = _ctrlFor(item).text.trim();
      final counted = num.tryParse(raw);
      if (counted == null) continue;
      lines.add(CycleCountLine(
        itemId: item.id,
        expectedQty: item.onHandQty,
        countedQty: counted,
      ));
    }
    if (lines.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryCycleEmpty), behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _submitting = true);
    final count = CycleCount(
      id: 'CYCLE-${DateTime.now().millisecondsSinceEpoch}',
      warehouseCode: _warehouseFilter ?? items.first.warehouseCode,
      locationCode: '*',
      startedAt: DateTime.now().toUtc(),
      lines: lines,
    );

    try {
      final out = await applyCycleCount(
        count,
        itemsRepo: getIt<ItemsRepository>(),
        movementsRepo: getIt<StockMovementsRepository>(),
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.inventoryCycleSuccess(out.adjustmentsPosted.length, out.totalVariance.toString())),
          behavior: SnackBarBehavior.floating,
        ));
      if (context.canPop()) context.pop();
    } on Failure catch (f) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryMovementFailed(f.toString())), behavior: SnackBarBehavior.floating));
      if (mounted) setState(() => _submitting = false);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryMovementFailed(e.toString())), behavior: SnackBarBehavior.floating));
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.inventoryCycleCountTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<List<InventoryItem>>(
          future: _itemsFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? const <InventoryItem>[];
            if (items.isEmpty) {
              return _CenteredMessage(text: l10n.inventoryCycleNoItems, icon: Icons.fact_check_rounded);
            }
            final warehouses = items.map((i) => i.warehouseCode).toSet().toList()..sort();
            final filtered = _warehouseFilter == null ? items : items.where((i) => i.warehouseCode == _warehouseFilter).toList();

            return Column(
              children: [
                SizedBox(height: context.dynamicAppBarPadding),
                _WarehouseChips(
                  warehouses: warehouses,
                  selected: _warehouseFilter,
                  onChanged: (wh) => setState(() => _warehouseFilter = wh),
                ).animate().fadeIn(delay: 50.ms),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), // Extra padding for bottom button
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CycleLine(
                        item: filtered[i],
                        controller: _ctrlFor(filtered[i]),
                      )
                          .animate()
                          .fadeIn(delay: (100 + i * 30).ms)
                          .slideY(begin: 0.05, end: 0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<List<InventoryItem>>(
        future: _itemsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done || (snap.data?.isEmpty ?? true)) {
            return const SizedBox.shrink();
          }
          final items = snap.data!;
          return Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(items),
                icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.fact_check_rounded),
                label: AppLabel(
                  text: l10n.inventoryCycleSubmitAction.toUpperCase(),
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
              ),
            ),
          ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms);
        },
      ),
    );
  }
}

class _WarehouseChips extends StatelessWidget {
  const _WarehouseChips({
    required this.warehouses,
    required this.selected,
    required this.onChanged,
  });

  final List<String> warehouses;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: AppLabel(
                  text: l10n.inventoryCycleAllWarehouses,
                  fontSize: AppFontSize.value13,
                ),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected == null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected == null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            for (final wh in warehouses)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: AppLabel(
                    text: wh,
                    fontSize: AppFontSize.value13,
                  ),
                  selected: selected == wh,
                  onSelected: (_) => onChanged(wh),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected == wh ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected == wh ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CycleLine extends StatelessWidget {
  const _CycleLine({required this.item, required this.controller});
  final InventoryItem item;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    // Determine variance dynamically based on input if possible, but since we're stateless here without a listener,
    // we'll highlight the expected quantity to draw attention.
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                  text: l10n.inventorySkuLocationCompound(item.sku, item.locationCode),
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: AppLabel(
                    text: l10n.inventoryCycleExpectedLabel(item.onHandQty.toString()).toUpperCase(),
                    fontSize: AppFontSize.value9,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()]),
              decoration: InputDecoration(
                labelText: l10n.inventoryCycleCountedLabel.toUpperCase(),
                labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: theme.colorScheme.primary),
                floatingLabelAlignment: FloatingLabelAlignment.center,
                filled: true,
                fillColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
              ),
            ),
          ),
        ],
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
              child: Icon(icon ?? Icons.fact_check_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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
