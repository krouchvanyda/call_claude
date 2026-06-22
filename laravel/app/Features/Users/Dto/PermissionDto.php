<?php

namespace App\Features\Users\Dto;

use App\Features\Users\Models\Permission;

/** Port of the Spring PermissionDto record. */
final class PermissionDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(Permission $p): array
    {
        return [
            'id' => (int) $p->id,
            'code' => $p->code,
            'description' => $p->description,
        ];
    }
}
