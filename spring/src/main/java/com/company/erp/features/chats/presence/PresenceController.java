package com.company.erp.features.chats.presence;

import com.company.erp.core.security.AuthenticatedUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/chats/presence")
public class PresenceController {

    private final PresenceService presence;

    public PresenceController(PresenceService presence) {
        this.presence = presence;
    }

    /** Get one user's current presence (ONLINE / BUSY / OFFLINE + lastSeenAt). */
    @GetMapping("/{userId}")
    public PresenceDto get(@PathVariable Long userId) {
        AuthenticatedUser.require();
        return presence.dtoOf(userId);
    }

    /** Batch presence for a comma-separated list of user ids; no `ids` param = whole snapshot. */
    @GetMapping
    public List<PresenceDto> batch(@RequestParam(value = "ids", required = false) List<Long> ids) {
        AuthenticatedUser.require();
        if (ids == null || ids.isEmpty()) return presence.snapshot();
        return presence.dtosFor(ids);
    }

    /**
     * App-lifecycle beacon: the caller minimized → mark them OFFLINE now so an
     * incoming call rings their device via VoIP/CallKit instead of being
     * skipped as "online". Fixes the "minimized, second call: no ring" bug
     * where the STOMP heartbeat took ~20-30s to notice the suspended socket.
     */
    @PostMapping("/background")
    public void background() {
        Long me = AuthenticatedUser.require().userId();
        presence.markBackgrounded(me);
    }

    /** App-lifecycle beacon: the caller returned to the foreground. */
    @PostMapping("/foreground")
    public void foreground() {
        Long me = AuthenticatedUser.require().userId();
        presence.clearBackgrounded(me);
    }
}
