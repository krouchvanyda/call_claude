package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.Message;
import com.company.erp.features.chats.entity.MessageType;

import java.time.Instant;
import java.util.List;
import java.util.Set;

public record MessageDto(
        Long id,
        Long conversationId,
        Long senderId,
        MessageType type,
        String body,
        String attachmentUrl,
        String attachmentContentType,
        Long attachmentSizeBytes,
        Integer durationSeconds,
        Long replyToMessageId,
        Instant editedAt,
        boolean deleted,
        List<ReactionDto> reactions,
        /**
         * User ids of conversation members (other than the sender) whose
         * {@code lastReadMessageId} is {@code >=} this message's id.
         * Derived at read time — no separate reads table.
         */
        Set<Long> readByUserIds,
        Instant createdAt
) {
    public static MessageDto from(Message m, List<ReactionDto> reactions) {
        return from(m, reactions, Set.of());
    }

    public static MessageDto from(Message m, List<ReactionDto> reactions, Set<Long> readByUserIds) {
        return new MessageDto(
                m.getId(),
                m.getConversationId(),
                m.getSenderId(),
                m.getType(),
                m.isDeleted() ? null : m.getBody(),
                m.isDeleted() ? null : m.getAttachmentUrl(),
                m.isDeleted() ? null : m.getAttachmentContentType(),
                m.isDeleted() ? null : m.getAttachmentSizeBytes(),
                m.isDeleted() ? null : m.getDurationSeconds(),
                m.getReplyToMessageId(),
                m.getEditedAt(),
                m.isDeleted(),
                reactions,
                readByUserIds,
                m.getCreatedAt());
    }
}
