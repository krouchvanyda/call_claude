import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/purchase_requests_repository.dart';
import '../../entities/purchase_request.dart';
import 'pr_list_page.dart';

class PurchaseRequestFormPage extends StatefulWidget {
  const PurchaseRequestFormPage({super.key});

  @override
  State<PurchaseRequestFormPage> createState() => _PurchaseRequestFormPageState();
}

class _PurchaseRequestFormPageState extends State<PurchaseRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _requester = TextEditingController();
  final _costCenter = TextEditingController();
  final _approver = TextEditingController();
  final _justification = TextEditingController();

  final List<_LineDraft> _lines = [_LineDraft()];

  @override
  void dispose() {
    _requester.dispose();
    _costCenter.dispose();
    _approver.dispose();
    _justification.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  String _resolveError(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.validatorRequired,
      'invalid_number' => l10n.validatorInvalidNumber,
      'must_be_positive' => l10n.validatorMustBePositive,
      _ => '',
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    var subtotal = 0.0;
    final lines = <PurchaseRequestLine>[];
    for (var i = 0; i < _lines.length; i++) {
      final draft = _lines[i];
      final qty = num.parse(draft.quantity.text.trim());
      final price = num.parse(draft.unitPrice.text.trim());
      final lineTotal = qty * price;
      subtotal += lineTotal.toDouble();
      lines.add(PurchaseRequestLine(
        id: 'tmp-li-${i + 1}',
        description: draft.description.text.trim(),
        quantity: qty,
        unitPrice: _money(price),
        lineTotal: _money(lineTotal),
      ));
    }

    final draft = PurchaseRequest(
      id: 'tmp',
      number: 'PR-tmp',
      requesterName: _requester.text.trim(),
      costCenter: _costCenter.text.trim(),
      approverName: _approver.text.trim(),
      createdAt: DateTime.now().toUtc(),
      status: PurchaseRequestStatus.submitted,
      totalAmount: _money(subtotal),
      lineItems: lines,
      justification: _justification.text.trim().isEmpty ? null : _justification.text.trim(),
    );

    try {
      await getIt<PurchaseRequestsRepository>().create(draft);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.prFormSavedSnack), behavior: SnackBarBehavior.floating));
      // Pop back to the list (form was pushed from it). Using pop
      // preserves the Modules → list history so the list's back
      // button still returns to Modules. goNamed would replace
      // the whole stack and break that.
      if (context.canPop()) {
        context.pop();
      } else {
        ConfigRouter.pushPageAndRemoveUntilAnimation(
          context,
          const PurchaseRequestListPage(),
        );
      }
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.prFormSaveFailed(e.toString())), behavior: SnackBarBehavior.floating));
    }
  }

  String _money(num n) {
    final neg = n < 0;
    final abs = n.abs().toStringAsFixed(2);
    final parts = abs.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${neg ? '-' : ''}\$$buf.${parts[1]}';
  }

  void _addLine() => setState(() => _lines.add(_LineDraft()));
  void _removeLine(int i) {
    if (_lines.length == 1) return;
    setState(() {
      _lines[i].dispose();
      _lines.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.prFormCreateTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Form(
          key: _formKey,
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
                title: 'GENERAL INFORMATION',
                children: [
                  AppTextField(
                    controller: _requester,
                    label: l10n.prFormRequesterLabel,
                    icon: Icons.person_outline_rounded,
                    validator: (v) => _resolveError(l10n, Validators.required(v)).ifEmptyToNull(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _costCenter,
                          label: l10n.prFormCostCenterLabel,
                          icon: Icons.account_balance_outlined,
                          validator: (v) => _resolveError(l10n, Validators.required(v)).ifEmptyToNull(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _approver,
                          label: l10n.prFormApproverLabel,
                          icon: Icons.how_to_reg_outlined,
                          validator: (v) => _resolveError(l10n, Validators.required(v)).ifEmptyToNull(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _justification,
                    label: l10n.prFormJustificationLabel,
                    icon: Icons.subject_rounded,
                    maxLines: 3,
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: AppLabel(
                        text: l10n.prFormLinesHeading.toUpperCase(),
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: AppLabel(
                      text: l10n.prFormAddLineAction.toUpperCase(),
                      fontSize: AppFontSize.value12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              for (var i = 0; i < _lines.length; i++) ...[
                _LineEditor(
                  key: ValueKey(_lines[i]),
                  draft: _lines[i],
                  index: i,
                  resolveError: (code) => _resolveError(l10n, code),
                  onRemove: _lines.length == 1 ? null : () => _removeLine(i),
                ).animate().fadeIn(delay: (150 + i * 50).ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: AppLabel(
                    text: l10n.prFormSubmitAction.toUpperCase(),
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
                ),
              ).animate().fadeIn(delay: 300.ms).scale(curve: Curves.easeOutBack),
            ],
          ),
        ),
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

class _LineDraft {
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unitPrice = TextEditingController();

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _LineEditor extends StatelessWidget {
  const _LineEditor({
    super.key,
    required this.draft,
    required this.index,
    required this.resolveError,
    required this.onRemove,
  });

  final _LineDraft draft;
  final int index;
  final String Function(String?) resolveError;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppLabel(
                  text: l10n.prFormLineHeading(index + 1).toUpperCase(),
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  tooltip: l10n.prFormRemoveLineTooltip,
                  icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error, size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: draft.description,
            label: l10n.prFormLineDescriptionLabel,
            icon: Icons.description_outlined,
            validator: (v) => resolveError(Validators.required(v)).ifEmptyToNull(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: draft.quantity,
                  label: l10n.prFormLineQuantityLabel,
                  icon: Icons.format_list_numbered_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) => resolveError(Validators.positiveNumber(v)).ifEmptyToNull(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: draft.unitPrice,
                  label: l10n.prFormLineUnitPriceLabel,
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) => resolveError(Validators.positiveNumber(v)).ifEmptyToNull(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

extension on String {
  String? ifEmptyToNull() => isEmpty ? null : this;
}
