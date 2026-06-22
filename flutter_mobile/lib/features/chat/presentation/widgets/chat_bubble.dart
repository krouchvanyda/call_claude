import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../entities/chat_message.dart';
import 'chat_avatar.dart';

/// Slice 10.1.2 — chat bubble rendering all four content types
/// (text / voice / image / file) plus reply quotes, edited label, and
/// own-message read receipts. System messages render as italic
/// centered captions (no bubble).
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.showSender,
    required this.currentUserId,
    this.onReact,
    this.onLongPress,
    this.onJumpToReply,
    this.onTapVoice,
    this.onTapImage,
    this.isVoicePlaying = false,
    this.highlight = false,
    this.expectedReaderIds = const <String>{},
  });

  final ChatMessage message;
  final bool isOwn;
  final bool showSender;
  final String currentUserId;
  final void Function(String emoji)? onReact;
  final VoidCallback? onLongPress;
  final void Function(String messageId)? onJumpToReply;
  final VoidCallback? onTapVoice;

  /// Slice 10.1.5 — invoked when the user taps an image bubble.
  /// The conversation page wires this to push [ImageViewerPage].
  final VoidCallback? onTapImage;
  final bool isVoicePlaying;
  final bool highlight;

  /// Every conversation member EXCEPT us — the set the read-receipt
  /// tick treats as "expected readers". For a direct chat that's one
  /// id; for a group it's everyone else. Empty when the conv hasn't
  /// hydrated yet — the tick falls back to single-check sent state.
  final Set<String> expectedReaderIds;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system) {
      return _SystemCaption(message: message);
    }
    final theme = Theme.of(context);
    final align = isOwn ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSender && !isOwn)
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: 4),
                child: AppLabel(
                  text: message.senderName,
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isOwn) _LeadingAvatar(message: message, show: showSender),
                if (!isOwn) const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onLongPress: onLongPress,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: _bubbleColor(theme),
                        borderRadius: _bubbleRadius(),
                        border: highlight
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                        boxShadow: highlight
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: _bubbleRadius(),
                        child: Padding(
                          padding: _bubblePadding(),
                          child: _BubbleContent(
                            message: message,
                            isOwn: isOwn,
                            onJumpToReply: onJumpToReply,
                            onTapVoice: onTapVoice,
                            onTapImage: onTapImage,
                            isVoicePlaying: isVoicePlaying,
                            expectedReaderIds: expectedReaderIds,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isOwn ? 0 : 44,
                  right: isOwn ? 4 : 0,
                ),
                child: _ReactionRow(
                  reactions: message.reactions,
                  currentUserId: currentUserId,
                  onReact: onReact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _bubbleColor(ThemeData theme) {
    if (message.isDeleted) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    }
    if (isOwn) return theme.colorScheme.primary;
    return theme.colorScheme.surface;
  }

  EdgeInsets _bubblePadding() {
    if (message.type == ChatMessageType.image && !message.isDeleted) {
      return const EdgeInsets.all(4);
    }
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  }

  BorderRadius _bubbleRadius() {
    const r = AppRadii.lg;
    if (isOwn) {
      return const BorderRadius.only(
        topLeft: Radius.circular(r),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(r),
        bottomRight: Radius.circular(r),
      );
    }
    return const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(r),
      bottomLeft: Radius.circular(r),
      bottomRight: Radius.circular(r),
    );
  }
}

