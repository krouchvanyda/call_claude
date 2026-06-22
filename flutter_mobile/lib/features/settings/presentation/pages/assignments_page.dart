import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/app_permissions.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../core/widgets/loading_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/datasources/roles_remote_data_source.dart';
import '../../data/datasources/users_remote_data_source.dart';
import '../../data/models/assign_roles_request.dart';
import '../../data/models/page_response.dart';
import '../../data/models/role_dto.dart';
import '../../data/models/user_dto.dart';

/// Admin-only **Assign Roles** page.
///
/// Bulk flow: pick one or more users → pick a role → pick a mode →
/// save. Calls `POST /api/v1/users/assign-roles` which takes the
/// Spring record:
///
/// ```java
/// public record AssignRolesRequest(
///     @NotEmpty Set<Long> userIds,
///     @NotNull  Set<String> roles,
///     Mode mode    // ADD | REPLACE | REMOVE
/// ) {}
/// ```
///
/// One round-trip mutates every selected user in a single transaction
/// on the server side — far better than looping `PATCH /users/{id}`
/// per-user.
///
/// **Permission gating** — only super-admins reach the editor. Non-
/// super-admins see [_SuperAdminLock] instead. Backend would 403
/// anyway; the client gate avoids the round-trip and shows a clearer
/// message.
///
/// One bundle load (`/users/me` + `/roles` + first page of `/users`)
/// on mount; save success re-fires it.
class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final _users = GetIt.I<UsersRemoteDataSource>();
  final _roles = GetIt.I<RolesRemoteDataSource>();

  late Future<_AssignmentsBundle> _bundleFuture = _load();

  void _reload() {
    setState(() => _bundleFuture = _load());
  }

  /// Fan out three GETs in parallel — none depend on each other.
  Future<_AssignmentsBundle> _load() async {
    final results = await Future.wait<dynamic>([
      _users.me(),
      _roles.listRoles(),
      _users.listUsers(page: 1, pageSize: 50),
    ]);
    return _AssignmentsBundle(
      me: results[0] as UserDto,
      roles: results[1] as List<RoleDto>,
      usersPage: results[2] as PageResponse<UserDto>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.assignmentsPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<_AssignmentsBundle>(
              future: _bundleFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: LoadingScreen());
                }
                if (snap.hasError || !snap.hasData) {
                  return _ErrorPanel(onRetry: _reload);
                }
                final bundle = snap.data!;
                developer.log(
                  '[Assignments] me.id=${bundle.me.id} '
                  'roles=${bundle.me.roles} canEdit=${bundle.canEdit}',
                  name: 'Assignments',
                );
                if (!bundle.canEdit) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: context.dynamicAppBarPadding,
                    ),
                    child: const _SuperAdminLock(),
                  );
                }
                return Padding(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                  ),
                  child: _AssignRolesForm(
                    bundle: bundle,
                    usersApi: _users,
                    onSaved: _reload,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Bundle of everything the form needs. Fetched once on mount + on
/// every save success.
class _AssignmentsBundle {
  const _AssignmentsBundle({
    required this.me,
    required this.roles,
    required this.usersPage,
  });

  final UserDto me;
  final List<RoleDto> roles;
  final PageResponse<UserDto> usersPage;

  /// Whole-page gate: assigning roles is super-admin only by policy.
  bool get canEdit => isSuperAdmin(me.roles);
}

// ════════════════════════════════════════════════════════════════════
// Bulk assignment form
// ════════════════════════════════════════════════════════════════════

class _AssignRolesForm extends StatefulWidget {
  const _AssignRolesForm({
    required this.bundle,
    required this.usersApi,
    required this.onSaved,
  });

  final _AssignmentsBundle bundle;
  final UsersRemoteDataSource usersApi;
  final VoidCallback onSaved;

  @override
  State<_AssignRolesForm> createState() => _AssignRolesFormState();
}

class _AssignRolesFormState extends State<_AssignRolesForm> {
  /// IDs of every user picked for assignment. A `Set` keeps toggle
  /// logic O(1) and dedups against accidental double-add when the
  /// modal sheet re-opens.
  final Set<String> _selectedUserIds = <String>{};

  /// Role to apply. Single-select: each user gets exactly one role
  /// per app policy. Backend's `roles` field is a `Set<String>` so it
  /// technically allows multi-role, but the UX never sends more than
  /// one entry.
  RoleDto? _draftRole;

  /// Mutation mode is always REPLACE: it strips the user's existing
  /// role(s) and sets exactly the picked one. Hardcoded (no UI) so
  /// the policy "one user = one role" can't be violated by accident
  /// — ADD would stack a second role on top of an existing one, and
  /// REMOVE isn't a flow this page offers.
  static const _mode = AssignRolesMode.replace;

  bool _saving = false;

  void _setSelectedUsers(Set<String> ids) {
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(ids);
    });
  }

  void _selectRole(RoleDto? role) {
    setState(() => _draftRole = role);
  }

  /// Lookup helper — turns the picked user ids back into [UserDto]s so
  /// the picker field can render names. Preserves the directory's
  /// natural order (alphabetical by API ranking) instead of selection
  /// order, which keeps the field stable as users tap on/off.
  List<UserDto> get _selectedUsers => widget.bundle.usersPage.items
      .where((u) => _selectedUserIds.contains(u.id))
      .toList(growable: false);

  bool get _isDirty => _selectedUserIds.isNotEmpty && _draftRole != null;

  Future<void> _save() async {
    if (!_isDirty || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);

    // UserDto.id is a stringified Spring Long — parse back to int for
    // the wire payload (backend expects `Set<Long> userIds`). Anything
    // non-numeric is dropped silently here; we add a sanity check
    // below in case the whole set ends up empty.
    final userIds = <int>[];
    for (final id in _selectedUserIds) {
      final parsed = int.tryParse(id);
      if (parsed != null) userIds.add(parsed);
    }
    if (userIds.isEmpty) {
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.assignmentsSaveFailedSnack),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final body = AssignRolesRequest(
      userIds: userIds,
      roles: <String>[_draftRole!.code],
      mode: _mode,
    );

    developer.log(
      '[Assignments] POST /users/assign-roles body=${body.toJson()}',
      name: 'Assignments',
    );

    try {
      await widget.usersApi.assignRoles(body);
      if (!mounted) return;
      // Pop back to Settings home with `true` so the parent tile can
      // show the success snackbar. Going via the root navigator
      // matches the original push (see `_Tile._open` →
      // `ConfigRouter.pushPageAnimation`) — using the non-root
      // navigator here would no-op because there's no in-shell route
      // to pop. We deliberately DON'T call `widget.onSaved()` (the
      // bundle reload) since we're leaving the page entirely.
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e, stack) {
      developer.log(
        '[Assignments] POST /users/assign-roles FAILED: $e',
        name: 'Assignments',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '${l10n.assignmentsSaveFailedSnack}: ${_humanError(e)}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Copy',
            textColor: Colors.white,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: e.toString()));
            },
          ),
        ),
      );
    }
  }

  /// Strip the noisy dio prefix so the snackbar shows the actionable
  /// part — HTTP status + server message — instead of the full
  /// "DioException [bad response]: …" wrapper.
  String _humanError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        final msg = data['message'] as String;
        return status != null ? 'HTTP $status — $msg' : msg;
      }
      if (status != null) {
        return 'HTTP $status — ${e.message ?? e.type.name}';
      }
      return e.message ?? e.type.name;
    }
    return e.toString();
  }

  Future<void> _openUserPicker() async {
    if (_saving) return;
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserPickerSheet(
        users: widget.bundle.usersPage.items,
        initialSelectedIds: _selectedUserIds,
      ),
    );
    if (picked != null) {
      _setSelectedUsers(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canEdit = widget.bundle.canEdit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLabel(
                  text: l10n.assignmentsAssignSubtitle,
                  fontSize: AppFontSize.value13,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 20),
                // ── ROLE section ────────────────────────────────────
                // Role goes first now: pick what you want to assign,
                // then pick who gets it. Both fields are independently
                // editable — the previous "pick a user first" gate
                // would feel arbitrary in this order, so it's gone.
                // The save bar still gates on the combination.
                _FieldLabel(text: l10n.assignmentsRoleFieldLabel),
                const SizedBox(height: 6),
                _AssignRoleDropdown(
                  roles: widget.bundle.roles,
                  value: _draftRole,
                  enabled: canEdit && !_saving,
                  onChanged: _selectRole,
                ),
                const SizedBox(height: 8),
                AppLabel(
                  text: l10n.assignmentsRoleHelperCurrentRole,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 20),
                // ── USERS section ───────────────────────────────────
                _FieldLabel(text: l10n.assignmentsUserFieldLabel),
                const SizedBox(height: 6),
                _UserPickerField(
                  selectedUsers: _selectedUsers,
                  enabled: canEdit && !_saving,
                  onTap: _openUserPicker,
                ),
                // MODE picker removed — see [_mode] doc: REPLACE is
                // hardcoded so the "one user, one role" policy can't
                // be bypassed by accident.
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _SaveBar(
              enabled: canEdit && _isDirty && !_saving,
              saving: _saving,
              // Save label = "Assign role to N users". Mode is no
              // longer a knob, so the label is just count-aware.
              dirtyLabel: l10n.assignmentsSaveActionAssign(
                _selectedUserIds.length,
              ),
              cleanLabel: l10n.assignmentsNoChangesYet,
              onSave: _save,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Form pieces — labels, pickers, mode picker, save bar
// ════════════════════════════════════════════════════════════════════

/// Small uppercase label that sits above each section ("ROLE",
/// "USERS", "MODE").
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AppLabel(
        text: text.toUpperCase(),
        fontSize: AppFontSize.value11,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Tap-to-pick users field. Renders a form-field-styled row showing a
/// summary of the selection (count + first few names) or a hint when
/// empty. Tapping opens [_UserPickerSheet] for multi-select.
class _UserPickerField extends StatelessWidget {
  const _UserPickerField({
    required this.selectedUsers,
    required this.enabled,
    required this.onTap,
  });

  final List<UserDto> selectedUsers;
  final bool enabled;
  final VoidCallback onTap;

  static String _displayName(UserDto u) =>
      u.fullName.trim().isEmpty ? u.email : u.fullName.trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasSelection = selectedUsers.isNotEmpty;

    String? summary;
    if (selectedUsers.length == 1) {
      summary = _displayName(selectedUsers.first);
    } else if (selectedUsers.length > 1 && selectedUsers.length <= 3) {
      summary = selectedUsers.map(_displayName).join(', ');
    } else if (selectedUsers.length > 3) {
      // "John +3 others" — keeps the field height stable regardless of
      // selection size, and the count line below carries the exact
      // number so the user never has to count names.
      summary = l10n.assignmentsUsersSelectedSummary(
        _displayName(selectedUsers.first),
        selectedUsers.length - 1,
      );
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.group_outlined,
              color: enabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasSelection
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: summary!,
                          fontSize: AppFontSize.value14,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AppLabel(
                          text: l10n.assignmentsUsersSelectedCount(
                              selectedUsers.length),
                          fontSize: AppFontSize.value12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    )
                  : AppLabel(
                      text: l10n.assignmentsPickUsersPrompt,
                      fontSize: AppFontSize.value14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
            ),
            Icon(
              Icons.unfold_more_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select user row used inside [_UserPickerSheet]. Toggle state
/// is owned by the sheet's state; this widget just paints checked /
/// unchecked + dispatches taps.
class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  final UserDto user;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName.trim()[0].toUpperCase();
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      leading: CircleAvatar(
        backgroundColor: user.enabled
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        child: AppLabel(
          text: initials,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w900,
          color: user.enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: AppLabel(
        text: user.fullName.trim().isEmpty ? user.email : user.fullName,
        fontSize: AppFontSize.value14,
        fontWeight: FontWeight.w700,
      ),
      // Two-line subtitle: email on one row, role-status chip on the
      // next. Surfaces "this person has no role" / "this person is
      // already STAFF" at a glance so the admin can pick the right
      // people without re-opening each user's profile.
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabel(
              text: user.email,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _RoleStatusChip(roles: user.roles),
          ],
        ),
      ),
      // Checkbox icon (not a real Checkbox widget) keeps the whole row
      // tappable without a hit-target collision between the box and
      // the ListTile.
      trailing: Icon(
        isSelected
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
    );
  }
}

/// Selectable pill used by the picker sheet's role-status filter row.
/// Looks like a Material `FilterChip` but rolled by hand so it picks
/// up the same `AppLabel` typography + `AppRadii.pill` shape as the
/// rest of the page.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: AppLabel(
          text: label,
          fontSize: AppFontSize.value12,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact pill showing a user's current role(s). Renders as:
///   - errorContainer "No role" when [roles] is empty
///   - primaryContainer with up to 2 role codes ("STAFF" / "ADMIN · STAFF")
///   - "+N" suffix if the user has more than 2 roles
///
/// Used inside the user picker sheet and (single-selection only) on
/// the picker field itself.
class _RoleStatusChip extends StatelessWidget {
  const _RoleStatusChip({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEmpty = roles.isEmpty;

    final bg = isEmpty
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.6);
    final fg = isEmpty
        ? theme.colorScheme.error
        : theme.colorScheme.onPrimaryContainer;

    // One user, one role per app policy — show just the first entry.
    // If the backend ever returns multiple (legacy data created before
    // the policy was tightened), only the first surfaces here; the
    // next REPLACE-mode save will collapse the user back to one role.
    final label = isEmpty ? l10n.assignmentsUserNoRoleBadge : roles.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: AppLabel(
        text: label,
        fontSize: AppFontSize.value10,
        color: fg,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Modal bottom sheet with a searchable, multi-select list of users.
/// Pops with the full set of picked ids; cancel = system back / drag
/// down = pop with null.
class _UserPickerSheet extends StatefulWidget {
  const _UserPickerSheet({
    required this.users,
    required this.initialSelectedIds,
  });

  final List<UserDto> users;
  final Set<String> initialSelectedIds;

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

/// Role-status filter applied on top of the text search inside the
/// user picker sheet. Lets the admin narrow to "everyone who already
/// has a role" vs "users who still need one assigned" — common ops
/// after onboarding a batch of new staff.
enum _RoleFilter { all, hasRole, noRole }

class _UserPickerSheetState extends State<_UserPickerSheet> {
  late final Set<String> _picked = <String>{...widget.initialSelectedIds};
  String _query = '';
  _RoleFilter _roleFilter = _RoleFilter.all;

  List<UserDto> get _filtered {
    final q = _query.trim().toLowerCase();
    return widget.users.where((u) {
      // Text predicate first — faster than the role check on long names.
      if (q.isNotEmpty &&
          !u.fullName.toLowerCase().contains(q) &&
          !u.email.toLowerCase().contains(q)) {
        return false;
      }
      switch (_roleFilter) {
        case _RoleFilter.all:
          return true;
        case _RoleFilter.hasRole:
          return u.roles.isNotEmpty;
        case _RoleFilter.noRole:
          return u.roles.isEmpty;
      }
    }).toList(growable: false);
  }

  bool get _allFilteredSelected =>
      _filtered.isNotEmpty &&
      _filtered.every((u) => _picked.contains(u.id));

  void _toggle(String userId) {
    setState(() {
      if (_picked.contains(userId)) {
        _picked.remove(userId);
      } else {
        _picked.add(userId);
      }
    });
  }

  /// "Select all" respects the active search filter — selecting only
  /// the currently visible rows so the user can narrow + pick a group
  /// without scooping up everyone in the directory.
  void _selectAllFiltered() {
    setState(() => _picked.addAll(_filtered.map((u) => u.id)));
  }

  void _clearAll() {
    setState(_picked.clear);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final users = _filtered;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 12),
              // Header row: count + Select all / Clear actions. Buttons
              // disable when their action would be a no-op so the user
              // gets visual feedback.
              Row(
                children: [
                  Expanded(
                    child: AppLabel(
                      text: l10n.assignmentsUsersSelectedCount(_picked.length),
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _allFilteredSelected ? null : _selectAllFiltered,
                    child: Text(l10n.assignmentsSelectAllAction),
                  ),
                  TextButton(
                    onPressed: _picked.isEmpty ? null : _clearAll,
                    child: Text(l10n.assignmentsClearSelectionAction),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: false,
                onChanged: (q) => setState(() => _query = q),
                decoration: InputDecoration(
                  hintText: l10n.assignmentsUsersSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              // Role-status filter chips. "All" is the default; the
              // other two let an admin laser-focus on either the
              // already-assigned set (e.g. about to add an extra role)
              // or the role-less set (e.g. onboarding fresh accounts).
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  children: [
                    _FilterChip(
                      label: l10n.assignmentsFilterAll,
                      selected: _roleFilter == _RoleFilter.all,
                      onTap: () =>
                          setState(() => _roleFilter = _RoleFilter.all),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: l10n.assignmentsFilterHasRole,
                      selected: _roleFilter == _RoleFilter.hasRole,
                      onTap: () =>
                          setState(() => _roleFilter = _RoleFilter.hasRole),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: l10n.assignmentsFilterNoRole,
                      selected: _roleFilter == _RoleFilter.noRole,
                      onTap: () =>
                          setState(() => _roleFilter = _RoleFilter.noRole),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: users.isEmpty
                    ? _EmptyHint(
                        icon: Icons.person_outline,
                        message: l10n.assignmentsEmptyUsers,
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: users.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) {
                          final u = users[i];
                          return _UserRow(
                            user: u,
                            isSelected: _picked.contains(u.id),
                            onTap: () => _toggle(u.id),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_picked),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: l10n.assignmentsConfirmDoneAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-select role dropdown — same widget as before, just lives in
/// the bulk form now.
class _AssignRoleDropdown extends StatelessWidget {
  const _AssignRoleDropdown({
    required this.roles,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final List<RoleDto> roles;
  final RoleDto? value;
  final bool enabled;
  final ValueChanged<RoleDto?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<RoleDto>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.assignmentsRolePickerLabel,
        prefixIcon: const Icon(Icons.shield_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      hint: AppLabel(
        text: l10n.assignmentsPickRolePrompt,
        fontSize: AppFontSize.value14,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      items: [
        for (final r in roles)
          DropdownMenuItem<RoleDto>(
            value: r,
            child: Row(
              children: [
                Icon(
                  r.isSystem
                      ? Icons.verified_user_rounded
                      : Icons.shield_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AppLabel(
                    text: r.name,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (r.isSystem) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: AppLabel(
                      text: l10n.assignmentsSystemRoleBadge,
                      fontSize: AppFontSize.value9,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.enabled,
    required this.saving,
    required this.dirtyLabel,
    required this.cleanLabel,
    required this.onSave,
  });

  final bool enabled;
  final bool saving;
  final String dirtyLabel;
  final String cleanLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onSave : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : AppLabel(
                text: enabled ? dirtyLabel : cleanLabel,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Empty / error / lock panels
// ════════════════════════════════════════════════════════════════════

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            AppLabel(
              text: message,
              fontSize: AppFontSize.value13,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperAdminLock extends StatelessWidget {
  const _SuperAdminLock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 56,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            AppLabel(
              text: l10n.assignmentsSuperAdminOnlyTitle,
              fontSize: AppFontSize.value18,
              fontWeight: FontWeight.w900,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppLabel(
              text: l10n.assignmentsSuperAdminOnlyMessage,
              fontSize: AppFontSize.value14,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.center,
              lineHeight: 1.4,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            AppLabel(
              text: l10n.commonLoadFailedFallback,
              fontSize: AppFontSize.value14,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: AppLabel(
                text: l10n.commonRetryAction,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
