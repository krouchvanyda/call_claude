package com.company.erp.features.users.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.Set;

public record AssignRolesRequest(
        @NotEmpty Set<Long> userIds,
        @NotNull Set<String> roles,
        Mode mode
) {
    public AssignRolesRequest {
        if (roles == null) roles = Set.of();
        if (mode == null)  mode  = Mode.ADD;
    }

    public enum Mode {
        /** Union the given roles into each user's existing role set. */
        ADD,
        /** Replace each user's role set with exactly the given roles. */
        REPLACE,
        /** Subtract the given roles from each user's existing role set. */
        REMOVE
    }
}
