#!/usr/bin/env bash
# ===========================================================================
# Auto-restore the ERP data backup on a FRESH database.
#
# Postgres runs every *.sh / *.sql in /docker-entrypoint-initdb.d exactly once
# — when the data volume is empty. This script restores erp_data.dump (a
# custom-format pg_dump of the production schema + data, the same schema the
# Laravel migrations build) and then stamps Laravel's `migrations` table for
# the migrations the dump already satisfies (0001..0017). That way the app's
# boot-time `php artisan migrate` only needs to add the Laravel-only tables
# (e.g. failed_jobs) instead of colliding with the already-restored schema.
#
# To re-run on an existing stack: `docker compose down -v` (wipes the DB
# volume) then `docker compose up` — a fresh volume re-triggers this script.
# ===========================================================================
set -euo pipefail

DIR="$(dirname "$0")"
DUMP="$DIR/erp_data.dump"

if [ ! -f "$DUMP" ]; then
  echo "[restore] $DUMP not found — skipping (the app's seeders will populate instead)."
  exit 0
fi

echo "[restore] Restoring ERP data from $(basename "$DUMP") into '$POSTGRES_DB'…"
pg_restore --no-owner --no-privileges --exit-on-error \
  -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$DUMP"

echo "[restore] Stamping Laravel migrations table (0001..0017 are in the dump)…"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS public.migrations (
    id        SERIAL PRIMARY KEY,
    migration VARCHAR(255) NOT NULL,
    batch     INTEGER NOT NULL
);
INSERT INTO public.migrations (migration, batch) VALUES
 ('2024_01_01_000001_create_users_table', 1),
 ('2024_01_01_000002_create_permissions_table', 1),
 ('2024_01_01_000003_create_roles_table', 1),
 ('2024_01_01_000004_create_role_permissions_table', 1),
 ('2024_01_01_000005_create_user_roles_table', 1),
 ('2024_01_01_000006_create_refresh_tokens_table', 1),
 ('2024_01_01_000007_create_employees_table', 1),
 ('2024_01_01_000008_add_employee_profile_extra_fields', 1),
 ('2024_01_01_000009_add_employee_avatar_upload_meta', 1),
 ('2024_01_01_000010_create_chat_conversations_table', 1),
 ('2024_01_01_000011_create_chat_conversation_members_table', 1),
 ('2024_01_01_000012_create_chat_messages_table', 1),
 ('2024_01_01_000013_create_chat_message_reactions_table', 1),
 ('2024_01_01_000014_create_chat_calls_table', 1),
 ('2024_01_01_000015_add_chat_call_stream_cid', 1),
 ('2024_01_01_000016_create_chat_call_participants_table', 1),
 ('2024_01_01_000017_create_devices_table', 1);
SQL

echo "[restore] Done. Real data loaded; the app adds Laravel-only tables on boot."
