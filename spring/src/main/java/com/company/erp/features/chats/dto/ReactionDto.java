package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.MessageReaction;

public record ReactionDto(
        Long userId,
        String emoji
) {
    public static ReactionDto from(MessageReaction r) {
        return new ReactionDto(r.getId().getUserId(), r.getId().getEmoji());
    }
}
