import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/contacts_repository.dart';
import '../../entities/contact.dart';

/// Add / edit a contact (Slice 6.1.2).
///
/// **Edit semantics**: when [initial] is passed, the form is in edit
/// mode and submit calls [`ContactsRepository.update`]; otherwise it
/// calls `.create`. The route layer pushes either flavour.
class ContactFormPage extends StatefulWidget {
  const ContactFormPage({
    super.key,
    required this.customerId,
    this.initial,
  });

  final String customerId;
  final CustomerContact? initial;

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late bool _isPrimary;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _role = TextEditingController(text: widget.initial?.role ?? '');
    _email = TextEditingController(text: widget.initial?.email ?? '');
    _phone = TextEditingController(text: widget.initial?.phone ?? '');
    _isPrimary = widget.initial?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    _phone.dispose();
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
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repo = getIt<ContactsRepository>();
    try {
      if (_isEdit) {
        await repo.update(widget.initial!.copyWith(
          name: _name.text.trim(),
          role: _role.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          isPrimary: _isPrimary,
        ));
      } else {
        await repo.create(CustomerContact(
          id: 'tmp',
          customerId: widget.customerId,
          name: _name.text.trim(),
          role: _role.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          isPrimary: _isPrimary,
        ));
      }
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.salesContactSavedSnack)));
      if (context.canPop()) context.pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(l10n.salesContactSaveFailed(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: _isEdit
              ? l10n.salesContactEditTitle
              : l10n.salesContactNewTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _name,
              label: l10n.salesContactNameLabel,
              icon: Icons.person_outline,
              validator: (v) =>
                  _resolve(l10n, Validators.required(v)).ifEmptyToNull(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _role,
              label: l10n.salesContactRoleLabel,
              icon: Icons.badge_outlined,
              validator: (v) =>
                  _resolve(l10n, Validators.required(v)).ifEmptyToNull(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              label: l10n.salesContactEmailLabel,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              validator: (v) =>
                  _resolve(l10n, Validators.email(v)).ifEmptyToNull(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phone,
              label: l10n.salesContactPhoneLabel,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  _resolve(l10n, Validators.required(v)).ifEmptyToNull(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: AppLabel(
                text: l10n.salesContactPrimaryToggle,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w600,
              ),
              subtitle: AppLabel(
                text: l10n.salesContactPrimaryDescription,
                fontSize: AppFontSize.value12,
              ),
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: AppLabel(
                text: l10n.salesContactSaveAction,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String? ifEmptyToNull() => isEmpty ? null : this;
}
