package com.company.erp.features.users.dto;

import com.company.erp.features.users.entity.Permission;

public record PermissionDto(Long id, String code, String description) {
    public static PermissionDto from(Permission p) {
        return new PermissionDto(p.getId(), p.getCode(), p.getDescription());
    }
}
