import '../entities/chat_message.dart';
import '../entities/conversation.dart';
import 'users_cache.dart';

/// Resolve a display name + avatar for [userId] by consulting the
/// in-memory [UsersCache] (populated from `/users` and `/users/me`).
/// Falls back to a `User #<id>` placeholder when the cache hasn't
/// learned about the user yet — guarantees a non-empty
/// [ChatParticipantPreview.name] so [ChatAvatar] never renders "?".
///
/// Lives in this file because both `messageFromDto` and
/// `conversationFromDto` need it and there's nowhere else sensible.
ChatParticipantPreview _resolveParticipant(String userId) {
  final cachedName = UsersCache.instance.nameOf(userId);
  if (cachedName != null) {
    return ChatParticipantPreview(
      employeeId: userId,
      name: cachedName,
      avatarUrl: UsersCache.instance.avatarOf(userId),
    );
  }
  return ChatParticipantPreview(employeeId: userId, name: 'User #$userId');
}

/// Shared mapping helpers between Spring DTOs (JSON maps coming from
/// REST + STOMP) and the project's existing chat entities
/// (`ChatMessage`, `ChatConversation`, `ChatParticipantPreview`).
///
/// Lives in one place so the transport (decoding STOMP frames) and
/// the repositories (decoding REST responses) agree on:
///   - which JSON key wins under multiple aliases
///   - how Long ids are stringified
///   - which fields fall back to seed-data defaults when the backend
///     doesn't surface them yet (display name, avatar URL, presence)
///
/// All maps are tolerant of missing/null fields — production payloads
/// can drop optional fields silently and we won't crash.

// ────────────────────────────────────────────────────────────────────
// Messages
// ────────────────────────────────────────────────────────────────────

ChatMessage messageFromDto(Map<String, dynamic> json) {
  final type = (json['type'] as String? ?? 'TEXT').toUpperCase();
  final mapped = switch (type) {
    'IMAGE' => ChatMessageType.image,
    'VOICE' => ChatMessageType.voice,
    'FILE' => ChatMessageType.file,
    'SYSTEM' => ChatMessageType.system,
    _ => ChatMessageType.text,
  };

  // Reactions ship as `[{userId, emoji}]` — collapse into the
  // existing per-emoji bucket shape `{emoji, employeeIds}`.
  final reactions = <ChatReaction>[];
  final reactionsRaw = json['reactions'];
  if (reactionsRaw is List) {
    final byEmoji = <String, List<String>>{};
    for (final r in reactionsRaw) {
      if (r is! Map) continue;
      final emoji = r['emoji']?.toString();
      final uid = r['userId']?.toString();
      if (emoji == null || uid == null) continue;
      byEmoji.putIfAbsent(emoji, () => <String>[]).add(uid);
    }
    for (final entry in byEmoji.entries) {
      reactions.add(ChatReaction(emoji: entry.key, employeeIds: entry.value));
    }
  }

  // Sender display name + avatar resolved via the shared
  // [UsersCache] (populated from `/users` + `/users/me`). Falls
  // back to a `User #<id>` placeholder when the cache hasn't seen
  // this user yet.
  final senderIdStr = json['senderId'].toString();
  final senderPreview = _resolveParticipant(senderIdStr);

  // Read receipts — server ships `readByUserIds: [Long, …]`; convert
  // to a Set<String> for the bubble's tick logic to consult.
  final readBy = <String>{};
  final readByRaw = json['readByUserIds'];
  if (readByRaw is List) {
    for (final v in readByRaw) {
      if (v != null) readBy.add(v.toString());
    }
  }

  return ChatMessage(
    id: json['id'].toString(),
    conversationId: json['conversationId'].toString(),
    senderId: senderIdStr,
    senderName: senderPreview.name,
    senderAvatarUrl: senderPreview.avatarUrl,
    type: mapped,
    sentAt: _parseInstant(json['createdAt']) ?? DateTime.now(),
    body: json['body'] as String?,
    replyToId: json['replyToMessageId']?.toString(),
    replyToSenderName: null,
    replyToPreview: null,
    editedAt: _parseInstant(json['editedAt']),
    isDeleted: json['deleted'] as bool? ?? false,
    fileUrl: mapped == ChatMessageType.voice
        ? null
        : json['attachmentUrl'] as String?,
    fileName: null,
    fileSizeBytes: (json['attachmentSizeBytes'] as num?)?.toInt(),
    voiceUrl: mapped == ChatMessageType.voice
        ? json['attachmentUrl'] as String?
        : null,
    voiceDurationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    reactions: reactions,
    readByUserIds: readBy,
  );
}

