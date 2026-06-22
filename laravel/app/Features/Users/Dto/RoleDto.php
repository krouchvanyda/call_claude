<?php

namespace App\Features\Users\Dto;

use App\Features\Users\Models\Role;

/** Port of the Spring RoleDto record. */
final class RoleDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(Role $r): array
    {
        $r->loadMissing('permissions');

        return [
            'id' => (int) $r->id,
            'code' => $r->code,
            'name' => $r->name,
            'description' => $r->description,
            'permissions' => $r->permissions->pluck('code')->values()->all(),
        ];
    }
}
