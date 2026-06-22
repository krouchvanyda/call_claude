<?php

namespace App\Support\Http\Middleware;

use App\Support\Auth\AuthenticatedUser;
use App\Support\Exceptions\ForbiddenException;
use App\Support\Exceptions\UnauthorizedException;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Route guard equivalent to @PreAuthorize("hasAuthority('<code>')"). Requires
 * the authenticated principal to carry the given permission code in its token.
 * Usage: ->middleware('permission:user:write').
 */
class EnsurePermission
{
    public function handle(Request $request, Closure $next, string $permission)
    {
        /** @var AuthenticatedUser|null $user */
        $user = Auth::guard('api')->user();

        if (! $user instanceof AuthenticatedUser) {
            throw new UnauthorizedException('Authentication required');
        }
        if (! $user->hasPermission($permission)) {
            throw new ForbiddenException('Forbidden');
        }

        return $next($request);
    }
}
