<?php

namespace App\Features\Users\Services;

use App\Features\Users\Models\Permission;
use App\Features\Users\Models\Role;
use App\Support\Exceptions\ConflictException;
use App\Support\Exceptions\NotFoundException;
use Illuminate\Support\Facades\DB;

class RoleService
{
    /**
     * @return \Illuminate\Database\Eloquent\Collection<int, Role>
     */
    public function list()
    {
        return Role::query()->with('permissions')->get();
    }

    public function getById(int $id): Role
    {
        $role = Role::query()->with('permissions')->find($id);
        if (! $role) {
            throw new NotFoundException('Role not found');
        }
        return $role;
    }

    /**
     * @return \Illuminate\Database\Eloquent\Collection<int, Permission>
     */
    public function listPermissions()
    {
        return Permission::query()->get();
    }

    /**
     * @param array<string, mixed> $data  code,name,description,permissions
     */
    public function create(array $data): Role
    {
        if (Role::query()->where('code', $data['code'])->exists()) {
            throw new ConflictException('Role code already in use');
        }

        return DB::transaction(function () use ($data) {
            $role = new Role();
            $role->code = $data['code'];
            $role->name = $data['name'];
            $role->description = $data['description'] ?? null;
            $role->save();

            $permissions = $this->resolvePermissions($data['permissions'] ?? []);
            $role->permissions()->sync($permissions->pluck('id')->all());

            return $role->load('permissions');
        });
    }

    /**
     * @param array<string, mixed> $data  partial: name,description,permissions
     */
    public function update(int $id, array $data): Role
    {
        return DB::transaction(function () use ($id, $data) {
            $role = $this->getById($id);

            if (array_key_exists('name', $data) && $data['name'] !== null) {
                $role->name = $data['name'];
            }
            if (array_key_exists('description', $data) && $data['description'] !== null) {
                $role->description = $data['description'];
            }
            $role->save();

            if (array_key_exists('permissions', $data) && $data['permissions'] !== null) {
                $permissions = $this->resolvePermissions($data['permissions']);
                $role->permissions()->sync($permissions->pluck('id')->all());
            }

            return $role->load('permissions');
        });
    }

    public function delete(int $id): void
    {
        $role = $this->getById($id);
        $role->delete();
    }

    /**
     * @param array<int, string> $codes
     * @return \Illuminate\Support\Collection<int, Permission>
     */
    private function resolvePermissions(array $codes)
    {
        if (empty($codes)) {
            return collect();
        }
        $found = Permission::query()->whereIn('code', $codes)->get();
        $foundCodes = $found->pluck('code')->all();
        $missing = array_values(array_diff(array_values(array_unique($codes)), $foundCodes));
        if (! empty($missing)) {
            throw new NotFoundException('Unknown permission(s): '.implode(',', $missing));
        }
        return $found;
    }
}
