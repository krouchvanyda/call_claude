<?php

namespace App\Features\Devices\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * FCM sender built directly on the Firebase Cloud Messaging HTTP v1 API — no
 * external SDK, so it stays clean on PHP 7.4. Pushes are data-only (no
 * notification block) so the Flutter background handler runs and the call sheet
 * can be drawn. All sends are exception-swallowing — a failed FCM delivery must
 * never block the underlying call/REST flow.
 *
 * Port of the Spring FcmService. Stays a no-op unless FCM_ENABLED=true and a
 * service-account JSON path is configured.
 */
class FcmService
{
    const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
    const TOKEN_URI = 'https://oauth2.googleapis.com/token';

    /** @var bool */
    private $initialised = false;

    /** @var bool */
    private $ready = false;

    /** @var string */
    private $projectId = '';

    /** @var string */
    private $clientEmail = '';

    /** @var string */
    private $privateKey = '';

    /** @var string|null */
    private $cachedToken = null;

    /** @var int */
    private $cachedTokenExpiresAt = 0;

    private function init(): void
    {
        if ($this->initialised) {
            return;
        }
        $this->initialised = true;

        if (! (bool) config('erp.fcm.enabled')) {
            Log::warning('[fcm] disabled (FCM_ENABLED=false). Call invites will not push.');
            return;
        }
        $saPath = (string) config('erp.fcm.service_account_json_path');
        if ($saPath === '' || ! is_file($saPath)) {
            Log::warning('[fcm] FCM_ENABLED=true but service-account JSON is missing — disabling.');
            return;
        }

        $sa = json_decode((string) file_get_contents($saPath), true);
        if (! is_array($sa) || empty($sa['project_id']) || empty($sa['client_email']) || empty($sa['private_key'])) {
            Log::error('[fcm] service-account JSON at '.$saPath.' is missing required fields — disabling.');
            return;
        }

        $this->projectId = (string) $sa['project_id'];
        $this->clientEmail = (string) $sa['client_email'];
        $this->privateKey = (string) $sa['private_key'];
        $this->ready = true;
        Log::info('[fcm] initialised for project '.$this->projectId);
    }

    public function isReady(): bool
    {
        $this->init();
        return $this->ready;
    }

    /**
     * Fire-and-forget data-only push to every supplied token. Failures are
     * logged at WARN and never propagated.
     *
     * @param array<int, string> $tokens
     * @param array<string, string|null> $data
     */
    public function sendDataToTokens(array $tokens, array $data): void
    {
        $this->init();
        if (! $this->ready) {
            Log::debug('[fcm] skip send — service not ready (tokens='.count($tokens).')');
            return;
        }
        if (empty($tokens)) {
            return;
        }

        try {
            $accessToken = $this->accessToken();
        } catch (Throwable $e) {
            Log::warning('[fcm] could not mint access token: '.$e->getMessage());
            return;
        }
        if ($accessToken === null) {
            return;
        }

        $safeData = [];
        foreach ($data as $k => $v) {
            $safeData[$k] = $v === null ? '' : (string) $v;
        }

        $endpoint = 'https://fcm.googleapis.com/v1/projects/'.$this->projectId.'/messages:send';

        foreach ($tokens as $token) {
            try {
                $resp = Http::withToken($accessToken)->post($endpoint, [
                    'message' => [
                        'token' => $token,
                        'data' => $safeData,
                        'android' => ['priority' => 'HIGH'],
                        'apns' => [
                            'headers' => ['apns-priority' => '10', 'apns-push-type' => 'alert'],
                            'payload' => ['aps' => ['content-available' => 1]],
                        ],
                    ],
                ]);
                if ($resp->successful()) {
                    Log::info('[fcm] sent type='.($safeData['type'] ?? '').' to token=…'.$this->tail($token));
                } else {
                    Log::warning('[fcm] send failed type='.($safeData['type'] ?? '').' token=…'.$this->tail($token)
                        .' status='.$resp->status());
                }
            } catch (Throwable $e) {
                Log::warning('[fcm] send failed type='.($safeData['type'] ?? '').' token=…'.$this->tail($token).': '.$e->getMessage());
            }
        }
    }

    /**
     * OAuth2 access token via the service-account JWT-bearer grant. Cached until
     * shortly before it expires.
     */
    private function accessToken(): ?string
    {
        if ($this->cachedToken !== null && time() < $this->cachedTokenExpiresAt - 60) {
            return $this->cachedToken;
        }

        $now = time();
        $assertion = $this->signRs256([
            'iss' => $this->clientEmail,
            'scope' => self::SCOPE,
            'aud' => self::TOKEN_URI,
            'iat' => $now,
            'exp' => $now + 3600,
        ]);

        $resp = Http::asForm()->post(self::TOKEN_URI, [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $assertion,
        ]);

        if (! $resp->successful() || ! $resp->json('access_token')) {
            Log::warning('[fcm] token endpoint returned status='.$resp->status());
            return null;
        }

        $this->cachedToken = (string) $resp->json('access_token');
        $this->cachedTokenExpiresAt = $now + (int) ($resp->json('expires_in') ?: 3600);

        return $this->cachedToken;
    }

    /**
     * @param array<string, mixed> $claims
     */
    private function signRs256(array $claims): string
    {
        $segments = [
            $this->b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])),
            $this->b64(json_encode($claims)),
        ];
        $signingInput = implode('.', $segments);

        $signature = '';
        if (! openssl_sign($signingInput, $signature, $this->privateKey, 'sha256WithRSAEncryption')) {
            throw new \RuntimeException('Failed to sign FCM OAuth2 assertion');
        }
        $segments[] = $this->b64($signature);

        return implode('.', $segments);
    }

    private function b64(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private function tail(string $t): string
    {
        return strlen($t) < 6 ? '?' : substr($t, -6);
    }
}
