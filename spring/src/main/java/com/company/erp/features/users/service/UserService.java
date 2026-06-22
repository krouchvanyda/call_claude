package com.company.erp.features.users.service;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.exceptions.ConflictException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.users.dto.AssignRolesRequest;
import com.company.erp.features.users.dto.CreateUserRequest;
import com.company.erp.features.users.dto.UpdateUserRequest;
import com.company.erp.features.users.entity.Role;
import com.company.erp.features.users.entity.User;
import com.company.erp.features.users.repository.RoleRepository;
import com.company.erp.features.users.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class UserService {

    private static final Set<String> ALLOWED_SORT = Set.of("email", "fullName", "createdAt");

    private final UserRepository users;
    private final RoleRepository roles;
    private final PasswordEncoder passwords;

    public UserService(UserRepository users, RoleRepository roles, PasswordEncoder passwords) {
        this.users = users;
        this.roles = roles;
        this.passwords = passwords;
    }

    @Transactional(readOnly = true)
    public Page<User> list(PageQuery query) {
        // Search filtering wires in once the products module introduces JPA
        // Specifications as the canonical pattern. For now: paginate only.
        return users.findAllBy(query.toPageable(ALLOWED_SORT, Sort.by("email")));
    }

    @Transactional(readOnly = true)
    public User getById(Long id) {
        return users.findWithRolesById(id).orElseThrow(() -> new NotFoundException("User not found"));
    }

    @Transactional(readOnly = true)
    public User getByEmail(String email) {
        return users.findByEmail(email.toLowerCase()).orElseThrow(() -> new NotFoundException("User not found"));
    }

    public User create(CreateUserRequest req) {
        String email = req.email().toLowerCase();
        if (users.existsByEmail(email)) throw new ConflictException("Email already in use");

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwords.encode(req.password()));
        user.setFullName(req.fullName());
        user.setPhone(req.phone());
        user.setRoles(new HashSet<>(resolveRoles(req.roles())));
        return users.save(user);
    }

    public User update(Long id, UpdateUserRequest req) {
        User user = getById(id);
        if (req.fullName()  != null) user.setFullName(req.fullName());
        if (req.phone()     != null) user.setPhone(req.phone());
        if (req.avatarUrl() != null) user.setAvatarUrl(req.avatarUrl());
        if (req.enabled()   != null) user.setEnabled(req.enabled());
        if (req.roles()     != null) user.setRoles(new HashSet<>(resolveRoles(req.roles())));
        return user;
    }

    public void delete(Long id) {
        users.delete(getById(id));
    }

    public List<User> assignRoles(AssignRolesRequest req) {
        List<User> targets = users.findAllWithRolesByIdIn(req.userIds());
        if (targets.size() != req.userIds().size()) {
            Set<Long> found = targets.stream().map(User::getId).collect(Collectors.toSet());
            Set<Long> missing = req.userIds().stream()
                    .filter(id -> !found.contains(id))
                    .collect(Collectors.toSet());
            throw new NotFoundException("User(s) not found: " + missing);
        }

        Set<Role> resolved = new HashSet<>(resolveRoles(req.roles()));
        for (User user : targets) {
            switch (req.mode()) {
                case ADD     -> user.getRoles().addAll(resolved);
                case REMOVE  -> user.getRoles().removeAll(resolved);
                case REPLACE -> user.setRoles(new HashSet<>(resolved));
            }
        }
        return targets;
    }

    private Set<Role> resolveRoles(Set<String> codes) {
        if (codes.isEmpty()) return Set.of();
        return codes.stream()
                .map(code -> roles.findByCode(code)
                        .orElseThrow(() -> new NotFoundException("Role not found: " + code)))
                .collect(Collectors.toSet());
    }
}
