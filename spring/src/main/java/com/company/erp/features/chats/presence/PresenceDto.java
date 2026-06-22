package com.company.erp.features.chats.presence;

import java.time.Instant;

public record PresenceDto(
        Long userId,
        PresenceStatus status,
        /** When the user last went OFFLINE, or null while ONLINE/BUSY. */
        Instant lastSeenAt
) {
}
