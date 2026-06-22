<?php

namespace App\Features\Devices\Dto;

use App\Features\Devices\Models\Device;

/** Port of the Spring DeviceDto record. */
final class DeviceDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(Device $d): array
    {
        return [
            'id' => (int) $d->id,
            'deviceId' => $d->device_id,
            'platform' => $d->platform,
            'appVersion' => $d->app_version,
            'updatedAt' => $d->updated_at ? $d->updated_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
        ];
    }
}
