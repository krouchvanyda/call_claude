<?php

namespace App\Support\Http\Middleware;

use App\Support\Http\ApiResponse;
use App\Support\Response\ErrorCodes;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

/**
 * Per-IP token bucket — auth endpoints get a stricter bucket so password
 * spraying / signup abuse is easier to throttle. Cache-backed fixed window of
 * one minute, the port of the Spring Bucket4j RateLimitFilter.
 *
 * NOTE: the cache store should be shared (Redis) for multi-instance
 * deployments — the default file/array store is per-process, same caveat as
 * the original in-memory buckets.
 */
class RateLimitPerIp
{
    public function handle(Request $request, Closure $next)
    {
        if (! config('erp.rate_limit.enabled')) {
            return $next($request);
        }

        $path = ltrim($request->path(), '/');
        if ($path === 'health' || $path === 'actuator' || strpos($path, 'actuator/') === 0) {
            return $next($request);
        }

        $isAuthPath = strpos($path, 'api/v1/auth/') !== false;
        $capacity = $isAuthPath
            ? (int) config('erp.rate_limit.auth_per_minute')
            : (int) config('erp.rate_limit.per_minute');

        $window = (int) floor(time() / 60);
        $bucket = ($isAuthPath ? 'auth' : 'general').'|'.$this->clientIp($request);
        $key = 'ratelimit:'.$bucket.':'.$window;

        $count = (int) Cache::get($key, 0);
        if ($count >= $capacity) {
            return ApiResponse::error('Too many requests', ErrorCodes::RATE_LIMITED, null, 429);
        }

        // Increment with a 1-minute TTL on first write.
        if ($count === 0) {
            Cache::put($key, 1, now()->addSeconds(61));
        } else {
            Cache::increment($key);
        }

        return $next($request);
    }

    private function clientIp(Request $request): string
    {
        $ip = $request->ip();
        return ($ip === null || $ip === '') ? 'unknown' : $ip;
    }
}
