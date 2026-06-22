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
import '../../data/repositories/tasks_repository.dart';
import '../../entities/task.dart';

/// Slice 8.1.5 — fast Task Create / Edit entry form.
///
/// Backed fields: title, description, status, priority, assigneeId/Name,
/// dueDate. The design guide also mentions inline subtasks — those aren't
/// on [ProjectTask] yet so the UI omits them.
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({
    super.key,
    required this.projectId,
    this.existing,
  });

  final String projectId;
  final ProjectTask? existing;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late TaskStatus _status;
  late TaskPriority _priority;
  Employee? _assignee;
  DateTime? _dueDate;
  late Future<List<Employee>> _employeesFuture;
  bool _saving = false;

  static final _date = DateFormat('MMM d, yyyy');

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _employeesFuture = GetIt.I<EmployeesRepository>().getAll();
    final t = widget.existing;
    if (t != null) {
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _status = t.status;
      _priority = t.priority;
      _dueDate = t.dueDate;
    } else {
      _status = TaskStatus.todo;
      _priority = TaskPriority.medium;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: _isEdit ? l10n.taskFormPageTitleEdit : l10n.taskFormPageTitleNew,
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
                if (_assignee == null && widget.existing?.assigneeId != null) {
                  for (final e in employees) {
                    if (e.id == widget.existing!.assigneeId) {
                      _assignee = e;
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
                      TextFormField(
                        controller: _titleCtrl,
                        maxLines: 2,
                        minLines: 1,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.taskFormTitleHint,
                          hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.taskFormTitleRequiredValidator : null,
                      ).animate().fadeIn().slideY(begin: 0.04, end: 0),
                      const SizedBox(height: 16),
                      _SectionLabel('Details'),
                      const SizedBox(height: 8),
                      _DetailsCard(
                        status: _status,
                        priority: _priority,
                        assignee: _assignee,
                        dueDate: _dueDate,
                        dateFormat: _date,
                        onStatusChanged: (s) => setState(() => _status = s),
                        onPriorityChanged: (p) => setState(() => _priority = p),
                        onAssigneeTap: () async {
                          final picked = await _showEmployeeSheet(
                              context, employees, _assignee);
                          if (picked != null) setState(() => _assignee = picked);
                        },
                        onDueDateTap: () => _pickDueDate(),
                        onClearDue: () => setState(() => _dueDate = null),
                      ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04, end: 0),
                      const SizedBox(height: 20),
                      _SectionLabel('Description'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: TextFormField(
                          controller: _descCtrl,
                          maxLines: 5,
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: l10n.taskFormDescriptionHint,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.04, end: 0),
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
                label: _isEdit ? 'Update Task' : 'Create Task',
                onSave: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final repo = GetIt.I<TasksRepository>();
      final existing = widget.existing;
      if (existing == null) {
        final draft = ProjectTask(
          id: '',
          projectId: widget.projectId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: _status,
          priority: _priority,
          createdAt: DateTime.now(),
          assigneeId: _assignee?.id,
          assigneeName: _assignee?.name,
          dueDate: _dueDate,
        );
        await repo.create(draft);
        _toast('Task created');
      } else {
        // Direct constructor — copyWith can't clear nullable fields
        // (assignee / dueDate) cleanly.
        final updated = ProjectTask(
          id: existing.id,
          projectId: existing.projectId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: _status,
          priority: _priority,
          createdAt: existing.createdAt,
          assigneeId: _assignee?.id,
          assigneeName: _assignee?.name,
          dueDate: _dueDate,
          estimatedHours: existing.estimatedHours,
        );
        await repo.update(updated);
        _toast('Task updated');
      }
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      _toast('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
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

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.status,
    required this.priority,
    required this.assignee,
    required this.dueDate,
    required this.dateFormat,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onAssigneeTap,
    required this.onDueDateTap,
    required this.onClearDue,
  });
  final TaskStatus status;
  final TaskPriority priority;
  final Employee? assignee;
  final DateTime? dueDate;
  final DateFormat dateFormat;
  final ValueChanged<TaskStatus> onStatusChanged;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final VoidCallback onAssigneeTap;
  final VoidCallback onDueDateTap;
  final VoidCallback onClearDue;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          _Row(
            icon: Icons.radio_button_checked_rounded,
            label: l10n.taskFormStatusLabel,
            child: _StatusChips(current: status, onChanged: onStatusChanged),
          ),
          const _Spacer(),
          _Row(
            icon: Icons.flag_rounded,
            label: l10n.taskFormPriorityLabel,
            child: _PriorityChips(current: priority, onChanged: onPriorityChanged),
          ),
          const _Spacer(),
          InkWell(
            onTap: onAssigneeTap,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: _Row(
              icon: Icons.person_rounded,
              label: l10n.taskFormAssigneeLabel,
              child: Row(
                children: [
                  if (assignee != null) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary,
                      child: AppLabel(
                        text: _initials(assignee!.name),
                        fontSize: AppFontSize.value10,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppLabel(
                        text: assignee!.name,
                        fontSize: AppFontSize.value14,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else
                    AppLabel(
                      text: l10n.taskFormUnassignedLabel,
                      fontSize: AppFontSize.value14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const _Spacer(),
          _Row(
            icon: Icons.event_rounded,
            label: l10n.taskFormDueDateLabel,
            child: Row(
              children: [
                if (dueDate != null) ...[
                  TextButton.icon(
                    onPressed: onDueDateTap,
                    icon: const Icon(Icons.calendar_today_rounded, size: 14),
                    label: AppLabel(
                      text: dateFormat.format(dueDate!),
                      fontSize: AppFontSize.value13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClearDue,
                    tooltip: l10n.taskFormClearDueDateTooltip,
                  ),
                ] else
                  TextButton.icon(
                    onPressed: onDueDateTap,
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: AppLabel(
                      text: l10n.taskFormAddDueDateAction,
                      fontSize: AppFontSize.value13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: AppLabel(
              text: label,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Spacer extends StatelessWidget {
  const _Spacer();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 16,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.current, required this.onChanged});
  final TaskStatus current;
  final ValueChanged<TaskStatus> onChanged;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in TaskStatus.values)
          ChoiceChip(
            label: AppLabel(
              text: _statusLabel(s),
              fontSize: AppFontSize.value12,
            ),
            selected: current == s,
            onSelected: (_) => onChanged(s),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class _PriorityChips extends StatelessWidget {
  const _PriorityChips({required this.current, required this.onChanged});
  final TaskPriority current;
  final ValueChanged<TaskPriority> onChanged;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in TaskPriority.values)
          ChoiceChip(
            avatar: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _priorityColor(p),
                shape: BoxShape.circle,
              ),
            ),
            label: AppLabel(
              text: _priorityLabel(p),
              fontSize: AppFontSize.value12,
            ),
            selected: current == p,
            onSelected: (_) => onChanged(p),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
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

String _statusLabel(TaskStatus s) {
  switch (s) {
    case TaskStatus.todo:
      return 'To Do';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.inReview:
      return 'In Review';
    case TaskStatus.done:
      return 'Done';
  }
}

String _priorityLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return 'Low';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.high:
      return 'High';
    case TaskPriority.urgent:
      return 'Urgent';
  }
}

Color _priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return Colors.grey;
    case TaskPriority.medium:
      return Colors.blue;
    case TaskPriority.high:
      return Colors.orange;
    case TaskPriority.urgent:
      return Colors.red;
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
                    text: l10n.taskFormAssignToAction,
                    fontSize: AppFontSize.value22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (current != null)
                ListTile(
                  leading: const Icon(Icons.person_off_outlined),
                  title: AppLabel(
                    text: l10n.taskFormUnassignAction,
                    fontSize: AppFontSize.value14,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),
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
