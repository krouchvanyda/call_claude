package com.company.erp.features.chats.dto;

import jakarta.validation.constraints.NotBlank;

public record EditMessageRequest(
        @NotBlank String body
) {
}
