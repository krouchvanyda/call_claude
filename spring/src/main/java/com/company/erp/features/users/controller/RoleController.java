package com.company.erp.features.users.controller;

import com.company.erp.core.security.Permissions;
import com.company.erp.features.users.dto.CreateRoleRequest;
import com.company.erp.features.users.dto.PermissionDto;
import com.company.erp.features.users.dto.RoleDto;
import com.company.erp.features.users.dto.UpdateRoleRequest;
import com.company.erp.features.users.service.RoleService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/roles")
public class RoleController {

    private final RoleService roles;

    public RoleController(RoleService roles) {
        this.roles = roles;
    }

    /** List all roles with their attached permission codes. */
    @GetMapping
    @PreAuthorize("hasAuthority('" + Permissions.ROLE_READ + "')")
    public List<RoleDto> list() {
        return roles.list().stream().map(RoleDto::from).toList();
    }

    /** Get one role by id, including its permissions. */
    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.ROLE_READ + "')")
    public RoleDto get(@PathVariable Long id) {
        return RoleDto.from(roles.getById(id));
    }

    /** Create a new role with a unique code and an initial permission set. */
    @PostMapping
    @PreAuthorize("hasAuthority('" + Permissions.ROLE_WRITE + "')")
    public RoleDto create(@Valid @RequestBody CreateRoleRequest body) {
        return RoleDto.from(roles.create(body));
    }

    /** Update a role's name / description / permission set. */
    @PatchMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.ROLE_WRITE + "')")
    public RoleDto update(@PathVariable Long id, @Valid @RequestBody UpdateRoleRequest body) {
        return RoleDto.from(roles.update(id, body));
    }

    /** Delete a role (users referencing it lose those grants but stay). */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.ROLE_WRITE + "')")
    public void delete(@PathVariable Long id) {
        roles.delete(id);
    }

    /** List every permission code in the system — used by the role editor UI. */
    @GetMapping("/permissions")
    @PreAuthorize("hasAuthority('" + Permissions.ROLE_READ + "')")
    public List<PermissionDto> listPermissions() {
        return roles.listPermissions().stream().map(PermissionDto::from).toList();
    }
}
