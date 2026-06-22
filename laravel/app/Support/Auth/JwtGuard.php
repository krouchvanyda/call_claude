<?php

namespace App\Support\Auth;

use App\Support\Exceptions\UnauthorizedException;
use Illuminate\Contracts\Auth\Guard;
use Illuminate\Http\Request;
use Illuminate\Support\Traits\Macroable;

/**
 * Stateless bearer-token guard — the analogue of the Spring JwtAuthFilter.
 * Reads the Authorization header, validates the access token via JwtService,
 * and exposes an AuthenticatedUser principal. An invalid / missing token
 * simply yields a guest (null user); enforcement is left to the `auth`
 * middleware, mirroring the original filter that silently cleared the context.
 */
class JwtGuard implements Guard
{
    use Macroable;

    /** @var JwtService */
    protected $jwt;

    /** @var Request */
    protected $request;

    /** @var AuthenticatedUser|null */
    protected $user = null;

    /** @var bool */
    protected $resolved = false;

    public function __construct(JwtService $jwt, Request $request)
    {
        $this->jwt = $jwt;
        $this->request = $request;
    }

    public function check()
    {
        return $this->user() !== null;
    }

    public function guest()
    {
        return ! $this->check();
    }

    public function user()
    {
        if ($this->resolved) {
            return $this->user;
        }
        $this->resolved = true;

        $token = $this->bearerToken();
        if ($token === null || $token === '') {
            return $this->user = null;
        }

        try {
            $this->user = $this->jwt->parseAccess($token);
        } catch (UnauthorizedException $e) {
            $this->user = null;
        }

        return $this->user;
    }

    public function id()
    {
        $user = $this->user();
        return $user ? $user->getAuthIdentifier() : null;
    }

    public function validate(array $credentials = [])
    {
        return false;
    }

    public function hasUser()
    {
        return $this->user !== null;
    }

    public function setUser(\Illuminate\Contracts\Auth\Authenticatable $user)
    {
        $this->user = $user;
        $this->resolved = true;

        return $this;
    }

    public function setRequest(Request $request): self
    {
        $this->request = $request;
        $this->resolved = false;
        $this->user = null;

        return $this;
    }

    protected function bearerToken(): ?string
    {
        return $this->request->bearerToken();
    }
}
