<?php

namespace App\Features\Auth\Controllers;

use App\Features\Auth\Requests\LoginRequest;
use App\Features\Auth\Requests\LogoutRequest;
use App\Features\Auth\Requests\RefreshRequest;
use App\Features\Auth\Requests\RegisterRequest;
use App\Features\Auth\Services\AuthService;
use App\Http\Controllers\Controller;
use App\Support\Http\ApiResponse;

class AuthController extends Controller
{
    /** @var AuthService */
    private $auth;

    public function __construct(AuthService $auth)
    {
        $this->auth = $auth;
    }

    /** Exchange email + password for an access + refresh token pair. */
    public function login(LoginRequest $request)
    {
        return $this->auth->login($request->input('email'), $request->input('password'));
    }

    /** Create a new user account and immediately issue tokens for them. */
    public function register(RegisterRequest $request)
    {
        return $this->auth->register(
            $request->input('email'),
            $request->input('password'),
            $request->input('fullName'),
            $request->input('phone')
        );
    }

    /** Rotate tokens — exchange a refresh token for a new access + refresh pair. */
    public function refresh(RefreshRequest $request)
    {
        return $this->auth->refresh($request->input('refreshToken'));
    }

    /** Revoke a refresh token; always succeeds even if the token is unknown. */
    public function logout(LogoutRequest $request)
    {
        $this->auth->logout($request->input('refreshToken'));
        return ApiResponse::empty('Logged out');
    }
}
