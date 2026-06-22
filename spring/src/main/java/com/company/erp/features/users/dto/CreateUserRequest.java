package com.company.erp.features.users.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record CreateUserRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, max = 100) String password,
        @NotBlank @Size(max = 255) String fullName,
        @Size(max = 50) String phone,
        /** Role codes to assign (e.g. ["STAFF"]). Optional. */
        Set<String> roles
) {
    public CreateUserRequest {
        if (roles == null) roles = Set.of();
    }
}
