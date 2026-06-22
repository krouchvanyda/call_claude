<?php

namespace App\Features\Chat\Models;

/**
 * Port of the Spring PresenceStatus enum.
 *
 * - ONLINE:  at least one active session, and not currently in a call.
 * - BUSY:    at least one active session AND currently in (or starting) a call.
 * - OFFLINE: no active sessions.
 */
final class PresenceStatus
{
    const ONLINE = 'ONLINE';
    const BUSY = 'BUSY';
    const OFFLINE = 'OFFLINE';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::ONLINE, self::BUSY, self::OFFLINE];
    }

    private function __construct()
    {
    }
}
