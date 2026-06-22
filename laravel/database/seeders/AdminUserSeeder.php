<?php

namespace Database\Seeders;

use App\Features\Users\Models\Role;
use App\Features\Users\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

/**
 * Creates the seeded super-admin user. Port of AdminBootstrap — the bcrypt hash
 * is produced at runtime (SQL can't). Idempotent.
 *
 *   email:    admin@company.com
 *   password: Admin@12345
 *
 * CHANGE THE PASSWORD immediately in any non-local environment.
 */
class AdminUserSeeder extends Seeder
{
    const ADMIN_EMAIL = 'admin@company.com';
    const ADMIN_PASSWORD = 'Admin@12345';

    public function run(): void
    {
        if (User::query()->where('email', self::ADMIN_EMAIL)->exists()) {
            return;
        }

        $superAdmin = Role::query()->where('code', 'SUPER_ADMIN')->first();
        if (! $superAdmin) {
            throw new \RuntimeException('SUPER_ADMIN role missing — run PermissionRoleSeeder first.');
        }

        $admin = new User();
        $admin->email = self::ADMIN_EMAIL;
        $admin->password_hash = Hash::make(self::ADMIN_PASSWORD);
        $admin->full_name = 'Bootstrap Admin';
        $admin->save();
        $admin->roles()->sync([$superAdmin->id]);

        Log::warning('Bootstrap admin seeded: '.self::ADMIN_EMAIL.' / '.self::ADMIN_PASSWORD.' — CHANGE THIS PASSWORD');
    }
}
