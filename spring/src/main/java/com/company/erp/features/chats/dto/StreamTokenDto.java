package com.company.erp.features.chats.dto;

import java.time.Instant;

/**
 * Short-lived Stream Video user token. Mobile clients exchange this for an
 * authenticated session against the Stream SDK, which carries the actual
 * audio/video traffic. The signalling ceremony (RINGING / ANSWERED / ENDED)
 * stays on our side over STOMP.
 */
public record StreamTokenDto(
        String token,
        String apiKey,
        String userId,
        Instant expiresAt
) {
}
