import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../features/hr/data/repositories/employees_repository.dart';
import '../../../../features/hr/entities/employee.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/projects_repository.dart';
import '../../entities/project.dart';

/// Slice 8.1.4 — Create / Edit Project charter form.
///
/// Backed fields (persist to [Project]): name, code, description, startDate,
/// endDate, status, ownerId/ownerName, budget. The design guide also
/// specifies billing type and priority — those aren't on the entity yet
/// so the UI omits them (extend the entity first when needed).
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key, this.existing});

  /// Null when creating, non-null when editing.
  final Project? existing;

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late ProjectStatus _status;
  Employee? _owner;
  late Future<List<Employee>> _employeesFuture;
  bool _saving = false;

  static final _date = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _employeesFuture = GetIt.I<EmployeesRepository>().getAll();
    final p = widget.existing;
    final now = DateTime.now();
    if (p != null) {
      _nameCtrl.text = p.name;
      _codeCtrl.text = p.code;
      _descCtrl.text = p.description;
      _budgetCtrl.text = p.budget;
      _startDate = p.startDate;
      _endDate = p.endDate;
      _status = p.status;
    } else {
      _startDate = now;
      _endDate = now.add(const Duration(days: 30));
      _status = ProjectStatus.planning;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  int get _durationDays => _endDate
          .difference(_startDate)
          .inDays +
      1;

  String get _durationLabel {
    final d = _durationDays;
    if (d <= 0) return '—';
    if (d % 7 == 0) {
      final w = d ~/ 7;
      return '$w week${w == 1 ? '' : 's'} ($d days)';
    }
    return '$d days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: _isEdit ? 'Edit Project' : 'New Project',
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<List<Employee>>(
              future: _employeesFuture,
              builder: (context, snap) {
                final employees = snap.data ?? const <Employee>[];
                if (_owner == null && widget.existing != null) {
                  for (final e in employees) {
                    if (e.id == widget.existing!.ownerId) {
                      _owner = e;
                      break;
                    }
                  }
                }
                return Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: context.dynamicAppBarPadding,
                      left: 16,
                      right: 16,
                      bottom: 120,
                    ),
                    children: [
                      _SectionLabel('Basic Info'),
                      const SizedBox(height: 8),
                      _BasicInfoCard(
                        nameCtrl: _nameCtrl,
                        codeCtrl: _codeCtrl,
                        descCtrl: _descCtrl,
                      ).animate().fadeIn().slideY(begin: 0.04, end: 0),
                      const SizedBox(height: 20),
                      _SectionLabel('Timeline'),
                      const SizedBox(height: 8),
                      _TimelineCard(
                        startDate: _startDate,
                        endDate: _endDate,
                        durationLabel: _durationLabel,
                        dateFormat: _date,
                        onPickStart: () => _pickDate(isStart: true),
                        onPickEnd: () => _pickDate(isStart: false),
                      ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04, end: 0),
                      const SizedBox(height: 20),
                      _SectionLabel('Budget'),
                      const SizedBox(height: 8),
                      _BudgetCard(controller: _budgetCtrl)
                          .animate()
                          .fadeIn(delay: 160.ms)
                          .slideY(begin: 0.04, end: 0),
                      const SizedBox(height: 20),
                      _SectionLabel('Owner'),
                      const SizedBox(height: 8),
                      _OwnerPickerCard(
                        employees: employees,
                        loading: snap.connectionState == ConnectionState.waiting,
                        current: _owner,
                        onPicked: (e) => setState(() => _owner = e),
                      ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.04, end: 0),
                      const SizedBox(height: 20),
                      _SectionLabel('Status'),
                      const SizedBox(height: 8),
                      _StatusPickerCard(
                        current: _status,
                        onChanged: (s) => setState(() => _status = s),
                      ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.04, end: 0),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SaveBar(
                saving: _saving,
                label: _isEdit ? 'Update Project' : 'Create Project',
                onSave: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        if (picked.isBefore(_startDate)) {
          _showToast('End date cannot be before start date');
          return;
        }
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_owner == null) {
      _showToast('Pick a project owner');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = GetIt.I<ProjectsRepository>();
      final existing = widget.existing;
      final draft = (existing ?? _blankProject()).copyWith(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        ownerId: _owner!.id,
        ownerName: _owner!.name,
        budget: _budgetCtrl.text.trim(),
      );
      if (existing == null) {
        await repo.create(draft);
        _showToast('Project created');
      } else {
        await repo.update(draft);
        _showToast('Project updated');
      }
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      _showToast('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Project _blankProject() => Project(
        id: '',
        code: '',
        name: '',
        description: '',
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        ownerId: '',
        ownerName: '',
        budget: '',
      );

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: AppLabel(
        text: text.toUpperCase(),
        fontSize: AppFontSize.value11,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.descCtrl,
  });
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController descCtrl;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Card(
      child: Column(
        children: [
          AppTextField(
            controller: nameCtrl,
            label: l10n.projectFormNameLabel,
            icon: Icons.folder_special_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: codeCtrl,
            label: l10n.projectFormCodeLabel,
            icon: Icons.qr_code_2_rounded,
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: descCtrl,
            label: l10n.projectFormDescriptionLabel,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.startDate,
    required this.endDate,
    required this.durationLabel,
    required this.dateFormat,
    required this.onPickStart,
    required this.onPickEnd,
  });
  final DateTime startDate;
  final DateTime endDate;
  final String durationLabel;
  final DateFormat dateFormat;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  label: l10n.projectFormStartLabel,
                  value: dateFormat.format(startDate),
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateBox(
                  label: l10n.projectFormEndLabel,
                  value: dateFormat.format(endDate),
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timelapse_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                AppLabel(
                  text: l10n.projectFormDurationLabel(durationLabel),
                  fontSize: AppFontSize.value14,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabel(
              text: label.toUpperCase(),
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                AppLabel(
                  text: value,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Card(
      child: AppTextField(
        controller: controller,
        label: l10n.projectFormBudgetLabel,
        icon: Icons.attach_money_rounded,
        keyboardType: TextInputType.number,
        textCapitalization: TextCapitalization.none,
        hintText: r'$120,000.00',
      ),
    );
  }
}

class _OwnerPickerCard extends StatelessWidget {
  const _OwnerPickerCard({
    required this.employees,
    required this.loading,
    required this.current,
    required this.onPicked,
  });
  final List<Employee> employees;
  final bool loading;
  final Employee? current;
  final ValueChanged<Employee> onPicked;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: InkWell(
        onTap: loading || employees.isEmpty
            ? null
            : () async {
                final picked = await _showEmployeeSheet(context, employees, current);
                if (picked != null) onPicked(picked);
              },
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: AppLabel(
                  text: current == null ? '?' : _initials(current!.name),
                  fontSize: AppFontSize.value14,
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(
                      text: current?.name ??
                          (loading ? 'Loading…' : 'Pick a project owner'),
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w700,
                    ),
                    if (current != null)
                      AppLabel(
                        text: current!.position,
                        fontSize: AppFontSize.value12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPickerCard extends StatelessWidget {
  const _StatusPickerCard({required this.current, required this.onChanged});
  final ProjectStatus current;
  final ValueChanged<ProjectStatus> onChanged;
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in ProjectStatus.values)
            ChoiceChip(
              label: AppLabel(
                text: _label(s),
                fontSize: AppFontSize.value13,
              ),
              selected: current == s,
              onSelected: (_) => onChanged(s),
              shape: const StadiumBorder(),
            ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.label,
    required this.onSave,
  });
  final bool saving;
  final String label;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: AppLabel(
            text: saving ? 'Saving…' : label,
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.w600,
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  helpers
// ─────────────────────────────────────────────────────────────────────────────

String _label(ProjectStatus s) {
  switch (s) {
    case ProjectStatus.planning:
      return 'Planning';
    case ProjectStatus.active:
      return 'Active';
    case ProjectStatus.onHold:
      return 'On Hold';
    case ProjectStatus.completed:
      return 'Completed';
    case ProjectStatus.archived:
      return 'Archived';
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}

Future<Employee?> _showEmployeeSheet(
    BuildContext context, List<Employee> employees, Employee? current) {
  return showModalBottomSheet<Employee>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final l10n = AppLocalizations.of(ctx);
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppLabel(
                    text: l10n.projectFormPickEmployeeAction,
                    fontSize: AppFontSize.value22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = employees[i];
                    final selected = current?.id == e.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: AppLabel(
                          text: _initials(e.name),
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      title: AppLabel(
                        text: e.name,
                        fontSize: AppFontSize.value16,
                        fontWeight: FontWeight.w600,
                      ),
                      subtitle: AppLabel(
                        text: '${e.position} • ${e.department}',
                        fontSize: AppFontSize.value12,
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, e),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
