package com.company.erp.features.chats.ws;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * STOMP endpoint at {@code /ws}. Clients should:
 *
 * <pre>
 *   ws.connect()           // CONNECT frame
 *      header Authorization: Bearer &lt;accessToken&gt;
 *
 *   ws.subscribe("/topic/conversations/42")          // message stream
 *   ws.subscribe("/topic/conversations/42/call")     // call state
 *   ws.subscribe("/user/queue/calls")                // per-user incoming-call invites
 *   ws.subscribe("/user/queue/inbox")                // per-user inbox previews
 *   ws.subscribe("/topic/presence")                  // online/busy/offline updates
 * </pre>
 *
 * <p><b>Heartbeats</b> are critical for presence — without them, when a mobile
 * app is force-closed, the server has no way to detect the dead socket until
 * OS-level TCP keepalive eventually kicks in (hours later on Linux). With
 * heartbeats configured, {@code SessionDisconnectEvent} fires within
 * ~20-30 seconds and {@code PresenceService} flips the user OFFLINE.</p>
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    /** Server expects a client heartbeat at least every 10s, and sends one every 10s. */
    private static final long[] HEARTBEAT_INTERVAL = new long[] { 10_000L, 10_000L };

    private final StompAuthChannelInterceptor authInterceptor;

    public WebSocketConfig(StompAuthChannelInterceptor authInterceptor) {
        this.authInterceptor = authInterceptor;
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Native STOMP-over-WebSocket on `/ws` (Flutter clients use this directly).
        registry.addEndpoint("/ws").setAllowedOriginPatterns("*");
        // SockJS fallback on `/ws-sockjs` for browser clients without WebSocket support.
        registry.addEndpoint("/ws-sockjs").setAllowedOriginPatterns("*").withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue")
                .setHeartbeatValue(HEARTBEAT_INTERVAL)
                .setTaskScheduler(heartbeatScheduler());
        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(authInterceptor);
    }

    /**
     * Dedicated scheduler the SimpleBroker uses to send server-side heartbeats
     * and time out clients whose heartbeats stop arriving.
     */
    private ThreadPoolTaskScheduler heartbeatScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(1);
        scheduler.setThreadNamePrefix("ws-heartbeat-");
        scheduler.setDaemon(true);
        scheduler.initialize();
        return scheduler;
    }
}
