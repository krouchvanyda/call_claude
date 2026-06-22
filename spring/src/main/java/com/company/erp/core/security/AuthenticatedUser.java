package com.company.erp.core.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.Set;

/**
 * Principal placed on the SecurityContext after a valid access token. The
 * {@code pms} claim on the token populates {@code permissions}, which is
 * mapped to Spring Security authorities so
 * {@code @PreAuthorize("hasAuthority('chat:read')")} works directly.
 */
public record AuthenticatedUser(Long userId, String email, Set<String> permissions) {

    /** Convenience accessor for the current request's principal. */
    public static Optional<AuthenticatedUser> current() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return Optional.empty();
        if (auth.getPrincipal() instanceof AuthenticatedUser u) return Optional.of(u);
        return Optional.empty();
    }

    public static AuthenticatedUser require() {
        return current().orElseThrow(() ->
                new IllegalStateException("No authenticated user on SecurityContext"));
    }
}
