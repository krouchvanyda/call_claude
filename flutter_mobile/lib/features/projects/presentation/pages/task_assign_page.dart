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

/// Slice 8.1.6 — Assign / Reassign Task.
///
/// Workload-aware member picker — every employee row shows how many
/// open tasks they already hold (≤3 calm, 4–6 warn, 7+ red). Optional
/// due-date update and an optional "note to assignee" field. The note
/// is form-only today (no entity field yet); the push-notification
/// dispatch is also a stub until the notifications module wires it.
class TaskAssignPage extends StatefulWidget {
  const TaskAssignPage({super.key, required this.task});

  final ProjectTask task;

  @override
  State<TaskAssignPage> createState() => _TaskAssignPageState();
}

class _TaskAssignPageState extends State<TaskAssignPage> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Employee? _selected;
  DateTime? _dueDate;
  bool _saving = false;
  late Future<_AssignContext> _ctxFuture;
  String _query = '';

  static final _date = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _dueDate = widget.task.dueDate;
    _ctxFuture = _loadContext();
  }

  Future<_AssignContext> _loadContext() async {
    final employees = await GetIt.I<EmployeesRepository>().getAll();
    final allTasks = await GetIt.I<TasksRepository>().getAll();
    final openCounts = <String, int>{};
    for (final t in allTasks) {
      if (t.status == TaskStatus.done) continue;
      final id = t.assigneeId;
      if (id == null) continue;
      openCounts[id] = (openCounts[id] ?? 0) + 1;
    }
    Employee? current;
    if (widget.task.assigneeId != null) {
      for (final e in employees) {
        if (e.id == widget.task.assigneeId) {
          current = e;
          break;
        }
      }
    }
    _selected ??= current;
    return _AssignContext(
      employees: employees,
      openCounts: openCounts,
      currentAssignee: current,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.taskAssignPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<_AssignContext>(
              future: _ctxFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ctx = snap.data;
                if (ctx == null) {
                  return Center(
                    child: AppLabel(
                      text: l10n.taskAssignErrorLoading,
                      fontSize: AppFontSize.value14,
                    ),
                  );
                }
                final filtered = _filterEmployees(ctx.employees, _query);
                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 140,
                  ),
                  children: [
                    _TaskContextCard(
                      task: widget.task,
                      currentAssignee: ctx.currentAssignee,
                    ).animate().fadeIn().slideY(begin: 0.04, end: 0),
                    const SizedBox(height: 20),
                    _SectionLabel('Select Assignee'),
                    const SizedBox(height: 8),
                    _SearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      _Empty()
                    else
                      for (var i = 0; i < filtered.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MemberTile(
                            employee: filtered[i],
                            openCount: ctx.openCounts[filtered[i].id] ?? 0,
                            selected: _selected?.id == filtered[i].id,
                            onTap: () => setState(() => _selected = filtered[i]),
                          ).animate().fadeIn(delay: (i * 20).ms),
                        ),
                    const SizedBox(height: 20),
                    _SectionLabel('Due Date (optional)'),
                    const SizedBox(height: 8),
                    _DueDateCard(
                      dueDate: _dueDate,
                      dateFormat: _date,
                      onPick: _pickDueDate,
                      onClear: () => setState(() => _dueDate = null),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Note to Assignee (optional)'),
                    const SizedBox(height: 8),
                    _NoteCard(controller: _noteCtrl),
                  ],
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _AssignBar(
                saving: _saving,
                enabled: _selected != null,
                onAssign: _assign,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Employee> _filterEmployees(List<Employee> all, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((e) {
      return e.name.toLowerCase().contains(query) ||
          e.position.toLowerCase().contains(query) ||
          e.department.toLowerCase().contains(query);
    }).toList();
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

  Future<void> _assign() async {
    if (_selected == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final repo = GetIt.I<TasksRepository>();
      // Direct constructor — copyWith can't clear nullable fields cleanly.
      final t = widget.task;
      final updated = ProjectTask(
        id: t.id,
        projectId: t.projectId,
        title: t.title,
        description: t.description,
        status: t.status,
        priority: t.priority,
        createdAt: t.createdAt,
        assigneeId: _selected!.id,
        assigneeName: _selected!.name,
        dueDate: _dueDate,
        estimatedHours: t.estimatedHours,
      );
      await repo.update(updated);
      // TODO(notifications): push-notify the new assignee once the
      // notifications module exposes a fire-from-feature API. The note
      // text in _noteCtrl will travel with that notification.
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.taskAssignSuccessSnack(_selected!.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (navigator.canPop()) navigator.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.taskAssignFailureSnack(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AssignContext {
  const _AssignContext({
    required this.employees,
    required this.openCounts,
    required this.currentAssignee,
  });
  final List<Employee> employees;
  final Map<String, int> openCounts;
  final Employee? currentAssignee;
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

class _TaskContextCard extends StatelessWidget {
  const _TaskContextCard({required this.task, required this.currentAssignee});
  final ProjectTask task;
  final Employee? currentAssignee;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final overdue = task.isOverdue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLabel(
            text: task.title,
            fontSize: AppFontSize.value16,
            fontWeight: FontWeight.w700,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (task.dueDate != null)
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: overdue ? theme.colorScheme.error : theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                AppLabel(
                  text:
                      '${overdue ? 'Overdue: ' : 'Due '}${DateFormat('MMM d, yyyy').format(task.dueDate!)}',
                  fontSize: AppFontSize.value12,
                  color: overdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              AppLabel(
                text: l10n.taskAssignCurrentlyLabel,
                fontSize: AppFontSize.value12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              AppLabel(
                text: currentAssignee?.name ?? 'Unassigned',
                fontSize: AppFontSize.value12,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: l10n.taskAssignSearchHint,
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.employee,
    required this.openCount,
    required this.selected,
    required this.onTap,
  });
  final Employee employee;
  final int openCount;
  final bool selected;
  final VoidCallback onTap;

  Color _badgeBg(BuildContext context) {
    final theme = Theme.of(context);
    if (openCount <= 3) return Colors.blue.withValues(alpha: 0.12);
    if (openCount <= 6) return Colors.orange.withValues(alpha: 0.18);
    return theme.colorScheme.error.withValues(alpha: 0.15);
  }

  Color _badgeFg(BuildContext context) {
    final theme = Theme.of(context);
    if (openCount <= 3) return Colors.blue.shade700;
    if (openCount <= 6) return Colors.orange.shade800;
    return theme.colorScheme.error;
  }

  Color _dotColor() {
    if (openCount <= 3) return Colors.green;
    if (openCount <= 6) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: AppLabel(
                    text: _initials(employee.name),
                    fontSize: AppFontSize.value14,
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _dotColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: employee.name,
                    fontSize: AppFontSize.value16,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 2),
                  AppLabel(
                    text: '${employee.position} • ${employee.department}',
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _badgeBg(context),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: AppLabel(
                text: '$openCount open',
                fontSize: AppFontSize.value11,
                color: _badgeFg(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _DueDateCard extends StatelessWidget {
  const _DueDateCard({
    required this.dueDate,
    required this.dateFormat,
    required this.onPick,
    required this.onClear,
  });
  final DateTime? dueDate;
  final DateFormat dateFormat;
  final VoidCallback onPick;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: AppLabel(
              text: dueDate == null ? 'No due date' : dateFormat.format(dueDate!),
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
              color: dueDate == null ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
          if (dueDate != null)
            IconButton(
              tooltip: AppLocalizations.of(context).taskAssignClearTooltip,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onClear,
            ),
          TextButton(
            onPressed: onPick,
            child: AppLabel(
              text: dueDate == null ? 'Pick date' : 'Change',
              fontSize: AppFontSize.value13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 2,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).taskAssignNoteHint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }
}

class _AssignBar extends StatelessWidget {
  const _AssignBar({
    required this.saving,
    required this.enabled,
    required this.onAssign,
  });
  final bool saving;
  final bool enabled;
  final VoidCallback onAssign;
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
          onPressed: (enabled && !saving) ? onAssign : null,
          icon: saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.assignment_ind_rounded),
          label: AppLabel(
            text: saving ? 'Assigning…' : 'Assign Task',
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

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          AppLabel(
            text: AppLocalizations.of(context).taskAssignEmpty,
            fontSize: AppFontSize.value14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}
