package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.CallType;
import jakarta.validation.constraints.NotNull;

public record StartCallRequest(
        @NotNull CallType type
) {
}