class _LeadingAvatar extends StatelessWidget {
  const _LeadingAvatar({required this.message, required this.show});
  final ChatMessage message;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox(width: 36);
    return ChatAvatar(
      name: message.senderName,
      size: 36,
      // Show a live presence dot for the sender of incoming bubbles
      // so group chats surface who's online without having to open
      // the chat info page.
      userId: message.senderId,
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.isOwn,
    required this.onJumpToReply,
    required this.onTapVoice,
    required this.onTapImage,
    required this.isVoicePlaying,
    this.expectedReaderIds = const <String>{},
  });
  final ChatMessage message;
  final bool isOwn;
  final void Function(String messageId)? onJumpToReply;
  final VoidCallback? onTapVoice;
  final VoidCallback? onTapImage;
  final bool isVoicePlaying;
  final Set<String> expectedReaderIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.isDeleted) {
      return AppLabel(
        text: 'Message deleted',
        fontSize: AppFontSize.value14,
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.replyToId != null)
          _ReplyQuote(message: message, isOwn: isOwn, onTap: onJumpToReply),
        switch (message.type) {
          ChatMessageType.text => _TextContent(message: message, isOwn: isOwn),
          ChatMessageType.voice => _VoiceContent(
              message: message,
              isOwn: isOwn,
              isPlaying: isVoicePlaying,
              onTap: onTapVoice,
            ),
          ChatMessageType.image =>
            _ImageContent(message: message, onTap: onTapImage),
          ChatMessageType.file => _FileContent(message: message, isOwn: isOwn),
          ChatMessageType.system => const SizedBox.shrink(),
        },
        const SizedBox(height: 4),
        _BubbleFooter(
          message: message,
          isOwn: isOwn,
          expectedReaderIds: expectedReaderIds,
        ),
      ],
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.message,
    required this.isOwn,
    required this.onTap,
  });
  final ChatMessage message;
  final bool isOwn;
  final void Function(String messageId)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.primary;
    final bg = isOwn
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.12)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (message.replyToId != null && onTap != null) {
            onTap!(message.replyToId!);
          }
        },
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border(left: BorderSide(color: fg, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLabel(
                text: message.replyToSenderName ?? '',
                fontSize: AppFontSize.value11,
                color: fg,
                fontWeight: FontWeight.w800,
              ),
              const SizedBox(height: 2),
              AppLabel(
                text: message.replyToPreview ?? '',
                fontSize: AppFontSize.value12,
                color: isOwn
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurfaceVariant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  const _TextContent({required this.message, required this.isOwn});
  final ChatMessage message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppLabel(
      text: message.body ?? '',
      fontSize: AppFontSize.value14,
      color: isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      lineHeight: 1.35,
    );
  }
}

class _VoiceContent extends StatelessWidget {
  const _VoiceContent({
    required this.message,
    required this.isOwn,
    required this.isPlaying,
    required this.onTap,
  });
  final ChatMessage message;
  final bool isOwn;
  final bool isPlaying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.primary;
    final bg = isOwn
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
    final duration = message.voiceDurationSeconds ?? 0;
    final minutes = (duration ~/ 60).toString();
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: fg,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          _Waveform(
            isOwn: isOwn,
            isPlaying: isPlaying,
            color: fg,
          ),
          const SizedBox(width: 10),
          AppLabel(
            text: '$minutes:$seconds',
            fontSize: AppFontSize.value12,
            color: isOwn
                ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.isOwn,
    required this.isPlaying,
    required this.color,
  });
  final bool isOwn;
  final bool isPlaying;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Static silhouette — real waveform would come from the audio file.
    const heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.7, 0.5, 0.9, 0.3, 0.6, 0.4, 0.5];
    return SizedBox(
      width: 110,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < heights.length; i++)
            Container(
              width: 3,
              height: 22 * heights[i],
              decoration: BoxDecoration(
                color: color.withValues(alpha: isPlaying ? 0.95 : 0.55),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.message, this.onTap});
  final ChatMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = message.fileUrl ?? '';
    final isLocalFile = url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('demo://');
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');

    Widget surface;
    if (isLocalFile) {
      // Slice 10.1.5 — local thumbnail when the user picked the image
      // via image_picker (`fileUrl` is then the absolute file path).
      surface = Image.file(
        File(url),
        width: 220,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _stubBox(theme, message),
      );
    } else if (isNetwork) {
      surface = Image.network(
        url,
        width: 220,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _stubBox(theme, message),
      );
    } else {
      surface = _stubBox(theme, message);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: surface,
        ),
      ),
    );
  }

  static Widget _stubBox(ThemeData theme, ChatMessage message) {
    return Container(
      width: 220,
      height: 160,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 40,
          ),
          const SizedBox(height: 6),
          AppLabel(
            text: message.fileName ?? 'photo',
            fontSize: AppFontSize.value12,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  const _FileContent({required this.message, required this.isOwn});
  final ChatMessage message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final muted = isOwn
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant;
    final iconBg = isOwn
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.18)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(
            Icons.insert_drive_file_outlined,
            color: fg,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLabel(
                text: message.fileName ?? 'file',
                fontSize: AppFontSize.value14,
                color: fg,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AppLabel(
                text: _fileSize(message.fileSizeBytes),
                fontSize: AppFontSize.value12,
                color: muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unit]}';
  }
}

