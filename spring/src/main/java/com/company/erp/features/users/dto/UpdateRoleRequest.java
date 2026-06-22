package com.company.erp.features.users.dto;

import jakarta.validation.constraints.Size;

import java.util.Set;

public record UpdateRoleRequest(
        @Size(max = 128) String name,
        @Size(max = 255) String description,
        /** Replaces the role's permission set. {@code null} means "leave permissions untouched." */
        Set<String> permissions
) {
}
