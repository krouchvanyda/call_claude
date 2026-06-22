package com.company.erp.features.chats.presence;

public enum PresenceStatus {
    /** At least one active STOMP session, and not currently in a call. */
    ONLINE,
    /** At least one active STOMP session AND currently in (or starting) a call. */
    BUSY,
    /** No active STOMP sessions. */
    OFFLINE
}
