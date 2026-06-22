package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.MessageType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(
        @NotNull MessageType type,
        String body,
        @Size(max = 1024) String attachmentUrl,
        @Size(max = 64)   String attachmentContentType,
        Long              attachmentSizeBytes,
        Integer           durationSeconds,
        Long              replyToMessageId
) {
}
