<?php

namespace App\Features\Employees\Models;

/** Port of the Spring EmployeeStatus enum (stored as VARCHAR). */
final class EmployeeStatus
{
    const ACTIVE = 'ACTIVE';
    const INACTIVE = 'INACTIVE';
    const ON_LEAVE = 'ON_LEAVE';
    const TERMINATED = 'TERMINATED';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::ACTIVE, self::INACTIVE, self::ON_LEAVE, self::TERMINATED];
    }

    private function __construct()
    {
    }
}
