import 'dart:ui';
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
import '../../data/repositories/leave_requests_repository.dart';
import '../../entities/leave_request.dart';
import 'leave_approval_detail_page.dart';
import 'leave_request_form_page.dart';

/// Slice 7.2.3 — manager view of pending leave requests with
/// approve / reject actions. Mine vs. Pending toggle keeps the same
/// page useful for employees too.
class LeaveRequestsListPage extends StatefulWidget {
  const LeaveRequestsListPage({super.key, this.currentUserId = 'emp-001'});
  final String currentUserId;

  @override
  State<LeaveRequestsListPage> createState() => _LeaveRequestsListPageState();
}

enum _Filter { all, pending, mine }

class _LeaveRequestsListPageState extends State<LeaveRequestsListPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrLeaveRequestsPageTitle,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<_Filter>(
              segments: [
                ButtonSegment(
                  value: _Filter.all,
                  label: AppLabel(text: l10n.hrLeaveRequestsTabAll, fontSize: AppFontSize.value13),
                  icon: const Icon(Icons.list_alt_rounded),
                ),
                ButtonSegment(
                  value: _Filter.pending,
                  label: AppLabel(
                    text: l10n.hrLeaveRequestsTabPending,
                    fontSize: AppFontSize.value13,
                  ),
                  icon: const Icon(Icons.hourglass_empty_rounded),
                ),
                ButtonSegment(
                  value: _Filter.mine,
                  label: AppLabel(text: l10n.hrLeaveRequestsTabMine, fontSize: AppFontSize.value13),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ],
              selected: {_filter},
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: theme.colorScheme.primaryContainer,
                selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              onSelectionChanged: (s) =>
                  setState(() => _filter = s.first),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.hrLeaveRequestsNewRequestTooltip,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
            onPressed: () =>
                ConfigRouter.pushPageAnimation(context, const LeaveRequestFormPage()),
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<List<LeaveRequest>>(
              stream: GetIt.I<LeaveRequestsRepository>().watchAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? const <LeaveRequest>[];
                final visible = all.where(_match).toList();

                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppLabel(
                          text: l10n.hrLeaveRequestsEmptyTitle,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 4),
                        AppLabel(
                          text: l10n.hrLeaveRequestsEmptySubtitle,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ).animate().fadeIn(),
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
                  itemBuilder: (context, idx) {
                    final request = visible[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestCard(
                        request: request,
                        approverId: widget.currentUserId,
                      ).animate()
                        .fadeIn(delay: (idx * 30).ms)
                        .slideY(begin: 0.05, end: 0, duration: 300.ms),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _match(LeaveRequest r) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.pending:
        return r.status == LeaveRequestStatus.pending;
      case _Filter.mine:
        return r.employeeId == widget.currentUserId;
    }
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.approverId});
  final LeaveRequest request;
  final String approverId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canAct = request.status == LeaveRequestStatus.pending;
    final statusColor = _statusColor(theme, request.status);

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Slice 7.2.4 — tapping a card opens the full-context approval
        // detail page. The inline Approve/Reject buttons below still
        // work for quick decisions (they're hit-tested above this
        // InkWell, so their taps don't propagate).
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          LeaveApprovalDetailPage(
            request: request,
            approverId: approverId,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: request.employeeName,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 2),
                        AppLabel(
                          text: request.type.name.toUpperCase(),
                          fontSize: AppFontSize.value11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: request.status, color: statusColor),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppLabel(
                    text:
                        '${request.fromDate.toIso8601String().split('T').first}   ➔   ${request.toDate.toIso8601String().split('T').first}',
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: AppLabel(
                    text: '${request.days} day(s)',
                    fontSize: AppFontSize.value11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: AppLabel(
                  text: request.reason,
                  fontSize: AppFontSize.value14,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (canAct) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: AppLabel(
                      text: l10n.commonRejectAction,
                      fontSize: AppFontSize.value13,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () => _reject(context),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: AppLabel(
                      text: l10n.commonApproveAction,
                      fontSize: AppFontSize.value13,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () => _approve(context),
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
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = GetIt.I<LeaveRequestsRepository>();
    try {
      final updated = repo.approve(
        request: request,
        approverId: approverId,
        now: DateTime.now(),
      );
      await repo.update(updated);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.hrLeaveRequestsApprovedSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(f.message ?? 'Cannot approve.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            // Wrapped in Expanded so the title can shrink/ellipsise on
            // narrow dialog widths instead of overflowing the Row.
            Expanded(
              child: AppLabel(
                text: l10n.hrLeaveRequestsRejectDialogTitle,
                fontSize: AppFontSize.value18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: reasonCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.hrLeaveApprovalRejectReasonTitle,
            alignLabelWithHint: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: AppLabel(
              text: l10n.commonCancelAction,
              fontSize: AppFontSize.value14,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                // Show inline validation error instead of closing the dialog
                reasonCtrl.clear();
              } else {
                Navigator.pop(dialogCtx, reason);
              }
            },
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
      final repo = GetIt.I<LeaveRequestsRepository>();
      final updated = repo.reject(
        request: request,
        approverId: approverId,
        now: DateTime.now(),
        reason: reason,
      );
      await repo.update(updated);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.hrLeaveRequestsRejectedSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationFailure {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.hrLeaveRequestsRejectionReasonRequiredSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(f.message ?? 'Cannot reject.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor(ThemeData theme, LeaveRequestStatus s) {
    switch (s) {
      case LeaveRequestStatus.pending:
        return Colors.orange;
      case LeaveRequestStatus.approved:
        return Colors.green;
      case LeaveRequestStatus.rejected:
        return Colors.red;
      case LeaveRequestStatus.cancelled:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final LeaveRequestStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppLabel(
        text: status.name.toUpperCase(),
        fontSize: AppFontSize.value11,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}
