<?php

namespace App\Features\Chat\Models;

/** Port of the Spring CallType enum (stored as VARCHAR). */
final class CallType
{
    const VOICE = 'VOICE';
    const VIDEO = 'VIDEO';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::VOICE, self::VIDEO];
    }

    private function __construct()
    {
    }
}
