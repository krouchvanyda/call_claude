-- ============================================================================
-- V9__employees.sql
-- HR-side employee profile. One employee MAY link to a login user (one-to-one,
-- nullable so HR can create profiles before the login account exists).
-- Photos are referenced by URL only — uploads are out of scope at this layer.
-- ============================================================================

CREATE TABLE employees (
    id              BIGSERIAL    PRIMARY KEY,
    user_id         BIGINT       UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    employee_no     VARCHAR(64)  NOT NULL UNIQUE,
    full_name       VARCHAR(255) NOT NULL,
    work_email      VARCHAR(255),
    phone           VARCHAR(50),
    position        VARCHAR(128),
    department      VARCHAR(128),
    hire_date       DATE,
    date_of_birth   DATE,
    gender          VARCHAR(16),
    address         VARCHAR(1024),
    avatar_url      VARCHAR(1024),
    status          VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      BIGINT,
    updated_by      BIGINT
);

CREATE INDEX idx_employees_user_id    ON employees (user_id);
CREATE INDEX idx_employees_full_name  ON employees (full_name);
CREATE INDEX idx_employees_department ON employees (department);
