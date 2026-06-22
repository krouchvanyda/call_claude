<?php

namespace App\Support\Http;

/**
 * Per-request trace id holder — the Laravel analogue of Spring's MDC
 * `traceId`. Set by the RequestId middleware, read by ApiResponse so every
 * envelope carries the same trace id that is echoed in the X-Request-Id header.
 */
final class TraceContext
{
    /** @var string|null */
    private static $traceId = null;

    public static function set(?string $traceId): void
    {
        self::$traceId = $traceId;
    }

    public static function get(): ?string
    {
        return self::$traceId;
    }

    public static function clear(): void
    {
        self::$traceId = null;
    }
}
