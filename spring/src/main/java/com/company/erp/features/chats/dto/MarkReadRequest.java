package com.company.erp.features.chats.dto;

import jakarta.validation.constraints.NotNull;

public record MarkReadRequest(
        @NotNull Long lastReadMessageId
) {
}
