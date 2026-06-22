<?php

namespace App\Features\Users\Services;

use App\Features\Users\Models\Role;
use App\Features\Users\Models\User;
use App\Support\Exceptions\ConflictException;
use App\Support\Exceptions\NotFoundException;
use App\Support\Pagination\PageQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserService
{
    /** @var array<string, string> apiField => dbColumn */
    private const ALLOWED_SORT = [
        'email' => 'email',
        'fullName' => 'full_name',
        'createdAt' => 'created_at',
    ];

    public function list(PageQuery $query): LengthAwarePaginator
    {
        // Search filtering wires in with the products module's filter pattern;
        // for now this paginates only, matching the original UserService.
        $builder = User::query()->with('roles.permissions');
        $query->applySort($builder, self::ALLOWED_SORT, ['email', 'asc']);

        return $builder->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    public function getById(int $id): User
    {
        $user = User::query()->with('roles.permissions')->find($id);
        if (! $user) {
            throw new NotFoundException('User not found');
        }
        return $user;
    }

    public function getByEmail(string $email): User
    {
        $user = User::query()->with('roles.permissions')
            ->where('email', strtolower($email))->first();
        if (! $user) {
            throw new NotFoundException('User not found');
        }
        return $user;
    }

    /**
     * @param array<string, mixed> $data  email,password,fullName,phone,roles
     */
    public function create(array $data): User
    {
        $email = strtolower($data['email']);
        if (User::query()->where('email', $email)->exists()) {
            throw new ConflictException('Email already in use');
        }

        return DB::transaction(function () use ($email, $data) {
            $user = new User();
            $user->email = $email;
            $user->password_hash = Hash::make($data['password']);
            $user->full_name = $data['fullName'];
            $user->phone = $data['phone'] ?? null;
            $user->save();

            $roles = $this->resolveRoles($data['roles'] ?? []);
            $user->roles()->sync($roles->pluck('id')->all());

            return $user->load('roles.permissions');
        });
    }

    /**
     * @param array<string, mixed> $data  partial: fullName,phone,avatarUrl,enabled,roles
     */
    public function update(int $id, array $data): User
    {
        return DB::transaction(function () use ($id, $data) {
            $user = $this->getById($id);

            if (array_key_exists('fullName', $data) && $data['fullName'] !== null) {
                $user->full_name = $data['fullName'];
            }
            if (array_key_exists('phone', $data) && $data['phone'] !== null) {
                $user->phone = $data['phone'];
            }
            if (array_key_exists('avatarUrl', $data) && $data['avatarUrl'] !== null) {
                $user->avatar_url = $data['avatarUrl'];
            }
            if (array_key_exists('enabled', $data) && $data['enabled'] !== null) {
                $user->enabled = (bool) $data['enabled'];
            }
            $user->save();

            // null means "leave roles untouched"; present (even empty) replaces.
            if (array_key_exists('roles', $data) && $data['roles'] !== null) {
                $roles = $this->resolveRoles($data['roles']);
                $user->roles()->sync($roles->pluck('id')->all());
            }

            return $user->load('roles.permissions');
        });
    }

    public function delete(int $id): void
    {
        $user = $this->getById($id);
        $user->delete();
    }

    /**
     * @param array<int, int> $userIds
     * @param array<int, string> $roleCodes
     * @return array<int, User>
     */
    public function assignRoles(array $userIds, array $roleCodes, string $mode): array
    {
        return DB::transaction(function () use ($userIds, $roleCodes, $mode) {
            $targets = User::query()->with('roles.permissions')
                ->whereIn('id', $userIds)->get();

            if ($targets->count() !== count($userIds)) {
                $found = $targets->pluck('id')->map('intval')->all();
                $missing = array_values(array_diff($userIds, $found));
                throw new NotFoundException('User(s) not found: ['.implode(', ', $missing).']');
            }

            $resolved = $this->resolveRoles($roleCodes);
            $roleIds = $resolved->pluck('id')->all();

            foreach ($targets as $user) {
                switch ($mode) {
                    case 'ADD':
                        $user->roles()->syncWithoutDetaching($roleIds);
                        break;
                    case 'REMOVE':
                        $user->roles()->detach($roleIds);
                        break;
                    case 'REPLACE':
                        $user->roles()->sync($roleIds);
                        break;
                }
                $user->load('roles.permissions');
            }

            return $targets->all();
        });
    }

    /**
     * @param array<int, string> $codes
     * @return \Illuminate\Support\Collection<int, Role>
     */
    private function resolveRoles(array $codes)
    {
        if (empty($codes)) {
            return collect();
        }
        return collect($codes)->map(function ($code) {
            $role = Role::query()->where('code', $code)->first();
            if (! $role) {
                throw new NotFoundException('Role not found: '.$code);
            }
            return $role;
        });
    }
}
