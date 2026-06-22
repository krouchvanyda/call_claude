<?php

namespace App\Support\Http\Middleware;

use App\Support\Exceptions\UnauthorizedException;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Enforces a valid access token on protected routes. Resolves the JWT guard
 * and, if no principal is present, throws UnauthorizedException (rendered as
 * the standard 401 envelope) — the equivalent of Spring's
 * RestAuthenticationEntryPoint on `anyRequest().authenticated()`.
 */
class Authenticate
{
    public function handle(Request $request, Closure $next, string $guard = 'api')
    {
        if (Auth::guard($guard)->guest()) {
            throw new UnauthorizedException('Authentication required');
        }

        Auth::shouldUse($guard);

        return $next($request);
    }
}
