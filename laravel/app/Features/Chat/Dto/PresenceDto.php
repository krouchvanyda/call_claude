<?php

namespace App\Features\Chat\Dto;

use DateTimeInterface;

/** Port of the Spring PresenceDto record. */
final class PresenceDto
{
    /**
     * @param DateTimeInterface|null $lastSeenAt  when the user last went OFFLINE, else null
     * @return array<string, mixed>
     */
    public static function from(int $userId, string $status, ?DateTimeInterface $lastSeenAt): array
    {
        return [
            'userId' => $userId,
            'status' => $status,
            'lastSeenAt' => $lastSeenAt ? $lastSeenAt->format('Y-m-d\TH:i:s\Z') : null,
        ];
    }
}
