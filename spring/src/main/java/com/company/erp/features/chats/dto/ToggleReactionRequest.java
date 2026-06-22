package com.company.erp.features.chats.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ToggleReactionRequest(
        @NotBlank @Size(max = 16) String emoji
) {
}
