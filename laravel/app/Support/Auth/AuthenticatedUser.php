<?php

namespace App\Support\Auth;

use Illuminate\Contracts\Auth\Authenticatable;

/**
 * The principal placed on the request after a valid access token — the
 * Laravel analogue of the Spring `AuthenticatedUser` record. Carries the user
 * id, email, and the permission codes flattened from the token's `pms` claim
 * (authorisation is checked against the token, not a DB lookup, exactly like
 * the original JwtAuthFilter).
 */
class AuthenticatedUser implements Authenticatable
{
    /** @var int */
    public $userId;

    /** @var string */
    public $email;

    /** @var array<int, string> */
    public $permissions;

    /**
     * @param array<int, string> $permissions
     */
    public function __construct(int $userId, string $email, array $permissions)
    {
        $this->userId = $userId;
        $this->email = $email;
        $this->permissions = array_values(array_unique($permissions));
    }

    public function hasPermission(string $code): bool
    {
        return in_array($code, $this->permissions, true);
    }

    // --- Authenticatable ----------------------------------------------------

    public function getAuthIdentifierName()
    {
        return 'id';
    }

    public function getAuthIdentifier()
    {
        return $this->userId;
    }

    public function getAuthPassword()
    {
        return '';
    }

    public function getRememberToken()
    {
        return '';
    }

    public function setRememberToken($value)
    {
        // stateless — no-op
    }

    public function getRememberTokenName()
    {
        return '';
    }
}
