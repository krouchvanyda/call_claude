package com.company.erp.features.auth.repository;

import com.company.erp.features.auth.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByJti(String jti);

    @Modifying
    @Query("delete from RefreshToken r where r.expiresAt < :cutoff or r.revokedAt is not null")
    int purgeInactive(@Param("cutoff") Instant cutoff);
}
