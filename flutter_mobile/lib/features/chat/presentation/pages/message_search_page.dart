import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../data/repositories/messages_repository.dart';
import '../../entities/chat_message.dart';
import '../../entities/conversation.dart';
import '../widgets/chat_avatar.dart';
import 'chat_conversation_page.dart';

/// Slice 10.1.4 — Message Search.
///
/// When [conversationId] is null, runs a local in-memory search over
/// every loaded message (Telegram-style global archive lookup).
/// When set, calls the backend's
/// `GET /chats/conversations/{id}/messages/search?q=` instead — server
/// authoritative, case-insensitive substring over the full server-side
/// history of that one conversation.
class MessageSearchPage extends StatefulWidget {
  const MessageSearchPage({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends State<MessageSearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search messages…',
              border: InputBorder.none,
              isDense: true,
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _ctrl,
                builder: (_, value, __) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            FutureBuilder<List<ChatMessage>>(
              future: widget.conversationId != null
                  ? GetIt.I<MessagesRepository>().searchInConversation(
                      widget.conversationId!,
                      _query,
                    )
                  : GetIt.I<MessagesRepository>().search(_query),
              builder: (context, snap) {
                if (_query.trim().isEmpty) {
                  return _Hint(
                    icon: Icons.search_rounded,
                    text: widget.conversationId != null
                        ? 'Search this conversation\'s messages.'
                        : 'Search every conversation for text, file names, or @mentions.',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = snap.data!;
                if (results.isEmpty) {
                  return _Hint(
                    icon: Icons.search_off_rounded,
                    text: 'No messages match "${_query.trim()}".',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final m = results[i];
                    return _ResultTile(
                      message: m,
                      query: _query,
                    )
                        .animate()
                        .fadeIn(delay: (i * 25).clamp(0, 240).ms)
                        .slideY(begin: 0.04, end: 0, duration: 260.ms);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.message, required this.query});
  final ChatMessage message;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () async {
          // Resolve the conversation name for context.
          await ConfigRouter.pushPageAnimation(
            context,
            ChatConversationPage(conversationId: message.conversationId),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatAvatar(name: message.senderName, size: 40, showStatus: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppLabel(
                            text: message.senderName,
                            fontSize: AppFontSize.value14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        AppLabel(
                          text: DateFormat('d MMM HH:mm').format(message.sentAt),
                          fontSize: AppFontSize.value11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<ChatConversation?>(
                      future: GetIt.I<ConversationsRepository>()
                          .findById(message.conversationId),
                      builder: (context, snap) {
                        final conv = snap.data;
                        if (conv == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                conv.isGroup
                                    ? Icons.group_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              AppLabel(
                                text: conv.name,
                                fontSize: AppFontSize.value11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _HighlightedPreview(
                      body: message.body ?? message.fileName ?? '(media)',
                      query: query,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedPreview extends StatelessWidget {
  const _HighlightedPreview({required this.body, required this.query});
  final String body;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = query.trim();
    if (q.isEmpty) {
      return AppLabel(
        text: body,
        fontSize: AppFontSize.value14,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lower = body.toLowerCase();
    final ql = q.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (i < body.length) {
      final hit = lower.indexOf(ql, i);
      if (hit == -1) {
        spans.add(TextSpan(text: body.substring(i)));
        break;
      }
      if (hit > i) spans.add(TextSpan(text: body.substring(i, hit)));
      spans.add(
        TextSpan(
          text: body.substring(hit, hit + q.length),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            backgroundColor: theme.colorScheme.primaryContainer
                .withValues(alpha: 0.5),
          ),
        ),
      );
      i = hit + q.length;
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          AppLabel(
            text: text,
            fontSize: AppFontSize.value14,
            color: theme.colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
