<?php

namespace App\Support\Http\Middleware;

use App\Support\Http\TraceContext;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Per-request traceId. Honours an inbound X-Request-Id if present, otherwise
 * mints a UUID. Stored in TraceContext (read by ApiResponse) and echoed back
 * in the response header — the port of Spring's RequestIdFilter.
 */
class RequestId
{
    const HEADER = 'X-Request-Id';

    public function handle(Request $request, Closure $next)
    {
        $incoming = $request->header(self::HEADER);
        $traceId = (is_string($incoming) && trim($incoming) !== '')
            ? $incoming
            : (string) Str::uuid();

        TraceContext::set($traceId);

        /** @var \Symfony\Component\HttpFoundation\Response $response */
        $response = $next($request);
        $response->headers->set(self::HEADER, $traceId);

        return $response;
    }

    public function terminate($request, $response): void
    {
        TraceContext::clear();
    }
}
