import 'dart:ui';
import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
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
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/quotations_repository.dart';
import '../../entities/customer.dart';
import '../../entities/sales_quotation.dart';

/// Create-quotation form (Slice 6.2.1).
class QuotationFormPage extends StatefulWidget {
  const QuotationFormPage({super.key});

  @override
  State<QuotationFormPage> createState() => _QuotationFormPageState();
}

class _QuotationFormPageState extends State<QuotationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<Customer>> _customersFuture;
  Customer? _customer;
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  final List<_LineDraft> _lines = [_LineDraft()];

  @override
  void initState() {
    super.initState();
    _customersFuture = getIt<CustomersRepository>().getAll();
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  String _resolve(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.validatorRequired,
      'invalid_number' => l10n.validatorInvalidNumber,
      'must_be_positive' => l10n.validatorMustBePositive,
      _ => '',
    };
  }

  String _money(num n) {
    final abs = n.abs().toStringAsFixed(2);
    final parts = abs.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${n < 0 ? '-' : ''}\$$buf.${parts[1]}';
  }

  Future<void> _pickValidUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_customer == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(
              content: Text(l10n.salesQuotationPickCustomer),
              behavior: SnackBarBehavior.floating,
            ));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    var subtotal = 0.0;
    final lines = <SalesLineItem>[];
    for (var i = 0; i < _lines.length; i++) {
      final draft = _lines[i];
      final qty = num.parse(draft.quantity.text.trim());
      final price = num.parse(draft.unitPrice.text.trim());
      final lineTotal = qty * price;
      subtotal += lineTotal.toDouble();
      lines.add(SalesLineItem(
        id: 'tmp-li-${i + 1}',
        description: draft.description.text.trim(),
        quantity: qty,
        unitPrice: _money(price),
        lineTotal: _money(lineTotal),
      ));
    }

    final draft = SalesQuotation(
      id: 'tmp',
      number: 'QT-tmp',
      customerId: _customer!.id,
      customerName: _customer!.name,
      createdAt: DateTime.now().toUtc(),
      validUntil: _validUntil.toUtc(),
      status: QuotationStatus.draft,
      totalAmount: _money(subtotal),
      lineItems: lines,
    );

    try {
      await getIt<QuotationsRepository>().create(draft);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesQuotationSavedSnack),
          behavior: SnackBarBehavior.floating,
        ));
      if (context.canPop()) context.pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesQuotationSaveFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    }
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
        title: l10n.salesQuotationNewTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas Gradient
           AppBackgroundGradient(),
            FutureBuilder<List<Customer>>(
              future: _customersFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final customers = snap.data ?? const <Customer>[];
                return Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: context.dynamicAppBarPadding + 12,
                      left: 16,
                      right: 16,
                      bottom: 40,
                    ),
                    children: [
                      // Header Form Card
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<Customer>(
                                initialValue: _customer,
                                decoration: InputDecoration(
                                  labelText: l10n.salesQuotationCustomerLabel,
                                  prefixIcon: Icon(Icons.business_outlined, color: theme.colorScheme.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: [
                                  for (final c in customers)
                                    DropdownMenuItem(
                                      value: c,
                                      child: AppLabel(
                                        text: c.name,
                                        fontSize: AppFontSize.value14,
                                      ),
                                    ),
                                ],
                                onChanged: (c) => setState(() => _customer = c),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _pickValidUntil,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.salesQuotationValidUntilField,
                                    prefixIcon: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: AppLabel(
                                    text:
                                        '${_validUntil.year.toString().padLeft(4, '0')}-${_validUntil.month.toString().padLeft(2, '0')}-${_validUntil.day.toString().padLeft(2, '0')}',
                                    fontSize: AppFontSize.value14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.format_list_bulleted_outlined, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppLabel(
                              text: l10n.salesQuotationLinesHeading,
                              fontSize: AppFontSize.value16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addLine,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: AppLabel(
                              text: l10n.salesQuotationAddLineAction,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _lines.length; i++) ...[
                        _LineEditor(
                          key: ValueKey(_lines[i]),
                          draft: _lines[i],
                          index: i,
                          resolve: (c) => _resolve(l10n, c),
                          onRemove:
                              _lines.length == 1 ? null : () => _removeLine(i),
                        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.02, end: 0),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: AppLabel(
                          text: l10n.salesQuotationSaveAction,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
    required this.resolve,
    required this.onRemove,
  });
  final _LineDraft draft;
  final int index;
  final String Function(String?) resolve;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: AppLabel(
                    text: l10n.salesQuotationLineHeading(index + 1),
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    tooltip: l10n.salesQuotationRemoveLineTooltip,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: draft.description,
              label: l10n.salesQuotationLineDescriptionLabel,
              icon: Icons.description_outlined,
              validator: (v) {
                final code = Validators.required(v);
                if (code == null) return null;
                final m = resolve(code);
                return m.isEmpty ? null : m;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: draft.quantity,
                    label: l10n.salesQuotationLineQuantityLabel,
                    icon: Icons.shopping_basket_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textCapitalization: TextCapitalization.none,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      final code = Validators.positiveNumber(v);
                      if (code == null) return null;
                      final m = resolve(code);
                      return m.isEmpty ? null : m;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: draft.unitPrice,
                    label: l10n.salesQuotationLineUnitPriceLabel,
                    icon: Icons.attach_money_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textCapitalization: TextCapitalization.none,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      final code = Validators.positiveNumber(v);
                      if (code == null) return null;
                      final m = resolve(code);
                      return m.isEmpty ? null : m;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
