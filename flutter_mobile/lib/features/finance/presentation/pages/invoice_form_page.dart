import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';

class InvoiceFormPage extends StatefulWidget {
  const InvoiceFormPage({super.key, this.invoiceId});

  final String? invoiceId;

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _unitPrice = TextEditingController();

  DateTime? _issued = DateTime.now();
  DateTime? _due = DateTime.now().add(const Duration(days: 30));
  String? _dateRangeError;

  bool get _isEdit => widget.invoiceId != null;

  @override
  void dispose() {
    _customer.dispose();
    _description.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  String _resolveError(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.validatorRequired,
      'invalid_number' => l10n.validatorInvalidNumber,
      'must_be_positive' => l10n.validatorMustBePositive,
      'must_be_non_negative' => l10n.validatorMustBeNonNegative,
      'due_before_issued' => l10n.validatorDueBeforeIssued,
      _ => '',
    };
  }

  Future<void> _pickDate(BuildContext context, bool isIssued) async {
    final initial = (isIssued ? _issued : _due) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isIssued) {
        _issued = picked;
      } else {
        _due = picked;
      }
      _dateRangeError = Validators.dueOnOrAfterIssued(
        issued: _issued,
        due: _due,
      );
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final dateErr = Validators.dueOnOrAfterIssued(
      issued: _issued,
      due: _due,
    );
    setState(() => _dateRangeError = dateErr);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || dateErr != null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.invoiceFormSavedSnack),
        behavior: SnackBarBehavior.floating,
      ));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat('MMM dd, yyyy');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: _isEdit ? l10n.invoiceFormEditTitle : l10n.invoiceFormCreateTitle,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submit,
            child: AppLabel(
              text: l10n.invoiceFormSaveTooltip.toUpperCase(),
              fontSize: AppFontSize.value14,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
                    controller: _customer,
                    label: l10n.invoiceFormCustomerLabel,
                    icon: Icons.person_outline_rounded,
                    validator: (v) => _resolveError(l10n, Validators.required(v)).ifEmptyToNull(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: l10n.invoiceFormIssuedLabel,
                          value: _issued,
                          formatter: dateFmt,
                          onTap: () => _pickDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: l10n.invoiceFormDueLabel,
                          value: _due,
                          formatter: dateFmt,
                          onTap: () => _pickDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  if (_dateRangeError != null) ...[
                    const SizedBox(height: 8),
                    AppLabel(
                      text: _resolveError(l10n, _dateRangeError),
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ],
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _Section(
                title: 'LINE ITEM',
                children: [
                  AppTextField(
                    controller: _description,
                    label: l10n.invoiceFormLineDescriptionLabel,
                    icon: Icons.description_outlined,
                    validator: (v) => _resolveError(l10n, Validators.required(v)).ifEmptyToNull(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _quantity,
                          label: l10n.invoiceFormLineQuantityLabel,
                          icon: Icons.format_list_numbered_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textCapitalization: TextCapitalization.none,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => _resolveError(l10n, Validators.positiveNumber(v)).ifEmptyToNull(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _unitPrice,
                          label: l10n.invoiceFormLineUnitPriceLabel,
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textCapitalization: TextCapitalization.none,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => _resolveError(l10n, Validators.positiveNumber(v)).ifEmptyToNull(),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: AppLabel(
                    text: l10n.invoiceFormSaveAction.toUpperCase(),
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(curve: Curves.easeOutBack),
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

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.formatter, required this.onTap});
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide(color: theme.colorScheme.outlineVariant)),
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
        ),
        child: AppLabel(
          text: value == null ? '' : formatter.format(value!.toLocal()),
          fontSize: AppFontSize.value16,
        ),
      ),
    );
  }
}

extension on String {
  String? ifEmptyToNull() => isEmpty ? null : this;
}
