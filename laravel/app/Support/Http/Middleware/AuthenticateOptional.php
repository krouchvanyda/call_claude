<?php

namespace App\Support\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Resolves the JWT guard if a token is present but never rejects the request.
 * Used by endpoints that are open but still want $request->user() populated.
 */
class AuthenticateOptional
{
    public function handle(Request $request, Closure $next, string $guard = 'api')
    {
        Auth::shouldUse($guard);
        Auth::guard($guard)->user();

        return $next($request);
    }
}
