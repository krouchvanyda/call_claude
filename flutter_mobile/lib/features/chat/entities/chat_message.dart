/// Slice 10.1.2 — message kind. Drives bubble variant + inbox preview.
enum ChatMessageType { text, voice, image, file, system }

/// Per-emoji reaction tally + the employee ids that reacted with it.
class ChatReaction {
  const ChatReaction({required this.emoji, required this.employeeIds});

  final String emoji;
  final List<String> employeeIds;

  int get count => employeeIds.length;

  ChatReaction copyWith({String? emoji, List<String>? employeeIds}) =>
      ChatReaction(
        emoji: emoji ?? this.emoji,
        employeeIds: employeeIds ?? this.employeeIds,
      );
}

/// Slice 10.1.2 — single message row.
///
/// Mirrors `chat_messages` (id, conversation_id, sender_id, body, type,
/// reply_to_id, edited_*, is_deleted, file_*, voice_*, sent/delivered/read_at,
/// reactions JSON). Pure data — Flutter-free.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.sentAt,
    this.body,
    this.replyToId,
    this.replyToSenderName,
    this.replyToPreview,
    this.editedAt,
    this.isDeleted = false,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.voiceUrl,
    this.voiceDurationSeconds,
    this.deliveredAt,
    this.readAt,
    this.reactions = const <ChatReaction>[],
    this.senderAvatarUrl,
    this.isPinned = false,
    this.readByUserIds = const <String>{},
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final ChatMessageType type;
  final DateTime sentAt;

  /// Text body — non-null for text / system messages; null for media.
  final String? body;

  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToPreview;

  /// `null` until the user edits. Once set the bubble renders an
  /// "(edited)" label in its footer.
  final DateTime? editedAt;

  /// Soft delete — the row stays but the bubble renders "Message
  /// deleted" italic placeholder. Reactions and replies become noops.
  final bool isDeleted;

  // Attachment fields.
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? voiceUrl;
  final int? voiceDurationSeconds;

  // Receipts.
  final DateTime? deliveredAt;
  final DateTime? readAt;

  final List<ChatReaction> reactions;

  /// User ids that have read up to (and including) this message — comes
  /// from the backend's `MessageDto.readByUserIds`. The chat bubble's
  /// read-receipt drives its tick state from this set: empty → single
  /// `done`; non-empty but missing one or more expected readers →
  /// grey `done_all`; all expected readers present → blue `done_all`.
  /// Inbound `message.read` STOMP events patch this set in place.
  final Set<String> readByUserIds;

  /// Pinned by an admin — rendered as the conversation's pinned banner.
  final bool isPinned;

  bool get isOwn => false; // overlay flag is computed in the page layer

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    ChatMessageType? type,
    DateTime? sentAt,
    String? body,
    String? replyToId,
    String? replyToSenderName,
    String? replyToPreview,
    DateTime? editedAt,
    bool? isDeleted,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? voiceUrl,
    int? voiceDurationSeconds,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<ChatReaction>? reactions,
    bool? isPinned,
    Set<String>? readByUserIds,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
        type: type ?? this.type,
        sentAt: sentAt ?? this.sentAt,
        body: body ?? this.body,
        replyToId: replyToId ?? this.replyToId,
        replyToSenderName: replyToSenderName ?? this.replyToSenderName,
        replyToPreview: replyToPreview ?? this.replyToPreview,
        editedAt: editedAt ?? this.editedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        voiceUrl: voiceUrl ?? this.voiceUrl,
        voiceDurationSeconds:
            voiceDurationSeconds ?? this.voiceDurationSeconds,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        reactions: reactions ?? this.reactions,
        isPinned: isPinned ?? this.isPinned,
        readByUserIds: readByUserIds ?? this.readByUserIds,
      );
}
