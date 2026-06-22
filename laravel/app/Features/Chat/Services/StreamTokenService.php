<?php

namespace App\Features\Chat\Services;

use App\Features\Chat\Dto\StreamTokenDto;
use App\Support\Auth\Jwt;
use App\Support\Exceptions\BadRequestException;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Log;

/**
 * Port of the Spring StreamTokenService. Mints Stream Video user tokens —
 * standard JWT, HS256-signed with the project API secret, carrying a single
 * `user_id` claim plus `iat` / `exp`.
 *
 * Requires STREAM_API_KEY and STREAM_API_SECRET (config erp.stream.*);
 * otherwise issueFor() throws BadRequestException (the Spring endpoint returned
 * 400 BAD_REQUEST).
 */
class StreamTokenService
{
    public function isEnabled(): bool
    {
        $secret = (string) config('erp.stream.api_secret');
        $apiKey = (string) config('erp.stream.api_key');
        return $secret !== '' && $apiKey !== '';
    }

    /**
     * @return array<string, mixed>
     */
    public function issueFor(int $userId): array
    {
        if (! $this->isEnabled()) {
            Log::warning('[stream] token requested but Stream not configured (userId='.$userId.')');
            throw new BadRequestException(
                'Stream Video is not configured — set STREAM_API_KEY and STREAM_API_SECRET'
            );
        }

        $now = CarbonImmutable::now('UTC');
        $ttlMinutes = (int) config('erp.stream.token_ttl_minutes');
        if ($ttlMinutes <= 0) {
            $ttlMinutes = 60;
        }
        $exp = $now->addMinutes($ttlMinutes);
        $userIdStr = (string) $userId;

        $payload = [
            'user_id' => $userIdStr,
            'iat' => $now->getTimestamp(),
            'exp' => $exp->getTimestamp(),
        ];

        $token = Jwt::encodeHs256($payload, (string) config('erp.stream.api_secret'));

        Log::info('[stream] minted token for userId='.$userIdStr.' expiresAt='.$exp->toIso8601String());
        return StreamTokenDto::from($token, (string) config('erp.stream.api_key'), $userIdStr, $exp);
    }

    /** Deterministic call CID — same call → same CID on every device. */
    public function cidForCall(int $callId): string
    {
        return 'default:erp-call-'.$callId;
    }
}
