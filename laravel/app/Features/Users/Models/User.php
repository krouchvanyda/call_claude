<?php

namespace App\Features\Users\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Foundation\Auth\User as Authenticatable;

/**
 * Login user. Password is stored in `password_hash` (BCrypt), not Laravel's
 * default `password` column. Roles aggregate permissions; allPermissions()
 * flattens permission codes across all assigned roles.
 *
 * @property int $id
 * @property string $email
 * @property string $password_hash
 * @property string $full_name
 * @property string|null $phone
 * @property string|null $avatar_url
 * @property bool $enabled
 */
class User extends Authenticatable
{
    use BlamesUser;

    protected $table = 'users';

    protected $fillable = [
        'email', 'password_hash', 'full_name', 'phone', 'avatar_url', 'enabled',
    ];

    protected $hidden = [
        'password_hash',
    ];

    protected $casts = [
        'enabled' => 'boolean',
    ];

    public function roles()
    {
        return $this->belongsToMany(Role::class, 'user_roles', 'user_id', 'role_id');
    }

    /**
     * Flattened permission codes across all assigned roles.
     *
     * @return array<int, string>
     */
    public function allPermissions(): array
    {
        $this->loadMissing('roles.permissions');

        $codes = [];
        foreach ($this->roles as $role) {
            foreach ($role->permissions as $permission) {
                $codes[$permission->code] = true;
            }
        }

        return array_keys($codes);
    }

    /**
     * @return array<int, string>
     */
    public function roleCodes(): array
    {
        $this->loadMissing('roles');
        return $this->roles->pluck('code')->all();
    }

    public function getAuthPassword()
    {
        return $this->password_hash;
    }
}
