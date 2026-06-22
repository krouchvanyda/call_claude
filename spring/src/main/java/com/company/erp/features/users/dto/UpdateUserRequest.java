package com.company.erp.features.users.dto;

import jakarta.validation.constraints.Size;

import java.util.Set;

public record UpdateUserRequest(
        @Size(max = 255) String fullName,
        @Size(max = 50)  String phone,
        @Size(max = 1024) String avatarUrl,
        Boolean enabled,
        /** Replaces the user's role set. {@code null} means "leave roles untouched." */
        Set<String> roles
) {
}
