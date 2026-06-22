package com.company.erp.features.employees.dto;

import com.company.erp.features.employees.entity.Employee;
import com.company.erp.features.employees.entity.EmployeeStatus;

import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.time.ZoneId;

public record EmployeeDto(
        Long id,
        Long userId,
        String employeeNo,
        String fullName,
        String workEmail,
        String phone,
        String position,
        String department,
        LocalDate hireDate,
        LocalDate dateOfBirth,
        String gender,
        String address,
        String avatarUrl,
        String avatarContentType,
        Instant avatarUploadedAt,
        String emergencyContact,
        String emergencyPhone,
        Instant lastLoginAt,
        /** Derived from hireDate at read time, formatted like "2y 5m". null if no hireDate. */
        String tenure,
        EmployeeStatus status
) {
    public static EmployeeDto from(Employee e) {
        return new EmployeeDto(
                e.getId(),
                e.getUserId(),
                e.getEmployeeNo(),
                e.getFullName(),
                e.getWorkEmail(),
                e.getPhone(),
                e.getPosition(),
                e.getDepartment(),
                e.getHireDate(),
                e.getDateOfBirth(),
                e.getGender(),
                e.getAddress(),
                e.getAvatarUrl(),
                e.getAvatarContentType(),
                e.getAvatarUploadedAt(),
                e.getEmergencyContact(),
                e.getEmergencyPhone(),
                e.getLastLoginAt(),
                formatTenure(e.getHireDate()),
                e.getStatus());
    }

    private static String formatTenure(LocalDate hireDate) {
        if (hireDate == null) return null;
        LocalDate today = LocalDate.now(ZoneId.of("UTC"));
        if (hireDate.isAfter(today)) return "0y 0m";
        Period p = Period.between(hireDate, today);
        return p.getYears() + "y " + p.getMonths() + "m";
    }
}
