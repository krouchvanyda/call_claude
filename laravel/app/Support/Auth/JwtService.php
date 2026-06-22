<?php

namespace App\Support\Auth;

use App\Support\Exceptions\UnauthorizedException;
use Illuminate\Support\Str;

/**
 * Issues and parses access / refresh JWTs (HMAC-SHA256), a faithful port of
 * the Spring JwtService.
 *
 * Access tokens carry: sub (user id), email, pms (permission codes), typ=access.
 * Refresh tokens carry: sub, jti, typ=refresh — the jti is persisted in
 * refresh_tokens so the token can be rotated / revoked.
 */
class JwtService
{
    const ALG = 'HS256';
    const CLAIM_EMAIL = 'email';
    const CLAIM_PERMISSIONS = 'pms';
    const CLAIM_TYPE = 'typ';
    const TYPE_ACCESS = 'access';
    const TYPE_REFRESH = 'refresh';

    /** @var string */
    private $issuer;

    /** @var string */
    private $secret;

    /** @var int seconds */
    private $accessTtl;

    /** @var int seconds */
    private $refreshTtl;

    public function __construct()
    {
        $this->issuer = (string) config('erp.security.jwt.issuer');
        $this->secret = (string) config('erp.security.jwt.secret');
        $this->accessTtl = (int) config('erp.security.jwt.access_token_ttl');
        $this->refreshTtl = (int) config('erp.security.jwt.refresh_token_ttl');
    }

    /**
     * @param array<int, string> $permissions
     * @return array{value:string, jti:string, expiresAt:int}
     */
    public function issueAccess(int $userId, string $email, array $permissions): array
    {
        $now = time();
        $exp = $now + $this->accessTtl;
        $jti = (string) Str::uuid();
        $token = Jwt::encodeHs256([
            'iss' => $this->issuer,
            'sub' => (string) $userId,
            'jti' => $jti,
            'iat' => $now,
            'exp' => $exp,
            self::CLAIM_EMAIL => $email,
            self::CLAIM_PERMISSIONS => array_values($permissions),
            self::CLAIM_TYPE => self::TYPE_ACCESS,
        ], $this->secret);

        return ['value' => $token, 'jti' => $jti, 'expiresAt' => $exp];
    }

    /**
     * @return array{value:string, jti:string, expiresAt:int}
     */
    public function issueRefresh(int $userId): array
    {
        $now = time();
        $exp = $now + $this->refreshTtl;
        $jti = (string) Str::uuid();
        $token = Jwt::encodeHs256([
            'iss' => $this->issuer,
            'sub' => (string) $userId,
            'jti' => $jti,
            'iat' => $now,
            'exp' => $exp,
            self::CLAIM_TYPE => self::TYPE_REFRESH,
        ], $this->secret);

        return ['value' => $token, 'jti' => $jti, 'expiresAt' => $exp];
    }

    public function parseAccess(string $token): AuthenticatedUser
    {
        $claims = $this->parse($token);
        if (($claims['typ'] ?? null) !== self::TYPE_ACCESS) {
            throw new UnauthorizedException('Wrong token type');
        }
        $email = isset($claims[self::CLAIM_EMAIL]) ? (string) $claims[self::CLAIM_EMAIL] : '';
        $perms = $claims[self::CLAIM_PERMISSIONS] ?? [];
        $permissions = is_array($perms) ? array_map('strval', $perms) : [];

        return new AuthenticatedUser((int) $claims['sub'], $email, $permissions);
    }

    /**
     * @return array{userId:int, jti:string, expiresAt:int}
     */
    public function parseRefresh(string $token): array
    {
        $claims = $this->parse($token);
        if (($claims['typ'] ?? null) !== self::TYPE_REFRESH) {
            throw new UnauthorizedException('Wrong token type');
        }

        return [
            'userId' => (int) $claims['sub'],
            'jti' => (string) ($claims['jti'] ?? ''),
            'expiresAt' => (int) ($claims['exp'] ?? 0),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function parse(string $token): array
    {
        try {
            $decoded = Jwt::decodeHs256($token, $this->secret);
        } catch (\Throwable $e) {
            throw new UnauthorizedException('Invalid or expired token');
        }

        if (($decoded['iss'] ?? null) !== $this->issuer) {
            throw new UnauthorizedException('Invalid or expired token');
        }

        return $decoded;
    }
}
