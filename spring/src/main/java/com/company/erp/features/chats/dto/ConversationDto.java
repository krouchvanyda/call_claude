package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.Conversation;
import com.company.erp.features.chats.entity.ConversationType;

import java.time.Instant;
import java.util.List;

public record ConversationDto(
        Long id,
        ConversationType type,
        String name,
        String avatarUrl,
        List<MemberDto> members,
        MessageDto lastMessage,
        Instant lastMessageAt,
        Long unreadCount,
        Instant createdAt
) {
    public static ConversationDto from(Conversation c,
                                       List<MemberDto> members,
                                       MessageDto lastMessage,
                                       Long unreadCount) {
        return new ConversationDto(
                c.getId(),
                c.getType(),
                c.getName(),
                c.getAvatarUrl(),
                members,
                lastMessage,
                c.getLastMessageAt(),
                unreadCount,
                c.getCreatedAt());
    }
}
