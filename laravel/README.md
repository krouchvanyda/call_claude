# ERP + E-Commerce Backend API

Enterprise REST + WebSocket API written in **PHP 7.4 + Laravel 8**, designed to
back a **Flutter mobile app** and a **Nuxt/Vue admin dashboard**. Feature-first
layout (every feature owns its `Models / Dto / Requests / Services /
Controllers`), JWT auth with RBAC, PostgreSQL, Laravel migrations + seeders,
plus a realtime chat and voice/video call subsystem (native
STOMP-over-WebSocket + Stream Video + FCM push).

Built on **Laravel 8** and **PHP 7.4**.

## Stack

| Layer            | Choice                                                                       |
|------------------|------------------------------------------------------------------------------|
| Language         | PHP 7.4                                                                       |
| Framework        | Laravel 8 (HTTP, Validation, Eloquent ORM, Queues, Broadcasting, Console)     |
| DI               | Laravel service container                                                     |
| ORM              | Eloquent                                                                      |
| DB               | PostgreSQL 16                                                                 |
| Migrations       | Laravel migrations + seeders (`php artisan migrate --seed`)                   |
| Auth             | Custom stateless JWT guard (`firebase/php-jwt`, HS256) + BCrypt              |
| Realtime         | Native STOMP-over-WebSocket on `/ws` (Ratchet/ReactPHP) + Redis fan-out      |
| Voice/Video      | [Stream Video](https://getstream.io/video/) (server mints a JWT, client joins)|
| Push             | Firebase Cloud Messaging via `kreait/laravel-firebase` (data-only call invites)|
| Rate limiting    | Per-IP cache-backed token bucket middleware                                   |
| Validation       | Form requests + service-layer rules                                           |
| Docs             | (OpenAPI generation not ported — see [Known gaps](#known-gaps))               |
| Logging          | Monolog + per-request `X-Request-Id` trace id                                 |
| Tests            | PHPUnit                                                                       |
| Container        | Docker, docker-compose, nginx reverse proxy                                   |

## Folder structure

Feature-first. Cross-cutting infrastructure lives under `app/Support/`; each
feature owns its vertical slice under `app/Features/<Name>/`:

```
app/
├── Support/                         # framework-level concerns, no feature logic
│   ├── Http/                        # ApiResponse, ApiFormRequest, TraceContext, Middleware/
│   │   └── Middleware/              # RequestId, WrapInApiEnvelope, RateLimitPerIp,
│   │                                #   Authenticate, AuthenticateOptional, EnsurePermission
│   ├── Auth/                        # JwtService, JwtGuard, AuthenticatedUser
│   ├── Pagination/                  # PageQuery, PageResponse
│   ├── Response/                    # ErrorCodes
│   ├── Security/                    # Permissions (permission-code constants)
│   ├── Exceptions/                  # AppException + Bad/Conflict/Forbidden/NotFound/Unauthorized
│   └── Database/                    # BlamesUser (created_by/updated_by auditing trait)
├── Features/
│   ├── Auth/                        # login, register, refresh (rotating), logout
│   ├── Users/                       # FULL CRUD + RBAC reference module (Users + Roles)
│   ├── Employees/                   # HR profiles + server-side avatar upload
│   ├── Devices/                     # FCM device-token registration + FcmService + push job
│   └── Chat/                        # realtime chat + voice/video calls + presence
│       ├── Models/ Dto/ Requests/ Services/ Controllers/ Events/ Console/
├── Http/                            # Kernel, base Controller, HealthController, framework middleware
├── Providers/                       # App, Auth (registers the jwt guard), Route, Broadcast, Event
├── Console/Kernel.php               # schedules erp:purge-refresh-tokens + erp:sweep-call-timeouts
└── Exceptions/Handler.php           # maps every exception to the standard envelope

config/erp.php                       # app.* properties (JWT, rate-limit, stream, fcm, chat, uploads)
database/migrations/                 # schema (PostgreSQL)
database/seeders/                    # PermissionRoleSeeder, AdminUserSeeder, EmployeeBackfillSeeder
routes/api.php                       # all REST routes (+ requires api_chat.php)
routes/channels.php                  # broadcast channel authorization
```

Every feature folder follows the same shape:

```
Features/<Name>/
├── Models/       ← Eloquent models (BlamesUser trait where the table has audit cols)
├── Dto/          ← final classes with static from() → associative arrays (camelCase keys)
├── Requests/     ← ApiFormRequest subclasses (validation)
├── Services/     ← business rules live here (DB::transaction for multi-write ops)
└── Controllers/  ← thin; return arrays/DTOs (auto-wrapped) or throw Support\Exceptions
```

### Migrations

Schema migrations (`database/migrations/`), in order:

| File                                            | Purpose                                       |
|-------------------------------------------------|-----------------------------------------------|
| `…000001_create_users_table`                    | users                                         |
| `…000002_create_permissions_table`              | permissions                                   |
| `…000003_create_roles_table`                    | roles                                         |
| `…000004_create_role_permissions_table`         | role ↔ permission                             |
| `…000005_create_user_roles_table`               | user ↔ role                                   |
| `…000006_create_refresh_tokens_table`           | rotating refresh tokens (tracked by `jti`)    |
| `…000007_create_employees_table`                | HR employee profiles                          |
| `…000008_add_employee_profile_extra_fields`     | last_login / emergency contact                |
| `…000009_add_employee_avatar_upload_meta`       | avatar content-type / uploaded-at             |
| `…000010_create_chat_conversations_table`       | conversations                                 |
| `…000011_create_chat_conversation_members_table`| members                                       |
| `…000012_create_chat_messages_table`            | messages (+ conversations.last_message_id FK) |
| `…000013_create_chat_message_reactions_table`   | reactions                                     |
| `…000014_create_chat_calls_table`               | call sessions                                 |
| `…000015_add_chat_call_stream_cid`              | Stream call CID                               |
| `…000016_create_chat_call_participants_table`   | call participants                             |
| `…000017_create_devices_table`                  | per-user FCM device tokens                    |

Reference data (permission catalogue, the four roles + their grants), the
bootstrap super-admin, and the employee backfill are **seeders** run by
`php artisan db:seed`.

## Quick start

### 1. Run with docker-compose

```bash
cp .env.example .env
# edit .env — at minimum, replace JWT_SECRET with a long random value
docker compose up --build
```

`web` (nginx) listens on `http://localhost:8080` and proxies `/ws` to the
`stomp` service; `app` (php-fpm) runs `migrate --seed` on boot; `stomp` serves
STOMP-over-WebSocket; `redis` holds presence state + the broadcast fan-out;
Postgres exposes `5432`. The full realtime path works out of the box.

### 2. Run locally (Postgres + Redis in Docker, app on host)

```bash
docker compose up -d db redis
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve --port=8080            # REST API (note: /ws needs nginx → use docker for realtime)
php artisan erp:stomp-serve              # STOMP-over-WebSocket server (separate terminal)
php artisan schedule:work                # refresh-token purge + call-timeout sweeper
```

### 3. Verify

```bash
curl http://localhost:8080/health
# { "success": true, "message": "Success", "data": { "status": "UP" }, "errorCode": null, "traceId": "0f1c…" }
```

### Bootstrap super-admin

Created by `AdminUserSeeder` (after `PermissionRoleSeeder` seeds the
SUPER_ADMIN role). The bcrypt hash is produced at runtime:

```
email:    admin@company.com
password: Admin@12345
```

**Change this password immediately in any non-local environment.**

## Standard API envelope

Every endpoint returns:

```json
{ "success": true, "message": "Success", "data": { /* ... */ }, "errorCode": null, "traceId": "0f1c…" }
```

Controllers return raw data; the `WrapInApiEnvelope` middleware wraps it.
Errors are rendered by `app/Exceptions/Handler.php`. Stable error codes:
`VALIDATION_FAILED`,
`UNAUTHORIZED`, `FORBIDDEN`, `CONFLICT`, `NOT_FOUND`, `RATE_LIMITED`,
`INTERNAL_ERROR`. Validation errors include per-field details in
`data.fieldErrors`.

## Pagination & filtering

```
GET /api/v1/employees?page=1&pageSize=20&search=sok&sort=fullName:asc
```

- `page` ≥ 1 (1-indexed)
- `pageSize` clamped to 1..100
- `search` case-insensitive substring on resource-specific columns
- `sort` is `field:asc|desc`; the service passes an explicit whitelist of
  allowed fields (rejecting others with `BAD_REQUEST`)

Responses use `PageResponse`: `{ items, page, pageSize, totalItems, totalPages }`.

## Authentication & RBAC

- `Authorization: Bearer <accessToken>` for every protected endpoint
- Access tokens are short-lived (default 15 min, `JWT_ACCESS_TTL_SECONDS`);
  refresh tokens are long-lived (default 14 d, `JWT_REFRESH_TTL_SECONDS`) and
  **rotated** on every `POST /api/v1/auth/refresh`
- Refresh tokens are tracked server-side by `jti` (`refresh_tokens`) so they
  can be revoked; `erp:purge-refresh-tokens` (hourly) cleans up inactive rows
- Tokens carry the user's permission codes in the `pms` claim; the `permission`
  middleware (`->middleware('permission:user:write')`) enforces them per route
- Roles aggregate permissions; the seeder ships `SUPER_ADMIN`, `ADMIN`,
  `STAFF`, `CUSTOMER`. Permission codes live in
  `App\Support\Security\Permissions` — keep it in sync with
  `database/seeders/PermissionRoleSeeder.php`

### Bulk role assignment

`POST /api/v1/users/assign-roles` (requires `user:write`):

```json
{ "userIds": [12, 17, 23], "roles": ["STAFF"], "mode": "ADD" }
```

`mode`: `ADD` (default, union) | `REPLACE` (exact set) | `REMOVE` (subtract).
Transactional and atomic — an unknown `userId` or role code fails the whole
call (`NOT_FOUND`) and nothing is persisted.

## Employees

HR-side employee profiles, separate from the login `User`. An `Employee` may
link to a `User` (`userId`, one-to-one) — how the mobile **My Profile** screen
finds the current user's profile via `GET /api/v1/employees/me`. `tenure`
(`"2y 5m"`) is derived from `hireDate` at read time. Avatars are uploaded via
multipart and stored on the API host's filesystem (`UPLOAD_AVATAR_DIR`), served
back at `UPLOAD_AVATAR_PUBLIC_BASE_URL` (default `/uploads/avatars`).

```
GET    /api/v1/employees/me                — current user's profile (404 if unlinked)
GET    /api/v1/employees                   — paginated (employee:read)
GET    /api/v1/employees/{id}              — (employee:read)
POST   /api/v1/employees                   — create (employee:write)
PATCH  /api/v1/employees/{id}              — partial update (employee:write)
DELETE /api/v1/employees/{id}              — (employee:write)
POST   /api/v1/employees/me/avatar         — upload my avatar (multipart `file`)
DELETE /api/v1/employees/me/avatar         — remove my avatar
POST   /api/v1/employees/{id}/avatar       — admin upload (employee:write)
DELETE /api/v1/employees/{id}/avatar       — admin remove (employee:write)
```

Avatar constraints (env-overridable): `UPLOAD_AVATAR_MAX_SIZE` (5 MiB),
`UPLOAD_AVATAR_ALLOWED_TYPES` (`image/jpeg,image/png,image/webp`).

`EmployeeBackfillSeeder` ensures every `User` has an `Employee` row
(`employeeNo = EMP-<id padded to 5>`), idempotently.

## Realtime chat & voice/video calls

Conversations (1:1 + group), messages (text/image/voice/file metadata),
reactions, replies, edits, deletes, group management, and voice/video call
**signalling**. All writes go over REST and fan out over broadcast events.

### REST endpoints (all under `/api/v1`, authenticated; chat is open to any logged-in user)

```
POST   /chats/conversations                       create direct or group
GET    /chats/conversations?page=&pageSize=       inbox (paginated, newest-first)
GET    /chats/conversations/{id}                  one + members + unread
PATCH  /chats/conversations/{id}                  rename / set avatar (admin)
DELETE /chats/conversations/{id}                  delete conversation
POST   /chats/conversations/{id}/members          add members (admin)
DELETE /chats/conversations/{id}/members/{userId} remove (admin, or self leave)
POST   /chats/conversations/{id}/read             mark-as-read

GET    /chats/conversations/{id}/messages         paginated history
GET    /chats/conversations/{id}/messages/search  substring search
POST   /chats/conversations/{id}/messages         send (text/image/voice/file)
PATCH  /chats/messages/{id}                        edit (sender, 15-min, TEXT only)
DELETE /chats/messages/{id}                        soft-delete
POST   /chats/messages/{id}/reactions              toggle emoji

POST   /chats/conversations/{id}/calls            start (VOICE | VIDEO)
POST   /chats/calls/{id}/accept                   callee accepts
POST   /chats/calls/{id}/reject?reason=…          callee declines
POST   /chats/calls/{id}/end                      hangup
GET    /chats/calls/{id}                          reconcile state
GET    /chats/calls                               my call history
GET    /chats/calls/stream-token                  Stream Video JWT (media auth)

GET    /chats/presence[?ids=1,2,3]                presence snapshot / batch
GET    /chats/presence/{userId}                   single user
```

### Realtime transport (native STOMP-over-WebSocket)

A faithful reimplementation of the Spring SimpleBroker, so the **existing
Flutter STOMP client connects unchanged**. The `stomp` service
(`php artisan erp:stomp-serve`, Ratchet/ReactPHP) speaks STOMP; nginx proxies
`/ws` (and `/ws-sockjs`) to it, so realtime shares the same origin/port as the
REST API. The REST controllers publish frames to a Redis channel which the STOMP
server fans out.

Client contract (identical to the Java backend):

```
ws.connect("ws://<host>/ws")
   CONNECT header  Authorization: Bearer <accessToken>     # JWT → session principal

ws.subscribe("/topic/conversations/{id}")        # message stream
ws.subscribe("/topic/conversations/{id}/call")   # call signalling
ws.subscribe("/topic/presence")                  # presence updates
ws.subscribe("/user/queue/inbox")                # per-user inbox previews
ws.subscribe("/user/queue/calls")                # per-user incoming-call invites
```

Server pushes `MESSAGE` frames whose body is `{ "event": "<name>", "payload": <dto> }`.
`/topic/*` is broadcast; `/user/queue/*` is routed to the authenticated
principal only (the analogue of Spring's `convertAndSendToUser`). 10s/10s
heartbeats drive dead-socket detection → presence OFFLINE. Clients only
SUBSCRIBE; every action is performed over REST.

Presence (`ONLINE` / `BUSY` / `OFFLINE`), read receipts, inbox `lastMessage`
previews, per-message `readByUserIds`, the 60 s ring timeout
(`erp:sweep-call-timeouts`), the 5 s accept-grace window, FCM `call.invite` /
`call.cancel` data pushes, and Stream Video token minting are all configurable
under `config/erp.php`.

### Stream Video

`GET /api/v1/chats/calls/stream-token` mints a per-user Stream JWT (HS256,
signed with `STREAM_API_SECRET`, TTL `STREAM_TOKEN_TTL_MINUTES`). A call's
deterministic `streamCallCid` is `default:erp-call-{callId}`. If the Stream
key/secret are blank the token endpoint returns `BAD_REQUEST`; the rest of the
call ceremony still works.

### FCM push

Set `FCM_ENABLED=true` and `FCM_SERVICE_ACCOUNT_JSON_PATH`. Pushes are
data-only (no `notification` block) so the Flutter background handler runs.
Sent via the queued `SendFcmDataPush` job (dispatch is fire-and-forget; with
`QUEUE_CONNECTION=sync` it runs inline, errors swallowed). Disabled by default —
the websocket path still works for foregrounded apps.

## Tests

```bash
php artisan test        # or: ./vendor/bin/phpunit
```

Tests run against an in-memory SQLite connection (see `phpunit.xml`).

## Notes & limitations

- **OpenAPI/Swagger UI** (`/docs`) is not bundled — add `darkaonline/l5-swagger`
  with annotations if you want generated API docs.
- **Sub-minute scheduling**: Laravel 8's scheduler is minute-granular, so the
  call-timeout sweeper runs as a command that loops internally every
  `CHAT_CALL_SWEEP_INTERVAL_MS` for ~a minute (`withoutOverlapping`).
- **Presence ONLINE/OFFLINE** is driven by STOMP CONNECT/DISCONNECT (with the
  10s heartbeat detecting dead sockets), exactly like the Spring backend; the
  `BUSY` flag is toggled by the call service.
- Presence state + rate-limit buckets live in Redis (shared across the app and
  stomp processes), so a single Redis already covers multi-process; point all
  instances at one Redis for multi-host.

## Useful endpoints

- `GET /health` — liveness
- `POST /api/v1/auth/login` — get tokens
- `GET /api/v1/users/me` — current user
- `GET /api/v1/users` — paginated list
- `POST /api/v1/users/assign-roles` — bulk role assignment
- `GET /api/v1/roles` / `GET /api/v1/roles/permissions`
- `GET /api/v1/employees/me`
- `GET /api/v1/chats/conversations` — current user's conversations
- `GET /api/v1/chats/calls` — call history
- `ws://<host>/ws` — STOMP-over-WebSocket for live chat & call signalling
  (CONNECT with `Authorization: Bearer <accessToken>`)
