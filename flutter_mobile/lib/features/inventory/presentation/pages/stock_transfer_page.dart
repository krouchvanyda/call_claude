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
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/items_repository.dart';
import '../../data/repositories/stock_movements_repository.dart';
import '../../entities/inventory_item.dart';

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key, required this.sourceItemId});

  final String sourceItemId;

  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late Future<_Bundle> _future;
  InventoryItem? _destination;
  String? _qtyError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bundle> _load() async {
    final repo = getIt<ItemsRepository>();
    final source = await repo.findById(widget.sourceItemId);
    if (source == null) {
      return const _Bundle(source: null, destinations: []);
    }
    // Candidate destinations: same sku, different id, active.
    final all = await repo.getAll();
    final dests = all
        .where((i) =>
            i.id != source.id &&
            i.sku == source.sku &&
            i.status == InventoryItemStatus.active)
        .toList();
    return _Bundle(source: source, destinations: dests);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _refCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _resolveValidator(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.validatorRequired,
      'invalid_number' => l10n.validatorInvalidNumber,
      'must_be_positive' => l10n.validatorMustBePositive,
      _ => '',
    };
  }

  Future<void> _submit(InventoryItem source) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_destination == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryTransferPickDestination), behavior: SnackBarBehavior.floating));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _qtyError = null;
    });
    try {
      await transferStock(
        itemsRepo: getIt<ItemsRepository>(),
        movementsRepo: getIt<StockMovementsRepository>(),
        sourceItemId: source.id,
        destinationItemId: _destination!.id,
        quantity: num.parse(_qtyCtrl.text.trim()),
        reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryTransferSuccess), behavior: SnackBarBehavior.floating));
      if (context.canPop()) context.pop();
    } on ValidationFailure catch (f) {
      final errs = f.fieldErrors['quantity'] ?? const [];
      final msg = errs.contains('exceeds_on_hand') ? l10n.inventoryQtyExceedsOnHand : l10n.validatorMustBePositive;
      setState(() {
        _submitting = false;
        _qtyError = msg;
      });
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.inventoryTransferFormTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<_Bundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final source = snap.data?.source;
            if (source == null) {
              return _CenteredMessage(text: l10n.inventoryItemNotFound(widget.sourceItemId), icon: Icons.search_off_rounded);
            }
            final dests = snap.data!.destinations;
            return _Body(
              source: source,
              destinations: dests,
              destination: _destination,
              onDestinationChanged: (d) => setState(() => _destination = d),
              formKey: _formKey,
              qtyCtrl: _qtyCtrl,
              refCtrl: _refCtrl,
              noteCtrl: _noteCtrl,
              qtyError: _qtyError,
              submitting: _submitting,
              resolveValidator: (c) => _resolveValidator(l10n, c),
              onSubmit: () => _submit(source),
            );
          },
        ),
      ),
    );
  }
}

class _Bundle {
  const _Bundle({required this.source, required this.destinations});
  final InventoryItem? source;
  final List<InventoryItem> destinations;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.source,
    required this.destinations,
    required this.destination,
    required this.onDestinationChanged,
    required this.formKey,
    required this.qtyCtrl,
    required this.refCtrl,
    required this.noteCtrl,
    required this.qtyError,
    required this.submitting,
    required this.resolveValidator,
    required this.onSubmit,
  });

  final InventoryItem source;
  final List<InventoryItem> destinations;
  final InventoryItem? destination;
  final ValueChanged<InventoryItem?> onDestinationChanged;
  final GlobalKey<FormState> formKey;
  final TextEditingController qtyCtrl;
  final TextEditingController refCtrl;
  final TextEditingController noteCtrl;
  final String? qtyError;
  final bool submitting;
  final String Function(String?) resolveValidator;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: EdgeInsets.only(
          top: context.dynamicAppBarPadding,
          left: 16,
          right: 16,
          bottom: 100,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.outbox_rounded, color: theme.colorScheme.secondary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabel(
                            text: l10n.inventoryTransferSourceHeading.toUpperCase(),
                            fontSize: AppFontSize.value11,
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          const SizedBox(height: 4),
                          AppLabel(
                            text: '${source.warehouseCode} / ${source.locationCode}',
                            fontSize: AppFontSize.value16,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 2),
                          AppLabel(
                            text: l10n.commonSkuLabel(source.sku),
                            fontSize: AppFontSize.value11,
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(AppRadii.md)),
                  child: Row(
                    children: [
                      Icon(Icons.stacked_bar_chart_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      AppLabel(
                        text: l10n.inventoryAvailableToTransferLabel,
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      const Spacer(),
                      AppLabel(
                        text: source.onHandQty.toString(),
                        fontSize: AppFontSize.value16,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.05, end: 0),
          
          const SizedBox(height: 24),
          _Section(
            title: 'TRANSFER DETAILS',
            children: [
              if (destinations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppLabel(
                          text: l10n.inventoryTransferNoDestinations,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<InventoryItem>(
                  value: destination,
                  // `isExpanded` lets the selected-item area fill the
                  // remaining width so a long warehouse/location label
                  // can ellipsise instead of overflowing the Row.
                  isExpanded: true,
                  decoration: _inputDecoration(context, l10n.inventoryTransferDestinationLabel, Icons.login_rounded),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: [
                    for (final d in destinations)
                      DropdownMenuItem(
                        value: d,
                        child: AppLabel(
                          text: '${d.warehouseCode}/${d.locationCode} (${l10n.inventoryItemsOnHand(d.onHandQty.toString())})',
                          fontSize: AppFontSize.value14,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                  ],
                  onChanged: submitting || destinations.isEmpty ? null : onDestinationChanged,
                ),
              const SizedBox(height: 16),
              AppTextField(
                controller: qtyCtrl,
                label: l10n.inventoryFormQuantityLabel,
                icon: Icons.numbers_rounded,
                errorText: qtyError,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textCapitalization: TextCapitalization.none,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v) {
                  final code = Validators.positiveNumber(v);
                  if (code == null) return null;
                  final msg = resolveValidator(code);
                  return msg.isEmpty ? null : msg;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: refCtrl,
                label: l10n.inventoryFormReferenceLabel,
                icon: Icons.receipt_long_rounded,
                hintText: l10n.inventoryTransferReferenceHint,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: noteCtrl,
                label: l10n.inventoryFormNoteLabel,
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
          
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: submitting || destinations.isEmpty ? null : onSubmit,
              icon: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.swap_horiz_rounded),
              label: AppLabel(
                text: l10n.inventoryTransferAction.toUpperCase(),
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).scale(curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, IconData icon, {String? errorText}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: theme.colorScheme.surface,
      errorText: errorText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.error, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.error, width: 2)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: AppLabel(
            text: title,
            fontSize: AppFontSize.value11,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(children: children),
        ),
      ],
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
