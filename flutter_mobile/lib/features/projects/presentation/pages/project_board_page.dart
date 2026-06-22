import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../entities/task.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';

/// Slice 8.1.2 — Kanban board with drag-and-drop between columns.
class ProjectBoardPage extends StatefulWidget {
  const ProjectBoardPage({super.key, required this.projectId});
  final String projectId;

  @override
  State<ProjectBoardPage> createState() => _ProjectBoardPageState();
}

class _ProjectBoardPageState extends State<ProjectBoardPage> {
  String? _flashMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.projectBoardPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<List<ProjectTask>>(
              stream:
                  GetIt.I<TasksRepository>().watchForProject(widget.projectId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snap.data ?? const <ProjectTask>[];
                final groups = groupTasksByStatus(tasks);
                return Column(
                  children: [
                    SizedBox(height: context.dynamicAppBarPadding - 8),
                    if (_flashMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppLabel(
                                text: _flashMessage!,
                                fontSize: AppFontSize.value14,
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final status in TaskStatus.values)
                              _Column(
                                status: status,
                                tasks: groups[status] ?? const [],
                                onAccept: (task) => _move(task, status),
                                onTapTask: _openTask,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConfigRouter.pushPageAnimation(
          context,
          TaskFormPage(projectId: widget.projectId),
        ),
        icon: const Icon(Icons.add_task_rounded),
        label: AppLabel(
          text: l10n.projectBoardNewTaskAction,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w600,
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Future<void> _move(ProjectTask task, TaskStatus to) async {
    try {
      final repo = GetIt.I<TasksRepository>();
      final updated = repo.move(task: task, toStatus: to);
      await repo.update(updated);
      if (mounted) setState(() => _flashMessage = null);
    } on ConflictFailure catch (f) {
      setState(() => _flashMessage = f.message ?? 'Illegal transition');
    }
  }

  void _openTask(ProjectTask task) {
    ConfigRouter.pushPageAnimation(
      context,
      TaskDetailPage(taskId: task.id),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.status,
    required this.tasks,
    required this.onAccept,
    required this.onTapTask,
  });

  final TaskStatus status;
  final List<ProjectTask> tasks;
  final void Function(ProjectTask task) onAccept;
  final void Function(ProjectTask task) onTapTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final headerColor = _columnColor(status);

    return DragTarget<ProjectTask>(
      onWillAcceptWithDetails: (d) => d.data.status != status,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return Container(
          width: 290,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: highlight
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                : theme.colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: highlight ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppLabel(
                      text: _columnTitle(status).toUpperCase(),
                      fontSize: AppFontSize.value12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppLabel(
                      text: '${tasks.length}',
                      fontSize: AppFontSize.value10,
                      color: headerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: AppLabel(
                            text: l10n.projectBoardDropZoneHint,
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      for (final task in tasks)
                        _TaskCard(task: task, onTap: () => onTapTask(task))
                            .animate()
                            .fadeIn(duration: 150.ms)
                            .slideY(begin: 0.05, end: 0, duration: 150.ms),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _columnTitle(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return 'To do';
      case TaskStatus.inProgress:
        return 'In progress';
      case TaskStatus.inReview:
        return 'In review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color _columnColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.amber.shade700;
      case TaskStatus.inReview:
        return Colors.purple;
      case TaskStatus.done:
        return Colors.green;
    }
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});
  final ProjectTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityCol = _priorityColor(task.priority);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: task.title,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityCol.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: priorityCol.withValues(alpha: 0.2)),
                        ),
                        child: AppLabel(
                          text: task.priority.name.toUpperCase(),
                          fontSize: AppFontSize.value9,
                          color: priorityCol,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (task.assigneeName != null)
                        AppLabel(
                          text: task.assigneeName!,
                          fontSize: AppFontSize.value12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      if (task.dueDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 10,
                              color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 3),
                            AppLabel(
                              text: task.isOverdue
                                  ? 'OVERDUE: ${_fmt(task.dueDate!)}'
                                  : 'Due: ${_fmt(task.dueDate!)}',
                              fontSize: AppFontSize.value10,
                              fontWeight: FontWeight.bold,
                              color: task.isOverdue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.outline,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return LongPressDraggable<ProjectTask>(
      data: task,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: SizedBox(width: 266, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange.shade700;
      case TaskPriority.urgent:
        return Colors.red.shade700;
    }
  }

  String _fmt(DateTime d) => d.toIso8601String().split('T').first;
}
