<?php

namespace App\Features\Devices\Services;

use App\Features\Devices\Models\Device;
use App\Support\Exceptions\NotFoundException;
use Illuminate\Support\Collection;

class DeviceService
{
    /**
     * Upsert by (userId, deviceId) — token rotation overwrites the row in place.
     *
     * @param array<string, mixed> $data  deviceId, fcmToken, platform, appVersion
     */
    public function register(int $userId, array $data): Device
    {
        $device = Device::query()
            ->where('user_id', $userId)
            ->where('device_id', $data['deviceId'])
            ->first();

        if (! $device) {
            $device = new Device();
            $device->user_id = $userId;
            $device->device_id = $data['deviceId'];
        }

        $device->fcm_token = $data['fcmToken'];
        $device->platform = $data['platform'];
        $device->app_version = $data['appVersion'] ?? null;
        $device->save();

        return $device;
    }

    public function delete(int $userId, string $deviceId): void
    {
        $device = Device::query()
            ->where('user_id', $userId)
            ->where('device_id', $deviceId)
            ->first();

        if (! $device) {
            throw new NotFoundException('Device not registered');
        }
        $device->delete();
    }

    /**
     * @return Collection<int, Device>
     */
    public function listForUser(int $userId): Collection
    {
        return Device::query()->where('user_id', $userId)->get();
    }

    /**
     * @param array<int, int> $userIds
     * @return Collection<int, Device>
     */
    public function listForUsers(array $userIds): Collection
    {
        if (empty($userIds)) {
            return collect();
        }
        return Device::query()->whereIn('user_id', $userIds)->get();
    }

    /**
     * FCM tokens for the given users.
     *
     * @param array<int, int> $userIds
     * @return array<int, string>
     */
    public function tokensForUsers(array $userIds): array
    {
        return $this->listForUsers($userIds)->pluck('fcm_token')->all();
    }
}
