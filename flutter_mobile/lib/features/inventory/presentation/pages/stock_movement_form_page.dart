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
import '../../entities/stock_movement.dart';

class StockMovementFormPage extends StatefulWidget {
  const StockMovementFormPage({
    super.key,
    required this.itemId,
    required this.type,
  });

  final String itemId;
  final StockMovementType type;

  @override
  State<StockMovementFormPage> createState() => _StockMovementFormPageState();
}

class _StockMovementFormPageState extends State<StockMovementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late Future<InventoryItem?> _itemFuture;
  String? _qtyError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _itemFuture = getIt<ItemsRepository>().findById(widget.itemId);
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

  Future<void> _submit(InventoryItem item) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _qtyError = null;
    });

    try {
      await recordStockMovement(
        itemsRepo: getIt<ItemsRepository>(),
        movementsRepo: getIt<StockMovementsRepository>(),
        itemId: item.id,
        type: widget.type,
        quantity: num.parse(_qtyCtrl.text.trim()),
        reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_successCopy(l10n, widget.type)), behavior: SnackBarBehavior.floating));
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

  String _titleCopy(AppLocalizations l10n) {
    return switch (widget.type) {
      StockMovementType.receipt => l10n.inventoryReceiptFormTitle,
      StockMovementType.issue => l10n.inventoryIssueFormTitle,
      _ => l10n.inventoryItemDetailTitle,
    };
  }

  String _successCopy(AppLocalizations l10n, StockMovementType t) {
    return switch (t) {
      StockMovementType.receipt => l10n.inventoryReceiptSuccessSnack,
      StockMovementType.issue => l10n.inventoryIssueSuccessSnack,
      _ => l10n.inventoryMovementGenericSuccess,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: _titleCopy(l10n),
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<InventoryItem?>(
          future: _itemFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final item = snap.data;
            if (item == null) {
              return _CenteredMessage(text: l10n.inventoryItemNotFound(widget.itemId), icon: Icons.search_off_rounded);
            }
            return _Body(
              item: item,
              type: widget.type,
              formKey: _formKey,
              qtyCtrl: _qtyCtrl,
              refCtrl: _refCtrl,
              noteCtrl: _noteCtrl,
              qtyError: _qtyError,
              submitting: _submitting,
              resolveValidator: (c) => _resolveValidator(l10n, c),
              onSubmit: () => _submit(item),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.item,
    required this.type,
    required this.formKey,
    required this.qtyCtrl,
    required this.refCtrl,
    required this.noteCtrl,
    required this.qtyError,
    required this.submitting,
    required this.resolveValidator,
    required this.onSubmit,
  });

  final InventoryItem item;
  final StockMovementType type;
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
    final isReceipt = type == StockMovementType.receipt;
    final primaryColor = isReceipt ? theme.colorScheme.primary : theme.colorScheme.error;
    final primaryIcon = isReceipt ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

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
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.inventory_2_rounded, color: theme.colorScheme.primary, size: 24),
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
                          ),
                          const SizedBox(height: 2),
                          AppLabel(
                            text: l10n.commonSkuLabel(item.sku),
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
                        text: l10n.inventoryCurrentStockLabel,
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      const Spacer(),
                      AppLabel(
                        text: item.onHandQty.toString(),
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
            title: 'MOVEMENT DETAILS',
            children: [
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
                hintText: isReceipt
                    ? l10n.inventoryFormReferenceReceiptHint
                    : l10n.inventoryFormReferenceIssueHint,
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
              onPressed: submitting ? null : onSubmit,
              icon: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(primaryIcon),
              label: AppLabel(
                text: (isReceipt ? l10n.inventoryReceiptAction : l10n.inventoryIssueAction).toUpperCase(),
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).scale(curve: Curves.easeOutBack),
        ],
      ),
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
