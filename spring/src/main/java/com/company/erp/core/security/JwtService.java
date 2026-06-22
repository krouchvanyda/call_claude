package com.company.erp.core.security;

import com.company.erp.core.config.AppProperties;
import com.company.erp.core.exceptions.UnauthorizedException;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Issues and parses access / refresh JWTs.
 *
 * <p>Access tokens carry:
 * <ul>
 *   <li>{@code sub}  — user id (Long, string form)</li>
 *   <li>{@code email}</li>
 *   <li>{@code pms}  — permission codes (string array)</li>
 *   <li>{@code typ}  — "access"</li>
 * </ul>
 *
 * <p>Refresh tokens carry only {@code sub}, {@code jti}, and
 * {@code typ=refresh}; their JTI is persisted in {@code refresh_tokens} so
 * they can be revoked / rotated.</p>
 */
@Service
public class JwtService {

    private static final String CLAIM_EMAIL       = "email";
    private static final String CLAIM_PERMISSIONS = "pms";
    private static final String CLAIM_TYPE        = "typ";
    private static final String TYPE_ACCESS       = "access";
    private static final String TYPE_REFRESH      = "refresh";

    private final AppProperties props;
    private final SecretKey key;

    public JwtService(AppProperties props) {
        this.props = props;
        this.key = Keys.hmacShaKeyFor(props.security().jwt().secret().getBytes(StandardCharsets.UTF_8));
    }

    public IssuedToken issueAccess(Long userId, String email, Set<String> permissions) {
        Instant now = Instant.now();
        Instant exp = now.plus(props.security().jwt().accessTokenTtl());
        String jti = UUID.randomUUID().toString();
        String token = Jwts.builder()
                .issuer(props.security().jwt().issuer())
                .subject(userId.toString())
                .id(jti)
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .claim(CLAIM_EMAIL, email)
                .claim(CLAIM_PERMISSIONS, permissions)
                .claim(CLAIM_TYPE, TYPE_ACCESS)
                .signWith(key)
                .compact();
        return new IssuedToken(token, jti, exp);
    }

    public IssuedToken issueRefresh(Long userId) {
        Instant now = Instant.now();
        Instant exp = now.plus(props.security().jwt().refreshTokenTtl());
        String jti = UUID.randomUUID().toString();
        String token = Jwts.builder()
                .issuer(props.security().jwt().issuer())
                .subject(userId.toString())
                .id(jti)
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .claim(CLAIM_TYPE, TYPE_REFRESH)
                .signWith(key)
                .compact();
        return new IssuedToken(token, jti, exp);
    }

    public AuthenticatedUser parseAccess(String token) {
        Claims claims = parse(token);
        if (!TYPE_ACCESS.equals(claims.get(CLAIM_TYPE))) {
            throw new UnauthorizedException("Wrong token type");
        }
        Long userId = Long.valueOf(claims.getSubject());
        String email = (String) claims.getOrDefault(CLAIM_EMAIL, "");
        @SuppressWarnings("unchecked")
        List<String> perms = (List<String>) claims.get(CLAIM_PERMISSIONS);
        Set<String> permissions = perms == null ? Set.of() : new HashSet<>(perms);
        return new AuthenticatedUser(userId, email, permissions);
    }

    public RefreshClaims parseRefresh(String token) {
        Claims claims = parse(token);
        if (!TYPE_REFRESH.equals(claims.get(CLAIM_TYPE))) {
            throw new UnauthorizedException("Wrong token type");
        }
        return new RefreshClaims(
                Long.valueOf(claims.getSubject()),
                claims.getId(),
                claims.getExpiration().toInstant());
    }

    private Claims parse(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(key)
                    .requireIssuer(props.security().jwt().issuer())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException ex) {
            throw new UnauthorizedException("Invalid or expired token");
        }
    }

    public record IssuedToken(String value, String jti, Instant expiresAt) {}
    public record RefreshClaims(Long userId, String jti, Instant expiresAt) {}
}
