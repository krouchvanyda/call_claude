import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/security_repositories.dart';
import '../../entities/audit_log_entry.dart';

/// Slice 9.3.2 — read-only audit log with filter chips + search.
class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  final Set<AuditAction> _actionFilter = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<AuditLogRepository>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.auditLogPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas
            AppBackgroundGradient(),
            StreamBuilder<List<AuditLogEntry>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final visible = queryAuditLog(
                  all,
                  actionFilter: _actionFilter,
                  searchQuery: _searchQuery,
                );
                return Column(
                  children: [
                    // Top spacing for Custom AppBar
                    SizedBox(height: context.dynamicAppBarPadding),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (q) => setState(() => _searchQuery = q),
                          decoration: InputDecoration(
                            hintText: l10n.auditLogSearchHint,
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: -0.05, end: 0, duration: 300.ms),
                    const SizedBox(height: 12),
                    // Horizontal Filter Chips
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: AuditAction.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final action = AuditAction.values[idx];
                          final isSelected = _actionFilter.contains(action);
                          return FilterChip(
                            label: AppLabel(
                              text: action.name,
                              fontSize: AppFontSize.value13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _actionFilter.add(action);
                              } else {
                                _actionFilter.remove(action);
                              }
                            }),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 8),
                    // List view
                    if (visible.isEmpty)
                      Expanded(
                        child: Center(
                          child: AppLabel(
                            text: l10n.auditLogEmpty,
                            fontSize: AppFontSize.value14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, idx) => _LogEntryTile(entry: visible[idx])
                              .animate()
                              .fadeIn(delay: (idx * 50).clamp(0, 400).ms)
                              .slideY(begin: 0.05, end: 0, duration: 300.ms),
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
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});
  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showDetailsSheet(context),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _actionColor(entry.action).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _actionIcon(entry.action),
                color: _actionColor(entry.action),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: entry.actorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' ${_actionVerb(entry.action)} ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: entry.targetLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: AppLabel(
                          text: entry.targetType.toUpperCase(),
                          fontSize: AppFontSize.value9,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppLabel(
                        text: _fmt(entry.occurredAt),
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (entry.detail != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: AppLabel(
                        text: entry.detail!,
                        fontSize: AppFontSize.value12,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppLabel(
              text: l10n.auditLogDetailDialogTitle,
              fontSize: AppFontSize.value16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 16),
            _metaRow(context, l10n.auditLogActorIdLabel, entry.actorId),
            _metaRow(context, l10n.auditLogActorNameLabel, entry.actorName),
            _metaRow(context, l10n.auditLogActionVerbLabel, _actionVerb(entry.action).toUpperCase()),
            _metaRow(context, l10n.auditLogTargetTypeLabel, entry.targetType),
            _metaRow(context, l10n.auditLogTargetIdLabel, entry.targetId),
            _metaRow(context, l10n.auditLogTargetLabelLabel, entry.targetLabel),
            _metaRow(context, l10n.auditLogTimestampLabel, entry.occurredAt.toIso8601String()),
            if (entry.detail != null) ...[
              const SizedBox(height: 8),
              AppLabel(
                text: l10n.auditLogAdditionalMetadataLabel,
                fontSize: AppFontSize.value12,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: AppLabel(
                  text: entry.detail!,
                  fontSize: AppFontSize.value14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: AppLabel(
                  text: l10n.auditLogCloseAction,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: AppLabel(
              text: label,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: AppLabel(
              text: value,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(AuditAction a) {
    switch (a) {
      case AuditAction.signIn:
      case AuditAction.signOut:
        return Colors.blueGrey;
      case AuditAction.approve:
      case AuditAction.create:
        return Colors.green.shade600;
      case AuditAction.reject:
      case AuditAction.delete:
        return Colors.red.shade600;
      case AuditAction.update:
        return Colors.blue.shade600;
      case AuditAction.permissionChange:
        return Colors.purple.shade500;
      case AuditAction.exportData:
        return Colors.orange.shade600;
    }
  }

  IconData _actionIcon(AuditAction a) {
    switch (a) {
      case AuditAction.signIn:
        return Icons.login;
      case AuditAction.signOut:
        return Icons.logout;
      case AuditAction.approve:
        return Icons.check;
      case AuditAction.reject:
        return Icons.close;
      case AuditAction.create:
        return Icons.add;
      case AuditAction.update:
        return Icons.edit;
      case AuditAction.delete:
        return Icons.delete;
      case AuditAction.permissionChange:
        return Icons.shield;
      case AuditAction.exportData:
        return Icons.file_download;
    }
  }

  String _actionVerb(AuditAction a) {
    switch (a) {
      case AuditAction.signIn:
        return 'signed into';
      case AuditAction.signOut:
        return 'signed out from';
      case AuditAction.approve:
        return 'approved';
      case AuditAction.reject:
        return 'rejected';
      case AuditAction.create:
        return 'created';
      case AuditAction.update:
        return 'updated';
      case AuditAction.delete:
        return 'deleted';
      case AuditAction.permissionChange:
        return 'changed permissions on';
      case AuditAction.exportData:
        return 'exported';
    }
  }

  String _fmt(DateTime dt) =>
      dt.toIso8601String().split('.').first.replaceFirst('T', ' ');
}
