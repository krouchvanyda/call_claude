package com.company.erp.core.security;

import java.util.Set;

/**
 * Compile-time constants for the permission codes referenced by
 * {@code @PreAuthorize("hasAuthority(Permissions.X)")} and seeded by
 * {@code V3__seed_roles_and_admin.sql}. Keep this and the seed in sync.
 */
public final class Permissions {

    private Permissions() {}

    // user / role management
    public static final String USER_READ         = "user:read";
    public static final String USER_WRITE        = "user:write";
    public static final String ROLE_READ         = "role:read";
    public static final String ROLE_WRITE        = "role:write";

    // ERP modules
    public static final String PRODUCT_READ      = "product:read";
    public static final String PRODUCT_WRITE     = "product:write";
    public static final String CATEGORY_READ     = "category:read";
    public static final String CATEGORY_WRITE    = "category:write";
    public static final String CUSTOMER_READ     = "customer:read";
    public static final String CUSTOMER_WRITE    = "customer:write";
    public static final String SUPPLIER_READ     = "supplier:read";
    public static final String SUPPLIER_WRITE    = "supplier:write";
    public static final String EMPLOYEE_READ     = "employee:read";
    public static final String EMPLOYEE_WRITE    = "employee:write";
    public static final String ATTENDANCE_READ   = "attendance:read";
    public static final String ATTENDANCE_WRITE  = "attendance:write";
    public static final String WAREHOUSE_READ    = "warehouse:read";
    public static final String WAREHOUSE_WRITE   = "warehouse:write";
    public static final String INVENTORY_READ    = "inventory:read";
    public static final String INVENTORY_WRITE   = "inventory:write";
    public static final String ORDER_READ        = "order:read";
    public static final String ORDER_WRITE       = "order:write";
    public static final String PAYMENT_READ      = "payment:read";
    public static final String PAYMENT_WRITE     = "payment:write";
    public static final String PROCUREMENT_READ  = "procurement:read";
    public static final String PROCUREMENT_WRITE = "procurement:write";
    public static final String ACCOUNTING_READ   = "accounting:read";
    public static final String ACCOUNTING_WRITE  = "accounting:write";
    public static final String REPORT_READ       = "report:read";
    public static final String NOTIFICATION_READ = "notification:read";
    public static final String AUDIT_READ        = "audit:read";
    public static final String SETTINGS_READ     = "settings:read";
    public static final String SETTINGS_WRITE    = "settings:write";

    // chat + calls
    public static final String CHAT_READ         = "chat:read";
    public static final String CHAT_WRITE        = "chat:write";

    // device tokens (FCM/VOIP)
    public static final String DEVICE_WRITE      = "device:write";

    /** Full permission set granted to SUPER_ADMIN. */
    public static final Set<String> ALL = Set.of(
            USER_READ, USER_WRITE, ROLE_READ, ROLE_WRITE,
            PRODUCT_READ, PRODUCT_WRITE, CATEGORY_READ, CATEGORY_WRITE,
            CUSTOMER_READ, CUSTOMER_WRITE, SUPPLIER_READ, SUPPLIER_WRITE,
            EMPLOYEE_READ, EMPLOYEE_WRITE, ATTENDANCE_READ, ATTENDANCE_WRITE,
            WAREHOUSE_READ, WAREHOUSE_WRITE, INVENTORY_READ, INVENTORY_WRITE,
            ORDER_READ, ORDER_WRITE, PAYMENT_READ, PAYMENT_WRITE,
            PROCUREMENT_READ, PROCUREMENT_WRITE, ACCOUNTING_READ, ACCOUNTING_WRITE,
            REPORT_READ, NOTIFICATION_READ, AUDIT_READ, SETTINGS_READ, SETTINGS_WRITE,
            CHAT_READ, CHAT_WRITE, DEVICE_WRITE
    );
}
