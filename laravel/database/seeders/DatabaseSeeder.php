<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            PermissionRoleSeeder::class,   // V3 role/permission catalogue
            AdminUserSeeder::class,        // AdminBootstrap
            EmployeeBackfillSeeder::class, // EmployeeBackfillBootstrap (after admin exists)
        ]);
    }
}
