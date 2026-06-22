package com.company.erp.core.web;

import com.company.erp.core.config.AppProperties;
import com.company.erp.core.response.ApiResponse;
import com.company.erp.core.response.ErrorCodes;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Per-IP token bucket. Auth endpoints get a stricter bucket so password
 * spraying / signup abuse is easier to throttle.
 *
 * <p>NOTE: in-memory only — for multi-instance deployments swap for the
 * Redis variant ({@code bucket4j-redis}) so all replicas share state.</p>
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class RateLimitFilter extends OncePerRequestFilter {

    private final AppProperties props;
    private final ObjectMapper mapper;
    private final ConcurrentHashMap<String, Bucket> buckets = new ConcurrentHashMap<>();

    public RateLimitFilter(AppProperties props, ObjectMapper mapper) {
        this.props = props;
        this.mapper = mapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        if (!props.rateLimit().enabled()) {
            chain.doFilter(request, response);
            return;
        }
        String path = request.getRequestURI();
        if (path.startsWith("/actuator") || path.startsWith("/health")) {
            chain.doFilter(request, response);
            return;
        }

        boolean isAuthPath = path.contains("/api/v1/auth/");
        int capacity = isAuthPath ? props.rateLimit().authPerMinute() : props.rateLimit().perMinute();
        String key = bucketKey(request, isAuthPath);

        Bucket bucket = buckets.computeIfAbsent(key, k -> newBucket(capacity));
        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(429);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            mapper.writeValue(
                    response.getOutputStream(),
                    ApiResponse.error("Too many requests", ErrorCodes.RATE_LIMITED));
        }
    }

    private String bucketKey(HttpServletRequest req, boolean isAuthPath) {
        String forwarded = req.getHeader("X-Forwarded-For");
        String ip;
        if (forwarded != null && !forwarded.isBlank()) {
            ip = forwarded.split(",")[0].trim();
        } else {
            ip = req.getRemoteAddr();
        }
        if (ip == null || ip.isBlank()) ip = "unknown";
        return (isAuthPath ? "auth" : "general") + "|" + ip;
    }

    private Bucket newBucket(int capacity) {
        Bandwidth limit = Bandwidth.builder()
                .capacity(capacity)
                .refillIntervally(capacity, Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }
}
