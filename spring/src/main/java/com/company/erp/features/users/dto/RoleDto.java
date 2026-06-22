package com.company.erp.features.users.dto;

import com.company.erp.features.users.entity.Permission;
import com.company.erp.features.users.entity.Role;

import java.util.Set;
import java.util.stream.Collectors;

public record RoleDto(
        Long id,
        String code,
        String name,
        String description,
        Set<String> permissions
) {
    public static RoleDto from(Role r) {
        return new RoleDto(
                r.getId(),
                r.getCode(),
                r.getName(),
                r.getDescription(),
                r.getPermissions().stream().map(Permission::getCode).collect(Collectors.toSet()));
    }
}
