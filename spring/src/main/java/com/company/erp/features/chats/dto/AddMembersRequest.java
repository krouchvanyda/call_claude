package com.company.erp.features.chats.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.Set;

public record AddMembersRequest(
        @NotEmpty Set<Long> memberIds
) {
}
