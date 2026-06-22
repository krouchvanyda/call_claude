package com.company.erp.features.employees.dto;

import com.company.erp.features.employees.entity.EmployeeStatus;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record UpdateEmployeeRequest(
        Long userId,
        @Size(max = 64)  String employeeNo,
        @Size(max = 255) String fullName,
        @Email @Size(max = 255) String workEmail,
        @Size(max = 50)  String phone,
        @Size(max = 128) String position,
        @Size(max = 128) String department,
        LocalDate hireDate,
        LocalDate dateOfBirth,
        @Size(max = 16)   String gender,
        @Size(max = 1024) String address,
        @Size(max = 1024) String avatarUrl,
        @Size(max = 255)  String emergencyContact,
        @Size(max = 50)   String emergencyPhone,
        EmployeeStatus status
) {
}
