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
import '../../data/repositories/timesheets_repository.dart';
import '../../entities/timesheet_entry.dart';
import 'timesheet_form_page.dart';
import 'utilization_page.dart';

/// Slice 8.2.1 + 8.2.2 — combined timesheets surface.
class TimesheetsListPage extends StatefulWidget {
  const TimesheetsListPage({super.key, this.currentUserId = 'emp-001'});
  final String currentUserId;

  @override
  State<TimesheetsListPage> createState() => _TimesheetsListPageState();
}

enum _TsFilter { mine, approvals, all }

class _TimesheetsListPageState extends State<TimesheetsListPage> {
  _TsFilter _filter = _TsFilter.mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.timesheetsPageTitle,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.timesheetsUtilizationTooltip,
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () =>
                ConfigRouter.pushPageAnimation(context, const UtilizationPage()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<_TsFilter>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(
                  value: _TsFilter.mine,
                  label: AppLabel(text: l10n.timesheetsTabMine, fontSize: AppFontSize.value13),
                ),
                ButtonSegment(
                  value: _TsFilter.approvals,
                  label: AppLabel(
                    text: l10n.timesheetsTabApprovals,
                    fontSize: AppFontSize.value13,
                  ),
                ),
                ButtonSegment(
                  value: _TsFilter.all,
                  label: AppLabel(text: l10n.timesheetsTabAll, fontSize: AppFontSize.value13),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (s) =>
                  setState(() => _filter = s.first),
            ),
          ),
        ),
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<List<TimesheetEntry>>(
              stream: GetIt.I<TimesheetsRepository>().watchAll(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? const <TimesheetEntry>[];
                final visible = all.where(_match).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 48,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        AppLabel(
                          text: l10n.timesheetsEmpty,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, idx) => _EntryCard(
                    entry: visible[idx],
                    filter: _filter,
                    currentUserId: widget.currentUserId,
                  ).animate().fadeIn(delay: (idx * 50).ms).slideY(begin: 0.05, end: 0, duration: 250.ms),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConfigRouter.pushPageAnimation(context, const TimesheetFormPage()),
        icon: const Icon(Icons.add_rounded),
        label: AppLabel(
          text: l10n.timesheetsLogTimeAction,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _match(TimesheetEntry e) {
    switch (_filter) {
      case _TsFilter.mine:
        return e.employeeId == widget.currentUserId;
      case _TsFilter.approvals:
        return e.status == TimesheetStatus.submitted;
      case _TsFilter.all:
        return true;
    }
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.filter,
    required this.currentUserId,
  });

  final TimesheetEntry entry;
  final _TsFilter filter;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(entry.status);

    final canApprove = filter != _TsFilter.mine &&
        entry.status == TimesheetStatus.submitted;
    final canSubmit = filter == _TsFilter.mine &&
        entry.status == TimesheetStatus.draft &&
        entry.employeeId == currentUserId;
    final canReopen = filter == _TsFilter.mine &&
        entry.status == TimesheetStatus.rejected &&
        entry.employeeId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: AppLabel(
                      text: entry.employeeName.isEmpty
                          ? '?'
                          : entry.employeeName[0].toUpperCase(),
                      fontSize: AppFontSize.value10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppLabel(
                      text: entry.employeeName,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: statusColor.withValues(alpha: 0.15)),
                    ),
                    child: AppLabel(
                      text: entry.status.name.toUpperCase(),
                      fontSize: AppFontSize.value9,
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppLabel(
                      text: entry.projectName,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppLabel(
                      text: '${entry.hours} Hours',
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  AppLabel(
                    text: entry.date.toIso8601String().split('T').first,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              if (entry.taskTitle != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 12, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      AppLabel(
                        text: l10n.timesheetsTaskLabel(entry.taskTitle!),
                        fontSize: AppFontSize.value12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              AppLabel(
                text: entry.description,
                fontSize: AppFontSize.value14,
                color: theme.colorScheme.onSurfaceVariant,
                lineHeight: 1.3,
              ),
              if (entry.decisionNote != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: AppLabel(
                    text: l10n.timesheetsRejectionNoteLabel(entry.decisionNote!),
                    fontSize: AppFontSize.value12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (canApprove) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                      onPressed: () => _reject(context),
                      child: AppLabel(
                        text: l10n.commonRejectAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                      onPressed: () => _approve(context),
                      child: AppLabel(
                        text: l10n.commonApproveAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else if (canSubmit) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      onPressed: () => _submit(context),
                      label: AppLabel(
                        text: l10n.timesheetsSubmitForApprovalAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else if (canReopen) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 14),
                      onPressed: () => _reopen(context),
                      label: AppLabel(
                        text: l10n.timesheetsReopenAsDraftAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final repo = GetIt.I<TimesheetsRepository>();
      final updated = repo.approve(
        entry: entry,
        approverId: currentUserId,
        now: DateTime.now(),
      );
      await repo.update(updated);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.timesheetsApprovedSnack)),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(content: Text(f.message ?? 'Cannot approve.')),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: AppLabel(
          text: l10n.timesheetsRejectDialogTitle,
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.bold,
        ),
        content: TextField(
          controller: reasonCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (required)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: AppLabel(
              text: l10n.commonCancelAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, reasonCtrl.text),
            child: AppLabel(
              text: l10n.commonRejectAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      final repo = GetIt.I<TimesheetsRepository>();
      final updated = repo.reject(
        entry: entry,
        approverId: currentUserId,
        now: DateTime.now(),
        reason: reason,
      );
      await repo.update(updated);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.timesheetsRejectedSnack)),
      );
    } on ValidationFailure {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.timesheetsReasonRequiredSnack)),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(content: Text(f.message ?? 'Cannot reject.')),
      );
    }
  }

  Future<void> _submit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final repo = GetIt.I<TimesheetsRepository>();
      final updated = repo.submit(entry);
      await repo.update(updated);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.timesheetsSubmittedSnack)),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(content: Text(f.message ?? 'Cannot submit.')),
      );
    }
  }

  Future<void> _reopen(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final repo = GetIt.I<TimesheetsRepository>();
      final updated = repo.reopenRejected(entry);
      await repo.update(updated);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.timesheetsReopenedSnack)),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(content: Text(f.message ?? 'Cannot reopen.')),
      );
    }
  }

  Color _statusColor(TimesheetStatus s) {
    switch (s) {
      case TimesheetStatus.draft:
        return Colors.grey;
      case TimesheetStatus.submitted:
        return Colors.orange;
      case TimesheetStatus.approved:
        return Colors.green;
      case TimesheetStatus.rejected:
        return Colors.red;
    }
  }
}
