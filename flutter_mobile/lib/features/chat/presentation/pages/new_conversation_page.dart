import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../../settings/data/datasources/users_remote_data_source.dart';
import '../../../settings/data/models/user_dto.dart';
import '../../data/chat_dto_mappers.dart';
import '../../data/chat_settings.dart';
import '../../data/chats_remote_data_source.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../data/users_cache.dart';
import '../../entities/conversation.dart';
import '../widgets/chat_avatar.dart';
import 'chat_conversation_page.dart';

/// Slice 10.1.3 — New Conversation / Group Chat.
class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

enum _Mode { direct, group }

class _NewConversationPageState extends State<NewConversationPage> {
  final _searchCtrl = TextEditingController();
  final _groupNameCtrl = TextEditingController();
  String _query = '';
  _Mode _mode = _Mode.direct;
  final Set<String> _selected = {};
  bool _creating = false;

  /// Real users pulled from `GET /api/v1/users` and mapped onto the
  /// chat module's [ChatParticipantPreview] shape. Replaces the
  /// pre-backend demo seed so the picker reflects
  /// who's actually in the database. Loaded once in initState.
  List<ChatParticipantPreview> _directory = const [];
  bool _loadingDirectory = true;
  String? _directoryError;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    final users = GetIt.I<UsersRemoteDataSource>();
    final settings = GetIt.I<ChatSettings>();
    // Resolve the real backend user id BEFORE filtering — `ChatSettings`
    // boots with the demo-seed default (e.g. "u-001") so a bare
    // `settings.userId` check would let the signed-in user show up in
    // their own picker. We hit `/users/me` in parallel with the
    // directory list to find out who we actually are, then sync the
    // result back into `ChatSettings` so downstream chat code
    // (sender-name resolution, conversation routing) also benefits.
    String me = settings.userId;
    try {
      // Fire both calls in parallel — they're independent and
      // `/users/me` is tiny next to a 200-row directory page.
      final mePending = users.me();
      final pagePending = users.listUsers(
        // 200 covers the vast majority of small/mid orgs in one shot.
        // Sort is intentionally NOT passed: backend's `PageQuery`
        // does not parse the Spring `field,direction` shorthand —
        // it treats "fullName,asc" as one column name and returns
        // 400. We sort client-side below.
        pageSize: 200,
      );
      final meUser = await mePending;
      me = meUser.id;
      // Fire-and-forget — setIdentity short-circuits when nothing
      // changed, so calling this every directory load is cheap.
      unawaited(settings.setIdentity(
        userId: me,
        userName: meUser.fullName.trim().isEmpty
            ? meUser.email
            : meUser.fullName,
      ));
      // Seed the shared users cache with self so chat_dto_mappers can
      // resolve "You" / own avatar without another /users/me roundtrip.
      UsersCache.instance.put(
        userId: me,
        name: meUser.fullName.trim().isEmpty
            ? meUser.email
            : meUser.fullName,
      );
      final page = await pagePending;
      final mapped = <ChatParticipantPreview>[];
      for (final u in page.items) {
        if (!u.enabled) continue; // disabled accounts can't be messaged
        if (u.id == me) continue; // exclude self
        mapped.add(
          ChatParticipantPreview(
            employeeId: u.id,
            name: _displayNameFor(u),
            // Backend doesn't ship avatar URL or presence on UserDto
            // yet — keep nulls so ChatAvatar falls back to initials and
            // the status dot stays grey. Wire real values in once
            // backend adds them.
          ),
        );
      }
      // Bulk-seed the cache so every chat surface (inbox tiles, chat
      // header, sender labels) can resolve names for everyone in this
      // org without per-id lookups. Includes self via the put() above.
      UsersCache.instance.putAll(
        page.items.where((u) => u.enabled).map((u) => (
              id: u.id,
              name: _displayNameFor(u),
              avatarUrl: null as String?,
            )),
      );
      mapped.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _directory = mapped;
        _loadingDirectory = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      // 403 means the signed-in user doesn't have `USER_READ`
      // permission — typical for CUSTOMER / STAFF roles. The backend
      // currently has no dedicated "chat-eligible users" endpoint, so
      // until it ships one (or `/users` is relaxed for anyone with
      // `chat:write`), non-admin users can't start new conversations
      // from this picker. Show a clear message instead of a generic
      // network error so the user / dev knows what to fix.
      final isForbidden = e.response?.statusCode == 403;
      setState(() {
        _loadingDirectory = false;
        _directoryError = isForbidden
            ? 'You don\'t have permission to browse users.\nAsk an admin to enable chat directory access.'
            : 'Could not load users. Tap retry.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDirectory = false;
        _directoryError = 'Could not load users. Tap retry.';
      });
    }
  }

  /// Look up a participant preview by id from the loaded directory.
  /// Falls back to a placeholder so a stale selection (e.g. user got
  /// disabled mid-flow) doesn't crash the create flow.
  ChatParticipantPreview _resolve(String id) {
    for (final p in _directory) {
      if (p.employeeId == id) return p;
    }
    return ChatParticipantPreview(employeeId: id, name: 'Unknown');
  }

  /// Stable display label for a backend [UserDto]. Picks the first
  /// non-empty of (fullName, email), then falls back to `User #id`
  /// so the picker never shows "?" / blank rows when both name and
  /// email come back empty from the backend.
  String _displayNameFor(UserDto u) {
    final full = u.fullName.trim();
    if (full.isNotEmpty) return full;
    final mail = u.email.trim();
    if (mail.isNotEmpty) return mail;
    return 'User #${u.id}';
  }

  List<ChatParticipantPreview> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _directory;
    return _directory.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  bool get _canCreate {
    if (_creating) return false;
    if (_mode == _Mode.direct) return _selected.length == 1;
    return _selected.length >= 2;
  }

  /// Group-mode confirm flow: members are already picked, so we only
  /// need the name. Prompt for it in a bottom sheet; on confirm, set
  /// the controller and run [_create].
  Future<void> _confirmCreateGroup() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GroupNameSheet(memberCount: _selected.length),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    _groupNameCtrl.text = name.trim();
    await _create();
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      // Resolve numeric backend ids for every selected member. The
      // picker only shows backend users, so every `_selected` entry
      // should parse — but be defensive: if any id is junk, bail with
      // a snackbar rather than POSTing a partially-broken payload.
      final memberIds = <int>{};
      for (final id in _selected) {
        final n = int.tryParse(id);
        if (n == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selection contains a non-backend user.'),
              ),
            );
          }
          return;
        }
        memberIds.add(n);
      }

      final remote = GetIt.I<ChatsRemoteDataSource>();
      final repo = GetIt.I<ConversationsRepository>();
      final settings = GetIt.I<ChatSettings>();

      // POST /chats/conversations — backend validates membership,
      // assigns a real numeric id, and (typically) publishes
      // `conversation.create` envelopes to every member's
      // `/user/queue/inbox` so peers hydrate on their own.
      final json = await remote.createConversation(
        type: _mode == _Mode.direct ? 'DIRECT' : 'GROUP',
        memberIds: memberIds,
        name: _mode == _Mode.group ? _groupNameCtrl.text.trim() : null,
      );

      // Hydrate locally via the shared mapper so the inbox tile +
      // chat page see the same shape they always have. `create` keeps
      // the backend's id because it's non-empty.
      final hydrated = conversationFromDto(json, currentUserId: settings.userId);
      final created = await repo.create(hydrated);

      if (!mounted) return;
      Navigator.pop(context);
      await ConfigRouter.pushPageAnimation(
        context,
        ChatConversationPage(conversationId: created.id),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create conversation: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(title: 'New Message', centerTitle: true),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            Column(
              children: [
                SizedBox(height: context.dynamicAppBarPadding + kToolbarHeight),
                _ModeToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() {
                    _mode = m;
                    if (m == _Mode.direct && _selected.length > 1) {
                      _selected.clear();
                    }
                  }),
                ),
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
                // Group mode only — Direct mode opens the chat
                // immediately on tap, so the chip row would just flash
                // briefly before navigation.
                if (_mode == _Mode.group && _selected.isNotEmpty)
                  _SelectedChips(
                    selectedIds: _selected,
                    resolve: _resolve,
                    onRemove: (id) => setState(() => _selected.remove(id)),
                  ),
                const Divider(height: 1),
                Expanded(child: _MemberList(
                  people: _filtered,
                  selected: _selected,
                  isMulti: _mode == _Mode.group,
                  loading: _loadingDirectory,
                  errorText: _directoryError,
                  onRetry: _directoryError != null
                      ? () {
                          setState(() {
                            _loadingDirectory = true;
                            _directoryError = null;
                          });
                          _loadDirectory();
                        }
                      : null,
                  onToggle: (id) {
                    if (_mode == _Mode.direct) {
                      // Direct mode: tapping a member opens the chat
                      // immediately — no Start Chat confirmation step.
                      setState(() {
                        _selected
                          ..clear()
                          ..add(id);
                      });
                      _create();
                      return;
                    }
                    setState(() {
                      if (_selected.contains(id)) {
                        _selected.remove(id);
                      } else {
                        _selected.add(id);
                      }
                    });
                  },
                )),
                // Bottom action bar only matters in Group mode —
                // Direct mode opens the chat the moment a member is tapped.
                if (_mode == _Mode.group)
                  _BottomBar(
                    enabled: _canCreate,
                    busy: _creating,
                    label: 'Create Group',
                    onPressed: _confirmCreateGroup,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _Pill(label: 'Direct', selected: mode == _Mode.direct, onTap: () => onChanged(_Mode.direct))),
          Expanded(child: _Pill(label: 'Group', selected: mode == _Mode.group, onTap: () => onChanged(_Mode.group))),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        alignment: Alignment.center,
        child: AppLabel(
          text: label,
          fontSize: AppFontSize.value14,
          color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Bottom-sheet prompt that asks for the group name only — members
/// are already picked on the underlying page. Pops with the trimmed
/// name on confirm, or `null` when dismissed / cancelled. The
/// controller is owned by [_GroupNameSheetState] so the TextField is
/// disposed cleanly with the sheet (avoids the InputDecorator
/// `_dependents.isEmpty` assertion).
class _GroupNameSheet extends StatefulWidget {
  const _GroupNameSheet({required this.memberCount});
  final int memberCount;

  @override
  State<_GroupNameSheet> createState() => _GroupNameSheetState();
}

class _GroupNameSheetState extends State<_GroupNameSheet> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-render on each keystroke so the Confirm button can flip
    // enabled the moment the field is non-empty.
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canConfirm = _ctrl.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLabel(
                      text: 'Name your group',
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 2),
                    AppLabel(
                      text: '${widget.memberCount} member${widget.memberCount == 1 ? '' : 's'} selected',
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (canConfirm) Navigator.pop(context, _ctrl.text);
            },
            decoration: InputDecoration(
              labelText: 'Group name',
              hintText: 'e.g. Q3 Launch Crew',
              prefixIcon: const Icon(Icons.edit_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: 'Cancel',
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: canConfirm
                      ? () => Navigator.pop(context, _ctrl.text)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: 'Create Group',
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: isLight ? 0.5 : 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox(width: 12);
              return IconButton(
                splashRadius: 18,
                padding: const EdgeInsets.only(right: 8),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          hintText: 'Search employees',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({
    required this.selectedIds,
    required this.resolve,
    required this.onRemove,
  });
  final Set<String> selectedIds;
  final ChatParticipantPreview Function(String employeeId) resolve;
  final void Function(String employeeId) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in selectedIds)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: InputChip(
                avatar: ChatAvatar(
                  name: resolve(id).name,
                  size: 24,
                  showStatus: false,
                ),
                label: AppLabel(
                  text: resolve(id).name,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w700,
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => onRemove(id),
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.people,
    required this.selected,
    required this.isMulti,
    required this.onToggle,
    this.loading = false,
    this.errorText,
    this.onRetry,
  });
  final List<ChatParticipantPreview> people;
  final Set<String> selected;
  final bool isMulti;
  final void Function(String id) onToggle;
  final bool loading;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              AppLabel(
                text: errorText!,
                fontSize: AppFontSize.value14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: AppLabel(
                    text: 'Retry',
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (people.isEmpty) {
      return const Center(
        child: AppLabel(
          text: 'No employees match.',
          fontSize: AppFontSize.value14,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: people.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      itemBuilder: (_, i) {
        final p = people[i];
        final isSel = selected.contains(p.employeeId);
        final theme = Theme.of(context);
        return Material(
          color: isSel
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onToggle(p.employeeId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ChatAvatar(name: p.name, size: 44, userId: p.employeeId),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppLabel(
                      text: p.name,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isMulti)
                    Checkbox(
                      value: isSel,
                      onChanged: (_) => onToggle(p.employeeId),
                    )
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (i * 25).clamp(0, 240).ms);
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.enabled,
    required this.busy,
    required this.label,
    required this.onPressed,
  });
  final bool enabled;
  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : AppLabel(
                    text: label,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w800,
                  ),
          ),
        ),
      ),
    );
  }
}