class _BubbleFooter extends StatelessWidget {
  const _BubbleFooter({
    required this.message,
    required this.isOwn,
    this.expectedReaderIds = const <String>{},
  });
  final ChatMessage message;
  final bool isOwn;
  final Set<String> expectedReaderIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOwn
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant;
    final df = DateFormat('HH:mm');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.editedAt != null) ...[
          AppLabel(
            text: 'edited · ',
            fontSize: AppFontSize.value10,
            color: color,
            fontStyle: FontStyle.italic,
          ),
        ],
        AppLabel(
          text: df.format(message.sentAt),
          fontSize: AppFontSize.value10,
          color: color,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        if (isOwn) ...[
          const SizedBox(width: 4),
          _ReadReceipt(
            message: message,
            color: color,
            expectedReaderIds: expectedReaderIds,
          ),
        ],
      ],
    );
  }
}

class _ReadReceipt extends StatelessWidget {
  const _ReadReceipt({
    required this.message,
    required this.color,
    this.expectedReaderIds = const <String>{},
  });
  final ChatMessage message;
  final Color color;

  /// Conversation members EXCEPT us — fed in by [ChatBubble] from the
  /// live conv. Direct chat: one id; group: everyone else. Empty when
  /// the conv hasn't hydrated yet (rare race) — we fall back to the
  /// legacy [ChatMessage.readAt] / [deliveredAt] flags.
  final Set<String> expectedReaderIds;

  @override
  Widget build(BuildContext context) {
    // All tick states render in the same footer color — read vs
    // unread is communicated by the icon (single ✓ vs double ✓✓),
    // not by a colour shift. Optimistic / in-flight messages use
    // the clock icon, also in footer color.
    //
    //   ✓✓  — message is sent AND at least one expected reader has
    //         read it (or it was marked delivered server-side).
    //   ✓   — sent but no one has read yet (or expectedReaderIds
    //         hasn't hydrated and we have no readAt/deliveredAt).
    //   ⏱   — pending — no canonical id yet (POST in flight).
    final readBy = message.readByUserIds;
    if (expectedReaderIds.isNotEmpty) {
      final anyRead = readBy.isNotEmpty;
      return Icon(
        anyRead ? Icons.done_all : Icons.done,
        size: 14,
        color: color,
      );
    }

    // Fallback when expectedReaderIds isn't supplied (conv not loaded
    // yet, legacy callers): keep the pre-readByUserIds behaviour.
    if (message.readAt != null || message.deliveredAt != null) {
      return Icon(Icons.done_all, size: 14, color: color);
    }
    return Icon(Icons.access_time_rounded, size: 12, color: color);
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({
    required this.reactions,
    required this.currentUserId,
    this.onReact,
  });
  final List<ChatReaction> reactions;
  final String currentUserId;
  final void Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final r in reactions)
          InkWell(
            onTap: onReact == null ? null : () => onReact!(r.emoji),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: r.employeeIds.contains(currentUserId)
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: r.employeeIds.contains(currentUserId)
                      ? theme.colorScheme.primary.withValues(alpha: 0.6)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLabel(
                    text: r.emoji,
                    fontSize: AppFontSize.value13,
                  ),
                  const SizedBox(width: 4),
                  AppLabel(
                    text: '${r.count}',
                    fontSize: AppFontSize.value11,
                    color: r.employeeIds.contains(currentUserId)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SystemCaption extends StatelessWidget {
  const _SystemCaption({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Center(
        child: AppLabel(
          text: message.body ?? '',
          fontSize: AppFontSize.value12,
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Date separator chip used between bubbles when the calendar day changes.
class DateSeparatorChip extends StatelessWidget {
  const DateSeparatorChip({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: AppLabel(
            text: _label(day),
            fontSize: AppFontSize.value11,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  static String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('EEE d MMM yyyy').format(d);
  }
}
