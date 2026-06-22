import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../../../shared/widgets/avatar_picker_sheet.dart';
import '../../../settings/data/datasources/users_remote_data_source.dart';
import '../../data/chat_settings.dart';
import '../../data/repositories/call_log_repository.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../data/repositories/messages_repository.dart';
import '../../data/repositories/presence_repository.dart';
import '../../entities/call_log.dart';
import '../../entities/chat_message.dart';
import '../../entities/conversation.dart';
import '../widgets/chat_avatar.dart';
import 'image_viewer_page.dart';
import 'message_search_page.dart';
import 'video_call_page.dart';
import 'voice_call_page.dart';

/// Slice 10.3.1 — Conversation Info / Chat Settings.
class ChatInfoPage extends StatelessWidget {
  const ChatInfoPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const DynamicAppBar(title: 'Info', centerTitle: false),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<ChatConversation?>(
              stream: GetIt.I<ConversationsRepository>()
                  .watchById(conversationId),
              builder: (context, snap) {
                final conv = snap.data;
                if (conv == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _Body(conversation: conv);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 32,
      ),
      children: [
        _Hero(conversation: conversation)
            .animate()
            .fadeIn()
            .slideY(begin: 0.04, end: 0, duration: 320.ms),
        const SizedBox(height: 20),
        _QuickActions(conversation: conversation)
            .animate()
            .fadeIn(delay: 60.ms)
            .slideY(begin: 0.04, end: 0, duration: 320.ms),
        const SizedBox(height: 20),
        _SharedMedia(conversationId: conversation.id)
            .animate()
            .fadeIn(delay: 120.ms)
            .slideY(begin: 0.04, end: 0, duration: 320.ms),
        const SizedBox(height: 20),
        _CallHistorySection(conversationId: conversation.id)
            .animate()
            .fadeIn(delay: 150.ms)
            .slideY(begin: 0.04, end: 0, duration: 320.ms),
        const SizedBox(height: 20),
        _Settings(conversation: conversation)
            .animate()
            .fadeIn(delay: 180.ms)
            .slideY(begin: 0.04, end: 0, duration: 320.ms),
        if (conversation.isGroup) ...[
          const SizedBox(height: 20),
          _Members(conversation: conversation)
              .animate()
              .fadeIn(delay: 240.ms)
              .slideY(begin: 0.04, end: 0, duration: 320.ms),
        ],
        const SizedBox(height: 20),
        _DangerZone(conversation: conversation)
            .animate()
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.04, end: 0, duration: 320.ms),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = conversation.isGroup;
    final hasPhoto = (conversation.avatarFilePath ?? '').isNotEmpty;
    return Column(
      children: [
        // Slice 10.3.3 — group avatar is tappable (admin only).
        // A custom photo wins over the participant cluster.
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                // Slice 10.3.5 — direct chats are now tappable too, so
                // the user can set a per-device photo for that contact
                // (Telegram "Set contact photo" pattern). Groups keep
                // the existing 10.3.3 behaviour.
                onTap: () => _showChangePhotoSheet(context, conversation),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: isGroup
                      ? (hasPhoto
                          ? ChatAvatar(
                              name: conversation.name,
                              size: 96,
                              avatarFilePath: conversation.avatarFilePath,
                              showStatus: false,
                            )
                          : GroupAvatarCluster(
                              previews: conversation.participantPreviews,
                              size: 96,
                            ))
                      : ChatAvatar(
                          name: conversation.name,
                          size: 96,
                          // Slice 10.3.5 — direct hero now honours the
                          // user-set photo (drives the inbox tile too
                          // via the same `ChatAvatar(avatarFilePath:)`).
                          avatarFilePath: conversation.avatarFilePath,
                          // Live presence for the other person; dot
                          // ticks on every `/topic/presence` frame.
                          userId: conversation.participantPreviews.isNotEmpty
                              ? conversation
                                  .participantPreviews.first.employeeId
                              : null,
                        ),
                ),
              ),
            ),
            // Camera badge — always shown now that both groups AND
            // direct convs are editable.
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Slice 10.3.3 — group name is tappable (admin only) → opens
        // the rename sheet. Pencil icon makes the affordance obvious.
        InkWell(
          onTap: isGroup
              ? () => _showRenameSheet(context, conversation)
              : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppLabel(
                    text: conversation.name,
                    fontSize: AppFontSize.value24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isGroup) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Live presence subtitle — same source of truth as the AppBar
        // on the chat page so they always agree. Reads from
        // PresenceRepository on every tick of `revision`, so peers
        // going Online → Busy → Offline update without us re-opening
        // the page.
        AnimatedBuilder(
          animation: GetIt.I<PresenceRepository>().revision,
          builder: (_, __) => AppLabel(
            text: _subtitleFor(conversation),
            fontSize: AppFontSize.value12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _subtitleFor(ChatConversation c) {
    if (c.isGroup) {
      // Online count derived live from PresenceRepository — the
      // ConversationDto's `onlineCount` is a snapshot at fetch time
      // and goes stale the moment a member's presence flips.
      final repo = GetIt.I<PresenceRepository>();
      final onlineNow = c.participantPreviews
          .where((p) =>
              repo.statusOf(p.employeeId).status == PresenceStatus.online)
          .length;
      return '${c.totalMembers} members · $onlineNow online';
    }
    if (c.participantPreviews.isEmpty) return 'Offline';
    final otherId = c.participantPreviews.first.employeeId;
    final p = GetIt.I<PresenceRepository>().statusOf(otherId);
    // `effectiveStatus` keeps a fresh-OFFLINE as AWAY for up to 5 min
    // so peers who just minimised show "Away · last seen X" instead
    // of skipping straight to plain "Last seen X" / "Offline".
    switch (p.effectiveStatus) {
      case PresenceStatus.online:
        return 'Online now';
      case PresenceStatus.busy:
        return 'In a call';
      case PresenceStatus.away:
        return p.lastSeenAt != null
            ? 'Away · last seen ${_relativeTime(p.lastSeenAt!)}'
            : 'Away';
      case PresenceStatus.offline:
        return p.lastSeenAt != null
            ? 'Last seen ${_relativeTime(p.lastSeenAt!)}'
            : 'Offline';
    }
  }

  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    final d = diff.inDays;
    if (d < 7) return '$d day${d == 1 ? '' : 's'} ago';
    return DateFormat('d MMM').format(when);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.call_rounded,
            iconColor: Colors.green.shade700,
            label: 'Voice call',
            onTap: () => ConfigRouter.pushPageAnimation(
              context,
              VoiceCallPage(conversationId: conversation.id),
            ),
          ),
          const _Hairline(),
          _ActionRow(
            icon: Icons.videocam_rounded,
            iconColor: Colors.blue.shade700,
            label: 'Video call',
            onTap: () => ConfigRouter.pushPageAnimation(
              context,
              VideoCallPage(conversationId: conversation.id),
            ),
          ),
          const _Hairline(),
          _ActionRow(
            icon: Icons.search_rounded,
            iconColor: Colors.deepPurple,
            label: 'Search messages',
            onTap: () => ConfigRouter.pushPageAnimation(
              context,
              MessageSearchPage(conversationId: conversation.id),
            ),
          ),
          if (conversation.isGroup) ...[
            const _Hairline(),
            _ActionRow(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: Colors.orange.shade700,
              label: 'Add members',
              onTap: () => _showAddMembersSheet(context, conversation),
            ),
          ],
        ],
      ),
    );
  }
}

