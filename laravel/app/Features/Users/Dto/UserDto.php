<?php

namespace App\Features\Users\Dto;

use App\Features\Users\Models\User;

/** Port of the Spring UserDto record. */
final class UserDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(User $u): array
    {
        return [
            'id' => (int) $u->id,
            'email' => $u->email,
            'fullName' => $u->full_name,
            'phone' => $u->phone,
            'avatarUrl' => $u->avatar_url,
            'enabled' => (bool) $u->enabled,
            'roles' => array_values($u->roleCodes()),
            'permissions' => array_values($u->allPermissions()),
        ];
    }
}
