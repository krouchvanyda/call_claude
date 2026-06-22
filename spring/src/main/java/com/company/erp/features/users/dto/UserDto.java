package com.company.erp.features.users.dto;

import com.company.erp.features.users.entity.Role;
import com.company.erp.features.users.entity.User;

import java.util.Set;
import java.util.stream.Collectors;

public record UserDto(
        Long id,
        String email,
        String fullName,
        String phone,
        String avatarUrl,
        boolean enabled,
        Set<String> roles,
        Set<String> permissions
) {
    public static UserDto from(User u) {
        return new UserDto(
                u.getId(),
                u.getEmail(),
                u.getFullName(),
                u.getPhone(),
                u.getAvatarUrl(),
                u.isEnabled(),
                u.getRoles().stream().map(Role::getCode).collect(Collectors.toSet()),
                u.allPermissions());
    }
}
