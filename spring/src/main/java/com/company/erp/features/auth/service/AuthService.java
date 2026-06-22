package com.company.erp.features.auth.service;

import com.company.erp.core.exceptions.ConflictException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.core.exceptions.UnauthorizedException;
import com.company.erp.core.security.JwtService;
import com.company.erp.core.security.JwtService.IssuedToken;
import com.company.erp.core.security.JwtService.RefreshClaims;
import com.company.erp.features.auth.dto.*;
import com.company.erp.features.auth.entity.RefreshToken;
import com.company.erp.features.auth.repository.RefreshTokenRepository;
import com.company.erp.features.employees.service.EmployeeService;
import com.company.erp.features.users.dto.UserDto;
import com.company.erp.features.users.entity.User;
import com.company.erp.features.users.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@Transactional
public class AuthService {

    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwords;
    private final JwtService jwt;
    private final EmployeeService employees;

    public AuthService(UserRepository users,
                       RefreshTokenRepository refreshTokens,
                       PasswordEncoder passwords,
                       JwtService jwt,
                       EmployeeService employees) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.passwords = passwords;
        this.jwt = jwt;
        this.employees = employees;
    }

    public AuthResponse login(LoginRequest req) {
        User user = users.findByEmail(req.email().toLowerCase())
                .orElseThrow(() -> new UnauthorizedException("Invalid email or password"));
        if (!user.isEnabled()) throw new UnauthorizedException("Account is disabled");
        if (!passwords.matches(req.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid email or password");
        }
        employees.touchLastLoginByUserId(user.getId());
        return issueTokens(user);
    }

    public AuthResponse register(RegisterRequest req) {
        String email = req.email().toLowerCase();
        if (users.existsByEmail(email)) throw new ConflictException("Email already in use");

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwords.encode(req.password()));
        user.setFullName(req.fullName());
        user.setPhone(req.phone());
        users.save(user);
        return issueTokens(user);
    }

    public AuthResponse refresh(RefreshRequest req) {
        RefreshClaims claims = jwt.parseRefresh(req.refreshToken());
        RefreshToken stored = refreshTokens.findByJti(claims.jti())
                .orElseThrow(() -> new UnauthorizedException("Refresh token not recognised"));
        if (!stored.isActive(Instant.now())) throw new UnauthorizedException("Refresh token expired or revoked");
        if (!stored.getUserId().equals(claims.userId())) throw new UnauthorizedException("Refresh token user mismatch");

        // Rotate: revoke the presented token, issue a fresh pair.
        stored.setRevokedAt(Instant.now());

        User user = users.findWithRolesById(claims.userId())
                .orElseThrow(() -> new NotFoundException("User no longer exists"));
        return issueTokens(user);
    }

    public void logout(LogoutRequest req) {
        // Silent on invalid/unknown tokens — logout must always succeed from the client's POV.
        RefreshClaims claims;
        try {
            claims = jwt.parseRefresh(req.refreshToken());
        } catch (UnauthorizedException ex) {
            return;
        }
        refreshTokens.findByJti(claims.jti()).ifPresent(rt -> rt.setRevokedAt(Instant.now()));
    }

    private AuthResponse issueTokens(User user) {
        IssuedToken access  = jwt.issueAccess(user.getId(), user.getEmail(), user.allPermissions());
        IssuedToken refresh = jwt.issueRefresh(user.getId());

        RefreshToken record = new RefreshToken();
        record.setUserId(user.getId());
        record.setJti(refresh.jti());
        record.setIssuedAt(Instant.now());
        record.setExpiresAt(refresh.expiresAt());
        refreshTokens.save(record);

        return new AuthResponse(
                access.value(), access.expiresAt(),
                refresh.value(), refresh.expiresAt(),
                UserDto.from(user));
    }
}
