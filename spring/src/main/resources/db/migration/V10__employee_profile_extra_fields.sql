-- ============================================================================
-- V10__employee_profile_extra_fields.sql
-- Adds last-login tracking and emergency-contact columns to employees.
-- `tenure` is intentionally not stored — it's derived from hire_date at read
-- time so it stays accurate without a daily refresh job.
-- ============================================================================

ALTER TABLE employees
    ADD COLUMN last_login_at     TIMESTAMPTZ,
    ADD COLUMN emergency_contact VARCHAR(255),
    ADD COLUMN emergency_phone   VARCHAR(50);
