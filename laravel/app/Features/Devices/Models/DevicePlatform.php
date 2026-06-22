<?php

namespace App\Features\Devices\Models;

/** Port of the Spring DevicePlatform enum (stored lowercase). */
final class DevicePlatform
{
    const ANDROID = 'android';
    const IOS = 'ios';
    const WEB = 'web';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return [self::ANDROID, self::IOS, self::WEB];
    }

    private function __construct()
    {
    }
}
