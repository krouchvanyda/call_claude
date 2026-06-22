<?php

namespace App\Features\Chat\Models;

/** Port of the Spring MessageType enum (stored as VARCHAR). */
final class MessageType
{
    const TEXT = 'TEXT';
    const IMAGE = 'IMAGE';
    const VOICE = 'VOICE';
    const FILE = 'FILE';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::TEXT, self::IMAGE, self::VOICE, self::FILE];
    }

    private function __construct()
    {
    }
}
