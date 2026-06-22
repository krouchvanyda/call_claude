-- ============================================================================
-- V3__seed_roles_and_admin.sql
-- Seeds: permission catalogue, four roles (SUPER_ADMIN, ADMIN, STAFF, CUSTOMER),
-- and a bootstrap super-admin user. CHANGE THE PASSWORD in any non-local env.
-- (Slot V2 is reserved for the ERP/e-commerce schema, added later. Flyway is
-- configured with out-of-order: true so V2 can land between V1 and V3.)
-- ============================================================================

-- ---- 1. seed all permission codes -----------------------------------------
INSERT INTO permissions (code, description) VALUES
    ('user:read',         'Read users'),
    ('user:write',        'Create / update / delete users'),
    ('role:read',         'Read roles'),
    ('role:write',        'Create / update / delete roles'),
    ('product:read',      'Read products'),
    ('product:write',     'Manage products'),
    ('category:read',     'Read categories'),
    ('category:write',    'Manage categories'),
    ('customer:read',     'Read customers'),
    ('customer:write',    'Manage customers'),
    ('supplier:read',     'Read suppliers'),
    ('supplier:write',    'Manage suppliers'),
    ('employee:read',     'Read employees'),
    ('employee:write',    'Manage employees'),
    ('attendance:read',   'Read attendance'),
    ('attendance:write',  'Record / edit attendance'),
    ('warehouse:read',    'Read warehouses'),
    ('warehouse:write',   'Manage warehouses'),
    ('inventory:read',    'Read inventory'),
    ('inventory:write',   'Adjust inventory'),
    ('order:read',        'Read orders'),
    ('order:write',       'Create / update orders'),
    ('payment:read',      'Read payments'),
    ('payment:write',     'Record payments'),
    ('procurement:read',  'Read purchase orders'),
    ('procurement:write', 'Create purchase orders'),
    ('accounting:read',   'Read accounting'),
    ('accounting:write',  'Post journal entries'),
    ('report:read',       'View reports / dashboards'),
    ('notification:read', 'Read notifications'),
    ('audit:read',        'Read audit logs'),
    ('settings:read',     'Read settings'),
    ('settings:write',    'Edit settings'),
    ('chat:read',         'Read chats'),
    ('chat:write',        'Send chats / create conversations / make calls'),
    ('device:write',      'Register / unregister device tokens');

-- ---- 2. seed the four roles ------------------------------------------------
INSERT INTO roles (code, name, description) VALUES
    ('SUPER_ADMIN', 'Super Admin', 'Unrestricted access to everything'),
    ('ADMIN',       'Admin',       'Full operational access; cannot manage roles'),
    ('STAFF',       'Staff',       'Day-to-day operational rights'),
    ('CUSTOMER',    'Customer',    'Self-service rights only');

-- ---- 3. wire role -> permission --------------------------------------------
-- SUPER_ADMIN: every permission
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'SUPER_ADMIN';

-- ADMIN: everything except role:write
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'ADMIN'
  AND p.code NOT IN ('role:write');

-- STAFF: read everywhere + write to operational modules + chat + device
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'STAFF'
  AND p.code IN (
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
        'chat:read', 'chat:write', 'device:write'
  );

-- CUSTOMER: minimal self-service permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'CUSTOMER'
  AND p.code IN (
        'product:read', 'category:read',
        'order:read', 'order:write', 'payment:read',
        'notification:read',
        'chat:read', 'chat:write', 'device:write'
  );

-- ---- 4. bootstrap super-admin user -----------------------------------------
-- NOTE: the actual user row + bcrypt-hashed password is created by
-- com.company.erp.core.bootstrap.AdminBootstrap on application start (it needs
-- a real BCryptPasswordEncoder, which SQL can't produce). The runner is
-- idempotent: if admin@company.local already exists it does nothing.
--
-- Default credentials seeded on first boot:
--   email:    admin@company.local
--   password: Admin@12345
-- CHANGE IMMEDIATELY in any non-local environment.
