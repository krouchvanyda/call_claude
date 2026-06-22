<?php

namespace App\Features\Auth\Dto;

/** Port of the Spring AuthResponse record. */
final class AuthResponse
{
    /**
     * @param array<string, mixed> $user  UserDto array
     * @return array<string, mixed>
     */
    public static function build(
        string $accessToken,
        int $accessTokenExpiresAt,
        string $refreshToken,
        int $refreshTokenExpiresAt,
        array $user
    ): array {
        return [
            'accessToken' => $accessToken,
            'accessTokenExpiresAt' => self::iso($accessTokenExpiresAt),
            'refreshToken' => $refreshToken,
            'refreshTokenExpiresAt' => self::iso($refreshTokenExpiresAt),
            'user' => $user,
        ];
    }

    private static function iso(int $epochSeconds): string
    {
        return gmdate('Y-m-d\TH:i:s\Z', $epochSeconds);
    }
}
