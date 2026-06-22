package com.company.erp.features.users.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record CreateRoleRequest(
        @NotBlank @Size(max = 64)  String code,
        @NotBlank @Size(max = 128) String name,
        @Size(max = 255) String description,
        Set<String> permissions
) {
    public CreateRoleRequest {
        if (permissions == null) permissions = Set.of();
    }
}
