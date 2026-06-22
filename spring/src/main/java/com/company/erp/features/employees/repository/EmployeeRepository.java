package com.company.erp.features.employees.repository;

import com.company.erp.features.employees.entity.Employee;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    Optional<Employee> findByUserId(Long userId);

    boolean existsByEmployeeNo(String employeeNo);

    boolean existsByUserId(Long userId);

    @Query("""
            SELECT e FROM Employee e
            WHERE (:q IS NULL OR :q = ''
                   OR LOWER(e.fullName)   LIKE LOWER(CONCAT('%', :q, '%'))
                   OR LOWER(e.employeeNo) LIKE LOWER(CONCAT('%', :q, '%'))
                   OR LOWER(COALESCE(e.workEmail, '')) LIKE LOWER(CONCAT('%', :q, '%')))
           """)
    Page<Employee> search(@Param("q") String q, Pageable pageable);
}
