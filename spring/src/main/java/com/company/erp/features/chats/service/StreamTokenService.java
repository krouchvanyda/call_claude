package com.company.erp.features.chats.service;

import com.company.erp.core.config.AppProperties;
import com.company.erp.core.exceptions.BadRequestException;
import com.company.erp.features.chats.dto.StreamTokenDto;
import io.jsonwebtoken.Jwts;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;

/**
 * Mints Stream Video user tokens. Stream uses standard JWT — HMAC-SHA256
 * signed with the project's API secret, with a single {@code user_id}
 * claim plus {@code iat} / {@code exp}. The mobile Stream SDK exchanges
 * this token for an authenticated session and handles all media
 * transport (mic capture, encoding, NAT traversal, mixing).
 *
 * <p>Requires {@code STREAM_API_KEY} and {@code STREAM_API_SECRET} to be
 * set; otherwise {@link #issueFor(Long)} throws {@code BAD_REQUEST}.</p>
 */
@Service
public class StreamTokenService {

    private static final Logger log = LoggerFactory.getLogger(StreamTokenService.class);

    private final AppProperties props;
    private final SecretKey key;
    private final boolean enabled;

    public StreamTokenService(AppProperties props) {
        this.props = props;
        String secret = (props.stream() == null) ? null : props.stream().apiSecret();
        String apiKey = (props.stream() == null) ? null : props.stream().apiKey();
        this.enabled = secret != null && !secret.isBlank()
                && apiKey != null && !apiKey.isBlank();
        this.key = enabled
                ? new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256")
                : null;
        if (enabled) {
            log.info("[stream] Stream Video configured. apiKey={} ttlMinutes={}",
                    maskKey(apiKey), props.stream().tokenTtlMinutes());
        } else {
            log.warn("[stream] Stream Video NOT configured — STREAM_API_KEY / STREAM_API_SECRET missing." +
                    " Call signalling will work; /chats/calls/stream-token will return 400.");
        }
    }

    private static String maskKey(String s) {
        if (s == null || s.length() <= 6) return s;
        return s.substring(0, 4) + "…" + s.substring(s.length() - 2);
    }

    public boolean isEnabled() {
        return enabled;
    }

    public StreamTokenDto issueFor(Long userId) {
        if (!enabled) {
            log.warn("[stream] token requested but Stream not configured (userId={})", userId);
            throw new BadRequestException(
                    "Stream Video is not configured — set STREAM_API_KEY and STREAM_API_SECRET");
        }
        Instant now = Instant.now();
        long ttlMinutes = props.stream().tokenTtlMinutes();
        Instant exp = now.plus(Duration.ofMinutes(ttlMinutes <= 0 ? 60 : ttlMinutes));
        String userIdStr = String.valueOf(userId);

        String token = Jwts.builder()
                .claim("user_id", userIdStr)
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .signWith(key)
                .compact();

        log.info("[stream] minted token for userId={} expiresAt={}", userIdStr, exp);
        return new StreamTokenDto(token, props.stream().apiKey(), userIdStr, exp);
    }

    /** Deterministic call CID — same call → same CID on every device. */
    public String cidForCall(Long callId) {
        return "default:erp-call-" + callId;
    }
}