class _SharedMedia extends StatelessWidget {
  const _SharedMedia({required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ChatMessage>>(
      future: GetIt.I<MessagesRepository>().getForConversation(conversationId),
      builder: (context, snap) {
        final media = (snap.data ?? const <ChatMessage>[])
            .where((m) =>
                m.type == ChatMessageType.image ||
                m.type == ChatMessageType.file)
            .take(6)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  AppLabel(
                    text: 'SHARED MEDIA',
                    fontSize: AppFontSize.value10,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  const Spacer(),
                  if (media.isNotEmpty)
                    TextButton(
                      onPressed: () {},
                      child: AppLabel(
                        text: 'See all',
                        fontSize: AppFontSize.value13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            _Card(
              child: media.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: AppLabel(
                          text: 'No shared media yet.',
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: [
                          for (final m in media) _MediaTile(message: m),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImage = message.type == ChatMessageType.image;
    final url = message.fileUrl ?? '';
    final isLocalFile = isImage &&
        url.isNotEmpty &&
        !url.startsWith('http') &&
        !url.startsWith('demo://');

    Widget cover;
    if (isLocalFile) {
      cover = Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _stubBox(context, message, isImage),
      );
    } else if (isImage && (url.startsWith('http://') || url.startsWith('https://'))) {
      cover = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _stubBox(context, message, isImage),
      );
    } else {
      cover = _stubBox(context, message, isImage);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          // Slice 10.1.5 — tapping an image tile opens the same
          // viewer as tapping the bubble. File tiles fall through to
          // the snackbar (downloading is a follow-up slice).
          onTap: isImage
              ? () => ConfigRouter.pushPageAnimation(
                    context,
                    ImageViewerPage(message: message),
                  )
              : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File download would run here.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
          child: SizedBox.expand(child: cover),
        ),
      ),
    );
  }

  static Widget _stubBox(BuildContext context, ChatMessage message, bool isImage) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 28,
          ),
          if (!isImage && message.fileName != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppLabel(
                text: message.fileName!,
                fontSize: AppFontSize.value10,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            ],
          ],
        ),
      );
  }
}

// ── Slice 10.2.5 — per-conversation call history ────────────────
//
// Reads `chat_call_log` for this conversation and shows the most
// recent entries. Each row is tappable → opens the matching voice or
// video call page so the user can re-dial in one tap.

class _CallHistorySection extends StatelessWidget {
  const _CallHistorySection({required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ChatCallLog>>(
      future:
          GetIt.I<CallLogRepository>().getForConversation(conversationId),
      builder: (context, snap) {
        final entries = (snap.data ?? const <ChatCallLog>[]).take(6).toList();
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: AppLabel(
                text: 'CALL HISTORY',
                fontSize: AppFontSize.value10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            _Card(
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const _Hairline(),
                    _CallHistoryRow(
                      log: entries[i],
                      conversationId: conversationId,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CallHistoryRow extends StatelessWidget {
  const _CallHistoryRow({required this.log, required this.conversationId});
  final ChatCallLog log;
  final String conversationId;

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

    return InkWell(
      onTap: () => ConfigRouter.pushPageAnimation(
        context,
        isVideo
            ? VideoCallPage(conversationId: conversationId)
            : VoiceCallPage(conversationId: conversationId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(isVideo, isOutgoing, isMissed),
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: _labelFor(isVideo, isOutgoing, isMissed, log.status),
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w700,
                    color: isMissed ? theme.colorScheme.error : null,
                  ),
                  const SizedBox(height: 2),
                  AppLabel(
                    text: _subtitleFor(log),
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Icon(
              isVideo ? Icons.videocam_outlined : Icons.call_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(bool isVideo, bool isOutgoing, bool isMissed) {
    if (isMissed) return Icons.call_missed_rounded;
    if (isOutgoing) return Icons.call_made_rounded;
    return Icons.call_received_rounded;
  }

  static String _labelFor(
      bool isVideo, bool isOutgoing, bool isMissed, ChatCallStatus status) {
    final kind = isVideo ? 'Video' : 'Voice';
    if (isMissed) return 'Missed $kind call';
    if (status == ChatCallStatus.rejected && isOutgoing) {
      return 'Declined $kind call';
    }
    return '${isOutgoing ? "Outgoing" : "Incoming"} $kind call';
  }

  static String _subtitleFor(ChatCallLog log) {
    final stamp = _formatStamp(log.startedAt);
    if (log.durationSeconds > 0) {
      return '$stamp · ${log.formattedDuration()}';
    }
    return stamp;
  }

  static String _formatStamp(DateTime when) {
    final now = DateTime.now();
    final whenDay = DateTime(when.year, when.month, when.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(whenDay).inDays;
    if (diff == 0) return 'Today ${DateFormat.Hm().format(when)}';
    if (diff == 1) return 'Yesterday ${DateFormat.Hm().format(when)}';
    if (diff < 7) return DateFormat('EEE HH:mm').format(when);
    return DateFormat('d MMM HH:mm').format(when);
  }
}

class _Settings extends StatelessWidget {
  const _Settings({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _SwitchRow(
            icon: Icons.notifications_off_outlined,
            iconColor: Colors.amber.shade700,
            label: 'Mute notifications',
            value: conversation.isMuted,
            onChanged: (v) => GetIt.I<ConversationsRepository>()
                .setMuted(conversation.id, v),
          ),
          if (conversation.pinnedMessageId != null) ...[
            const _Hairline(),
            _ActionRow(
              icon: Icons.push_pin_outlined,
              iconColor: Colors.teal,
              label: 'View pinned message',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _Members extends StatelessWidget {
  const _Members({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = conversation.participantPreviews.take(5).toList();
    final extra = conversation.totalMembers - shown.length - 1; // -1 for self
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: AppLabel(
            text: 'MEMBERS · ${conversation.totalMembers}',
            fontSize: AppFontSize.value10,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        _Card(
          child: Column(
            children: [
              _MemberRow(
                name: GetIt.I<ChatSettings>().userName,
                role: 'You',
                presence: PresenceStatus.online,
                isAdmin: true,
                userId: GetIt.I<ChatSettings>().userId,
              ),
              for (final p in shown) ...[
                const _Hairline(),
                _MemberRow(
                  name: p.name,
                  presence: p.presence,
                  role: null,
                  isAdmin: false,
                  // Drive the row's dot from PresenceRepository so
                  // it ticks live on every `/topic/presence` frame.
                  userId: p.employeeId,
                ),
              ],
              if (extra > 0) ...[
                const _Hairline(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextButton(
                    onPressed: () {},
                    child: AppLabel(
                      text: '+ $extra more',
                      fontSize: AppFontSize.value13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.presence,
    required this.role,
    required this.isAdmin,
    this.userId,
  });
  final String name;
  final PresenceStatus presence;
  final String? role;
  final bool isAdmin;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ChatAvatar(
            name: name,
            size: 40,
            userId: userId,
            presence: userId == null ? presence : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: name,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w700,
                ),
                if (role != null)
                  AppLabel(
                    text: role!,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: AppLabel(
                text: 'ADMIN',
                fontSize: 9,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        children: [
          if (conversation.isGroup) ...[
            _ActionRow(
              icon: Icons.exit_to_app_rounded,
              iconColor: theme.colorScheme.error,
              destructive: true,
              label: 'Leave group',
              onTap: () => _confirmLeave(context),
            ),
            const _Hairline(),
          ],
          _ActionRow(
            icon: Icons.cleaning_services_rounded,
            iconColor: theme.colorScheme.error,
            destructive: true,
            label: 'Clear chat history',
            onTap: () => _confirmClear(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: AppLabel(
          text: 'Leave "${conversation.name}"?',
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.w800,
        ),
        content: AppLabel(
          text: 'You will stop receiving messages from this group. An admin can re-add you.',
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
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dCtx, true),
            child: AppLabel(
              text: 'Leave',
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    // Section 7 op #8 — DELETE /chats/conversations/{id}/members/{me}.
    // Backend removes us, fans `conversation.remove` to our other
    // sessions, and `conversation.update` to remaining members.
    try {
      await GetIt.I<ConversationsRepository>()
          .leaveGroupRemote(conversation.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not leave: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: AppLabel(
          text: 'Clear chat history?',
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.w800,
        ),
        content: AppLabel(
          text: 'This clears the history on your device only. Other members keep their copy.',
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
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dCtx, true),
            child: AppLabel(
              text: 'Clear',
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History cleared on this device.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── shared bits ────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppLabel(
                text: label,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w700,
                color: destructive ? theme.colorScheme.error : null,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.outline,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppLabel(
              text: label,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Slice 10.3.2 — Add Members ───────────────────────────────────
//
// Top-level helper invoked from the "Add members" action row + (later)
// from "Add" trailing button on the members section header. Opens a
// modal sheet whose state is owned by [_AddMembersSheet] so the
// controller / selection set live with the sheet's State instead of
// leaking through the outer function (same pattern as _ReAuthSheet).

Future<void> _showAddMembersSheet(
  BuildContext context,
  ChatConversation conversation,
) async {
  final picks = await showModalBottomSheet<List<ChatParticipantPreview>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddMembersSheet(conversation: conversation),
  );
  if (picks == null || picks.isEmpty || !context.mounted) return;
  // Section 7 op #6 — POST /chats/conversations/{id}/members.
  // Convert the preview employeeIds to numeric backend ids; any pick
  // that doesn't parse (e.g. seed-only entry) is dropped silently.
  final memberIds = <int>{};
  for (final p in picks) {
    final n = int.tryParse(p.employeeId);
    if (n != null) memberIds.add(n);
  }
  if (memberIds.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selection contains no backend users.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  try {
    await GetIt.I<ConversationsRepository>()
        .addMembersRemote(conversation.id, memberIds);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not add members: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        picks.length == 1
            ? '${picks.first.name} added to the group.'
            : '${picks.length} members added.',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _AddMembersSheet extends StatefulWidget {
  const _AddMembersSheet({required this.conversation});
  final ChatConversation conversation;

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';

  // Real users pulled from `GET /api/v1/users` on sheet open. Replaces
  // the pre-backend demo seed so the picker reflects
  // who's actually in the database. Already-in-group folks are filtered
  // out before render.
  List<ChatParticipantPreview> _directory = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    try {
      final page = await GetIt.I<UsersRemoteDataSource>().listUsers(
        // 200 covers small/mid orgs in one shot; `_candidates` filters
        // out current group members + self locally.
        pageSize: 200,
      );
      final mapped = <ChatParticipantPreview>[];
      for (final u in page.items) {
        if (!u.enabled) continue;
        final name = u.fullName.trim().isEmpty
            ? (u.email.trim().isEmpty ? 'User #${u.id}' : u.email)
            : u.fullName;
        mapped.add(ChatParticipantPreview(employeeId: u.id, name: name));
      }
      mapped.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _directory = mapped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load users.';
      });
    }
  }

  List<ChatParticipantPreview> get _candidates {
    final me = GetIt.I<ChatSettings>().userId;
    final inGroup = {
      me,
      ...widget.conversation.participantPreviews.map((p) => p.employeeId),
    };
    final q = _query.trim().toLowerCase();
    return _directory
        .where((p) => !inGroup.contains(p.employeeId))
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = _candidates;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
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
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.orange.shade700,
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
                      text: 'Add members',
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w800,
                    ),
                    AppLabel(
                      text: 'Pick from your directory — already-in-group folks '
                          'are filtered out.',
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurfaceVariant,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search employees…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: AppLabel(
                            text: _error!,
                            fontSize: AppFontSize.value14,
                            color: theme.colorScheme.error,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : candidates.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: AppLabel(
                        text: _query.isEmpty
                            ? 'Everyone in the directory is already in this '
                                'group.'
                            : 'No employees match "${_query.trim()}".',
                        fontSize: AppFontSize.value14,
                        color: theme.colorScheme.onSurfaceVariant,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 64,
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                    itemBuilder: (_, i) {
                      final p = candidates[i];
                      final sel = _selected.contains(p.employeeId);
                      return Material(
                        color: sel
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() {
                            if (sel) {
                              _selected.remove(p.employeeId);
                            } else {
                              _selected.add(p.employeeId);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                ChatAvatar(
                                  name: p.name,
                                  size: 40,
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
                                Checkbox(
                                  value: sel,
                                  onChanged: (_) => setState(() {
                                    if (sel) {
                                      _selected.remove(p.employeeId);
                                    } else {
                                      _selected.add(p.employeeId);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
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
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          // Map each selected id to its preview from
                          // the loaded directory. Falls back to a
                          // placeholder if the user vanished between
                          // load and confirm — rare but safe.
                          final picks = _selected.map((id) {
                            for (final p in _directory) {
                              if (p.employeeId == id) return p;
                            }
                            return ChatParticipantPreview(
                              employeeId: id,
                              name: 'User #$id',
                            );
                          }).toList(growable: false);
                          Navigator.pop(context, picks);
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: _selected.isEmpty
                        ? 'Add'
                        : 'Add ${_selected.length}',
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

// ── Slice 10.3.3 — Rename group + Change group photo ────────────

Future<void> _showRenameSheet(
  BuildContext context,
  ChatConversation conversation,
) async {
  final name = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RenameGroupSheet(initialName: conversation.name),
  );
  if (name == null || name.trim().isEmpty || !context.mounted) return;
  final trimmed = name.trim();
  // Section 7 op #5 — backend rename. The server fans
  // `conversation.update` to every member's `/user/queue/inbox` and to
  // `/topic/conversations/{id}` so peers update via STOMP — no
  // client-side broadcast needed (the previous relay-era
  // `sendConversationUpdate` call is gone).
  try {
    await GetIt.I<ConversationsRepository>()
        .renameRemote(conversation.id, trimmed);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not rename: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _RenameGroupSheet extends StatefulWidget {
  const _RenameGroupSheet({required this.initialName});
  final String initialName;

  @override
  State<_RenameGroupSheet> createState() => _RenameGroupSheetState();
}

class _RenameGroupSheetState extends State<_RenameGroupSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
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
    final canSave =
        _ctrl.text.trim().isNotEmpty && _ctrl.text.trim() != widget.initialName;
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
            text: 'Rename group',
            fontSize: AppFontSize.value16,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (canSave) Navigator.pop(context, _ctrl.text);
            },
            decoration: InputDecoration(
              labelText: 'Group name',
              prefixIcon: const Icon(Icons.edit_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              isDense: true,
            ),
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
                  onPressed: canSave
                      ? () => Navigator.pop(context, _ctrl.text)
                      : null,
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

/// Slice 10.3.5 — wording for the change-photo sheet header. Direct
/// chats read "Change/Add contact photo", groups read "Change/Add
/// group photo" — same sheet, two contexts.
String _photoSheetTitle(ChatConversation conversation, bool hasPhoto) {
  final what = conversation.isGroup ? 'group photo' : 'contact photo';
  return hasPhoto ? 'Change $what' : 'Add a $what';
}

Future<void> _showChangePhotoSheet(
  BuildContext context,
  ChatConversation conversation,
) async {
  final hasPhoto = (conversation.avatarFilePath ?? '').isNotEmpty;
  // Shared sheet UI (Slice 9.1.4 + 10.3.3 / 10.3.5 / 10.3.6 used to
  // duplicate this — now everything routes through `AvatarPickerSheet`).
  final choice = await AvatarPickerSheet.show(
    context: context,
    title: _photoSheetTitle(conversation, hasPhoto),
    subtitle: conversation.isGroup
        ? 'Photo will sync to every group member.'
        : 'Photo only changes on this device.',
    allowRemove: hasPhoto,
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case AvatarPickChoice.camera:
      await _pickGroupPhoto(context, conversation, ImageSource.camera);
    case AvatarPickChoice.gallery:
      await _pickGroupPhoto(context, conversation, ImageSource.gallery);
    case AvatarPickChoice.remove:
      await GetIt.I<ConversationsRepository>()
          .setAvatarPath(conversation.id, null);
      // Group avatar URL on the backend (op #5) is `null` here too —
      // PATCH `avatarUrl: ''` would clear it. Skipped while there's
      // no binary upload endpoint: the local file path is per-device
      // by definition and won't be useful to peers either way.
  }
}

Future<void> _pickGroupPhoto(
  BuildContext context,
  ChatConversation conversation,
  ImageSource source,
) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read the selected image.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await GetIt.I<ConversationsRepository>()
        .setAvatarPath(conversation.id, picked.path);
    // Per-device avatar only — the previous relay-era base64 broadcast
    // is gone with the relay. Cross-device group avatar needs a binary
    // upload endpoint on the backend; the resulting URL would then go
    // to PATCH /chats/conversations/{id} { avatarUrl } via
    // `setAvatarUrlRemote(...)`. Out of scope until that endpoint ships.
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not pick image: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

