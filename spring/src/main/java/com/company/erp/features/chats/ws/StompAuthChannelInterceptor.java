package com.company.erp.features.chats.ws;

import com.company.erp.core.security.AuthenticatedUser;
import com.company.erp.core.security.JwtService;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Validates the {@code Authorization: Bearer <accessToken>} header on STOMP
 * CONNECT frames and binds the resulting {@link AuthenticatedUser} as the
 * STOMP session principal. {@code convertAndSendToUser(userId, ...)} then
 * routes per-user destinations via {@link Principal#getName()} = user id.
 */
@Component
public class StompAuthChannelInterceptor implements ChannelInterceptor {

    private static final String AUTH_HEADER = "Authorization";
    private static final String BEARER      = "Bearer ";

    private final JwtService jwt;

    public StompAuthChannelInterceptor(JwtService jwt) {
        this.jwt = jwt;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) return message;

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String header = firstNativeHeader(accessor, AUTH_HEADER);
            if (header == null || !header.startsWith(BEARER)) return message; // anonymous; later subscribes will fail
            String token = header.substring(BEARER.length()).trim();

            AuthenticatedUser principal = jwt.parseAccess(token);
            Set<GrantedAuthority> authorities = principal.permissions().stream()
                    .map(SimpleGrantedAuthority::new)
                    .collect(Collectors.toUnmodifiableSet());
            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(principal, token, authorities) {
                        @Override public String getName() { return String.valueOf(principal.userId()); }
                    };
            accessor.setUser(auth);
        }
        return message;
    }

    private static String firstNativeHeader(StompHeaderAccessor accessor, String name) {
        List<String> values = accessor.getNativeHeader(name);
        return (values == null || values.isEmpty()) ? null : values.get(0);
    }
}
