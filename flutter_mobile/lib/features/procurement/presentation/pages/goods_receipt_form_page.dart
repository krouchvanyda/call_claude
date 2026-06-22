import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/purchase_orders_repository.dart';
import '../../entities/goods_receipt.dart';
import '../../entities/purchase_order.dart';

class GoodsReceiptFormPage extends StatefulWidget {
  const GoodsReceiptFormPage({super.key, required this.purchaseOrderId});

  final String purchaseOrderId;

  @override
  State<GoodsReceiptFormPage> createState() => _GoodsReceiptFormPageState();
}

class _GoodsReceiptFormPageState extends State<GoodsReceiptFormPage> {
  late PurchaseOrdersRepository _repo;
  late Future<PurchaseOrder?> _poFuture;
  final _receivedBy = TextEditingController();
  final _note = TextEditingController();
  final Map<String, TextEditingController> _qtyByLineId = {};
  final _formKey = GlobalKey<FormState>();
  String? _formError;

  @override
  void initState() {
    super.initState();
    _repo = getIt<PurchaseOrdersRepository>();
    _poFuture = _repo.findById(widget.purchaseOrderId);
  }

  @override
  void dispose() {
    _receivedBy.dispose();
    _note.dispose();
    for (final c in _qtyByLineId.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String id) => _qtyByLineId.putIfAbsent(id, TextEditingController.new);

  String _errorMessage(AppLocalizations l10n, GoodsReceiptError e) {
    return switch (e) {
      GoodsReceiptError.poClosed => l10n.goodsReceiptErrorPoClosed,
      GoodsReceiptError.noLines => l10n.goodsReceiptErrorNoLines,
      GoodsReceiptError.nonPositiveQuantity => l10n.goodsReceiptErrorNonPositive,
      GoodsReceiptError.unknownLineId => l10n.goodsReceiptErrorUnknownLine,
      GoodsReceiptError.exceedsOutstanding => l10n.goodsReceiptErrorExceedsOutstanding,
    };
  }

  Future<void> _submit(PurchaseOrder po) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final lines = <GoodsReceiptLine>[];
    for (final pol in po.lineItems) {
      final raw = _ctrl(pol.id).text.trim();
      if (raw.isEmpty) continue;
      final qty = num.tryParse(raw);
      if (qty == null || qty == 0) continue;
      lines.add(GoodsReceiptLine(purchaseOrderLineId: pol.id, quantity: qty));
    }

    final receipt = GoodsReceipt(
      id: 'tmp',
      purchaseOrderId: po.id,
      receivedAt: DateTime.now().toUtc(),
      receivedBy: _receivedBy.text.trim(),
      lines: lines,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );

    final err = validateGoodsReceipt(receipt, po);
    if (err != null) {
      setState(() => _formError = _errorMessage(l10n, err));
      return;
    }

    try {
      await _repo.recordGoodsReceipt(receipt);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.goodsReceiptSavedSnack), behavior: SnackBarBehavior.floating));
      if (context.canPop()) context.pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.goodsReceiptSaveFailed(e.toString())), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.goodsReceiptFormTitle,
        centerTitle: true,
        actions: [
          FutureBuilder<PurchaseOrder?>(
            future: _poFuture,
            builder: (context, snap) {
              final po = snap.data;
              if (po == null) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _submit(po),
                child: AppLabel(
                  text: l10n.invoiceFormSaveTooltip.toUpperCase(),
                  fontSize: AppFontSize.value14,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<PurchaseOrder?>(
          future: _poFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final po = snap.data;
            if (po == null) {
              return _CenteredMessage(text: l10n.poDetailNotFound(widget.purchaseOrderId), icon: Icons.search_off_rounded);
            }
            return _Body(
              po: po,
              formKey: _formKey,
              receivedBy: _receivedBy,
              note: _note,
              controllerFor: _ctrl,
              formError: _formError,
              onSubmit: () => _submit(po),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.po,
    required this.formKey,
    required this.receivedBy,
    required this.note,
    required this.controllerFor,
    required this.formError,
    required this.onSubmit,
  });

  final PurchaseOrder po;
  final GlobalKey<FormState> formKey;
  final TextEditingController receivedBy;
  final TextEditingController note;
  final TextEditingController Function(String) controllerFor;
  final String? formError;
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
          _Section(
            title: 'RECEIPT DETAILS',
            children: [
              AppLabel(
                text: l10n.goodsReceiptFormForPo(po.number).toUpperCase(),
                fontSize: AppFontSize.value12,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
              AppLabel(
                text: po.vendorName,
                fontSize: AppFontSize.value14,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: receivedBy,
                label: l10n.goodsReceiptReceivedByLabel,
                icon: Icons.person_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validatorRequired : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: note,
                label: l10n.goodsReceiptNoteLabel,
                icon: Icons.note_rounded,
                maxLines: 2,
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: AppLabel(
              text: l10n.goodsReceiptLinesHeading.toUpperCase(),
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          for (final line in po.lineItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LineRow(line: line, controller: controllerFor(line.id))
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.1, end: 0),
            ),
          if (formError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_rounded, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppLabel(
                      text: formError!,
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().shake(),
          ],
          const SizedBox(height: 40),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.local_shipping_rounded),
              label: AppLabel(
                text: l10n.goodsReceiptSubmitAction.toUpperCase(),
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.controller});
  final PurchaseOrderLine line;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final outstanding = line.outstandingQuantity;
    final isDisabled = outstanding == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDisabled ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(
                      text: line.description,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? theme.colorScheme.outline : null,
                    ),
                    if (line.sku != null) ...[
                      const SizedBox(height: 4),
                      AppLabel(
                        text: l10n.commonSkuLabel(line.sku!),
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDisabled ? theme.colorScheme.outline : theme.colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: AppLabel(
                  text: l10n.poLineOutstandingLabel(outstanding.toString()).toUpperCase(),
                  fontSize: AppFontSize.value10,
                  color: isDisabled ? theme.colorScheme.outline : theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: controller,
            label: l10n.goodsReceiptQuantityLabel,
            icon: Icons.add_shopping_cart_rounded,
            enabled: !isDisabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textCapitalization: TextCapitalization.none,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
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
            Icon(icon ?? Icons.local_shipping_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value16,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
