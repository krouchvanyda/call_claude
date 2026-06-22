-- ============================================================================
-- V14__chat_calls.sql
-- Voice + video call signalling state. Media (WebRTC / Stream Video) lives
-- elsewhere — this layer only tracks the ceremony.
-- ============================================================================

CREATE TABLE chat_calls (
    id               BIGSERIAL    PRIMARY KEY,
    conversation_id  BIGINT       NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    caller_id        BIGINT       NOT NULL REFERENCES users(id)              ON DELETE SET NULL,
    type             VARCHAR(16)  NOT NULL,                       -- VOICE | VIDEO
    status           VARCHAR(16)  NOT NULL DEFAULT 'RINGING',     -- RINGING | ANSWERED | ENDED | MISSED | REJECTED | BUSY
    started_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    answered_at      TIMESTAMPTZ,
    ended_at         TIMESTAMPTZ,
    duration_seconds INTEGER,
    end_reason       VARCHAR(64),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by       BIGINT,
    updated_by       BIGINT
);
CREATE INDEX idx_chat_calls_conv_started ON chat_calls (conversation_id, started_at DESC);
CREATE INDEX idx_chat_calls_caller       ON chat_calls (caller_id, started_at DESC);

CREATE TABLE chat_call_participants (
    call_id   BIGINT       NOT NULL REFERENCES chat_calls(id) ON DELETE CASCADE,
    user_id   BIGINT       NOT NULL REFERENCES users(id)      ON DELETE CASCADE,
    status    VARCHAR(16)  NOT NULL DEFAULT 'RINGING',   -- RINGING | ANSWERED | REJECTED | LEFT | MISSED
    joined_at TIMESTAMPTZ,
    left_at   TIMESTAMPTZ,
    PRIMARY KEY (call_id, user_id)
);
CREATE INDEX idx_chat_call_participants_user ON chat_call_participants (user_id);
