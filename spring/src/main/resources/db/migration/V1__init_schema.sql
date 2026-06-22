-- ============================================================================
-- V1__init_schema.sql
-- Core tables: users, roles, permissions (entity), role_permissions,
-- user_roles, refresh_tokens. ERP / e-commerce schema arrives in V2.
--
-- All primary keys are BIGSERIAL (auto-incrementing BIGINT).
-- ============================================================================

-- ---- users -----------------------------------------------------------------
CREATE TABLE users (
    id              BIGSERIAL    PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    phone           VARCHAR(50),
    avatar_url      VARCHAR(1024),
    enabled         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      BIGINT,
    updated_by      BIGINT
);
CREATE INDEX idx_users_email ON users (email);

-- ---- permissions (entity) --------------------------------------------------
CREATE TABLE permissions (
    id              BIGSERIAL    PRIMARY KEY,
    code            VARCHAR(64)  NOT NULL UNIQUE,
    description     VARCHAR(255),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      BIGINT,
    updated_by      BIGINT
);

-- ---- roles -----------------------------------------------------------------
CREATE TABLE roles (
    id              BIGSERIAL    PRIMARY KEY,
    code            VARCHAR(64)  NOT NULL UNIQUE,
    name            VARCHAR(128) NOT NULL,
    description     VARCHAR(255),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      BIGINT,
    updated_by      BIGINT
);

CREATE TABLE role_permissions (
    role_id         BIGINT NOT NULL REFERENCES roles (id)       ON DELETE CASCADE,
    permission_id   BIGINT NOT NULL REFERENCES permissions (id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id         BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id         BIGINT NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- ---- refresh tokens (tracked by jti so they can be rotated/revoked) --------
CREATE TABLE refresh_tokens (
    id              BIGSERIAL    PRIMARY KEY,
    user_id         BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    jti             VARCHAR(64)  NOT NULL UNIQUE,
    issued_at       TIMESTAMPTZ  NOT NULL,
    expires_at      TIMESTAMPTZ  NOT NULL,
    revoked_at      TIMESTAMPTZ
);
CREATE INDEX idx_refresh_tokens_user_id     ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_expires_at  ON refresh_tokens (expires_at);
