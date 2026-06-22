package com.company.erp.features.chats.presence;

import com.company.erp.features.chats.ws.ChatBroadcaster;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory presence tracker. Sessions are added on STOMP CONNECT and removed
 * on DISCONNECT. Busy-state is driven separately by {@code ChatCallService}
 * (a user is BUSY whenever they're in an active call).
 *
 * <p>State is process-local — multi-instance deployments need to move this
 * to Redis (pub/sub for cross-instance fan-out plus a hash for the map).
 * Single-instance is the current scope.</p>
 */
@Service
public class PresenceService {

    /** userId → set of currently active STOMP session ids. */
    private final Map<Long, Set<String>> sessionsByUser = new ConcurrentHashMap<>();
    /** sessionId → userId, used for O(1) cleanup on DISCONNECT. */
    private final Map<String, Long> userBySession = new ConcurrentHashMap<>();
    /** userId → last time they went OFFLINE (for "last seen 5 min ago" UI). */
    private final Map<Long, Instant> lastSeenAt = new ConcurrentHashMap<>();
    /** userId → true if they're currently in an active call. */
    private final Set<Long> busy = ConcurrentHashMap.newKeySet();
    /**
     * userId → true if the app sent an explicit "I minimized" beacon
     * ({@code POST /chats/presence/background}). Flips the user OFFLINE
     * instantly for call-routing instead of waiting ~20-30s for the STOMP
     * heartbeat to notice the OS-suspended socket. This is what lets a
     * just-minimized callee receive the VoIP/CallKit ring (the ring gate in
     * {@code ChatCallService.start} keys off OFFLINE). Cleared on the
     * foreground beacon or on the next STOMP CONNECT (reconnect ⇒ foreground).
     */
    private final Set<Long> backgrounded = ConcurrentHashMap.newKeySet();

    private final ChatBroadcaster broadcaster;
    private final SimpMessagingTemplate template;

    public PresenceService(ChatBroadcaster broadcaster, SimpMessagingTemplate template) {
        this.broadcaster = broadcaster;
        this.template = template;
    }

    public void connect(Long userId, String sessionId) {
        if (userId == null || sessionId == null) return;
        PresenceStatus before = statusOf(userId);
        // NOTE: do NOT clear the `backgrounded` override here. A STOMP CONNECT
        // is NOT proof of foreground: a KILLED iOS app woken by a call VoIP
        // push cold-starts and connects STOMP while still in the background
        // (no UI on screen). If we cleared `backgrounded` on every connect, that
        // cold-start would mark the user ONLINE, so a FOLLOW-UP call would skip
        // the apn/VoIP ring (the "2nd call: no ring after a killed-app reject"
        // bug). Only an EXPLICIT foreground beacon (`/presence/foreground` →
        // clearBackgrounded), which the client sends on a genuine
        // AppLifecycleState.resumed, means the app is really on screen — that is
        // what clears the override. A background STOMP reconnect now correctly
        // keeps the user OFFLINE so the next call still rings via apn.
        sessionsByUser.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(sessionId);
        userBySession.put(sessionId, userId);
        PresenceStatus after = statusOf(userId);
        if (before != after) emit(userId, after);
    }

    public void disconnect(String sessionId) {
        Long userId = userBySession.remove(sessionId);
        if (userId == null) return;
        Set<String> sessions = sessionsByUser.get(userId);
        if (sessions != null) {
            sessions.remove(sessionId);
            if (sessions.isEmpty()) sessionsByUser.remove(userId);
        }
        if (!sessionsByUser.containsKey(userId)) {
            lastSeenAt.put(userId, Instant.now());
        }
        // Always emit on disconnect: status may have flipped to OFFLINE,
        // or stayed ONLINE/BUSY because other sessions are still up.
        emit(userId, statusOf(userId));
    }

    public void markBusy(Long userId) {
        if (userId == null) return;
        boolean changed = busy.add(userId);
        if (changed) emit(userId, statusOf(userId));
    }

    public void clearBusy(Long userId) {
        if (userId == null) return;
        boolean changed = busy.remove(userId);
        if (changed) emit(userId, statusOf(userId));
    }

    public PresenceStatus statusOf(Long userId) {
        // BUSY wins (in an active call). Otherwise an explicit background
        // beacon forces OFFLINE immediately — without it, a minimized iOS
        // app's suspended socket keeps the session "ONLINE" for ~20-30s, so
        // a call placed in that window is wrongly treated as foreground and
        // the VoIP/CallKit ring is skipped (the "minimized: no ring" bug).
        if (busy.contains(userId)) return PresenceStatus.BUSY;
        if (backgrounded.contains(userId)) return PresenceStatus.OFFLINE;
        return sessionsByUser.containsKey(userId)
                ? PresenceStatus.ONLINE
                : PresenceStatus.OFFLINE;
    }

    /**
     * App-lifecycle beacon: the user minimized. Flip them OFFLINE now for
     * call-routing instead of waiting for the STOMP heartbeat to time out the
     * OS-suspended socket. Idempotent.
     */
    public void markBackgrounded(Long userId) {
        if (userId == null) return;
        PresenceStatus before = statusOf(userId);
        backgrounded.add(userId);
        PresenceStatus after = statusOf(userId);
        if (before != after) {
            lastSeenAt.put(userId, Instant.now());
            emit(userId, after);
        }
    }

    /** App-lifecycle beacon: the user returned to the foreground. */
    public void clearBackgrounded(Long userId) {
        if (userId == null) return;
        PresenceStatus before = statusOf(userId);
        if (backgrounded.remove(userId)) {
            PresenceStatus after = statusOf(userId);
            if (before != after) emit(userId, after);
        }
    }

    public PresenceDto dtoOf(Long userId) {
        PresenceStatus s = statusOf(userId);
        Instant seen = (s == PresenceStatus.OFFLINE) ? lastSeenAt.get(userId) : null;
        return new PresenceDto(userId, s, seen);
    }

    /** Snapshot of every user the service has ever seen (online or offline). */
    public List<PresenceDto> snapshot() {
        Set<Long> ids = new HashSet<>();
        ids.addAll(sessionsByUser.keySet());
        ids.addAll(lastSeenAt.keySet());
        ids.addAll(busy);
        return ids.stream().map(this::dtoOf).toList();
    }

    public List<PresenceDto> dtosFor(List<Long> userIds) {
        return userIds.stream().map(this::dtoOf).toList();
    }

    private void emit(Long userId, PresenceStatus status) {
        Instant seen = (status == PresenceStatus.OFFLINE) ? lastSeenAt.get(userId) : null;
        PresenceDto dto = new PresenceDto(userId, status, seen);
        // Public topic — anyone interested in any user's presence can subscribe.
        template.convertAndSend("/topic/presence",
                Map.of("event", "presence.update", "payload", dto));
    }
}
