package com.company.erp.features.employees.entity;

import com.company.erp.core.database.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "employees")
public class Employee extends BaseEntity {

    /** Optional FK to the login user. One employee per user (unique on the DB side). */
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "employee_no", nullable = false, unique = true)
    private String employeeNo;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "work_email")
    private String workEmail;

    @Column
    private String phone;

    @Column
    private String position;

    @Column
    private String department;

    @Column(name = "hire_date")
    private LocalDate hireDate;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column
    private String gender;

    @Column
    private String address;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "avatar_content_type")
    private String avatarContentType;

    @Column(name = "avatar_uploaded_at")
    private Instant avatarUploadedAt;

    @Column(name = "emergency_contact")
    private String emergencyContact;

    @Column(name = "emergency_phone")
    private String emergencyPhone;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EmployeeStatus status = EmployeeStatus.ACTIVE;
}
