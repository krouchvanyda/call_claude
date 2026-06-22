package com.company.erp.core.bootstrap;

import com.company.erp.features.users.entity.Role;
import com.company.erp.features.users.entity.User;
import com.company.erp.features.users.repository.RoleRepository;
import com.company.erp.features.users.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.HashSet;
import java.util.Set;

/**
 * On first boot, creates the seeded super-admin user referenced by the README:
 *
 * <pre>
 *     email:    admin@company.local
 *     password: Admin@12345
 * </pre>
 *
 * Idempotent — does nothing if the user already exists. The actual bcrypt hash
 * has to be produced at runtime (SQL can't produce one) so this runs after
 * Flyway's V3 seeds the SUPER_ADMIN role.
 *
 * <p><strong>CHANGE THE PASSWORD immediately in any non-local environment.</strong></p>
 */
@Configuration
public class AdminBootstrap {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);
    private static final String ADMIN_EMAIL    = "admin@company.local";
    private static final String ADMIN_PASSWORD = "Admin@12345";

    @Bean
    public ApplicationRunner seedAdminUser(
            UserRepository users,
            RoleRepository roles,
            PasswordEncoder passwords,
            TransactionTemplate txTemplate
    ) {
        return args -> txTemplate.executeWithoutResult(status -> {
            if (users.existsByEmail(ADMIN_EMAIL)) {
                log.debug("Bootstrap admin {} already exists; skipping", ADMIN_EMAIL);
                return;
            }
            Role superAdmin = roles.findByCode("SUPER_ADMIN")
                    .orElseThrow(() -> new IllegalStateException("SUPER_ADMIN role missing — did Flyway V3 run?"));

            User admin = new User();
            admin.setEmail(ADMIN_EMAIL);
            admin.setPasswordHash(passwords.encode(ADMIN_PASSWORD));
            admin.setFullName("Bootstrap Admin");
            Set<Role> roleSet = new HashSet<>();
            roleSet.add(superAdmin);
            admin.setRoles(roleSet);
            users.save(admin);

            log.warn("Bootstrap admin seeded: {} / {} — CHANGE THIS PASSWORD",
                    ADMIN_EMAIL, ADMIN_PASSWORD);
        });
    }
}
