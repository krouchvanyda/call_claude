package com.company.erp.features.chats.ws;

import com.company.erp.features.chats.dto.ChatEvent;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import java.util.Collection;

/**
 * Thin wrapper over {@link SimpMessagingTemplate} so services don't reach for
 * the messaging plumbing directly. Destinations follow the contract documented
 * in {@link WebSocketConfig}.
 */
@Component
public class ChatBroadcaster {

    private final SimpMessagingTemplate template;

    public ChatBroadcaster(SimpMessagingTemplate template) {
        this.template = template;
    }

    /** Public conversation topic — anyone subscribed sees this. */
    public void toConversation(Long conversationId, String event, Object payload) {
        template.convertAndSend("/topic/conversations/" + conversationId, ChatEvent.of(event, payload));
    }

    /** Per-call topic for ringing → answered → ended state transitions. */
    public void toCall(Long conversationId, String event, Object payload) {
        template.convertAndSend("/topic/conversations/" + conversationId + "/call", ChatEvent.of(event, payload));
    }

    /** Private fan-out to a single user — {@code /user/queue/<destination>}. */
    public void toUser(Long userId, String destination, String event, Object payload) {
        template.convertAndSendToUser(String.valueOf(userId), "/queue/" + destination, ChatEvent.of(event, payload));
    }

    /** Convenience: notify every user in a collection on a private destination. */
    public void toUsers(Collection<Long> userIds, String destination, String event, Object payload) {
        for (Long id : userIds) toUser(id, destination, event, payload);
    }
}