// ────────────────────────────────────────────────────────────────────
// Conversations
// ────────────────────────────────────────────────────────────────────

/// Map a Spring `ConversationDto` JSON onto the existing
/// [ChatConversation] entity used by the inbox + chat pages.
///
/// [currentUserId] is needed so we can compute:
///   - the conversation's display [name] for direct conversations
///     (the OTHER participant's name; backend ships `name=null` for
///     direct convs since there's no group title)
///   - `participantPreviews` excluding self (matches the seed-era
///     convention; the AppBar member count uses `totalMembers`)
ChatConversation conversationFromDto(
  Map<String, dynamic> json, {
  required String currentUserId,
}) {
  final id = json['id'].toString();
  final typeRaw = (json['type'] as String? ?? 'DIRECT').toUpperCase();
  final isGroup = typeRaw == 'GROUP';

  // Build participant previews from the members[] array; resolve
  // display name + avatar + presence via the local seed because
  // backend's MemberDto only carries `userId, role, muted, lastReadMessageId`.
  final previews = <ChatParticipantPreview>[];
  String? otherDisplayName;
  PresenceStatus directPresence = PresenceStatus.offline;

  final membersRaw = json['members'];
  if (membersRaw is List) {
    for (final m in membersRaw) {
      if (m is! Map) continue;
      final uid = m['userId']?.toString();
      if (uid == null) continue;
      if (uid == currentUserId) continue;
      // Backend ships per-member `lastReadMessageId` (the highest msg
      // id this member has read). Threaded onto the preview so the
      // chat bubble's read-tick can compute who has caught up.
      final lastReadId = m['lastReadMessageId']?.toString();
      final p = _resolveParticipant(uid).copyWith(
        lastReadMessageId: lastReadId,
      );
      previews.add(p);
      otherDisplayName ??= p.name;
      if (!isGroup) directPresence = p.presence;
    }
  }

  final lastMessage = json['lastMessage'];
  String? lastBody;
  String? lastSenderId;
  String? lastSenderName;
  String lastType = 'text';
  if (lastMessage is Map) {
    lastBody = lastMessage['body'] as String?;
    lastSenderId = lastMessage['senderId']?.toString();
    if (lastSenderId != null) {
      lastSenderName = _resolveParticipant(lastSenderId).name;
    }
    final lastTypeRaw = (lastMessage['type'] as String? ?? 'TEXT').toUpperCase();
    lastType = switch (lastTypeRaw) {
      'VOICE' => 'voice',
      'IMAGE' => 'image',
      'FILE' => 'file',
      'SYSTEM' => 'system',
      _ => 'text',
    };
  }

  final lastAt = _parseInstant(json['lastMessageAt']);
  final createdAt = _parseInstant(json['createdAt']) ?? DateTime.now();

  final name = isGroup
      ? (json['name'] as String? ?? '')
      : (otherDisplayName ?? json['name'] as String? ?? '');

  final unread = (json['unreadCount'] as num?)?.toInt() ?? 0;

  final onlineCount = previews
      .where((p) => p.presence == PresenceStatus.online)
      .length;

  return ChatConversation(
    id: id,
    name: name,
    isGroup: isGroup,
    isMuted: false, // backend ships `muted` per-MEMBER, not per-conv
    unreadCount: unread,
    createdAt: createdAt,
    updatedAt: lastAt ?? createdAt,
    avatarUrl: json['avatarUrl'] as String?,
    avatarFilePath: null,
    lastMessageBody: lastBody,
    lastMessageSenderId: lastSenderId,
    lastMessageSenderName: lastSenderName,
    lastMessageAt: lastAt,
    lastMessageType: lastType,
    presence: directPresence,
    pinnedMessageId: null,
    participantPreviews: previews,
    onlineCount: onlineCount,
    totalMembers: (membersRaw is List ? membersRaw.length : 0),
  );
}

// ────────────────────────────────────────────────────────────────────
// Misc
// ────────────────────────────────────────────────────────────────────

DateTime? _parseInstant(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
