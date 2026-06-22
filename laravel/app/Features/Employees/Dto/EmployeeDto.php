<?php

namespace App\Features\Employees\Dto;

use App\Features\Employees\Models\Employee;
use Carbon\CarbonImmutable;

/**
 * Port of the Spring EmployeeDto record, including the derived `tenure`
 * ("2y 5m") computed from hire_date at read time.
 */
final class EmployeeDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(Employee $e): array
    {
        return [
            'id' => (int) $e->id,
            'userId' => $e->user_id !== null ? (int) $e->user_id : null,
            'employeeNo' => $e->employee_no,
            'fullName' => $e->full_name,
            'workEmail' => $e->work_email,
            'phone' => $e->phone,
            'position' => $e->position,
            'department' => $e->department,
            'hireDate' => $e->hire_date ? $e->hire_date->format('Y-m-d') : null,
            'dateOfBirth' => $e->date_of_birth ? $e->date_of_birth->format('Y-m-d') : null,
            'gender' => $e->gender,
            'address' => $e->address,
            'avatarUrl' => $e->avatar_url,
            'avatarContentType' => $e->avatar_content_type,
            'avatarUploadedAt' => $e->avatar_uploaded_at ? $e->avatar_uploaded_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'emergencyContact' => $e->emergency_contact,
            'emergencyPhone' => $e->emergency_phone,
            'lastLoginAt' => $e->last_login_at ? $e->last_login_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'tenure' => self::formatTenure($e->hire_date),
            'status' => $e->status,
        ];
    }

    private static function formatTenure($hireDate): ?string
    {
        if ($hireDate === null) {
            return null;
        }
        $hire = CarbonImmutable::parse($hireDate->format('Y-m-d'), 'UTC')->startOfDay();
        $today = CarbonImmutable::now('UTC')->startOfDay();
        if ($hire->greaterThan($today)) {
            return '0y 0m';
        }
        $diff = $hire->diff($today);
        return $diff->y.'y '.$diff->m.'m';
    }
}
