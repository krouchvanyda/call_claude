package com.company.erp.features.auth.service;

import com.company.erp.features.auth.repository.RefreshTokenRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * Hourly cleanup of expired / revoked refresh tokens. Keeps the table small
 * without losing audit value: rows are purged only after they've been inactive
 * for at least 24h.
 */
@Component
public class RefreshTokenCleanupJob {

    private static final Logger log = LoggerFactory.getLogger(RefreshTokenCleanupJob.class);

    private final RefreshTokenRepository refreshTokens;

    public RefreshTokenCleanupJob(RefreshTokenRepository refreshTokens) {
        this.refreshTokens = refreshTokens;
    }

    @Scheduled(fixedDelayString = "PT1H", initialDelayString = "PT5M")
    @Transactional
    public void purge() {
        Instant cutoff = Instant.now().minus(24, ChronoUnit.HOURS);
        int purged = refreshTokens.purgeInactive(cutoff);
        if (purged > 0) log.info("Purged {} inactive refresh tokens", purged);
    }
}
