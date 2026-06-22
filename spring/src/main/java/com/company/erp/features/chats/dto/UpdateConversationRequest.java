package com.company.erp.features.chats.dto;

import jakarta.validation.constraints.Size;

public record UpdateConversationRequest(
        @Size(max = 255) String name,
        @Size(max = 1024) String avatarUrl
) {
}
