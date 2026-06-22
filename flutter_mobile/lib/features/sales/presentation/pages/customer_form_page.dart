import 'package:flutter/material.dart';
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
import '../../entities/customer.dart';
import 'customer_list_page.dart' show customerStatusLabel, customerSegmentLabel;

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key, this.initial});

  final Customer? initial;

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _billingAddress;
  late final TextEditingController _industry;
  late final TextEditingController _notes;

  late CustomerSegment _segment;
  late CustomerStatus _status;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _email = TextEditingController(text: widget.initial?.email ?? '');
    _phone = TextEditingController(text: widget.initial?.phone ?? '');
    _billingAddress = TextEditingController(
      text: widget.initial?.billingAddress ?? '',
    );
    _industry = TextEditingController(text: widget.initial?.industry ?? '');
    _notes = TextEditingController(text: widget.initial?.notes ?? '');

    _segment = widget.initial?.segment ?? CustomerSegment.smb;
    _status = widget.initial?.status ?? CustomerStatus.prospect;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _billingAddress.dispose();
    _industry.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _resolve(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.validatorRequired,
      'invalid_email' => l10n.validatorInvalidEmail,
      _ => '',
    };
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repo = getIt<CustomersRepository>();
    final draft = Customer(
      id: widget.initial?.id ?? 'tmp',
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      billingAddress: _billingAddress.text.trim(),
      segment: _segment,
      status: _status,
      onboardedAt: widget.initial?.onboardedAt ?? DateTime.now(),
      lifetimeValue: widget.initial?.lifetimeValue ?? '฿0.00',
      industry: _industry.text.trim().isEmpty ? null : _industry.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      if (_isEdit) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Customer updated successfully'
                  : 'Customer created successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      if (context.canPop()) {
        context.pop();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.customerFormSaveFailureSnack(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: _isEdit ? 'Edit Customer' : 'New Customer',
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
                    theme.colorScheme.surface,
                    theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.04,
                    ),
                  ],
                ),
              ),
            ),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: context.dynamicAppBarPadding + 50,
                  left: 16,
                  right: 16,
                  bottom: 40,
                ),
                children: [
                  // Identity Section Card
                  _sectionHeader(theme, 'Identity'),
                  const SizedBox(height: 8),
                  Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
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
                              Center(
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  foregroundColor: theme.colorScheme.primary,
                                  child: const Icon(
                                    Icons.business_outlined,
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _name,
                                label: l10n.customerFormCompanyOrPersonNameLabel,
                                icon: Icons.person_outline,
                                validator: (v) => _resolve(
                                  l10n,
                                  Validators.required(v),
                                ).ifEmptyToNull(),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _industry,
                                label: l10n.customerFormIndustryOptionalLabel,
                                icon: Icons.domain_outlined,
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .scale(
                        begin: const Offset(0.98, 0.98),
                        end: const Offset(1, 1),
                      ),

                  const SizedBox(height: 20),

                  // Contact Section Card
                  _sectionHeader(theme, 'Contact'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
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
                        children: [
                          AppTextField(
                            controller: _email,
                            label: l10n.commonEmailLabel,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            validator: (v) => _resolve(
                              l10n,
                              Validators.email(v),
                            ).ifEmptyToNull(),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _phone,
                            label: l10n.commonPhoneNumberLabel,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => _resolve(
                              l10n,
                              Validators.required(v),
                            ).ifEmptyToNull(),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _billingAddress,
                            label: l10n.customerFormBillingAddressLabel,
                            icon: Icons.place_outlined,
                            maxLines: 3,
                            validator: (v) => _resolve(
                              l10n,
                              Validators.required(v),
                            ).ifEmptyToNull(),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

                  const SizedBox(height: 20),

                  // Commercial / Status Card
                  _sectionHeader(theme, 'Commercial Settings'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
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
                        children: [
                          DropdownButtonFormField<CustomerSegment>(
                            initialValue: _segment,
                            decoration: InputDecoration(
                              labelText: 'Segment',
                              prefixIcon: Icon(
                                Icons.category_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              for (final s in CustomerSegment.values)
                                DropdownMenuItem(
                                  value: s,
                                  child: AppLabel(
                                    text: customerSegmentLabel(l10n, s),
                                    fontSize: AppFontSize.value14,
                                  ),
                                ),
                            ],
                            onChanged: (val) => setState(() => _segment = val!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<CustomerStatus>(
                            initialValue: _status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(
                                Icons.rule_folder_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              for (final s in CustomerStatus.values)
                                DropdownMenuItem(
                                  value: s,
                                  child: AppLabel(
                                    text: customerStatusLabel(l10n, s),
                                    fontSize: AppFontSize.value14,
                                  ),
                                ),
                            ],
                            onChanged: (val) => setState(() => _status = val!),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _notes,
                            label: l10n.customerFormNotesRemarksOptionalLabel,
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: AppLabel(
                      text: _isEdit ? 'Update Customer' : 'Create Customer',
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: AppLabel(
        text: title,
        fontSize: AppFontSize.value16,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

extension on String {
  String? ifEmptyToNull() => isEmpty ? null : this;
}
