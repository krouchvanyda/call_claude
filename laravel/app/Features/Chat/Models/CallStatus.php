<?php

namespace App\Features\Chat\Models;

/** Port of the Spring CallStatus enum (stored as VARCHAR). */
final class CallStatus
{
    const RINGING = 'RINGING';
    const ANSWERED = 'ANSWERED';
    const ENDED = 'ENDED';
    const MISSED = 'MISSED';
    const REJECTED = 'REJECTED';
    const BUSY = 'BUSY';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::RINGING, self::ANSWERED, self::ENDED, self::MISSED, self::REJECTED, self::BUSY];
    }

    private function __construct()
    {
    }
}
