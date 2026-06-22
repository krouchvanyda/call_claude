package com.company.erp.features.users.controller;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.response.PageResponse;
import com.company.erp.core.security.AuthenticatedUser;
import com.company.erp.core.security.Permissions;
import com.company.erp.features.users.dto.AssignRolesRequest;
import com.company.erp.features.users.dto.CreateUserRequest;
import com.company.erp.features.users.dto.UpdateUserRequest;
import com.company.erp.features.users.dto.UserDto;
import com.company.erp.features.users.service.UserService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService users;

    public UserController(UserService users) {
        this.users = users;
    }

    /** Get the currently authenticated user (roles + flattened permissions). */
    @GetMapping("/me")
    public UserDto me() {
        return UserDto.from(users.getById(AuthenticatedUser.require().userId()));
    }

    /**
     * List all users, paginated, with substring search on email / fullName.
     * Open to every authenticated user so the chat module can pick peers to
     * message; mutating endpoints below still require {@code user:write}.
     */
    @GetMapping
    public PageResponse<UserDto> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sort) {
        return PageResponse.from(users.list(new PageQuery(page, pageSize, search, sort)), UserDto::from);
    }

    /** Get one user by id. Open to every authenticated user (same reasoning as list). */
    @GetMapping("/{id}")
    public UserDto get(@PathVariable Long id) {
        return UserDto.from(users.getById(id));
    }

    /** Create a new user with bcrypt-hashed password and optional roles. */
    @PostMapping
    @PreAuthorize("hasAuthority('" + Permissions.USER_WRITE + "')")
    public UserDto create(@Valid @RequestBody CreateUserRequest body) {
        return UserDto.from(users.create(body));
    }

    /** Partial update — only fields present in the body are touched (null body = no-op). */
    @PatchMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.USER_WRITE + "')")
    public UserDto update(@PathVariable Long id,
                          @Valid @RequestBody(required = false) UpdateUserRequest body) {
        if (body == null) return UserDto.from(users.getById(id));
        return UserDto.from(users.update(id, body));
    }

    /** Hard-delete a user (their refresh tokens are cascaded by the DB). */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.USER_WRITE + "')")
    public void delete(@PathVariable Long id) {
        users.delete(id);
    }

    /** Bulk-assign roles to many users at once: mode = ADD (default) | REPLACE | REMOVE. */
    @PostMapping("/assign-roles")
    @PreAuthorize("hasAuthority('" + Permissions.USER_WRITE + "')")
    public List<UserDto> assignRoles(@Valid @RequestBody AssignRolesRequest body) {
        return users.assignRoles(body).stream().map(UserDto::from).toList();
    }
}
