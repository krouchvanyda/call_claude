-- ============================================================================
-- V15__chat_call_stream_cid.sql
-- Adds the Stream Video call CID generated when a call starts. Mobile clients
-- use this id to join the same Stream call that hosts the actual audio/video
-- media. Signalling state (RINGING / ANSWERED / ENDED) stays in our tables.
-- ============================================================================

ALTER TABLE chat_calls
    ADD COLUMN stream_call_cid VARCHAR(128);
