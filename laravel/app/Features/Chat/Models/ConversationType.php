<?php

namespace App\Features\Chat\Models;

/** Port of the Spring ConversationType enum (stored as VARCHAR). */
final class ConversationType
{
    const DIRECT = 'DIRECT';
    const GROUP = 'GROUP';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::DIRECT, self::GROUP];
    }

    private function __construct()
    {
    }
}
