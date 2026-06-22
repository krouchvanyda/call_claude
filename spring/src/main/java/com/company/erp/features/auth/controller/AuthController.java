package com.company.erp.features.auth.controller;

import com.company.erp.core.response.ApiResponse;
import com.company.erp.features.auth.dto.AuthResponse;
import com.company.erp.features.auth.dto.LoginRequest;
import com.company.erp.features.auth.dto.LogoutRequest;
import com.company.erp.features.auth.dto.RefreshRequest;
import com.company.erp.features.auth.dto.RegisterRequest;
import com.company.erp.features.auth.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    /** Exchange email + password for an access + refresh token pair. */
    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest body) {
        return auth.login(body);
    }

    /** Create a new user account and immediately issue tokens for them. */
    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest body) {
        return auth.register(body);
    }

    /** Rotate tokens — exchange a refresh token for a new access + refresh pair. */
    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest body) {
        return auth.refresh(body);
    }

    /** Revoke a refresh token; always succeeds even if the token is unknown. */
    @PostMapping("/logout")
    public ApiResponse<Void> logout(@Valid @RequestBody LogoutRequest body) {
        auth.logout(body);
        return ApiResponse.empty("Logged out");
    }
}
