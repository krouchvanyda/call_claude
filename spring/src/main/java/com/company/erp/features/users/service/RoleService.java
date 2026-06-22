package com.company.erp.features.users.service;

import com.company.erp.core.exceptions.ConflictException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.users.dto.CreateRoleRequest;
import com.company.erp.features.users.dto.UpdateRoleRequest;
import com.company.erp.features.users.entity.Permission;
import com.company.erp.features.users.entity.Role;
import com.company.erp.features.users.repository.PermissionRepository;
import com.company.erp.features.users.repository.RoleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class RoleService {

    private final RoleRepository roles;
    private final PermissionRepository permissions;

    public RoleService(RoleRepository roles, PermissionRepository permissions) {
        this.roles = roles;
        this.permissions = permissions;
    }

    @Transactional(readOnly = true)
    public List<Role> list() {
        return roles.findAll();
    }

    @Transactional(readOnly = true)
    public Role getById(Long id) {
        return roles.findById(id).orElseThrow(() -> new NotFoundException("Role not found"));
    }

    @Transactional(readOnly = true)
    public List<Permission> listPermissions() {
        return permissions.findAll();
    }

    public Role create(CreateRoleRequest req) {
        if (roles.existsByCode(req.code())) throw new ConflictException("Role code already in use");
        Role role = new Role();
        role.setCode(req.code());
        role.setName(req.name());
        role.setDescription(req.description());
        role.setPermissions(new HashSet<>(resolvePermissions(req.permissions())));
        return roles.save(role);
    }

    public Role update(Long id, UpdateRoleRequest req) {
        Role role = getById(id);
        if (req.name()        != null) role.setName(req.name());
        if (req.description() != null) role.setDescription(req.description());
        if (req.permissions() != null) role.setPermissions(new HashSet<>(resolvePermissions(req.permissions())));
        return role;
    }

    public void delete(Long id) {
        roles.delete(getById(id));
    }

    private Set<Permission> resolvePermissions(Set<String> codes) {
        if (codes.isEmpty()) return Set.of();
        List<Permission> found = permissions.findByCodeIn(codes);
        Set<String> foundCodes = found.stream().map(Permission::getCode).collect(Collectors.toSet());
        Set<String> missing = new HashSet<>(codes);
        missing.removeAll(foundCodes);
        if (!missing.isEmpty()) {
            throw new NotFoundException("Unknown permission(s): " + String.join(",", missing));
        }
        return new HashSet<>(found);
    }
}
