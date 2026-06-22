<?php

/*
|--------------------------------------------------------------------------
| Application properties (port of Spring's `app.*` / AppProperties)
|--------------------------------------------------------------------------
|
| Every value is env-driven with the same defaults as the original
| application.yml. Durations that were ISO-8601 (PT15M / P14D) are expressed
| here as integer seconds so they map cleanly onto JWT exp claims.
|
*/

return [

    'security' => [
        'jwt' => [
            'issuer' => env('JWT_ISSUER', 'erp'),
            'secret' => env('JWT_SECRET', 'dev-secret-change-me-in-production-must-be-long-enough-for-hmac-sha256'),
            // 15 minutes / 14 days, in seconds.
            'access_token_ttl' => (int) env('JWT_ACCESS_TTL_SECONDS', 900),
            'refresh_token_ttl' => (int) env('JWT_REFRESH_TTL_SECONDS', 1209600),
        ],
    ],

    'rate_limit' => [
        'enabled' => filter_var(env('RATE_LIMIT_ENABLED', true), FILTER_VALIDATE_BOOLEAN),
        'per_minute' => (int) env('RATE_LIMIT_PER_MINUTE', 120),
        'auth_per_minute' => (int) env('AUTH_RATE_LIMIT_PER_MINUTE', 20),
    ],

    'stream' => [
        'api_key' => env('STREAM_API_KEY', ''),
        'api_secret' => env('STREAM_API_SECRET', ''),
        'token_ttl_minutes' => (int) env('STREAM_TOKEN_TTL_MINUTES', 60),
    ],

    'fcm' => [
        'enabled' => filter_var(env('FCM_ENABLED', false), FILTER_VALIDATE_BOOLEAN),
        'service_account_json_path' => env('FCM_SERVICE_ACCOUNT_JSON_PATH', ''),
    ],

    'chat' => [
        'call' => [
            'ring_timeout_seconds' => (int) env('CHAT_CALL_RING_TIMEOUT_SECONDS', 60),
            'accept_grace_seconds' => (int) env('CHAT_CALL_ACCEPT_GRACE_SECONDS', 5),
            'sweep_interval_ms' => (int) env('CHAT_CALL_SWEEP_INTERVAL_MS', 5000),
        ],
    ],

    'uploads' => [
        'avatar' => [
            'dir' => env('UPLOAD_AVATAR_DIR', base_path('uploads/avatars')),
            'public_base_url' => env('UPLOAD_AVATAR_PUBLIC_BASE_URL', '/uploads/avatars'),
            'max_file_size' => (int) env('UPLOAD_AVATAR_MAX_SIZE', 5242880),
            'allowed_content_types' => env('UPLOAD_AVATAR_ALLOWED_TYPES', 'image/jpeg,image/png,image/webp'),
        ],
    ],

    // STOMP-over-WebSocket realtime (Spring SimpleBroker replacement). The REST
    // app publishes frames to this Redis channel; erp:stomp-serve fans them out.
    'stomp' => [
        'channel' => env('STOMP_REDIS_CHANNEL', 'erp.stomp'),
        'host' => env('STOMP_HOST', '0.0.0.0'),
        'port' => (int) env('STOMP_PORT', 8090),
    ],

];
