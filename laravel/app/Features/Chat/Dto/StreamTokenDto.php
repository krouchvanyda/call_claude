<?php

namespace App\Features\Chat\Dto;

use DateTimeInterface;

/**
 * Port of the Spring StreamTokenDto record — a short-lived Stream Video user
 * token the mobile SDK exchanges for an authenticated media session.
 */
final class StreamTokenDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(string $token, string $apiKey, string $userId, DateTimeInterface $expiresAt): array
    {
        return [
            'token' => $token,
            'apiKey' => $apiKey,
            'userId' => $userId,
            'expiresAt' => $expiresAt->format('Y-m-d\TH:i:s\Z'),
        ];
    }
}
