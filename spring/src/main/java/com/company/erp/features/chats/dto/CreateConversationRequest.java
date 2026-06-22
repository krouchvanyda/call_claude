package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.ConversationType;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record CreateConversationRequest(
        @NotNull ConversationType type,
        @NotEmpty Set<Long> memberIds,
        @Size(max = 255) String name,
        @Size(max = 1024) String avatarUrl
) {
}
