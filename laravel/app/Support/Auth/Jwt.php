<?php

namespace App\Support\Auth;

use UnexpectedValueException;

/**
 * Minimal, dependency-free HS256 JWT codec. PHP 7.4-safe and free of any
 * external JWT package (and its security-advisory churn). Only what this app
 * needs: sign with HMAC-SHA256, verify signature + `exp`/`nbf`.
 */
final class Jwt
{
    /**
     * @param array<string, mixed> $payload
     */
    public static function encodeHs256(array $payload, string $secret): string
    {
        $segments = [
            self::b64(json_encode(['alg' => 'HS256', 'typ' => 'JWT'])),
            self::b64(json_encode($payload)),
        ];
        $signingInput = implode('.', $segments);
        $signature = hash_hmac('sha256', $signingInput, $secret, true);
        $segments[] = self::b64($signature);

        return implode('.', $segments);
    }

    /**
     * Verifies the HS256 signature and (if present) the exp / nbf claims.
     *
     * @return array<string, mixed>
     * @throws UnexpectedValueException on a malformed, mis-signed, or expired token
     */
    public static function decodeHs256(string $jwt, string $secret): array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            throw new UnexpectedValueException('Wrong number of segments');
        }
        [$headB64, $payloadB64, $sigB64] = $parts;

        $header = json_decode(self::b64decode($headB64), true);
        if (! is_array($header) || ($header['alg'] ?? null) !== 'HS256') {
            throw new UnexpectedValueException('Unexpected or missing algorithm');
        }

        $expected = hash_hmac('sha256', $headB64.'.'.$payloadB64, $secret, true);
        $provided = self::b64decode($sigB64);
        if (! hash_equals($expected, $provided)) {
            throw new UnexpectedValueException('Signature verification failed');
        }

        $payload = json_decode(self::b64decode($payloadB64), true);
        if (! is_array($payload)) {
            throw new UnexpectedValueException('Invalid claims');
        }

        $now = time();
        if (isset($payload['nbf']) && $now < (int) $payload['nbf']) {
            throw new UnexpectedValueException('Token not yet valid');
        }
        if (isset($payload['exp']) && $now >= (int) $payload['exp']) {
            throw new UnexpectedValueException('Token expired');
        }

        return $payload;
    }

    private static function b64(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function b64decode(string $data): string
    {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $data .= str_repeat('=', 4 - $remainder);
        }
        $decoded = base64_decode(strtr($data, '-_', '+/'), true);
        if ($decoded === false) {
            throw new UnexpectedValueException('Invalid base64url');
        }
        return $decoded;
    }
}
