<?php

namespace App\Support\Security;

/**
 * Permission codes referenced by the `permission:<code>` route middleware and
 * seeded by PermissionRoleSeeder. Keep this and the seeder in sync — port of
 * the Spring Permissions constants class.
 */
final class Permissions
{
    // user / role management
    const USER_READ = 'user:read';
    const USER_WRITE = 'user:write';
    const ROLE_READ = 'role:read';
    const ROLE_WRITE = 'role:write';

    // ERP modules
    const PRODUCT_READ = 'product:read';
    const PRODUCT_WRITE = 'product:write';
    const CATEGORY_READ = 'category:read';
    const CATEGORY_WRITE = 'category:write';
    const CUSTOMER_READ = 'customer:read';
    const CUSTOMER_WRITE = 'customer:write';
    const SUPPLIER_READ = 'supplier:read';
    const SUPPLIER_WRITE = 'supplier:write';
    const EMPLOYEE_READ = 'employee:read';
    const EMPLOYEE_WRITE = 'employee:write';
    const ATTENDANCE_READ = 'attendance:read';
    const ATTENDANCE_WRITE = 'attendance:write';
    const WAREHOUSE_READ = 'warehouse:read';
    const WAREHOUSE_WRITE = 'warehouse:write';
    const INVENTORY_READ = 'inventory:read';
    const INVENTORY_WRITE = 'inventory:write';
    const ORDER_READ = 'order:read';
    const ORDER_WRITE = 'order:write';
    const PAYMENT_READ = 'payment:read';
    const PAYMENT_WRITE = 'payment:write';
    const PROCUREMENT_READ = 'procurement:read';
    const PROCUREMENT_WRITE = 'procurement:write';
    const ACCOUNTING_READ = 'accounting:read';
    const ACCOUNTING_WRITE = 'accounting:write';
    const REPORT_READ = 'report:read';
    const NOTIFICATION_READ = 'notification:read';
    const AUDIT_READ = 'audit:read';
    const SETTINGS_READ = 'settings:read';
    const SETTINGS_WRITE = 'settings:write';

    // chat + calls
    const CHAT_READ = 'chat:read';
    const CHAT_WRITE = 'chat:write';

    // device tokens (FCM/VOIP)
    const DEVICE_WRITE = 'device:write';

    /**
     * Full permission set granted to SUPER_ADMIN.
     *
     * @return array<int, string>
     */
    public static function all(): array
    {
        return [
            self::USER_READ, self::USER_WRITE, self::ROLE_READ, self::ROLE_WRITE,
            self::PRODUCT_READ, self::PRODUCT_WRITE, self::CATEGORY_READ, self::CATEGORY_WRITE,
            self::CUSTOMER_READ, self::CUSTOMER_WRITE, self::SUPPLIER_READ, self::SUPPLIER_WRITE,
            self::EMPLOYEE_READ, self::EMPLOYEE_WRITE, self::ATTENDANCE_READ, self::ATTENDANCE_WRITE,
            self::WAREHOUSE_READ, self::WAREHOUSE_WRITE, self::INVENTORY_READ, self::INVENTORY_WRITE,
            self::ORDER_READ, self::ORDER_WRITE, self::PAYMENT_READ, self::PAYMENT_WRITE,
            self::PROCUREMENT_READ, self::PROCUREMENT_WRITE, self::ACCOUNTING_READ, self::ACCOUNTING_WRITE,
            self::REPORT_READ, self::NOTIFICATION_READ, self::AUDIT_READ, self::SETTINGS_READ, self::SETTINGS_WRITE,
            self::CHAT_READ, self::CHAT_WRITE, self::DEVICE_WRITE,
        ];
    }

    private function __construct()
    {
    }
}
