<?php

namespace Database\Seeders;

use App\Features\Users\Models\Permission;
use App\Features\Users\Models\Role;
use Illuminate\Database\Seeder;

/**
 * Seeds the permission catalogue, the four roles, and their permission grants.
 * Port of V3__seed_roles_and_admin.sql (the role/permission portion).
 * Idempotent via firstOrCreate / sync.
 */
class PermissionRoleSeeder extends Seeder
{
    public function run(): void
    {
        $permissions = [
            'user:read' => 'Read users',
            'user:write' => 'Create / update / delete users',
            'role:read' => 'Read roles',
            'role:write' => 'Create / update / delete roles',
            'product:read' => 'Read products',
            'product:write' => 'Manage products',
            'category:read' => 'Read categories',
            'category:write' => 'Manage categories',
            'customer:read' => 'Read customers',
            'customer:write' => 'Manage customers',
            'supplier:read' => 'Read suppliers',
            'supplier:write' => 'Manage suppliers',
            'employee:read' => 'Read employees',
            'employee:write' => 'Manage employees',
            'attendance:read' => 'Read attendance',
            'attendance:write' => 'Record / edit attendance',
            'warehouse:read' => 'Read warehouses',
            'warehouse:write' => 'Manage warehouses',
            'inventory:read' => 'Read inventory',
            'inventory:write' => 'Adjust inventory',
            'order:read' => 'Read orders',
            'order:write' => 'Create / update orders',
            'payment:read' => 'Read payments',
            'payment:write' => 'Record payments',
            'procurement:read' => 'Read purchase orders',
            'procurement:write' => 'Create purchase orders',
            'accounting:read' => 'Read accounting',
            'accounting:write' => 'Post journal entries',
            'report:read' => 'View reports / dashboards',
            'notification:read' => 'Read notifications',
            'audit:read' => 'Read audit logs',
            'settings:read' => 'Read settings',
            'settings:write' => 'Edit settings',
            'chat:read' => 'Read chats',
            'chat:write' => 'Send chats / create conversations / make calls',
            'device:write' => 'Register / unregister device tokens',
        ];

        foreach ($permissions as $code => $description) {
            Permission::query()->firstOrCreate(['code' => $code], ['description' => $description]);
        }

        $allCodes = array_keys($permissions);

        $roles = [
            'SUPER_ADMIN' => ['Super Admin', 'Unrestricted access to everything'],
            'ADMIN' => ['Admin', 'Full operational access; cannot manage roles'],
            'STAFF' => ['Staff', 'Day-to-day operational rights'],
            'CUSTOMER' => ['Customer', 'Self-service rights only'],
        ];
        foreach ($roles as $code => [$name, $desc]) {
            Role::query()->firstOrCreate(['code' => $code], ['name' => $name, 'description' => $desc]);
        }

        $staff = [
            'user:read', 'role:read',
            'product:read', 'category:read',
            'customer:read', 'customer:write',
            'supplier:read', 'supplier:write',
            'employee:read', 'attendance:read', 'attendance:write',
            'warehouse:read', 'inventory:read', 'inventory:write',
            'order:read', 'order:write', 'payment:read', 'payment:write',
            'procurement:read', 'procurement:write',
            'accounting:read', 'report:read',
            'notification:read', 'settings:read',
            'chat:read', 'chat:write', 'device:write',
        ];

        $customer = [
            'product:read', 'category:read',
            'order:read', 'order:write', 'payment:read',
            'notification:read',
            'chat:read', 'chat:write', 'device:write',
        ];

        $admin = array_values(array_diff($allCodes, ['role:write']));

        $this->grant('SUPER_ADMIN', $allCodes);
        $this->grant('ADMIN', $admin);
        $this->grant('STAFF', $staff);
        $this->grant('CUSTOMER', $customer);
    }

    /**
     * @param array<int, string> $codes
     */
    private function grant(string $roleCode, array $codes): void
    {
        $role = Role::query()->where('code', $roleCode)->firstOrFail();
        $ids = Permission::query()->whereIn('code', $codes)->pluck('id')->all();
        $role->permissions()->sync($ids);
    }
}
