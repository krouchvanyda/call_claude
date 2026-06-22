import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/projects_repository.dart';
import '../../data/repositories/timesheets_repository.dart';
import '../../entities/project.dart';

/// Slice 8.2.1 — daily timesheet entry form.
class TimesheetFormPage extends StatefulWidget {
  const TimesheetFormPage({
    super.key,
    this.employeeId = 'emp-001',
    this.employeeName = 'Demo Approver',
  });

  final String employeeId;
  final String employeeName;

  @override
  State<TimesheetFormPage> createState() => _TimesheetFormPageState();
}

class _TimesheetFormPageState extends State<TimesheetFormPage> {
  Project? _project;
  DateTime? _date;
  final _hoursCtrl = TextEditingController(text: '8.0');
  final _descCtrl = TextEditingController();
  bool _submitImmediately = false;
  bool _isSubmitting = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _topError;

  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = GetIt.I<ProjectsRepository>().getAll();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? _errFor(String key) {
    final list = _fieldErrors[key];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _topError = null;
      _fieldErrors = const {};
    });
    try {
      final hours = num.tryParse(_hoursCtrl.text.trim()) ?? -1;
      final repo = GetIt.I<TimesheetsRepository>();
      final draft = repo.validate(
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        projectId: _project?.id ?? '',
        projectName: _project?.name ?? '',
        date: _date ?? DateTime.fromMillisecondsSinceEpoch(0),
        hours: hours,
        description: _descCtrl.text,
        now: DateTime.now(),
      );
      final stamped = _submitImmediately ? repo.submit(draft) : draft;
      await repo.create(stamped);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _submitImmediately
                ? 'Timesheet submitted for approval.'
                : 'Timesheet draft saved.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on ValidationFailure catch (f) {
      setState(() => _fieldErrors = f.fieldErrors);
    } catch (e) {
      setState(() => _topError = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.timesheetFormPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<List<Project>>(
              future: _projectsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final projects = snap.data ?? const <Project>[];
                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<Project>(
                            initialValue: _project,
                            // Expand the field + ellipsise long
                            // "{code} — {name}" labels so the
                            // InputDecorator's internal Row doesn't
                            // overflow on narrow phones.
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Project',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              errorText: _errFor('projectId'),
                              prefixIcon: const Icon(Icons.folder_open_rounded),
                            ),
                            items: projects
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: AppLabel(
                                        text: '${p.code} — ${p.name}',
                                        fontSize: AppFontSize.value14,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (p) => setState(() => _project = p),
                          ),
                          const SizedBox(height: 16),
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              errorText: _errFor('date'),
                              prefixIcon: const Icon(Icons.calendar_today_rounded),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date ?? DateTime.now(),
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 90)),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) setState(() => _date = picked);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: AppLabel(
                                  text: _date == null
                                      ? 'Select Date'
                                      : _date!.toIso8601String().split('T').first,
                                  fontSize: AppFontSize.value14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _hoursCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Hours (decimal)',
                              helperText: 'e.g., 0.25 = 15 min, 8.0 = full day',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              errorText: _errFor('hours'),
                              prefixIcon: const Icon(Icons.timer_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'What did you work on?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              errorText: _errFor('description'),
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: AppLabel(
                              text: l10n.timesheetFormSubmitToggleLabel,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: AppLabel(
                              text: l10n.timesheetFormSubmitToggleHint,
                              fontSize: AppFontSize.value12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            value: _submitImmediately,
                            onChanged: (v) => setState(() => _submitImmediately = v),
                          ),
                          if (_topError != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: AppLabel(
                                text: _topError!,
                                fontSize: AppFontSize.value14,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                ),
                              ),
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : AppLabel(
                                      text: l10n.timesheetFormSaveAction,
                                      fontSize: AppFontSize.value14,
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 300.ms),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
