<?php

namespace App\Features\Chat\Models;

/** Port of the Spring MemberRole enum (stored as VARCHAR). */
final class MemberRole
{
    const ADMIN = 'ADMIN';
    const MEMBER = 'MEMBER';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::ADMIN, self::MEMBER];
    }

    private function __construct()
    {
    }
}
