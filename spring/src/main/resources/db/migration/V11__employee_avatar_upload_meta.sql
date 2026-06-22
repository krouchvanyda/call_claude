-- ============================================================================
-- V11__employee_avatar_upload_meta.sql
-- Adds metadata columns to track server-stored employee avatar uploads.
-- The avatar_url column already exists from V9; these two columns capture
-- what type of file is at that URL and when it was uploaded.
-- ============================================================================

ALTER TABLE employees
    ADD COLUMN avatar_content_type VARCHAR(64),
    ADD COLUMN avatar_uploaded_at  TIMESTAMPTZ;
