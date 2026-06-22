-- ============================================================================
-- V13__chat_module.sql
-- Chat module — Module 10 from CHAT_MODULE_GUIDE.md.
-- Conversations (1:1 + group), members, messages, reactions.
-- Calls live in V14.
-- ============================================================================

-- ---- conversations ---------------------------------------------------------
CREATE TABLE chat_conversations (
    id              BIGSERIAL    PRIMARY KEY,
    type            VARCHAR(16)  NOT NULL,                -- DIRECT | GROUP
    name            VARCHAR(255),                          -- group name; null for DIRECT
    avatar_url      VARCHAR(1024),
    last_message_id BIGINT,                                -- denormalised for inbox preview
    last_message_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      BIGINT,
    updated_by      BIGINT
);
CREATE INDEX idx_chat_conversations_last_message_at ON chat_conversations (last_message_at DESC);

-- ---- conversation members --------------------------------------------------
CREATE TABLE chat_conversation_members (
    conversation_id      BIGINT       NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id              BIGINT       NOT NULL REFERENCES users(id)              ON DELETE CASCADE,
    role                 VARCHAR(16)  NOT NULL DEFAULT 'MEMBER',     -- ADMIN | MEMBER
    joined_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    last_read_message_id BIGINT,
    muted                BOOLEAN      NOT NULL DEFAULT FALSE,
    PRIMARY KEY (conversation_id, user_id)
);
CREATE INDEX idx_chat_conv_members_user ON chat_conversation_members (user_id);

-- ---- messages --------------------------------------------------------------
CREATE TABLE chat_messages (
    id                      BIGSERIAL    PRIMARY KEY,
    conversation_id         BIGINT       NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id               BIGINT       NOT NULL REFERENCES users(id)              ON DELETE SET NULL,
    type                    VARCHAR(16)  NOT NULL,                  -- TEXT | IMAGE | VOICE | FILE
    body                    TEXT,                                    -- text or caption
    attachment_url          VARCHAR(1024),
    attachment_content_type VARCHAR(64),
    attachment_size_bytes   BIGINT,
    duration_seconds        INTEGER,                                 -- voice only
    reply_to_message_id     BIGINT       REFERENCES chat_messages(id) ON DELETE SET NULL,
    edited_at               TIMESTAMPTZ,
    deleted_at              TIMESTAMPTZ,                             -- soft delete
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by              BIGINT,
    updated_by              BIGINT
);
CREATE INDEX idx_chat_messages_conv_created ON chat_messages (conversation_id, created_at DESC);
CREATE INDEX idx_chat_messages_sender       ON chat_messages (sender_id);

ALTER TABLE chat_conversations
    ADD CONSTRAINT fk_chat_conversations_last_message
        FOREIGN KEY (last_message_id) REFERENCES chat_messages(id) ON DELETE SET NULL;

-- ---- reactions -------------------------------------------------------------
CREATE TABLE chat_message_reactions (
    message_id BIGINT       NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id    BIGINT       NOT NULL REFERENCES users(id)         ON DELETE CASCADE,
    emoji      VARCHAR(16)  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id, emoji)
);
CREATE INDEX idx_chat_reactions_message ON chat_message_reactions (message_id);
