import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
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
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/admin_repositories.dart';
import '../../entities/managed_user.dart';

/// Slice 9.2.2 — role + permission scope editor.
const _knownScopes = <String>[
  'admin',
  'finance.*',
  'finance.read',
  'finance.approve',
  'inventory.*',
  'inventory.read',
  'sales.*',
  'sales.read',
  'hr.*',
  'projects.*',
];

class RoleEditorPage extends StatelessWidget {
  const RoleEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<RolesRepository>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.roleEditorPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas
            AppBackgroundGradient(),
            StreamBuilder<List<Role>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roles = snap.data!;
                return ListView.separated(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 100,
                  ),
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final role = roles[idx];
                    return _RoleCard(role: role)
                        .animate()
                        .fadeIn(delay: (idx * 80).clamp(0, 300).ms)
                        .slideY(begin: 0.04, end: 0, duration: 300.ms);
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: AppLabel(
          text: l10n.roleEditorNewRoleAction,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
        ),
      ).animate().scale(delay: 200.ms),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Set<String> selectedScopes = {};
    String? errorMsg;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            // Only pin the sheet up to the AppBar WHEN the keyboard is
            // open — otherwise let the sheet hug its content's natural
            // height. We use a Builder to read MediaQuery fresh on every
            // rebuild (StatefulBuilder doesn't refresh MediaQuery via
            // setSheet, but the keyboard open/close triggers a global
            // rebuild that flows through).
            final media = MediaQuery.of(sheetCtx);
            final keyboardOpen = media.viewInsets.bottom > 0;
            final sheetHeight =
                media.size.height - media.padding.top - kToolbarHeight;
            final padded = Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                AppLabel(
                  text: l10n.roleEditorCreateCustomRoleTitle,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: nameCtrl,
                  label: l10n.roleEditorRoleNameLabel,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: descCtrl,
                  label: l10n.roleEditorDescriptionLabel,
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 16),
                AppLabel(
                  text: l10n.roleEditorAssignScopesHeading,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final scope in _knownScopes)
                      FilterChip(
                        label: AppLabel(
                          text: scope,
                          fontSize: AppFontSize.value13,
                          fontFamily: 'monospace',
                        ),
                        selected: selectedScopes.contains(scope),
                        checkmarkColor: theme.colorScheme.primary,
                        selectedColor: theme.colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          side: BorderSide(
                            color: selectedScopes.contains(scope)
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        onSelected: (sel) => setSheet(() {
                          if (sel) {
                            selectedScopes.add(scope);
                          } else {
                            selectedScopes.remove(scope);
                          }
                        }),
                      ),
                  ],
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: AppLabel(
                      text: errorMsg!,
                      fontSize: AppFontSize.value14,
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await GetIt.I<RolesRepository>().createFromInput(
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          permissionTokens: selectedScopes.toList(),
                        );
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      } on ValidationFailure catch (f) {
                        setSheet(() => errorMsg = f.fieldErrors.entries
                            .map((e) => '${e.key}: ${e.value.join(', ')}')
                            .join('\n'));
                      }
                    },
                    child: AppLabel(
                      text: l10n.roleEditorCreateRoleAction,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              );
            // Pin the sheet up to just below the AppBar ONLY when the
            // keyboard is open — otherwise (height: null) the SizedBox
            // sizes to its child's natural height. The SizedBox wrapper
            // MUST stay in the tree both ways: if we switched between
            // `SizedBox(child: padded)` and bare `padded`, the widget
            // tree shape would change as the keyboard tried to open,
            // destroying the focused TextField's element identity and
            // killing the focus before the keyboard finished animating
            // in. That's why tapping a field looked like "no keyboard".
            return SizedBox(
              height: keyboardOpen ? sheetHeight : null,
              child: padded,
            );
          },
        );
      },
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role});
  final Role role;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSys = widget.role.isSystem;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadii.lg),
              bottom: Radius.circular(_isExpanded ? 0 : AppRadii.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isSys ? Colors.blueGrey : theme.colorScheme.primary)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSys ? Icons.lock_outline : Icons.shield_outlined,
                      color: isSys ? Colors.blueGrey : theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppLabel(
                              text: widget.role.name,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(width: 8),
                            if (isSys)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                ),
                                child: AppLabel(
                                  text: l10n.roleEditorSystemBadge,
                                  fontSize: AppFontSize.value8,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AppLabel(
                          text: widget.role.description,
                          fontSize: AppFontSize.value12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: l10n.roleEditorPermissionScopesHeading,
                    fontSize: AppFontSize.value11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scope in _knownScopes)
                        _PermissionChip(
                          scope: scope,
                          isEnabled: widget.role.permissionTokens.contains(scope),
                          isSystem: isSys,
                          onToggle: (selected) => _toggleScope(scope, selected),
                        ),
                    ],
                  ),
                  if (!isSys) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: AppLabel(
                          text: l10n.roleEditorDeleteRoleAction,
                          fontSize: AppFontSize.value14,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleScope(String scope, bool selected) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final next = Set<String>.of(widget.role.permissionTokens);
    if (selected) {
      next.add(scope);
    } else {
      next.remove(scope);
    }
    try {
      await GetIt.I<RolesRepository>().updatePermissions(
        role: widget.role,
        permissionTokens: next.toList(),
      );
    } on Failure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.roleEditorUpdateFailedSnack(f.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final rolesRepo = GetIt.I<RolesRepository>();
    final users = await GetIt.I<ManagedUsersRepository>().getAll();
    // Pre-check: refuse early so we don't even show the confirm dialog
    // for a guaranteed-fail delete.
    if (widget.role.isSystem ||
        users.any((u) => u.roleIds.contains(widget.role.id))) {
      try {
        await rolesRepo.deleteGuarded(
          role: widget.role,
          currentUsers: users,
        );
      } on ConflictFailure catch (f) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(f.message ?? l10n.roleEditorCannotDeleteFallback),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: AppLabel(
          text: l10n.roleEditorDeleteConfirmTitle(widget.role.name),
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.bold,
        ),
        content: AppLabel(
          text: l10n.roleEditorDeleteConfirmMessage,
          fontSize: AppFontSize.value14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: AppLabel(
              text: l10n.commonCancelAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: AppLabel(
              text: l10n.roleEditorDeleteAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await rolesRepo.deleteGuarded(role: widget.role, currentUsers: users);
    }
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({
    required this.scope,
    required this.isEnabled,
    required this.isSystem,
    required this.onToggle,
  });

  final String scope;
  final bool isEnabled;
  final bool isSystem;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isSystem ? null : () => onToggle(!isEnabled),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.check_circle : Icons.radio_button_off,
              size: 14,
              color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            AppLabel(
              text: scope,
              fontSize: AppFontSize.value12,
              fontWeight: isEnabled ? FontWeight.bold : FontWeight.w500,
              color: isEnabled
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ],
        ),
      ),
    );
  }
}
