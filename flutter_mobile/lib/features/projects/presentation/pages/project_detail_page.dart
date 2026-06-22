import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/projects_repository.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../entities/project.dart';
import '../../entities/task.dart';
import 'project_board_page.dart';
import 'project_form_page.dart';
import 'task_detail_page.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.projectDetailPageTitle,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.projectDetailOpenBoardTooltip,
            icon: const Icon(Icons.view_kanban_outlined),
            onPressed: () => ConfigRouter.pushPageAnimation(
              context,
              ProjectBoardPage(projectId: projectId),
            ),
          ),
          IconButton(
            tooltip: l10n.projectDetailEditProjectTooltip,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              // Fetch fresh so the form opens with the latest state if
              // the user just came back from another edit screen.
              final p = await GetIt.I<ProjectsRepository>().findById(projectId);
              if (p == null || !context.mounted) return;
              await ConfigRouter.pushPageAnimation(
                context,
                ProjectFormPage(existing: p),
              );
            },
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<Project?>(
              future: GetIt.I<ProjectsRepository>().findById(projectId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final project = snap.data;
                if (project == null) {
                  return Center(
                    child: AppLabel(
                      text: l10n.projectDetailNotFound(projectId),
                      fontSize: AppFontSize.value14,
                    ),
                  );
                }
                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  children: [
                    // Premium Project Header Card
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  color: _projectColor(project.color).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: _projectColor(project.color).withValues(alpha: 0.3),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: AppLabel(
                                  text: project.code.split('-').first.substring(
                                      0, project.code.split('-').first.length.clamp(0, 3)),
                                  fontSize: AppFontSize.value13,
                                  color: _projectColor(project.color),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppLabel(
                                      text: project.name,
                                      fontSize: AppFontSize.value16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    const SizedBox(height: 2),
                                    AppLabel(
                                      text: l10n.projectDetailProjectIdLabel(project.code),
                                      fontSize: AppFontSize.value12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(project.status).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                  border: Border.all(color: _statusColor(project.status).withValues(alpha: 0.15)),
                                ),
                                child: AppLabel(
                                  text: project.status.name.toUpperCase(),
                                  fontSize: AppFontSize.value10,
                                  color: _statusColor(project.status),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32, thickness: 0.5),
                          _row(theme, 'Owner', project.ownerName, Icons.person_outline_rounded),
                          _row(theme, 'Start Date', project.startDate.toIso8601String().split('T').first, Icons.calendar_today_rounded),
                          _row(theme, 'End Date', project.endDate.toIso8601String().split('T').first, Icons.event_busy_rounded),
                          _row(theme, 'Duration', '${project.totalDays} Days', Icons.timelapse_rounded),
                          _row(theme, 'Budget', project.budget, Icons.monetization_on_outlined),
                          const SizedBox(height: 16),
                          AppLabel(
                            text: l10n.projectDetailDescriptionHeading,
                            fontSize: AppFontSize.value11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          const SizedBox(height: 6),
                          AppLabel(
                            text: project.description,
                            fontSize: AppFontSize.value14,
                            color: theme.colorScheme.onSurfaceVariant,
                            lineHeight: 1.4,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 300.ms),
                    const SizedBox(height: 24),
                    AppLabel(
                      text: l10n.projectDetailTasksHeading,
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<ProjectTask>>(
                      stream: GetIt.I<TasksRepository>()
                          .watchForProject(projectId),
                      builder: (context, taskSnap) {
                        final tasks = taskSnap.data ?? const <ProjectTask>[];
                        if (tasks.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: AppLabel(
                                text: l10n.projectDetailNoTasks,
                                fontSize: AppFontSize.value14,
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        final groups = groupTasksByStatus(tasks);
                        return Column(
                          children: [
                            for (final status in TaskStatus.values)
                              _StatusGroup(
                                status: status,
                                tasks: groups[status] ?? const [],
                                projectId: projectId,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: AppLabel(
                text: label,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: AppLabel(
                text: value,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );

  Color _projectColor(String? hex) {
    if (hex == null || hex.length != 6) return Colors.indigo;
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Colors.blue;
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.onHold:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.teal;
      case ProjectStatus.archived:
        return Colors.grey;
    }
  }
}

class _StatusGroup extends StatelessWidget {
  const _StatusGroup({
    required this.status,
    required this.tasks,
    required this.projectId,
  });
  final TaskStatus status;
  final List<ProjectTask> tasks;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                AppLabel(
                  text: _statusText(status),
                  fontSize: AppFontSize.value12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AppLabel(
                    text: '${tasks.length}',
                    fontSize: AppFontSize.value10,
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          for (final task in tasks)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: AppLabel(
                      text: task.title,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.bold,
                    ),
                    subtitle: AppLabel(
                      text: task.assigneeName ?? 'Unassigned',
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    onTap: () => ConfigRouter.pushPageAnimation(
                      context,
                      TaskDetailPage(taskId: task.id),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 250.ms),
        ],
      ),
    );
  }

  String _statusText(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return 'TO DO';
      case TaskStatus.inProgress:
        return 'IN PROGRESS';
      case TaskStatus.inReview:
        return 'IN REVIEW';
      case TaskStatus.done:
        return 'DONE';
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.amber;
      case TaskStatus.inReview:
        return Colors.purple;
      case TaskStatus.done:
        return Colors.green;
    }
  }
}
