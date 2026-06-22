<?php

namespace App\Features\Auth\Services;

use App\Features\Auth\Dto\AuthResponse;
use App\Features\Auth\Models\RefreshToken;
use App\Features\Employees\Services\EmployeeService;
use App\Features\Users\Dto\UserDto;
use App\Features\Users\Models\User;
use App\Support\Auth\JwtService;
use App\Support\Exceptions\ConflictException;
use App\Support\Exceptions\NotFoundException;
use App\Support\Exceptions\UnauthorizedException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    /** @var JwtService */
    private $jwt;

    /** @var EmployeeService */
    private $employees;

    public function __construct(JwtService $jwt, EmployeeService $employees)
    {
        $this->jwt = $jwt;
        $this->employees = $employees;
    }

    /**
     * @return array<string, mixed>
     */
    public function login(string $email, string $password): array
    {
        $user = User::query()->with('roles.permissions')
            ->where('email', strtolower($email))->first();

        if (! $user) {
            throw new UnauthorizedException('Invalid email or password');
        }
        if (! $user->enabled) {
            throw new UnauthorizedException('Account is disabled');
        }
        if (! Hash::check($password, $user->password_hash)) {
            throw new UnauthorizedException('Invalid email or password');
        }

        $this->employees->touchLastLoginByUserId((int) $user->id);

        return $this->issueTokens($user);
    }

    /**
     * @return array<string, mixed>
     */
    public function register(string $email, string $password, string $fullName, ?string $phone): array
    {
        $email = strtolower($email);
        if (User::query()->where('email', $email)->exists()) {
            throw new ConflictException('Email already in use');
        }

        $user = new User();
        $user->email = $email;
        $user->password_hash = Hash::make($password);
        $user->full_name = $fullName;
        $user->phone = $phone;
        $user->save();

        return $this->issueTokens($user->load('roles.permissions'));
    }

    /**
     * @return array<string, mixed>
     */
    public function refresh(string $refreshToken): array
    {
        $claims = $this->jwt->parseRefresh($refreshToken);

        return DB::transaction(function () use ($claims) {
            $stored = RefreshToken::query()->where('jti', $claims['jti'])->first();
            if (! $stored) {
                throw new UnauthorizedException('Refresh token not recognised');
            }
            if (! $stored->isActive(Carbon::now())) {
                throw new UnauthorizedException('Refresh token expired or revoked');
            }
            if ((int) $stored->user_id !== (int) $claims['userId']) {
                throw new UnauthorizedException('Refresh token user mismatch');
            }

            // Rotate: revoke the presented token, issue a fresh pair.
            $stored->revoked_at = Carbon::now();
            $stored->save();

            $user = User::query()->with('roles.permissions')->find($claims['userId']);
            if (! $user) {
                throw new NotFoundException('User no longer exists');
            }

            return $this->issueTokens($user);
        });
    }

    public function logout(string $refreshToken): void
    {
        // Silent on invalid/unknown tokens — logout must always succeed.
        try {
            $claims = $this->jwt->parseRefresh($refreshToken);
        } catch (UnauthorizedException $e) {
            return;
        }

        $stored = RefreshToken::query()->where('jti', $claims['jti'])->first();
        if ($stored) {
            $stored->revoked_at = Carbon::now();
            $stored->save();
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function issueTokens(User $user): array
    {
        $access = $this->jwt->issueAccess((int) $user->id, $user->email, $user->allPermissions());
        $refresh = $this->jwt->issueRefresh((int) $user->id);

        $record = new RefreshToken();
        $record->user_id = (int) $user->id;
        $record->jti = $refresh['jti'];
        $record->issued_at = Carbon::now();
        $record->expires_at = Carbon::createFromTimestampUTC($refresh['expiresAt']);
        $record->save();

        return AuthResponse::build(
            $access['value'],
            $access['expiresAt'],
            $refresh['value'],
            $refresh['expiresAt'],
            UserDto::from($user)
        );
    }
}
