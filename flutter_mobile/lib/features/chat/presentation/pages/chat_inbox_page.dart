import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/chat_settings.dart';
import '../../data/chat_transport.dart';
import '../../data/users_cache.dart';
import '../../data/repositories/call_log_repository.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../data/repositories/presence_repository.dart';
import '../../entities/call_log.dart';
import '../../entities/conversation.dart';
import '../widgets/chat_avatar.dart';
import 'chat_conversation_page.dart';
import 'message_search_page.dart';
import 'new_conversation_page.dart';
import 'video_call_page.dart';
import 'voice_call_page.dart';

/// Slice 10.1.1 — Chat Inbox.
///
/// Conversation list with All / Unread / Groups tabs, online dots,
/// unread badges, and swipe actions (mute / delete). Tapping a row
/// opens the chat conversation page.
class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showIdentitySheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _IdentitySheet(),
    );
  }

  Future<void> _showRelayUrlSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RelayUrlSheet(),
    );
  }

  List<ChatConversation> _filter(List<ChatConversation> all, int tabIndex) {
    final q = _query.trim().toLowerCase();
    Iterable<ChatConversation> result = all;
    if (tabIndex == 1) {
      result = result.where((c) => c.unreadCount > 0);
    } else if (tabIndex == 2) {
      result = result.where((c) => c.isGroup);
    }
    if (q.isNotEmpty) {
      result = result.where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.lastMessageBody ?? '').toLowerCase().contains(q));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<ConversationsRepository>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: 'Messages',
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => ConfigRouter.pushPageAnimation(
              context,
              const MessageSearchPage(),
            ),
          ),
          IconButton(
            tooltip: 'New message',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => ConfigRouter.pushPageAnimation(
              context,
              const NewConversationPage(),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Chat settings',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'identity':
                  _showIdentitySheet(context);
                case 'relay':
                  _showRelayUrlSheet(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'identity',
                child: ListTile(
                  leading: Icon(Icons.switch_account_rounded),
                  title: Text('Sign in as…'),
                  subtitle: Text('Switch demo identity'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'relay',
                child: ListTile(
                  leading: Icon(Icons.cable_rounded),
                  title: Text('Relay URL…'),
                  subtitle: Text('Connect 2 devices'),
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
            StreamBuilder<List<ChatConversation>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                return Column(
                  children: [
                    SizedBox(height: context.dynamicAppBarPadding),
                    const _TransportStatusPill(),
                    _SearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    _Tabs(controller: _tabs),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _List(items: _filter(all, 0)),
                          _List(items: _filter(all, 1)),
                          _List(items: _filter(all, 2)),
                          // Slice 10.2.5 — global recent calls.
                          const _RecentCallsList(),
                        ],
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        // Use a slightly elevated surface tier — pops above the page
        // gradient in both light and dark mode (plain `surface` blends
        // into the gradient's middle stop in light mode).
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
          hintText: 'Search conversations',
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

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(AppRadii.pill),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unread'),
          Tab(text: 'Groups'),
          Tab(text: 'Calls'),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});
  final List<ChatConversation> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        return _Tile(conversation: items[i])
            .animate()
            .fadeIn(delay: (i * 40).clamp(0, 240).ms)
            .slideY(begin: 0.04, end: 0, duration: 280.ms);
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = GetIt.I<ConversationsRepository>();
    final hasUnread = conversation.unreadCount > 0;
    return Dismissible(
      key: ValueKey(conversation.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Icon(
              conversation.isMuted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            AppLabel(
              text: conversation.isMuted ? 'Unmute' : 'Mute',
              fontSize: AppFontSize.value14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w800,
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppLabel(
              text: 'Delete',
              fontSize: AppFontSize.value14,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.red.shade700),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await repo.setMuted(conversation.id, !conversation.isMuted);
          return false; // never actually dismiss
        }
        return await showDialog<bool>(
              context: context,
              builder: (dCtx) => AlertDialog(
                title: AppLabel(
                  text: 'Delete conversation?',
                  fontSize: AppFontSize.value18,
                  fontWeight: FontWeight.w800,
                ),
                content: AppLabel(
                  text: 'Remove "${conversation.name}" from your inbox. The other side keeps the conversation.',
                  fontSize: AppFontSize.value14,
                  maxLines: 4,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dCtx, false),
                    child: AppLabel(
                      text: 'Cancel',
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () => Navigator.pop(dCtx, true),
                    child: AppLabel(
                      text: 'Delete',
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        // Hit the backend so the conversation actually goes away —
        // not just locally. For groups the server enforces admin-only
        // (returns 403); for direct convs either party may delete.
        // The Dismissible animation has already torn the local row
        // out, so on failure we reconcile via loadInbox so the tile
        // pops back in, and surface a snackbar explaining why.
        unawaited(repo.deleteRemote(conversation.id).catchError((Object e) {
          if (!context.mounted) return;
          final msg = e is DioException && e.response?.statusCode == 403
              ? 'Only an admin can delete this group.'
              : 'Could not delete this conversation.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Re-fetch the inbox so the row the Dismissible removed
          // reappears — the server still has it.
          unawaited(repo.loadInbox());
        }));
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () async {
            await GetIt.I<ConversationsRepository>().markRead(conversation.id);
            if (!context.mounted) return;
            await ConfigRouter.pushPageAnimation(
              context,
              ChatConversationPage(conversationId: conversation.id),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Slice 10.3.5 — user-set photo wins for both groups
                // and direct convs. Groups fall back to the 3-avatar
                // cluster; direct convs fall back to the initials
                // gradient (handled inside ChatAvatar).
                if (conversation.isGroup &&
                    (conversation.avatarFilePath ?? '').isEmpty)
                  GroupAvatarCluster(
                    previews: conversation.participantPreviews,
                    size: 52,
                  )
                else
                  ChatAvatar(
                    name: conversation.name,
                    size: 52,
                    avatarFilePath: conversation.avatarFilePath,
                    // For direct convs feed the other person's id so
                    // the dot tracks live presence from
                    // PresenceRepository (rebuilds on every
                    // `/topic/presence` STOMP frame). Groups don't
                    // show a dot.
                    userId: conversation.isGroup
                        ? null
                        : conversation.participantPreviews.isNotEmpty
                            ? conversation
                                .participantPreviews.first.employeeId
                            : null,
                    showStatus: !conversation.isGroup,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AppLabel(
                              text: conversation.name,
                              fontSize: AppFontSize.value16,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Direct conv: live "· Away" / "· In a call"
                          // pill that ticks on every PresenceRepository
                          // revision. Group convs skip it (their
                          // online-count belongs in the chat header).
                          if (!conversation.isGroup &&
                              conversation.participantPreviews.isNotEmpty)
                            _PresenceInline(
                              userId: conversation
                                  .participantPreviews.first.employeeId,
                            ),
                          const Spacer(),
                          const SizedBox(width: 8),
                          if (conversation.isMuted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (conversation.lastMessageAt != null)
                            AppLabel(
                              text: _formatStamp(conversation.lastMessageAt!),
                              fontSize: AppFontSize.value11,
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: AppLabel(
                              text: _previewFor(conversation),
                              fontSize: AppFontSize.value12,
                              color: hasUnread
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            _UnreadBadge(count: conversation.unreadCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Inbox tile preview composed from the conversation's `lastMessage`
  /// payload. Mirrors the backend spec:
  ///   text   → "You: hi" / "hi"
  ///   image  → "You: 📷 Photo" / "📷 Photo"
  ///   voice  → "You: 🎤 Voice · 0:05" / "🎤 Voice · 0:05"
  ///   file   → "You: 📎 File" / "📎 File"
  ///   deleted → "Message deleted"
  ///   no last message → "No message yet"  (brand-new conv)
  ///
  /// Single "You:" prefix is enforced here so callers must NEVER also
  /// prepend "You:" to the lastMessageBody they save into the conv —
  /// otherwise tiles would render "You: You: hi".
  static String _previewFor(ChatConversation c) {
    // A truly empty conv has no lastMessageAt — use that as the
    // canonical "no messages ever" signal so we don't accidentally
    // hit this branch for a deleted-only message or a voice/image
    // with empty body.
    if (c.lastMessageAt == null) return '💬 No message yet';
    final body = c.lastMessageBody;
    if (body == null && c.lastMessageType == 'text') return '💬 No message yet';

    // Heuristic for soft-delete: backend sends body "Message deleted"
    // OR no body with type=text. The conv doesn't currently carry a
    // separate `deleted` flag on its last-message snapshot — if/when
    // it does, swap to that.
    if (body == 'Message deleted') return 'Message deleted';

    // Sender prefix:
    //   * own message       → "You: ..."
    //   * group / other     → "<FirstName>: ..." so members can tell
    //                          who said what without opening the chat
    //   * direct / other    → no prefix (tile title is already the
    //                          other person's name)
    final me = GetIt.I<ChatSettings>().userId;
    final isOwn = c.lastMessageSenderId == me;
    String prefix = '';
    if (isOwn) {
      prefix = 'You: ';
    } else if (c.isGroup) {
      final senderName = (c.lastMessageSenderName ?? '').trim();
      if (senderName.isNotEmpty) {
        // First word only so a long full-name doesn't crowd out the
        // body on narrow tiles.
        final first = senderName.split(RegExp(r'\s+')).first;
        prefix = '$first: ';
      }
    }
    final type = c.lastMessageType;
    if (type == 'image') return '${prefix}📷 Photo';
    if (type == 'file') return '${prefix}📎 File';
    if (type == 'voice') {
      // We don't carry duration on the conv snapshot today; fall back
      // to a label without timing. Real duration shows in the bubble.
      return '${prefix}🎤 Voice message';
    }
    return '$prefix${body ?? ''}';
  }

  static String _formatStamp(DateTime when) {
    final now = DateTime.now();
    final whenDay = DateTime(when.year, when.month, when.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(whenDay).inDays;
    if (diff == 0) return DateFormat('HH:mm').format(when);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEE').format(when);
    return DateFormat('d MMM').format(when);
  }
}

/// Tiny inline presence pill rendered next to the conversation name
/// on direct-conv inbox tiles. Reads from [PresenceRepository] and
/// rebuilds on every revision tick so the label flips live as peers
/// go Online / Busy / Away. Renders nothing for online + offline so
/// the tile stays clean — the avatar dot already conveys those.
class _PresenceInline extends StatelessWidget {
  const _PresenceInline({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = GetIt.I<PresenceRepository>();
    return AnimatedBuilder(
      animation: repo.revision,
      builder: (_, __) {
        final p = repo.statusOf(userId);
        final (String? label, Color color) = switch (p.effectiveStatus) {
          PresenceStatus.online => (null, Colors.transparent),
          PresenceStatus.busy => ('In a call', const Color(0xFFE2A03F)),
          PresenceStatus.away => ('Away', const Color(0xFFE2A03F)),
          PresenceStatus.offline => (null, Colors.transparent),
        };
        if (label == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLabel(
                text: '· ',
                fontSize: AppFontSize.value12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              AppLabel(
                text: label,
                fontSize: AppFontSize.value11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      alignment: Alignment.center,
      child: AppLabel(
        text: count > 99 ? '99+' : '$count',
        fontSize: AppFontSize.value11,
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            AppLabel(
              text: 'No conversations',
              fontSize: AppFontSize.value16,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(height: 6),
            AppLabel(
              text: 'Start a chat with a teammate or create a group.',
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transport status pill ───────────────────────────────────────
//
// Sits just below the AppBar. Streams from [ChatTransport.status] so
// the user can tell at a glance whether peer messages will flow.
// Tappable: opens the Relay URL sheet directly so a misconfigured URL
// is one tap from being fixed.

class _TransportStatusPill extends StatelessWidget {
  const _TransportStatusPill();

  @override
  Widget build(BuildContext context) {
    final transport = GetIt.I<ChatTransport>();
    final settings = GetIt.I<ChatSettings>();
    return StreamBuilder<ChatTransportStatus>(
      stream: transport.status,
      initialData: transport.currentStatus,
      builder: (context, snap) {
        final status = snap.data ?? ChatTransportStatus.disconnected;
        // Hide entirely when no relay is configured AND we're idle —
        // there's nothing useful to show and the row would just
        // waste vertical space on the single-device demo.
        if (status == ChatTransportStatus.disconnected &&
            settings.relayUrl.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final (label, accent, icon) = switch (status) {
          ChatTransportStatus.connected => (
              'Live · ${_shortHost(settings.relayUrl)}',
              Colors.green.shade600,
              Icons.bolt_rounded,
            ),
          ChatTransportStatus.connecting => (
              'Connecting…',
              Colors.amber.shade700,
              Icons.sync_rounded,
            ),
          ChatTransportStatus.error => (
              'Connection error — tap to fix',
              theme.colorScheme.error,
              Icons.error_outline_rounded,
            ),
          ChatTransportStatus.disconnected => (
              'Offline — tap to set a relay',
              theme.colorScheme.onSurfaceVariant,
              Icons.cloud_off_rounded,
            ),
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const _RelayUrlSheet(),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AppLabel(
                        text: label,
                        fontSize: AppFontSize.value11,
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (settings.userName.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppLabel(
                        text: settings.userName,
                        fontSize: AppFontSize.value11,
                        color: accent.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _shortHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return '${uri.host}:${uri.port}';
  }
}

// ── Identity picker ─────────────────────────────────────────────
//
// **Legacy dev sheet.** Pre-backend this was used to switch the
// active demo identity. With real auth in place, signing in/out is
// the canonical path and this sheet should be hidden in production.
// It still works as a debug helper: it lists whatever users are in
// the [UsersCache] (populated from `/users` for admins) plus the
// currently signed-in user so you can switch back. Selecting a row
// rewrites [ChatSettings] and the transport reconnects.

class _IdentitySheet extends StatefulWidget {
  const _IdentitySheet();

  @override
  State<_IdentitySheet> createState() => _IdentitySheetState();
}

class _IdentitySheetState extends State<_IdentitySheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = GetIt.I<ChatSettings>().userId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = GetIt.I<ChatSettings>();
    // Build the picker list from whatever the UsersCache has — which
    // gets seeded at boot (`/users/me`) and after the new-message
    // picker fetches `/users`. For non-admin users whose cache only
    // contains self, the picker will just show their own row; that's
    // fine — there's no one else to switch to without admin rights.
    final everyone = <ChatParticipantPreview>[];
    if (settings.userId.isNotEmpty) {
      everyone.add(ChatParticipantPreview(
        employeeId: settings.userId,
        name: UsersCache.instance.nameOf(settings.userId) ??
            (settings.userName.isEmpty
                ? 'User #${settings.userId}'
                : settings.userName),
        avatarUrl: UsersCache.instance.avatarOf(settings.userId),
        presence: PresenceStatus.online,
      ));
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            const SizedBox(height: 12),
            AppLabel(
              text: 'Sign in as…',
              fontSize: AppFontSize.value16,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(height: 4),
            AppLabel(
              text: 'Switch identity to test two-way chat. The relay routes '
                  'each message to every other connected client.',
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: everyone.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 64,
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
                itemBuilder: (_, i) {
                  final p = everyone[i];
                  final isSel = p.employeeId == _selectedId;
                  return Material(
                    color: isSel
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.4)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        setState(() => _selectedId = p.employeeId);
                        await GetIt.I<ChatSettings>().setIdentity(
                          userId: p.employeeId,
                          userName: p.name,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Row(
                          children: [
                            ChatAvatar(
                              name: p.name,
                              size: 40,
                              // Live presence from PresenceRepository
                              // rather than the (now-empty) seed
                              // `p.presence`. The legacy demo sheet
                              // still works, and the row's dot updates
                              // with `/topic/presence` frames.
                              userId: p.employeeId,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppLabel(
                                text: p.name,
                                fontSize: AppFontSize.value14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isSel)
                              Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Relay URL sheet ─────────────────────────────────────────────

class _RelayUrlSheet extends StatefulWidget {
  const _RelayUrlSheet();

  @override
  State<_RelayUrlSheet> createState() => _RelayUrlSheetState();
}

class _RelayUrlSheetState extends State<_RelayUrlSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: GetIt.I<ChatSettings>().relayUrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
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
          AppLabel(
            text: 'Chat relay URL',
            fontSize: AppFontSize.value16,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 4),
          AppLabel(
            text: 'Point both devices at the WebSocket relay running on your PC. '
                'Leave blank to stay offline.',
            fontSize: AppFontSize.value12,
            color: theme.colorScheme.onSurfaceVariant,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'ws:// URL',
              hintText: 'ws://192.168.1.42:7777',
              prefixIcon: const Icon(Icons.cable_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in const [
                ('Emulator', 'ws://10.0.2.2:7777'),
                ('Simulator', 'ws://127.0.0.1:7777'),
              ])
                ActionChip(
                  label: AppLabel(
                    text: preset.$1,
                    fontSize: AppFontSize.value12,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => _ctrl.text = preset.$2,
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                  onPressed: () async {
                    await GetIt.I<ChatSettings>().setRelayUrl(_ctrl.text);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: 'Save',
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

// ── Slice 10.2.5 — Recent Calls tab ─────────────────────────────
//
// 4th tab on the inbox. Lists every entry from `chat_call_log`,
// newest first, with direction + missed icons and a tap target that
// re-opens the matching voice/video call page.

class _RecentCallsList extends StatelessWidget {
  const _RecentCallsList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatCallLog>>(
      stream: GetIt.I<CallLogRepository>().watchAll(),
      builder: (context, snap) {
        final logs = snap.data ?? const <ChatCallLog>[];
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.call_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  AppLabel(
                    text: 'No calls yet',
                    fontSize: AppFontSize.value16,
                    fontWeight: FontWeight.w800,
                  ),
                  const SizedBox(height: 6),
                  AppLabel(
                    text: 'Place a voice or video call from any conversation.',
                    fontSize: AppFontSize.value12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (_, i) {
            return _RecentCallTile(log: logs[i])
                .animate()
                .fadeIn(delay: (i * 40).clamp(0, 240).ms)
                .slideY(begin: 0.04, end: 0, duration: 280.ms);
          },
        );
      },
    );
  }
}

class _RecentCallTile extends StatelessWidget {
  const _RecentCallTile({required this.log});
  final ChatCallLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = GetIt.I<ChatSettings>().userId;
    final isOutgoing = log.callerId == me;
    final isMissed = log.status == ChatCallStatus.missed ||
        log.status == ChatCallStatus.noAnswer ||
        (log.status == ChatCallStatus.rejected && !isOutgoing);
    final isVideo = log.callType == ChatCallType.video;
    final accent = isMissed
        ? theme.colorScheme.error
        : (isOutgoing ? Colors.blue.shade700 : Colors.green.shade700);
    // For now we surface the caller's display name; once participant
    // metadata is on the log row we'd flip to "the other party".
    final peerName = isOutgoing ? log.callerName : log.callerName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          isVideo
              ? VideoCallPage(conversationId: log.conversationId)
              : VoiceCallPage(conversationId: log.conversationId),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ChatAvatar(name: peerName, size: 44, showStatus: false),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      size: 9,
                      color: theme.colorScheme.onPrimary,
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
                      text: peerName,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w700,
                      color: isMissed ? theme.colorScheme.error : null,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isMissed
                              ? Icons.call_missed_rounded
                              : (isOutgoing
                                  ? Icons.call_made_rounded
                                  : Icons.call_received_rounded),
                          size: 13,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppLabel(
                            text: _subtitle(log, isMissed, isOutgoing),
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.onSurfaceVariant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppLabel(
                text: _formatStamp(log.startedAt),
                fontSize: AppFontSize.value11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(ChatCallLog log, bool isMissed, bool isOutgoing) {
    if (isMissed) return 'Missed';
    if (log.durationSeconds > 0) {
      return '${isOutgoing ? "Outgoing" : "Incoming"} · ${log.formattedDuration()}';
    }
    return isOutgoing ? 'Outgoing' : 'Incoming';
  }

  static String _formatStamp(DateTime when) {
    final now = DateTime.now();
    final whenDay = DateTime(when.year, when.month, when.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(whenDay).inDays;
    if (diff == 0) return DateFormat('HH:mm').format(when);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEE').format(when);
    return DateFormat('d MMM').format(when);
  }
}
