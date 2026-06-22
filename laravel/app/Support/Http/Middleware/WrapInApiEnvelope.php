<?php

namespace App\Support\Http\Middleware;

use App\Support\Http\ApiResponse;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Auto-wraps controller return values in the standard envelope so handlers can
 * return DTOs/arrays directly — the analogue of Spring's
 * ResponseEnvelopeAdvice. Skips bodies already wrapped (tagged with the
 * X-Api-Envelope header), file/stream downloads, and infra paths
 * (docs, websockets dashboard, broadcasting auth, static uploads).
 */
class WrapInApiEnvelope
{
    /** @var array<int, string> */
    private static $skipPrefixes = [
        'docs',
        'v3/api-docs',
        'swagger-ui',
        'laravel-websockets',
        'broadcasting/auth',
        'uploads',
        'storage',
    ];

    public function handle(Request $request, Closure $next)
    {
        /** @var \Symfony\Component\HttpFoundation\Response $response */
        $response = $next($request);

        if ($this->shouldSkip($request, $response)) {
            return $response;
        }

        $status = $response->getStatusCode();

        if ($response instanceof JsonResponse) {
            $data = $response->getData(true);
            // Already an envelope (defensive — header check usually catches it).
            if (is_array($data) && array_key_exists('success', $data) && array_key_exists('traceId', $data)) {
                return $response;
            }
            return ApiResponse::ok($data, 'Success', $status)
                ->withHeaders($this->carryHeaders($response));
        }

        // Empty-body responses (e.g. void controller actions) -> data:null.
        $content = $response->getContent();
        if ($content === '' || $content === false) {
            return ApiResponse::ok(null, 'Success', $status === 200 ? 200 : $status)
                ->withHeaders($this->carryHeaders($response));
        }

        return $response;
    }

    private function shouldSkip(Request $request, $response): bool
    {
        if ($response instanceof BinaryFileResponse || $response instanceof StreamedResponse) {
            return true;
        }
        if ($response->headers->get(ApiResponse::ENVELOPE_HEADER) !== null) {
            return true;
        }
        // Redirects and other non-2xx/3xx infra responses are left untouched
        // except plain JSON handled above.
        if ($response->isRedirection()) {
            return true;
        }

        $path = ltrim($request->path(), '/');
        foreach (self::$skipPrefixes as $prefix) {
            if ($path === $prefix || strpos($path, $prefix.'/') === 0) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return array<string, string>
     */
    private function carryHeaders($response): array
    {
        $carry = [];
        foreach (['X-Request-Id'] as $name) {
            $value = $response->headers->get($name);
            if ($value !== null) {
                $carry[$name] = $value;
            }
        }
        return $carry;
    }
}
