package com.company.erp.core.audit;

import com.company.erp.core.security.AuthenticatedUser;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorAware")
public class AuditorAwareConfig {

    @Component("auditorAware")
    public static class SecurityAuditorAware implements AuditorAware<Long> {
        @Override
        public Optional<Long> getCurrentAuditor() {
            return AuthenticatedUser.current().map(AuthenticatedUser::userId);
        }
    }
}
