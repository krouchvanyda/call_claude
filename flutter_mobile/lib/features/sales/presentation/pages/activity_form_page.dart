import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/activities_repository.dart';
import '../../entities/activity_event.dart';

/// Log a new activity against a customer (Slice 6.1.3).
///
/// Limited to the touch-points a CRM user records by hand —
/// `note`, `call`, `meeting`, `email`. The other kinds (`order`,
/// `quotation`, `payment`) are written by their respective domain
/// flows.
class ActivityFormPage extends StatefulWidget {
  const ActivityFormPage({super.key, required this.customerId});

  final String customerId;

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  static const _manualTypes = <ActivityEventType>[
    ActivityEventType.note,
    ActivityEventType.call,
    ActivityEventType.meeting,
    ActivityEventType.email,
  ];

  final _formKey = GlobalKey<FormState>();
  final _summary = TextEditingController();
  final _actor = TextEditingController(text: 'Demo Approver');
  ActivityEventType _type = ActivityEventType.note;

  @override
  void dispose() {
    _summary.dispose();
    _actor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await getIt<ActivitiesRepository>().append(ActivityEvent(
        id: 'tmp',
        customerId: widget.customerId,
        type: _type,
        occurredAt: DateTime.now().toUtc(),
        summary: _summary.text.trim(),
        actor: _actor.text.trim(),
      ));
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.salesActivitySavedSnack)));
      if (context.canPop()) context.pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesActivitySaveFailed(e.toString())),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.salesActivityFormTitle,
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
            DropdownButtonFormField<ActivityEventType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: l10n.salesActivityTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final t in _manualTypes)
                  DropdownMenuItem(
                    value: t,
                    child: AppLabel(
                      text: activityTypeLabel(l10n, t),
                      fontSize: AppFontSize.value14,
                    ),
                  ),
              ],
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _summary,
              label: l10n.salesActivitySummaryLabel,
              icon: Icons.notes_outlined,
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? l10n.validatorRequired
                      : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _actor,
              label: l10n.salesActivityActorLabel,
              icon: Icons.person_outline,
              validator: (v) {
                final code = Validators.required(v);
                return code == null ? null : l10n.validatorRequired;
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: AppLabel(
                text: l10n.salesActivitySaveAction,
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

String activityTypeLabel(AppLocalizations l10n, ActivityEventType t) {
  return switch (t) {
    ActivityEventType.note => l10n.salesActivityTypeNote,
    ActivityEventType.call => l10n.salesActivityTypeCall,
    ActivityEventType.meeting => l10n.salesActivityTypeMeeting,
    ActivityEventType.email => l10n.salesActivityTypeEmail,
    ActivityEventType.quotation => l10n.salesActivityTypeQuotation,
    ActivityEventType.order => l10n.salesActivityTypeOrder,
    ActivityEventType.payment => l10n.salesActivityTypePayment,
  };
}

IconData activityTypeIcon(ActivityEventType t) {
  return switch (t) {
    ActivityEventType.note => Icons.sticky_note_2_outlined,
    ActivityEventType.call => Icons.call_outlined,
    ActivityEventType.meeting => Icons.event_outlined,
    ActivityEventType.email => Icons.email_outlined,
    ActivityEventType.quotation => Icons.request_quote_outlined,
    ActivityEventType.order => Icons.shopping_bag_outlined,
    ActivityEventType.payment => Icons.payments_outlined,
  };
}
