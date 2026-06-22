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
import '../../data/repositories/tasks_repository.dart';
import '../../entities/task.dart';
import 'task_assign_page.dart';
import 'task_form_page.dart';

/// Slice 8.1.3 — task detail + comment thread.
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.taskId,
    this.currentUserId = 'emp-001',
  });

  final String taskId;
  final String currentUserId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _commentCtrl = TextEditingController();
  bool _isPosting = false;
  // Cache the task future so setState() (e.g. toggling _isPosting on
  // each comment post) doesn't recreate it and flip the FutureBuilder
  // back to ConnectionState.waiting — which would unmount the comment
  // list + input mid-post and make new comments appear to fail.
  late Future<ProjectTask?> _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = GetIt.I<TasksRepository>().findById(widget.taskId);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _isPosting = true);
    try {
      await GetIt.I<TaskCommentsRepository>().create(
        TaskComment(
          id: '',
          taskId: widget.taskId,
          authorId: widget.currentUserId,
          authorName: 'Demo Approver',
          body: body,
          postedAt: DateTime.now(),
        ),
      );
      _commentCtrl.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.taskDetailPageTitle,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.taskDetailMoreTooltip,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              // Fetch fresh so the form / assign sheet always opens
              // with the latest state.
              final t = await GetIt.I<TasksRepository>().findById(widget.taskId);
              if (t == null || !context.mounted) return;
              switch (value) {
                case 'edit':
                  await ConfigRouter.pushPageAnimation(
                    context,
                    TaskFormPage(projectId: t.projectId, existing: t),
                  );
                case 'assign':
                  await ConfigRouter.pushPageAnimation(
                    context,
                    TaskAssignPage(task: t),
                  );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: AppLabel(
                    text: l10n.taskDetailEditTaskAction,
                    fontSize: AppFontSize.value14,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'assign',
                child: ListTile(
                  leading: const Icon(Icons.assignment_ind_outlined),
                  title: AppLabel(
                    text: l10n.taskDetailReassignAction,
                    fontSize: AppFontSize.value14,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<ProjectTask?>(
              future: _taskFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final task = snap.data;
                if (task == null) {
                  return Center(
                    child: AppLabel(
                      text: l10n.taskDetailNotFound(widget.taskId),
                      fontSize: AppFontSize.value14,
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          top: context.dynamicAppBarPadding,
                          left: 16,
                          right: 16,
                          bottom: 24,
                        ),
                        children: [
                          // Task Primary Details Card
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
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppLabel(
                                  text: task.title,
                                  fontSize: AppFontSize.value18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(task.status).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(AppRadii.pill),
                                        border: Border.all(color: _statusColor(task.status).withValues(alpha: 0.15)),
                                      ),
                                      child: AppLabel(
                                        text: task.status.name.toUpperCase(),
                                        fontSize: AppFontSize.value9,
                                        color: _statusColor(task.status),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _priorityColor(task.priority).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(AppRadii.pill),
                                        border: Border.all(color: _priorityColor(task.priority).withValues(alpha: 0.15)),
                                      ),
                                      child: AppLabel(
                                        text: task.priority.name.toUpperCase(),
                                        fontSize: AppFontSize.value9,
                                        color: _priorityColor(task.priority),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (task.assigneeName != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(AppRadii.md),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 8,
                                              backgroundColor: theme.colorScheme.primary,
                                              child: AppLabel(
                                                text: task.assigneeName![0].toUpperCase(),
                                                fontSize: AppFontSize.value8,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            AppLabel(
                                              text: task.assigneeName!,
                                              fontSize: AppFontSize.value12,
                                              fontWeight: FontWeight.w700,
                                              color: theme.colorScheme.onSecondaryContainer,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (task.dueDate != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: task.isOverdue
                                              ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
                                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(AppRadii.md),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 11,
                                              color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            AppLabel(
                                              text: task.dueDate!.toIso8601String().split('T').first,
                                              fontSize: AppFontSize.value12,
                                              fontWeight: FontWeight.bold,
                                              color: task.isOverdue
                                                  ? theme.colorScheme.error
                                                  : theme.colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (task.estimatedHours != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(AppRadii.md),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 11,
                                              color: theme.colorScheme.onTertiaryContainer,
                                            ),
                                            const SizedBox(width: 6),
                                            AppLabel(
                                              text: '${task.estimatedHours}h',
                                              fontSize: AppFontSize.value12,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onTertiaryContainer,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const Divider(height: 32, thickness: 0.5),
                                  AppLabel(
                                    text: l10n.taskDetailDescriptionHeading,
                                    fontSize: AppFontSize.value11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                  const SizedBox(height: 6),
                                  AppLabel(
                                    text: task.description,
                                    fontSize: AppFontSize.value14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    lineHeight: 1.4,
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 300.ms),
                          const SizedBox(height: 24),
                          AppLabel(
                            text: l10n.taskDetailCommentsHeading,
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<List<TaskComment>>(
                            stream: GetIt.I<TaskCommentsRepository>()
                                .watchForTask(widget.taskId),
                            builder: (context, cSnap) {
                              final comments =
                                  cSnap.data ?? const <TaskComment>[];
                              if (comments.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: AppLabel(
                                      text: l10n.taskDetailNoComments,
                                      fontSize: AppFontSize.value14,
                                      color: theme.colorScheme.outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (var i = 0; i < comments.length; i++)
                                    _CommentTile(comment: comments[i])
                                        .animate()
                                        .fadeIn(delay: (i * 50).ms)
                                        .slideY(begin: 0.05, end: 0, duration: 250.ms),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Bottom comment textbox
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: l10n.taskDetailAddCommentHint,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.lg),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.lg),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.lg),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 38,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.lg),
                                  ),
                                ),
                                onPressed: _isPosting ? null : _post,
                                child: _isPosting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                              ),
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

  Color _statusColor(TaskStatus s) {
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final TaskComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: AppLabel(
                  text: comment.authorName.isEmpty ? '?' : comment.authorName[0].toUpperCase(),
                  fontSize: AppFontSize.value10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              AppLabel(
                text: comment.authorName,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              AppLabel(
                text: comment.postedAt
                    .toIso8601String()
                    .split('.')
                    .first
                    .replaceFirst('T', ' '),
                fontSize: AppFontSize.value10,
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppLabel(
            text: comment.body,
            fontSize: AppFontSize.value14,
            color: theme.colorScheme.onSurface,
            lineHeight: 1.3,
          ),
        ],
      ),
    );
  }
}
