<?php

namespace App\Features\Chat\Models;

/** Port of the Spring ParticipantStatus enum (stored as VARCHAR). */
final class ParticipantStatus
{
    const RINGING = 'RINGING';
    const ANSWERED = 'ANSWERED';
    const REJECTED = 'REJECTED';
    const LEFT = 'LEFT';
    const MISSED = 'MISSED';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::RINGING, self::ANSWERED, self::REJECTED, self::LEFT, self::MISSED];
    }

    private function __construct()
    {
    }
}
