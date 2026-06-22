-- ============================================================================
-- V16__devices.sql
-- Maps userId → FCM token(s). One user can have many devices (phone + tablet).
-- Upserts on (user_id, device_id) so token rotation overwrites in place.
-- ============================================================================

CREATE TABLE devices (
    id           BIGSERIAL    PRIMARY KEY,
    user_id      BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id    VARCHAR(128) NOT NULL,
    fcm_token    TEXT         NOT NULL,
    platform     VARCHAR(16)  NOT NULL,
    app_version  VARCHAR(32),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by   BIGINT,
    updated_by   BIGINT,
    UNIQUE (user_id, device_id)
);
CREATE INDEX idx_devices_user_id ON devices (user_id);
