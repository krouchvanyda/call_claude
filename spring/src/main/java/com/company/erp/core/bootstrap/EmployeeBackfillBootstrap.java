package com.company.erp.core.bootstrap;

import com.company.erp.features.employees.entity.Employee;
import com.company.erp.features.employees.entity.EmployeeStatus;
import com.company.erp.features.employees.repository.EmployeeRepository;
import com.company.erp.features.users.entity.User;
import com.company.erp.features.users.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * On every boot, creates an {@link Employee} row for any existing
 * {@link User} that doesn't already have one. Idempotent — runs after
 * {@code AdminBootstrap} so the seeded super-admin is included.
 *
 * <p>Employee numbers are deterministic: {@code EMP-<userId padded to 5>}.
 * If you want HR-managed numbering, change them via
 * {@code PATCH /api/v1/employees/{id}} afterwards.</p>
 */
@Configuration
public class EmployeeBackfillBootstrap {

    private static final Logger log = LoggerFactory.getLogger(EmployeeBackfillBootstrap.class);

    @Bean
    public ApplicationRunner backfillEmployeesForUsers(
            UserRepository users,
            EmployeeRepository employees,
            TransactionTemplate txTemplate
    ) {
        return args -> txTemplate.executeWithoutResult(status -> {
            int created = 0;
            for (User u : users.findAll()) {
                if (employees.existsByUserId(u.getId())) continue;

                String employeeNo = "EMP-" + String.format("%05d", u.getId());
                if (employees.existsByEmployeeNo(employeeNo)) {
                    log.warn("Skipping backfill for user {}: employee_no {} already taken",
                            u.getId(), employeeNo);
                    continue;
                }

                Employee e = new Employee();
                e.setUserId(u.getId());
                e.setEmployeeNo(employeeNo);
                e.setFullName(u.getFullName());
                e.setWorkEmail(u.getEmail());
                e.setPhone(u.getPhone());
                e.setStatus(EmployeeStatus.ACTIVE);
                employees.save(e);
                created++;
            }
            if (created > 0) {
                log.info("Employee backfill: created {} employee row(s) for existing users", created);
            } else {
                log.debug("Employee backfill: no new rows needed");
            }
        });
    }
}
