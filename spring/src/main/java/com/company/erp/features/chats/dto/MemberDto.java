package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.ConversationMember;
import com.company.erp.features.chats.entity.MemberRole;

public record MemberDto(
        Long userId,
        MemberRole role,
        boolean muted,
        Long lastReadMessageId
) {
    public static MemberDto from(ConversationMember m) {
        return new MemberDto(m.getUserId(), m.getRole(), m.isMuted(), m.getLastReadMessageId());
    }
}
