package com.company.erp.features.chats.presence;

import com.company.erp.core.security.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

@Component
public class WebSocketSessionListener {

    private static final Logger log = LoggerFactory.getLogger(WebSocketSessionListener.class);

    private final PresenceService presence;

    public WebSocketSessionListener(PresenceService presence) {
        this.presence = presence;
    }

    @EventListener
    public void onConnected(SessionConnectedEvent event) {
        StompHeaderAccessor sha = StompHeaderAccessor.wrap(event.getMessage());
        Long userId = userIdOf(sha);
        String sessionId = sha.getSessionId();
        if (userId != null && sessionId != null) {
            log.debug("STOMP CONNECT user={} session={}", userId, sessionId);
            presence.connect(userId, sessionId);
        }
    }

    @EventListener
    public void onDisconnect(SessionDisconnectEvent event) {
        log.debug("STOMP DISCONNECT session={} status={}",
                event.getSessionId(), event.getCloseStatus());
        presence.disconnect(event.getSessionId());
    }

    private Long userIdOf(StompHeaderAccessor sha) {
        if (sha.getUser() instanceof Authentication auth
                && auth.getPrincipal() instanceof AuthenticatedUser u) {
            return u.userId();
        }
        return null;
    }
}
