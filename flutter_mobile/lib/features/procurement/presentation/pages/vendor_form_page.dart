import 'dart:ui';
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
import '../../data/repositories/vendors_repository.dart';
import '../../entities/vendor.dart';

class VendorFormPage extends StatefulWidget {
  const VendorFormPage({super.key});

  @override
  State<VendorFormPage> createState() => _VendorFormPageState();
}

class _VendorFormPageState extends State<VendorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _taxId = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _contactPerson = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _taxId.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _contactPerson.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _resolveError(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.validatorRequired,
      'invalid_email' => l10n.validatorInvalidEmail,
      _ => '',
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = Vendor(
      id: 'tmp',
      name: _name.text.trim(),
      taxId: _taxId.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      status: VendorStatus.active,
      onboardedAt: DateTime.now().toUtc(),
      contactPerson: _contactPerson.text.trim().isEmpty ? null : _contactPerson.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      await getIt<VendorsRepository>().create(draft);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.vendorFormSavedSnack), behavior: SnackBarBehavior.floating));
      if (context.canPop()) context.pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.vendorFormSaveFailed(e.toString())), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.vendorFormTitle,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submit,
            child: AppLabel(
              text: l10n.vendorFormSaveTooltip.toUpperCase(),
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
                title: 'BUSINESS INFORMATION',
                children: [
                  _field(_name, l10n.vendorFormNameLabel, Validators.required, l10n, Icons.business_rounded),
                  const SizedBox(height: 16),
                  _field(_taxId, l10n.vendorFormTaxIdLabel, Validators.required, l10n, Icons.badge_rounded),
                ],
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _Section(
                title: 'CONTACT DETAILS',
                children: [
                  _field(_email, l10n.vendorFormEmailLabel, Validators.email, l10n, Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _field(_phone, l10n.vendorFormPhoneLabel, Validators.required, l10n, Icons.phone_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _field(_contactPerson, l10n.vendorFormContactPersonLabel, (v) => null, l10n, Icons.person_rounded),
                  const SizedBox(height: 16),
                  _field(_address, l10n.vendorFormAddressLabel, Validators.required, l10n, Icons.location_on_rounded, maxLines: 2),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _Section(
                title: 'ADDITIONAL NOTES',
                children: [
                  AppTextField(
                    controller: _notes,
                    label: l10n.vendorFormNotesLabel,
                    icon: Icons.note_rounded,
                    maxLines: 3,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: AppLabel(
                    text: l10n.vendorFormSaveAction.toUpperCase(),
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

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) rule,
    AppLocalizations l10n,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) {
        final code = rule(v);
        if (code == null) return null;
        final msg = _resolveError(l10n, code);
        return msg.isEmpty ? null : msg;
      },
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
