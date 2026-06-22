# Enterprise ERP Mobile — Project Plan

## Core Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| UI Framework | Flutter (Dart) | Cross-platform iOS/Android |
| State Management | flutter_bloc (open source) | BLoC pattern |
| Architecture | MVVM | View ↔ ViewModel/BLoC ↔ Repository (flat) |
| DI | get_it + injectable | Service locator |
| Networking | dio | HTTP client |
| Local DB | SQLite | Open source |
| Secure Storage | flutter_secure_storage | Tokens/credentials |
| Navigation | go_router | Declarative routing |
| Serialization | freezed + json_serializable | Immutable models |
| Offline Sync | Custom sync engine (SQLite + dio) | No commercial deps |
| Localization | flutter_localizations (built-in) | i18n |
| Testing | bloc_test, mocktail, flutter_test | Unit + widget tests |

---

## Design Spec

Per-screen layout intent, design tokens, component patterns, motion rules,
and the prompt template for generating new screens live in a separate file:

> **[`ERP_MOBILE_DESIGN_GUIDE.md`](./ERP_MOBILE_DESIGN_GUIDE.md)** — single
> source of truth for all screen designs. Read this before creating or
> redesigning any UI.

CLAUDE.md (this file) owns the *project plan* — modules, phases, slices,
and architectural guardrails. The design guide owns the *visual + UX spec* —
colors, typography, spacing, component patterns, per-screen layouts, BLoC
contracts.

The design guide is **aspirational** in places (e.g. it describes a Chat
& Voice module that doesn't exist yet, and a 6-tab bottom nav vs the
current 3-tab shell). Treat it as the target, not the as-built state.

---

## Project Architecture

```
lib/
├── core/                      # Shared infrastructure
│   ├── network/               # Dio client, interceptors, error handler
│   ├── database/              # SQLite DB setup, DAOs
│   ├── sync/                  # Offline-first sync engine
│   ├── di/                    # Dependency injection setup
│   ├── router/                # go_router configuration
│   ├── error/                 # Failures, exceptions, Either type
│   ├── utils/                 # Extensions, helpers
│   └── theme/                 # Design tokens, typography
│
├── features/                  # One folder per ERP module
│   └── [module]/              # Flat MVVM — no data/domain split
│       ├── data/
│       │   ├── datasources/   # Remote (API) + Local (SQLite DAO)
│       │   ├── models/        # JSON ↔ Dart (freezed)
│       │   └── repositories/  # Concrete repositories (no abstract interface)
│       ├── entities/          # Pure value objects (formerly under domain/)
│       └── presentation/
│           ├── bloc/          # BLoC: events, states, bloc class
│           ├── viewmodels/    # MVVM ViewModel wrapping BLoC
│           ├── pages/         # Screens (views)
│           └── widgets/       # Module-specific widgets
│
└── shared/                    # Reusable UI components
    ├── widgets/
    └── validators/
```

> **Legacy note** — Modules 1–9 were built under the older "MVVM + Clean
> Architecture" convention and still ship a `domain/repositories/`
> (abstract interfaces) and a `domain/usecases/` folder. **Do not refactor
> them.** New modules (and new features inside existing modules) follow the
> flat layout above: one concrete repository, no abstract interface, no
> separate use-case classes — business rules live in the repository or
> the BLoC/ViewModel.

### MVVM + BLoC Data Flow

```
View (Flutter Widget)
   │  calls
   ▼
ViewModel (exposes streams, commands)
   │  dispatches events to / listens to
   ▼
BLoC (processes events → emits states)
   │  calls
   ▼
Repository (concrete — business rules live here)
   │  calls
   ▼
DataSource (Remote API / Local DB)
```

> **Legacy variant** in Modules 1–9: an extra `UseCase` layer sits
> between BLoC and Repository, and the Repository is reached through an
> abstract interface. Keep that flow when editing those modules; use the
> flat flow above for new work.

---

## Modules, Phases & Slices

---

### MODULE 0 — Core Foundation

#### Phase 0.1 — Project Scaffold
- Slice 0.1.1: Monorepo structure, folder conventions, lint rules (`flutter_lints`)
- Slice 0.1.2: `get_it` + `injectable` DI wiring
- Slice 0.1.3: `go_router` setup with route guards (auth-aware)
- Slice 0.1.4: Global theme system (colors, typography, spacing tokens)

#### Phase 0.2 — Networking Layer
- Slice 0.2.1: `dio` base client with base URL, timeouts
- Slice 0.2.2: JWT auth interceptor (attach + refresh token)
- Slice 0.2.3: Error interceptor → maps HTTP errors to domain `Failure` types
- Slice 0.2.4: Network connectivity checker (`connectivity_plus`)

#### Phase 0.3 — Local Database
- Slice 0.3.1: `SQLite` database setup, migration strategy — register `CachedUser` + `UserPermissions` + `SyncQueue` tables
- Slice 0.3.2: Generic DAO base class
- Slice 0.3.3: Cache invalidation policy (TTL-based)
- Slice 0.3.4: `AuthDao` — upsertUser, getUser, deleteUser, upsertPermissions, getPermissions, deletePermissions

**SQLite tables for auth:**
```
TABLE: cached_user
  id             TEXT PRIMARY KEY
  name           TEXT
  email          TEXT
  avatar_url     TEXT
  biometric_on   BOOLEAN
  last_login_at  DATETIME
  cached_at      DATETIME   ← TTL invalidation

TABLE: user_permissions
  user_id        TEXT
  module         TEXT       ← e.g. "finance", "inventory"
  scope          TEXT       ← e.g. "read", "write", "approve"
  cached_at      DATETIME
```

#### Phase 0.4 — Offline-First Sync Engine
- Slice 0.4.1: Sync queue (pending operations stored in SQLite)
- Slice 0.4.2: Conflict resolution strategy (last-write-wins or server-wins, configurable)
- Slice 0.4.3: Background sync trigger on connectivity restore
- Slice 0.4.4: Sync status BLoC (UI-visible sync state)

#### Phase 0.5 — Cross-Cutting Concerns
- Slice 0.5.1: Logging service (structured logs, `logger` package)
- Slice 0.5.2: Analytics abstraction interface (swap implementations freely)
- Slice 0.5.3: Error boundary widget + crash reporting hook
- Slice 0.5.4: Localization setup (ARB files, `intl`)

---

### MODULE 1 — Authentication & Identity

#### Phase 1.1 — Auth Core
- Slice 1.1.1: Login page (MVVM + BLoC)
- Slice 1.1.2: JWT token storage (`flutter_secure_storage`) — tokens only, never in SQLite
- Slice 1.1.2b: Cache user profile + permissions → SQLite (`cached_user` + `user_permissions` tables) ← **NEW**
- Slice 1.1.3: Token refresh logic in interceptor — reads `user_id` from SQLite to re-attach context
- Slice 1.1.4: Logout + token revocation + SQLite wipe (`deleteUser` + `deletePermissions`)
- Slice 1.1.5: **Auto-login on app start** — splash probes `TokenStorage.read()`,
  calls `AuthSession.markAuthenticated()` when tokens exist, then routes:
  tokens present → `/dashboard`, no tokens → `/login`. The user only sees the
  login screen again after an explicit logout, a refresh failure (interceptor
  routes back to `/login`), or a manual secure-storage wipe (uninstall/reset). ← **NEW**

**Storage boundary for Phase 1.1:**
```
Login API response
   ├── access_token  + refresh_token ──→ flutter_secure_storage  (secrets)
   ├── user profile                  ──→ SQLite: cached_user       (structural)
   └── permissions                   ──→ SQLite: user_permissions  (structural)
```

**Session persistence rules (Slice 1.1.5):**
- Tokens persist across app kills because `SecureTokenStorage` writes to
  `flutter_secure_storage` (iOS Keychain / Android Keystore). Do NOT add a
  process-lifetime cache that shadows it — the splash must always read the
  authoritative storage on cold start.
- `AuthSession.isAuthenticated` boots to `false` on every cold start (the
  bool is in-process state, not persisted). The splash MUST flip it via
  `AuthSession.markAuthenticated()` before navigating to `/dashboard` —
  otherwise the router's `redirect` (which reads `session.isAuthenticated`)
  bounces the request back to `/login` even when tokens are present. Stored
  tokens alone do not equal "router thinks I'm signed in."
- The splash does NOT validate the access token before redirecting. An expired
  access token is fine here — the first authenticated call hits the
  `AuthInterceptor`, which transparently refreshes via the refresh token. The
  user only bounces back to `/login` if BOTH access AND refresh have expired
  (or been revoked) — exactly the "session truly ended" case.
- Logout (and any failed refresh) MUST call `TokenStorage.clear()`. Skipping it
  re-grants auto-login on the next app start, which would be a security bug.
- The splash redirect target is the only place the "should I auto-login?"
  decision lives. Route guards and interceptors handle the after-the-fact
  cases (401 → refresh → maybe-logout). Don't duplicate the decision in
  individual pages or BLoCs.

#### Phase 1.2 — Multi-Factor & SSO
- Slice 1.2.1: TOTP/OTP input screen — ephemeral, memory only, no SQLite
- Slice 1.2.2: OAuth2 PKCE flow (`oauth2` package) — PKCE verifier/challenge in memory only, resulting tokens → `flutter_secure_storage`
- Slice 1.2.3: Biometric unlock (`local_auth`) — reads `biometric_on` flag from SQLite, biometric keys stay in OS keychain

**Storage boundary for Phase 1.2:**
```
OTP code          → memory only (ephemeral)
PKCE verifier     → memory only (ephemeral)
OAuth2 tokens     → flutter_secure_storage
biometric_on flag → SQLite: cached_user
```

#### Phase 1.3 — Role-Based Access Control (RBAC)
- Slice 1.3.1: Permission model (roles, scopes) from API — cached to SQLite `user_permissions`
- Slice 1.3.2: Permission-aware route guard — reads from SQLite so it works offline
- Slice 1.3.3: Widget-level permission gating (`PermissionGuard` widget)

**Full storage map — Module 1:**
```
                flutter_secure_storage    SQLite                  Memory
                ──────────────────────   ──────────────────────  ──────────────
Login           access_token             cached_user             —
                refresh_token            user_permissions
                                         last_login_at

Token refresh   (reads/writes tokens)    reads user_id           —

Biometric       —                        biometric_on (r/w)      —
                                         last_login_at

OTP / PKCE      —                        —                       verifier
                                                                  challenge
                                                                  OTP code

Logout          deleteAll()              deleteUser()            cleared
                                         deletePermissions()
```

---

### MODULE 2 — Dashboard & Home

#### Phase 2.1 — Shell & Navigation
- Slice 2.1.1: Bottom nav / side drawer shell responsive to screen size
- Slice 2.1.2: Module shortcut tiles (permission-filtered)
- Slice 2.1.3: Global search bar (federated search across modules)

#### Phase 2.2 — KPI Widgets
- Slice 2.2.1: KPI card component (value, trend, sparkline)
- Slice 2.2.2: Dashboard layout engine (configurable grid)
- Slice 2.2.3: Charts (`fl_chart`)
- Slice 2.2.4: Real-time refresh via WebSocket (`web_socket_channel`)

#### Phase 2.3 — Notifications
- Slice 2.3.1: Notification inbox BLoC
- Slice 2.3.2: Push notification handler (`firebase_messaging`)
- Slice 2.3.3: In-app notification center UI
- Slice 2.3.4: Deep-link from notification to record

---

### MODULE 3 — Finance & Accounting

#### Phase 3.1 — Chart of Accounts
- Slice 3.1.1: Account tree view (hierarchical list)
- Slice 3.1.2: Account detail + transactions list
- Slice 3.1.3: Offline cache of accounts

#### Phase 3.2 — Accounts Payable / Receivable
- Slice 3.2.1: Invoice list (filter, sort, search)
- Slice 3.2.2: Invoice detail view + PDF preview
- Slice 3.2.3: Create/edit invoice form with validation
- Slice 3.2.4: Approve/reject workflow action

##### Slice 3.2.4 — Approve/Reject Workflow Detail

**Invoice status state machine:**
```
DRAFT → PENDING_APPROVAL → APPROVED
                         → REJECTED → DRAFT (re-open for revision)
                                        └──→ PENDING_APPROVAL (re-submitted)
```

**Domain layer:**
- `ApproveInvoiceUseCase` — takes `invoiceId` + `approverId`; validates `finance.approve` permission scope before executing
- `RejectInvoiceUseCase` — takes `invoiceId` + `approverId` + `reason: String`; same permission check; reason is mandatory at domain level

**Repository / DataSource:**
- Online: `PATCH /invoices/{id}/approve` or `PATCH /invoices/{id}/reject` with body `{ approver_id, reason? }`
- Offline: write action to `SyncQueue` (Phase 0.4.1) with full payload; retry on connectivity restore (Phase 0.4.3)

**BLoC:**
- Events: `InvoiceActionEvent.approve(invoiceId)` / `InvoiceActionEvent.reject(invoiceId, reason)`
- States: `InvoiceActionLoading` → `InvoiceActionSuccess` / `InvoiceActionFailure`
- On success → dispatches refresh event to invoice list BLoC to update status chip

**UI:**
- Approve: single tap → confirmation bottom sheet → dispatch event
- Reject: tap → bottom sheet with mandatory `reason` text field (`FormBLoC` with field-level validation) → dispatch event
- Both buttons wrapped in `PermissionGuard` checking `finance.approve` scope from SQLite `user_permissions`
- Once status is `APPROVED` or `REJECTED` both buttons are disabled — status chip acts as visual lock

**SQLite — additional columns on `cached_invoices`:**
```
TABLE: cached_invoices  (add to existing schema)
  status           TEXT       ← DRAFT / PENDING_APPROVAL / APPROVED / REJECTED
  approved_by      TEXT       ← user_id FK → cached_user
  rejected_reason  TEXT
  actioned_at      DATETIME
```

**SyncQueue entry shape (Phase 0.4.1):**
```
SyncQueue row
  operation   TEXT   ← "invoice.approve" / "invoice.reject"
  payload     TEXT   ← JSON: { invoice_id, approver_id, reason? }
  status      TEXT   ← PENDING / SYNCING / FAILED
  created_at  DATETIME
```

**Storage boundary for Slice 3.2.4:**
```
                SQLite                             SyncQueue              Memory
                ──────────────────────────────   ──────────────────────  ──────────────
Online          cached_invoices (optimistic       —                       —
approve/reject  status + actioned_at +
                approved_by + reason)

Offline         cached_invoices (optimistic       enqueue operation       rejection reason
approve/reject  status update)                    payload                 (FormBLoC field)

Sync restore    cached_invoices (overwrite        dequeue on success      —
                with server truth)
```

**Guardrails for this slice:**
- Optimistic update on tap — write status to SQLite immediately, rollback on sync failure
- RBAC gate enforced at both UseCase level (domain) and widget level (`PermissionGuard`) — never rely on UI alone
- Rejection reason is mandatory — enforced in `RejectInvoiceUseCase`, not just the form validator
- No double-action — once `APPROVED` or `REJECTED`, UseCases throw `InvalidStateFailure` if re-triggered
- Audit trail — `approved_by` + `actioned_at` written to SQLite so Slice 9.3.2 (audit log viewer) can read offline

#### Phase 3.3 — General Ledger & Reporting
- Slice 3.3.1: Journal entry list + detail
- Slice 3.3.2: Trial balance report (paginated table)
- Slice 3.3.3: Export to CSV (`dart:io`)

---

### MODULE 4 — Procurement

#### Phase 4.1 — Purchase Requests
- Slice 4.1.1: PR list with status chips
- Slice 4.1.2: Create PR form (line items, cost center, approver)
- Slice 4.1.3: Approval workflow BLoC

#### Phase 4.2 — Purchase Orders
- Slice 4.2.1: PO list + detail
- Slice 4.2.2: Convert PR → PO flow
- Slice 4.2.3: Goods receipt entry

#### Phase 4.3 — Vendor Management
- Slice 4.3.1: Vendor list + detail
- Slice 4.3.2: Vendor onboarding form
- Slice 4.3.3: Vendor performance scorecard

---

### MODULE 5 — Inventory & Warehouse

#### Phase 5.1 — Stock Management
- Slice 5.1.1: Item catalog (search, filter by warehouse/location)
- Slice 5.1.2: Stock level detail + movement history
- Slice 5.1.3: Low-stock alerts (local notification trigger)

#### Phase 5.2 — Warehouse Operations
- Slice 5.2.1: Barcode/QR scan (`mobile_scanner`)
- Slice 5.2.2: Goods issue / goods receipt scan flow
- Slice 5.2.3: Stock transfer between locations
- Slice 5.2.4: Inventory count / cycle count workflow

#### Phase 5.3 — Offline Inventory
- Slice 5.3.1: Download item master to local SQLite DB
- Slice 5.3.2: Queue scanned transactions offline
- Slice 5.3.3: Batch sync on reconnect

---

### MODULE 6 — Sales & CRM

#### Phase 6.1 — Customer Management
- Slice 6.1.1: Customer list + detail
- Slice 6.1.2: Contact management (linked contacts per customer)
- Slice 6.1.3: Customer activity timeline
- Slice 6.1.4: Create Customer (avatar picker, identity + contact + commercial-terms sections; saves draft to SQLite) ← **NEW**
- Slice 6.1.5: Edit Customer (pre-filled from cache; discard confirmation when dirty) ← **NEW**

#### Phase 6.2 — Quotation & Orders
- Slice 6.2.1: Sales quotation create/edit
- Slice 6.2.2: Quotation → Sales Order conversion
- Slice 6.2.3: Order fulfillment status tracking

#### Phase 6.3 — Sales Analytics
- Slice 6.3.1: Revenue by period chart (`fl_chart`)
- Slice 6.3.2: Top customers / top products widgets
- Slice 6.3.3: Sales rep leaderboard

---

### MODULE 7 — Human Resources

#### Phase 7.1 — Employee Directory
- Slice 7.1.1: Employee list with avatar + department filter
- Slice 7.1.2: Employee profile detail
- Slice 7.1.3: Org chart (tree widget)

#### Phase 7.2 — Leave Management
- Slice 7.2.1: Leave request form + calendar picker
- Slice 7.2.2: Leave balance widget
- Slice 7.2.3: Manager approval flow
- Slice 7.2.4: Leave Approval Detail — full context view with employee snapshot, balance-after-approval preview, approval timeline, and approve/reject bottom sheets (gated by `hr.approve`) ← **NEW**

#### Phase 7.3 — Attendance & Payroll View
- Slice 7.3.1: Attendance log (clock in/out)
- Slice 7.3.2: Payslip viewer (PDF)
- Slice 7.3.3: Overtime/deduction summary

---

### MODULE 8 — Project Management

#### Phase 8.1 — Projects & Tasks
- Slice 8.1.1: Project list + Gantt-style timeline (custom painter)
- Slice 8.1.2: Task board (Kanban drag-and-drop with `flutter_reorderable_list`)
- Slice 8.1.3: Task detail + comment thread
- Slice 8.1.4: Create/Edit Project — charter form (basic info, timeline with live-computed duration, budget + billing type, team picker, status/priority) ← **NEW**
- Slice 8.1.5: Task Create/Edit — fast entry form (title, status/priority/assignee/due date pickers, description, inline subtasks) ← **NEW**
- Slice 8.1.6: Assign/Reassign Task — workload-aware member picker (open-task counts + availability dots), optional due date + note to assignee, push-notifies new assignee ← **NEW**

#### Phase 8.2 — Timesheets
- Slice 8.2.1: Daily timesheet entry
- Slice 8.2.2: Timesheet approval workflow
- Slice 8.2.3: Utilization report chart

---

### MODULE 9 — Settings & Administration

#### Phase 9.1 — User Preferences
- Slice 9.1.1: Theme toggle (light/dark)
- Slice 9.1.2: Language selector (i18n)
- Slice 9.1.3: Notification preferences
- Slice 9.1.4: My Profile Info — avatar edit (camera/gallery), contact + personal sections, account-security row (change password / change PIN / biometric toggle, all require re-auth) ← **NEW**
- Slice 9.1.5: My Roles & Permissions — read-only transparency view, granted vs not-granted lists with searchable filter, render scope strings as human labels ← **NEW**

#### Phase 9.2 — System Config (Admin)
- Slice 9.2.1: User management (admin only, RBAC-gated)
- Slice 9.2.2: Role & permission editor
- Slice 9.2.3: API endpoint configuration (multi-tenant/environment)

#### Phase 9.3 — Security
- Slice 9.3.1: Session management (active devices list)
- Slice 9.3.2: Audit log viewer
- Slice 9.3.3: App PIN lock / biometric re-auth on resume

---

### MODULE 10 — Chat & Voice / Video ← **NEW MODULE**

> Real-time internal communication. Built on a WebSocket signalling layer
> with SQLite for offline message persistence; voice + video calls use
> WebRTC peer-to-peer via `flutter_webrtc`. New package dependencies:
> `flutter_webrtc`, `record`, `just_audio`, `image_picker`, `file_picker`.

**SQLite tables for Module 10:**
```
TABLE: chat_conversations
  id, name, avatar_url, is_group, is_muted,
  last_message_body, last_message_sender_id, last_message_at,
  unread_count, created_at, updated_at

TABLE: chat_participants
  conversation_id, employee_id, is_admin, joined_at, last_read_at

TABLE: chat_messages
  id, conversation_id, sender_id,
  body, type,                            -- text | voice | image | file | system
  reply_to_id, edited_body, edited_at, is_deleted,
  file_url, file_name, file_size_bytes,
  voice_url, voice_duration_seconds,
  sent_at, delivered_at, read_at,
  reactions                              -- JSON: [{emoji, employee_ids[]}]

TABLE: chat_call_log
  id, conversation_id, caller_id, call_type,   -- voice | video
  started_at, answered_at, ended_at,
  duration_seconds, status                     -- missed | answered | rejected | no_answer
```

#### Phase 10.1 — Chat Core
- Slice 10.1.1: Chat Inbox — conversation list (All / Unread / Groups tabs), online-status dots, unread badges, swipe-to-mute / swipe-to-delete; subscribes to `/ws/inbox` for real-time updates
- Slice 10.1.2: Chat Conversation — paginated message list with date separators, reply quotes, reaction row, typing indicator, optimistic-insert sends; supports text + voice (hold-to-record) + image + file attachments; `/ws/chat/:conversationId` for live message/typing/seen events
- Slice 10.1.3: New Conversation / Group Chat — searchable member picker with Direct vs Group toggle, group name + avatar setup; creates `chat_conversations` + `chat_participants` rows
- Slice 10.1.4: Message Search — SQLite FTS5 full-text search over `chat_messages.body`, tap result → jump to + highlight in conversation
- Slice 10.1.5: Image Viewer + real Gallery send — full-screen viewer (`ImageViewerPage`) opened on tap of an image bubble or a Shared-Media tile. Pinch-to-zoom via `InteractiveViewer`, tap-to-toggle chrome, drag-down-to-dismiss with fading scrim, top-right share / save stubs, bottom caption with filename + sender + timestamp. Sources adapt automatically: `http(s)://` → `Image.network`, local file path → `Image.file` (after `File.exists` check), `demo://` seed stub → friendly placeholder. Companion change: the Conversation page's attachment sheet's Camera + Gallery options now run a real `ImagePicker` (max 1920 × 1920, quality 88) and send the result as a `ChatMessageType.image` message whose `fileUrl` is the local absolute path — so the new viewer has real bytes to display, and the wire transport (Slice 10.1.x) syncs the metadata to peers. ← **NEW**
- Slice 10.1.6: Real-time inbox sync — every inbound `MessageReceivedEvent` now also feeds `ConversationsRepository.updateLastMessage(...)` AND `bumpUnread(...)` from `bootChatTransport`, so the inbox tile of the receiving phone shows the new preview and the unread badge ticks up (1 → 2 → 3) **without** the user having to re-open the chat. A new `ActiveConversationTracker` singleton (entered in `ChatConversationPage.initState`, left in `dispose`) lets the bump skip the conversation the user is currently reading — counters only grow for chats the user is NOT looking at. The conversation page also calls `markRead(...)` on entry so search-result / call-back / deep-link paths clear the badge the same way an inbox tap does. The per-type preview helper renders `📷 Photo` / `📎 filename.pdf` / `🎤 Voice · 0:23` / raw body so the inbox row matches what the user sees in the conversation. ← **NEW**
- Slice 10.1.7: Cross-device group propagation — when User A creates a group `CHAT01` with Users B + C, every invited member's device used to stay empty because `NewConversationPage._create` only touched the local in-memory repo. A new `conversation.create` wire envelope (`ConversationCreatedEvent` in `ChatTransport`) carries `{ conversationId, name, isGroup, creatorId, creatorName, participantIds, createdAt }` over the relay; `participantIds` includes the creator AND every invited member so each callee can verify the envelope is addressed to them (the relay is broadcast-only, no identity awareness). `bootChatTransport` listens for the event, filters on `participantIds.contains(settings.userId)`, short-circuits on duplicate id (idempotent re-broadcast), then hydrates `ConversationsRepository.create(...)` with `participantPreviews` resolved from `ChatSeed.peopleDirectory` (excluding self) and `totalMembers = participantIds.length`. Direct conversations are still created implicitly on the first message exchange — no envelope needed. ← **NEW**
- Slice 10.1.8: Targeted direct messages — fixes three related bugs the user surfaced after 10.1.7. **Bug A** (cross-user leakage): `message.send` was broadcast to every connected socket with no addressing, so when Vibol→Pisey landed on Channary's relay socket, Channary's inbox processed it and her "Pisey Chhan" tile preview updated with Vibol's text. Fix: added `targetIds: List<String>` to the `message.send` envelope (mirrors the Slice 10.2.7 call routing). Sender computes from `conversation.participantPreviews` minus self; `bootChatTransport` drops inbound messages whose targetIds is non-empty and doesn't contain `settings.userId`. Empty list = legacy broadcast for back-compat. **Bug B** (direct-conv id mismatch): the seed reuses ids like `conv-005` ("Pisey Chhan") on every device, so when Vibol sends in HIS conv-005 (his Pisey-direct slot), Pisey's device looks up conv-005 → finds it locally → but it's *her own* self-direct slot, not her chat-with-Vibol. Fix: new `ConversationsRepository.findDirectWith(employeeId)` walks the seed for a non-group conv whose `participantPreviews` contains that id. On receive, if `targetIds == [me]` (direct-to-me), the handler looks up the local conv with the sender as the other party and rewrites `m.conversationId` to that local id before persisting. Vibol→Pisey now lands in Pisey's conv-003 ("Vibol Sok") tile. **Bug C** (double "You:" prefix on the inbox): the conversation page was sending `'You: $body'` to `updateLastMessage`, and the inbox tile's `_previewFor` was ALSO prepending "You: " when `senderId == me` — net effect "You: You: hi" / "You: You: 📷 Photo" / "You: You: 🎤 Voice…". Fix: send the raw body to `updateLastMessage` and let the inbox handle the prefix in one place. ← **NEW**
- Slice 10.1.9: Profile photo + inline call history on the chat page itself — two follow-ups so the conversation page matches the other surfaces. **Bug A** (AppBar avatar ignored `avatarFilePath`): the chat page's AppBar still rendered `GroupAvatarCluster` for groups and the initials gradient for direct convs, even after Slice 10.3.5 (direct contact photo) and Slice 10.3.6 (group avatar sync). Fix: groups with a photo now render `ChatAvatar(avatarFilePath: ...)` and only fall back to the cluster when the path is empty; direct hero passes `avatarFilePath` through. Three surfaces (inbox tile, chat AppBar, call hero) now stay in lockstep. **Bug B** (call history wasn't visible inside the chat). `chat_call_log` was surfaced only on the Calls tab + the Chat Info page, not in the chat itself — Telegram weaves call rows into the message timeline so you see the call context inline. Fix: `ChatConversationPage` now subscribes to `CallLogRepository.watchAll()` alongside the messages stream, builds a `_TimelineEntry` list that merges messages + call logs sorted by time, and renders call entries as a new `_CallEntryBubble` (alignment by `callerId == currentUserId`, direction icon `call_made` / `call_received` / `call_missed`, missed in error red, tap to redial via `ConfigRouter.pushPageAnimation` to the matching voice/video page). Date separators + sender-group breaks still work — a call entry resets `lastSenderId` so the next bubble re-prints its header. ← **NEW**

#### Phase 10.2 — Voice & Video Calls
- Slice 10.2.1: Voice Call — WebRTC via `flutter_webrtc`, signalling over `/ws/voice/:callId`, incoming-call modal sheet (system-overlay), in-call screen with mute / speaker / keypad / end controls; requests `Permission.microphone` first; logs to `chat_call_log`
- Slice 10.2.2: Video Call — same WebRTC stack with both audio + video tracks, full-screen remote `RTCVideoRenderer` + draggable local PiP (mirrored front camera), auto-hide controls after 3s; requires both mic + camera permissions, handles partial grant; logs to `chat_call_log`
- Slice 10.2.3: Cross-device call ceremony (signalling-only stub) — gives the existing voice + video pages real two-device behaviour over the WebSocket relay **without** adding WebRTC. Extends the wire protocol with four envelope types (`call.invite` / `call.accept` / `call.reject` / `call.hangup`) and a new `CallSignalingService` that turns them into a typed `ActiveCall` state machine (`outgoingRinging → connected → ended`, plus an `incomingRinging` branch for the callee). A root-level `IncomingCallOverlay` (mounted via `MaterialApp.builder`) listens to the service and paints a full-screen Accept/Reject sheet over any route the callee happens to be on. Pressing **Accept** transitions both sides to `connected` and pushes the matching `VoiceCallPage` / `VideoCallPage` (now driven by the service instead of a local `Timer`), so the elapsed-time counter starts on both phones simultaneously. **No audio or video actually flows** — replacing the connected branch with real WebRTC offer/answer + ICE (which would ride the same transport) is Slice 10.2.4. The `chat_call_log` rows are written end-to-end so the call history / inbox previews stay accurate. ← **NEW**
- Slice 10.2.4: Busy signal — when User 1 is mid-call (`outgoingRinging` or `connected`) and User 3 fires a fresh `call.invite`, User 1's `CallSignalingService` auto-rejects with `reason: 'busy'` on the wire. The `CallRejectEvent` carries the reason back to User 3, which the call page surfaces both in the top-bar label (`Busy` instead of `Call ended`) and as a floating snackbar (`"User 1 is on another call."` / `"User 1 declined the call."`). Stale `incomingRinging` states from missed invites are *replaced* by new ones (instead of locking out follow-ups) and an aggressive 30s ring timeout auto-clears them so a phone that never showed the sheet can't get permanently stuck rejecting everything. ← **NEW**
- Slice 10.2.5: Call history (per-conversation + global Recent Calls) — surfaces the `chat_call_log` everywhere the user expects it. Per-conversation: a new section in Chat Info between Shared Media and Settings, showing the last 6 entries with direction icons (`call_made` / `call_received` / `call_missed`), missed-state in error red, duration, and a relative timestamp; tap re-opens the matching voice/video page. Global: a fourth tab **Calls** on the inbox `TabBar` that lists every log entry newest-first with a per-row direction badge sitting on the avatar, plus the same one-tap re-dial. ← **NEW**
- Slice 10.2.6: App lifecycle awareness — `ChatLifecycleBridge` registers a `WidgetsBindingObserver` from `bootChatTransport`; on `AppLifecycleState.resumed` it forces `transport.updateConfig(...)` to re-validate the socket, which kicks the existing 2-second reconnect chain when the OS killed the WebSocket while we were backgrounded. **Honest limitations** — the relay is a local-LAN demo, so two states cannot be made to work without a real backend: (1) **out-of-app for >30s** — the ring timeout fires before the user returns, so the call shows as missed; fixing this needs `flutter_local_notifications` with a heads-up notification + Accept/Reject actions; (2) **app killed entirely** — the WebSocket dies with the process, no relay event can wake it, and `chat_call_log` stays in `noAnswer`. Production path: FCM (Android) / APNs (iOS) high-priority push from a server-side relay, which the OS delivers to a background isolate that then shows the incoming-call sheet. Neither is wired here. ← **NEW**
- Slice 10.2.7: Targeted call routing — `call.invite` now carries `targetIds: List<String>` (callee user ids). The relay still fan-outs to every connected socket (no identity awareness on the server), but each callee's `CallSignalingService` filters: if the envelope's `targetIds` is non-empty and doesn't contain `settings.userId`, the invite is dropped silently. Direct conversations compute `[other_person]`; group conversations compute `[every participant except self]`. Empty list = pre-10.2.7 broadcast (kept for backwards compatibility with old clients on the wire). Companion seed change: direct conversations now carry a single-element `participantPreviews` so the caller actually knows the other person's `employeeId` — before this, a Demo-Approver → Channary call rang every connected client (including Vibol Sok on a third phone). ← **NEW**
- Slice 10.2.8: Accept actually opens the call page (+ independent group accepts) — fixes two bugs the user surfaced after 10.2.7. **Bug A** (individual + group): tapping **Accept** on the incoming sheet flipped `CallSignalingService` to `connected`, which immediately unmounted `IncomingCallOverlay` so the `if (!context.mounted) return;` guard right after the `await signaling.acceptIncoming()` swallowed the `Navigator.push` and the in-call page never opened — the sheet just disappeared and the call log row stayed in `answered` with no `endedAt`. Fix: capture the rootNavigator BEFORE doing anything, push the call page first, then fire-and-forget `acceptIncoming()` — the page subscribes to `activeCallListenable` in its initState so the connected-state transition is picked up either way (it reads `_signaling.current` if the transition lands during the build microtask, or via the listener if it lands later). **Bug B** (group only): the caller AND every other callee share the same `callId`, so when one callee accepted, all other callees' `_onEvent` saw `CallAcceptEvent` and ran `_setActive(copyWith(state: connected))` — which yanked them out of `incomingRinging` and closed their sheet without them ever choosing. Fix: in the `CallAcceptEvent` branch, return early if `active.state != outgoingRinging` so only the original caller transitions; every other callee stays ringing and gets to accept independently. ← **NEW**
- Slice 10.2.9: Accept-call via root navigator key + group call header — fixes two more bugs reported after 10.2.8. **Bug A** (accept STILL doesn't open the call page): the prior fix used `Navigator.of(context, rootNavigator: true)` from inside `IncomingCallOverlay`, but the overlay is mounted via `MaterialApp.builder` — i.e. the go_router Navigator is a SIBLING in the Stack, not an ancestor. `Navigator.of(context)` walked up the tree, found no Navigator, and silently dropped the push (the exception was caught and produced no visible error). Fix: added `AppRouter.rootNavigatorKey` (a `GlobalKey<NavigatorState>`) and attached it to `GoRouter(navigatorKey: ...)`. The accept handler now pushes via `AppRouter.rootNavigatorKey.currentState!.push(...)`, which goes through the actual root navigator regardless of where the overlay's context sits in the widget tree. **Bug B** (group call shows caller name): the incoming sheet on Pisey / Channary's phone showed `call.peerName` ("Vibol") for a group call to TEST01 — recipients had no way to tell whether the invite was a 1:1 or a group call. Fix: added `conversationName` + `isGroup` to `ActiveCall`, populated from `conversations.findById(...)` in both `startOutgoing` and the inbound `CallInviteEvent` handler. The sheet now renders the GROUP name as the title ("TEST01"), a `Icons.groups_rounded` cluster instead of caller initials, an "Incoming group voice/video call" top label, and "Vibol is calling…" as a subtitle so the recipient still knows WHO triggered it. Direct calls keep the pre-10.2.9 look. ← **NEW**
- Slice 10.2.10: Group multi-party hangup + group call photo + Telegram-style call history on inbox tiles — three bugs reported after 10.2.9. **Bug A** (one End kills everyone in a group call): `CallHangupEvent` was processed by every peer regardless of who pressed End, so when Pisey tapped End in a group with Demo + Vibol + Pisey, all three call pages closed. Fix: added `hangerUpperId` to `CallHangupEvent` (caller stamps it from `settings.userId`) and `callerId` to `ActiveCall` (populated in both `startOutgoing` and the inbound `CallInviteEvent` handler). On receive, when `active.isGroup` and `hangerUpperId` is neither the original `callerId` nor ourselves, drop the event — the rest of the group stays connected and the timer keeps ticking. The original caller's End still ends the call for everyone (their bow-out is canonical). Direct 1:1 calls keep the pre-10.2.10 "either side ends it" behaviour because there's nobody else to stay connected with. Pre-10.2.10 clients without `hangerUpperId` fall back to "everyone ends" for back-compat. **Bug B** (group call shows initials, not the uploaded group photo): both `VoiceCallPage._PulsingAvatar` and `VideoCallPage` placeholder cards rendered `GroupAvatarCluster(previews:)` for groups regardless of whether a `avatarFilePath` was set. Fix: render `ChatAvatar(avatarFilePath: conversation.avatarFilePath)` whenever a photo exists; fall back to the cluster only when null. Direct calls already had the field but weren't passing it through — also fixed. **Bug C** (call history hidden on the Calls tab — Telegram surfaces it inline). New `CallSignalingService._writeCallSummary(...)` hooks into all four end paths (local `hangup`, local `rejectIncoming`, peer `CallRejectEvent`, peer `CallHangupEvent`) and writes a per-type summary into `conversations.updateLastMessage(...)` — `📞 Voice call · 5:23` for answered, `📞 Missed voice call` for missed, `📞 Declined video call` for rejected (video uses `📹`). `senderId = active.callerId` so the inbox `_previewFor` adds "You: " for the caller and bare text for the callee. Net effect: the inbox tile mirrors what Telegram's "Recent" list shows for every conversation. ← **NEW**
- Slice 10.2.11: Last-callee-out auto-ends the group call + group photo on incoming sheet + direct-call summary lands in the right tile — three follow-ups after 10.2.10. **Bug A** (caller stranded after every callee leaves a group call): Slice 10.2.10 stopped a single callee's End from killing everyone, but the caller was then left alone with a running timer when every callee bowed out — there was nobody else in the call. Fix: added `accepterId` to `CallAcceptEvent` (callee stamps it from `settings.userId`) and a caller-only `Set<String> _activeCallees` tracked in `CallSignalingService`. The caller adds an id when a peer accepts (state stays `connected` for any accepts beyond the first so additional joiners get tracked) and removes one on each non-caller `CallHangupEvent`. When the set drains to empty, the caller fires its own `hangup(...)` so the timer stops and the call page pops — Telegram's last-person-out behaviour. **Bug B** (group photo missing on the incoming sheet itself): the in-call hero rendered the photo (Slice 10.2.10) but the modal sheet shown by `IncomingCallOverlay` only had a group icon. Fix: added `conversationAvatarFilePath` to `ActiveCall`, populated from `conv?.avatarFilePath` in both `startOutgoing` and the inbound invite handler; the overlay now wraps the hero in a new `_IncomingAvatar` widget that paints the file via `DecorationImage(FileImage(...))` when one exists, falling back to the group icon (groups) or caller initials (direct). **Bug C** (call summary on a direct call landed in the wrong inbox tile on the callee): `_writeCallSummary` wrote to `active.conversationId`, which on the receiver was the caller's local conv id — different from the callee's local conv-with-caller because the seed reuses ids per device (same bug Slice 10.1.8 fixed for messages). Fix: for non-group calls, look up `conversations.findDirectWith(otherId)` and redirect the summary there. Group calls use the shared conv id verbatim (Slice 10.1.7 broadcast). ← **NEW**

#### Phase 10.3 — Chat Admin
- Slice 10.3.1: Conversation Info / Chat Settings — different layouts for direct vs group conversations, shared-media grid, mute toggle, pinned-message row; group view adds member list with admin badges and admin-only options (add/remove members, promote, rename, edit avatar, leave group); shared "Clear Chat History" (device-local only)
- Slice 10.3.2: Add Members — admin-gated modal sheet that lists every directory employee NOT already in the group, with a search bar and multi-select checkboxes. Confirm pushes the picks through `ConversationsRepository.addMembers(...)` which de-dups against current `participantPreviews` and bumps `totalMembers` + `onlineCount`. Reachable from the Quick Actions row + the future "Add" trailing button on the Members section header. ← **NEW**
- Slice 10.3.3: Change Group Profile — admin-gated edits to the group's identity in the Chat Info hero. Tapping the **group avatar** opens a camera/gallery/remove sheet powered by `image_picker`; the picked file path persists on the new `ChatConversation.avatarFilePath` field and is rendered by `ChatAvatar` via `FileImage`, falling back to the participant cluster when null. Tapping the **group name** (or the pencil affordance beside it) opens a rename sheet whose Save button is disabled until the name actually changed. Both flows route through `ConversationsRepository` (`setAvatarPath` / `rename`) so the inbox tile + AppBar update reactively. ← **NEW**
- Slice 10.3.4: Profile + group rename sync — extends 10.3.3 / 9.1.4 so identity changes propagate across devices. Two new wire envelopes: **`conversation.update`** (`ConversationUpdatedEvent`) carries `{ conversationId, name, participantIds }`. `_showRenameSheet` in `chat_info_page.dart` broadcasts it after `ConversationsRepository.rename(...)`; `bootChatTransport` filters by participantIds, looks up the conv, and applies `rename(...)` locally — so when Channary renames `CHAT01` → `TEST01`, Vibol and Pisey's inboxes + AppBars rename live without re-opening the chat. **`profile.update`** (`ProfileUpdatedEvent`) carries `{ userId, newName }`. `ChatSettings.setIdentity` fires it when the same user keeps their id but changes their display name; on the peer side, `bootChatTransport` calls `ConversationsRepository.findDirectWith(userId)` and renames the matching local direct conv — so when Vibol renames himself, Pisey's "Vibol Sok" tile + AppBar pick up the new name. **Avatar is NOT broadcast** because the demo's avatars are local `image_picker` file paths that don't exist on peer devices; production would route through an upload endpoint and broadcast the resulting URL. ← **NEW**
- Slice 10.3.5: Set photo for direct chats (Telegram "Set contact photo") — until now `avatarFilePath` was group-only; direct convs rendered initials with no way to override. The Chat Info hero is now tap-to-change for BOTH direct and group conversations, the camera-pencil badge is always shown, and the sheet header text adapts ("Change contact photo" / "Change group photo") via a new `_photoSheetTitle(...)` helper. `ChatAvatar(avatarFilePath:)` was already wired through; the direct-conv hero just wasn't passing the field. Inbox tiles match — `chat_inbox_page.dart` now prefers the user-set photo over both the group cluster (groups) and initials (direct), keeping all three surfaces (Hero, AppBar, inbox tile) in lockstep. Per-device only — broadcasting the file path is meaningless, and adding an upload endpoint is out of scope for the demo. ← **NEW**
- Slice 10.3.6: Group avatar sync — when Channary picks a photo for group TEST01, every member's inbox tile + AppBar + call hero now picks it up too. The 10.3.4 sync covered name only; avatars stayed per-device because the path is local. Fix: new `conversation.avatar.update` envelope (`ConversationAvatarUpdatedEvent`) carries `{ conversationId, participantIds, avatarBase64, fileExtension }`. The sender (`_pickGroupPhoto` in `chat_info_page.dart`) reads the picked file (already sized to 1024×1024 / quality 85 by image_picker, typically 50–200 KB), base64-encodes, and broadcasts. The receiver (`_applyInboundAvatarUpdate` in `chat_di.dart`) filters by participantIds, decodes the bytes, writes them to `getApplicationCacheDirectory()` under `chat_avatar_<conversationId>.<ext>` (deterministic name = next sync overwrites the same file, no leak), then calls `ConversationsRepository.setAvatarPath(...)` with the new local path. A null `avatarBase64` means "admin removed the photo" — peers clear their own path too. Direct conv photos stay per-device (Slice 10.3.5) — no peer envelope. Limitation: in a hypothetical production stack the bytes would go to an upload endpoint and only the URL would ride this envelope. ← **NEW**

> Note: per the design guide, Module 10 was restructured from 5 → 7 screens (net +2). All 7 are listed above across the 3 phases. Slices 10.3.2 and 10.3.3 extend the existing Conversation Info screen — no new pages.

---

## Development Guardrails

### What TO do
- Keep BLoC events **immutable** (use `freezed`)
- Business rules live in the Repository (or, when stateful, the BLoC) — not in widgets or ViewModels
- Repository is a single concrete class; it owns the `dio`/`SQLite` calls directly
- All forms use a dedicated `FormBLoC` with field-level validation
- Write unit tests per slice before moving to the next
- Version your SQLite DB with explicit migrations from day one

### What NOT to do
- No business logic in widgets or ViewModels
- No direct API calls from BLoC — always through the Repository
- No `BuildContext` inside BLoC or ViewModel
- No hardcoded strings — always use l10n ARB keys
- No commercial/paid packages — validate every package on pub.dev for open-source license (MIT, BSD, Apache 2.0)
- Don't share BLoC instances across unrelated modules — use scoped BLoC providers
- Don't introduce new `UseCase` classes or abstract repository interfaces — Modules 1–9 still have them for legacy reasons, but new code stays flat

### Legacy modules (1–9)
The existing modules were built under MVVM + Clean Architecture and still
contain `domain/usecases/` + `domain/repositories/` (abstract). Honour
that convention when editing those modules — don't mix flat and layered
styles inside the same feature. New modules use flat MVVM (above).

---

## Recommended Build Order

```
Phase 0 (Core) → Module 1 (Auth) → Module 2 (Dashboard)
   → Module 3 (Finance) + Module 4 (Procurement)  [parallel]
   → Module 5 (Inventory)
   → Module 6 (Sales)
   → Module 7 (HR) + Module 8 (Projects)  [parallel]
   → Module 9 (Settings)
   → Module 10 (Chat & Voice/Video)  [last — adds WebSocket + WebRTC stack]
```


---

# Appended: ERP Mobile Design Guide

> Verbatim copy of [`ERP_MOBILE_DESIGN_GUIDE.md`](./ERP_MOBILE_DESIGN_GUIDE.md), inlined here for single-file reference.
> The standalone file remains the canonical source — edit it there, then re-sync.

# ERP Mobile Flutter — Complete Design & Coding Standards
> Single source of truth for all 72 screens. Use this file when prompting Claude Code.
> Covers: design tokens · component patterns · coding rules · per-screen layout intent · BLoC/SQLite spec · prompt template.

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Design Tokens (AppTheme singleton)](#2-design-tokens-apptheme-singleton)
3. [Shared Component Patterns](#3-shared-component-patterns)
4. [Navigation Structure](#4-navigation-structure)
5. [Motion & Animation Rules](#5-motion--animation-rules)
6. [Coding Standards & Architecture Rules](#6-coding-standards--architecture-rules)
7. [Screen Specifications — All 76 Screens](#7-screen-specifications--all-76-screens)
   - [Module 0 — App Entry](#module-0--app-entry)
   - [Module 1 — Authentication & Identity](#module-1--authentication--identity)
   - [Module 2 — Dashboard & Home](#module-2--dashboard--home)
   - [Module 3 — Finance & Accounting](#module-3--finance--accounting)
   - [Module 4 — Procurement](#module-4--procurement)
   - [Module 5 — Inventory & Warehouse](#module-5--inventory--warehouse)
   - [Module 6 — Sales & CRM](#module-6--sales--crm) *(+2 new screens)*
   - [Module 7 — Human Resources](#module-7--human-resources) *(+1 new screen)*
   - [Module 8 — Project Management](#module-8--project-management) *(+3 new screens)*
   - [Module 9 — Settings & Administration](#module-9--settings--administration) *(+2 new screens)*
   - [Module 10 — Chat & Voice](#module-10--chat--voice) *(new module, 5 screens)*
8. [Screen Complexity Summary](#8-screen-complexity-summary)
9. [Claude Code Prompt Template](#9-claude-code-prompt-template)

---

## 1. Design Philosophy

**Clean. Spacious. Data-first.**

This is an enterprise tool used daily by real workers — accountants, warehouse staff, HR managers. The design must feel modern but never trendy. Every pixel must earn its place.

**Three principles:**

- **Clarity over decoration** — users need to find data fast, not admire animations
- **Density with breathing room** — ERP has a lot of data; use cards and sections, never walls of text
- **Calm confidence** — muted colors, consistent spacing, no aggressive CTAs

---

## 2. Design Tokens (AppTheme singleton)

> All values live in a single `AppTheme` singleton.
> **Never hardcode colors, sizes, or fonts anywhere in widget code.**

### 2.1 Colors

```dart
// Primary palette — deep indigo, professional
primary:            Color(0xFF3B4FE8)   // buttons, active states, links
onPrimary:          Color(0xFFFFFFFF)
primaryContainer:   Color(0xFFE8EBFF)  // chip backgrounds, light badges

// Surface
surface:            Color(0xFFF8F9FC)  // page background (light)
surfaceVariant:     Color(0xFFEEF0F5)  // card background, input fill
onSurface:          Color(0xFF1A1D23)  // primary text
onSurfaceVariant:   Color(0xFF6B7280)  // secondary text, placeholders

// Status colors
success:  Color(0xFF16A34A)  // APPROVED, in-stock, on-time
warning:  Color(0xFFD97706)  // PENDING, low-stock, expiring
error:    Color(0xFFDC2626)  // REJECTED, overdue, failed
info:     Color(0xFF0284C7)  // neutral status, info banners

// Status container variants (backgrounds for chips/badges)
successContainer: Color(0xFFDCFCE7)
warningContainer: Color(0xFFFEF3C7)
errorContainer:   Color(0xFFFEE2E2)
infoContainer:    Color(0xFFE0F2FE)

// Dark mode overrides
// surface → Color(0xFF0F1117), cards → Color(0xFF1A1D23)
```

### 2.2 Typography — AppLabel

```dart
// All text uses Inter font family
// Register in AppLabel singleton — never use raw TextStyle in widgets

AppLabel.displayLarge   // 32sp, w700 — splash app name only
AppLabel.headlineLarge  // 24sp, w700 — page titles
AppLabel.headlineMedium // 20sp, w600 — section headers, card titles
AppLabel.titleMedium    // 16sp, w600 — list tile titles, tab labels
AppLabel.bodyLarge      // 16sp, w400 — body text, descriptions
AppLabel.bodyMedium     // 14sp, w400 — secondary info, subtitles
AppLabel.bodySmall      // 12sp, w400 — timestamps, captions, version text
AppLabel.labelLarge     // 14sp, w600 — button labels
AppLabel.labelSmall     // 11sp, w500 — status chips, badges
```

### 2.3 Spacing — AppSpacing

```dart
AppSpacing.xs   =  4.0
AppSpacing.sm   =  8.0
AppSpacing.md   = 16.0
AppSpacing.lg   = 24.0
AppSpacing.xl   = 32.0
AppSpacing.xxl  = 48.0
```

### 2.4 Border Radius — AppRadius

```dart
AppRadius.sm   =  8.0   // chips, small badges
AppRadius.md   = 12.0   // input fields, small cards
AppRadius.lg   = 16.0   // main cards, bottom sheets
AppRadius.xl   = 24.0   // FAB, large modal sheets
AppRadius.full = 999.0  // pill-shaped chips
```

### 2.5 Elevation / Shadows

```dart
AppShadow.card = BoxShadow(
  color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2),
)
AppShadow.modal = BoxShadow(
  color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8),
)
```

### 2.6 Module Icon Colors

```
Finance      → indigo (primary)
Inventory    → orange
HR           → purple
Sales        → green
Procurement  → teal
Projects     → blue
```

---

## 3. Shared Component Patterns

### AppCard
Every content block lives in a card. **Never raw containers.**
```
white bg · AppRadius.lg · AppShadow.card · padding AppSpacing.md
```

### StatusChip
```
pill shape · AppRadius.full · labelSmall text · status color map:

  DRAFT            → surfaceVariant bg,    onSurfaceVariant text
  PENDING_APPROVAL → warningContainer bg,  warning text
  APPROVED         → successContainer bg,  success text
  REJECTED         → errorContainer bg,    error text
  ACTIVE           → successContainer bg,  success text
  ON_HOLD          → warningContainer bg,  warning text
  COMPLETED        → infoContainer bg,     info text
```

### SectionHeader
```
headlineMedium text · left-aligned · bottom padding AppSpacing.sm
optional trailing TextButton (labelLarge)
```

### EmptyState
```
centered column · illustration (80×80) · headlineMedium title
· bodyMedium subtitle · optional FilledButton CTA
```

### LoadingShimmer
```
shimmer skeleton matching real layout shape — never blank screen
never CircularProgressIndicator alone on lists
```

### FAB
```
primary color · AppRadius.xl · icon+label (extended) on tablet
icon only on mobile · bottom-right · never covers key content
```

### InputField (all forms)
```
filled style · surfaceVariant fill · no border at rest
primary border 2px on focus · AppRadius.md
prefixIcon where applicable · error text below on invalid
```

### ApprovalTimeline
```
vertical list with connector line between steps
each step: avatar · name · action chip · timestamp
used in: Invoice Detail, PR Detail, Leave Approval
```

### PermissionGuard
```
wraps any widget that requires a specific RBAC scope
PermissionGuard(scope: 'finance.approve') { ... }
renders nothing (or disabled state) if user lacks permission
```

---

## 4. Navigation Structure

```
BottomNavigationBar (mobile):
  Dashboard · Finance · Inventory · HR · Chat · More (→ side sheet)

NavigationRail (tablet, always visible left):
  Same 6 items + expanded text labels

"More" side sheet expands to show:
  Procurement · Sales · Projects · Settings
```

**Chat badge:** unread message count badge on Chat nav item (warningContainer bg, labelSmall)

**Page transitions:**
- Bottom nav: fade-through
- Push routes: slide-from-right
- Back: slide-to-right (default)

---

## 5. Motion & Animation Rules

| Element | Animation | Duration |
|---|---|---|
| Page (bottom nav) | fade-through | system default |
| Page (push) | slide-from-right | system default |
| List items | staggered fade-in, 50ms delay per item | 300ms max total |
| Bottom sheets | slide up | 300ms ease-out |
| Status chips | AnimatedSwitcher crossfade on status change | 200ms |
| Buttons | AnimatedScale 0.97 on press | 100ms |
| Errors | horizontal shake on PIN fail / form submit fail | 300ms |
| Loading | LoadingShimmer skeleton | — |
| Splash logo | fade + scale | 900ms easeOutBack |
| Biometric icon | soft pulse scale 1.0→1.08→1.0 | 1.5s repeat |

**Never:** bounce, spin, or add gratuitous motion — this is a work tool.

---

## 6. Coding Standards & Architecture Rules

### 6.1 Non-negotiable rules

- **Never hardcode** colors, sizes, or fonts — use `AppTheme`, `AppLabel`, `AppSpacing`, `AppRadius` exclusively
- **Never use raw containers** as content blocks — always `AppCard`
- **Never show a blank screen** while loading — always `LoadingShimmer` on lists
- **Never unguard admin actions** — wrap with `PermissionGuard(scope: '...')`
- **Never use raw `TextStyle`** in widget code — always `AppLabel`

### 6.2 Widget architecture

- Split into **small private widget classes** — one per visual section
- Add `buildWhen` on **every `BlocBuilder`** to minimise rebuilds
- Show `EmptyState` widget whenever any list is empty
- Use `StatusChip` from the shared status color map — no custom chips
- Use `LoadingShimmer` instead of `CircularProgressIndicator` on list screens

### 6.3 BLoC patterns

```dart
// Standard BLoC shape — all screens follow this
Events: [Entity]Loaded, [Action]Requested, FilterChanged, etc.
States: [Entity]Initial → [Entity]Loading → [Entity]Loaded / [Entity]Failure

// Forms use this extended pattern
States: [Form]Initial → [Form]Valid / [Form]Invalid → [Form]Saving
      → [Form]Success / [Form]Failure
```

### 6.4 Data / state rules

- All SQLite reads happen in BLoC — never in widget `build()`
- Admin screens (`/settings/admin/*`) read from API only — no local cache (security)
- Splash screen uses only local SQLite + `flutter_secure_storage` — no network calls
- PIN hash stored in `flutter_secure_storage`, not SQLite
- Offline transactions enqueue to `sync_queue` SQLite table; `SyncStatusBLoC` surfaces status
- Optimistic UI updates for stock transactions — revert on API failure

### 6.5 Form rules

- All forms use `FormBLoC` for validation state
- Save Draft = upsert to SQLite; Submit = POST to API
- Line item forms must support dynamic add/remove rows
- Show running totals reactively as fields change

### 6.6 Approval flow pattern

Used in: Invoice (3.4), Purchase Request (4.3), Leave (7.6)

```
DetailBLoC   — loads the document
ActionBLoC   — handles approve/reject
  Events:    [Entity]Approved(id) / [Entity]Rejected(id, reason)
  States:    ActionLoading → ActionSuccess / ActionFailure

UI pattern:
  ActionRow (sticky bottom, visible only when status=PENDING + user has permission)
    RejectButton (OutlinedButton, error color, half width)
    ApproveButton (FilledButton, success color, half width)

  RejectBottomSheet (modal):
    drag handle · "Reason for rejection" headlineMedium
    ReasonTextField (multiline, 3 rows min) · character count
    ConfirmRejectButton (FilledButton, error, full width)
```

### 6.7 List screen pattern

Used universally across all list screens:

```
FilterChips row (horizontal scroll, if applicable)
SearchBar (surfaceVariant fill, AppRadius.md)
ListView
  LoadingShimmer while state = Loading
  EmptyState if state = Empty
  ListView.separated of [Entity]Tile (AppCard, AppSpacing.sm gap) if Loaded
FAB (create action, if user has create permission)
```

### 6.8 Detail screen pattern

Used universally across all detail screens:

```
AppBar: entity name/number · optional overflow menu
SingleChildScrollView
  [Entity]HeaderCard (AppCard) — key metadata in 2-column grid
  StatusChip (large, centered, pill) — if entity has status
  SectionHeader "[Section Name]"
  [Content] (AppCard)
  ...more sections...
  ActionRow (sticky bottom, conditional on status + permission)
```

---

## 7. Screen Specifications — All 72 Screens

> For each screen: **Feel** = design intent. **Layout** = widget tree. **BLoC** = state machine. **SQLite** = local tables used.

---

### Module 0 — App Entry

---

#### Screen 0.1 — Splash Screen
**Complexity: M** | **Route:** `/` (initial, always replaced)

**Feel:** Calm, minimal, centered. Brand moment before work begins.

**Layout:**
```
Full screen, surface bg
  ├── Center (flex 1)
  │     ├── Rounded square icon (96×96, AppRadius.xl, primary bg)
  │     │     fade + scale animation 900ms easeOutBack
  │     └── App name — displayLarge, AppSpacing.md below icon
  └── Bottom pinned, AppSpacing.xxl from bottom
        ├── CircularProgressIndicator (24×24, strokeWidth 2) while loading
        │     AnimatedSwitcher → invisible once routing done
        └── Version text — bodySmall, onSurfaceVariant
        │     If DB migration needed: "MigratingDatabaseText" replaces version text
```

**Do:** Logo + name + subtle spinner only.
**Don't:** No gradients, no marketing copy, no network calls.

**BLoC:** `AppInitBLoC`
```
Events: AppStarted
States: AppInitLoading → AppInitAuthenticated / AppInitUnauthenticated / AppInitLocked

On AppStarted:
  1. Check flutter_secure_storage for existing tokens
  2. Read cached_user from SQLite — if present and TTL valid, user is known
  3. Read biometric_on flag from SQLite
  4. Decide redirect:
     - No token            → /login
     - Token + biometric   → /biometric-unlock
     - Token + PIN policy  → /lock
     - Token valid         → /dashboard
```

**SQLite tables:** `cached_user` (read id, biometric_on, last_login_at, cached_at for TTL check)

**Notes:**
- Only screen with no back navigation — always replaced, never pushed
- Keep animation under 1.5s; do not block on network calls

---

### Module 1 — Authentication & Identity

---

#### Screen 1.1 — Login
**Complexity: M** | **Route:** `/login`

**Feel:** Professional, welcoming. Single column, no clutter.

**Layout:**
```
Scaffold, surface bg, SingleChildScrollView
  padding: horizontal AppSpacing.lg, vertical AppSpacing.xl
  ├── App icon (52×52, AppRadius.md, primaryContainer bg)
  ├── AppSpacing.lg
  ├── "Welcome back" — headlineLarge
  ├── "Sign in to your account" — bodyMedium, onSurfaceVariant
  ├── AppSpacing.xxl
  ├── EmailField (prefixIcon: email)
  ├── AppSpacing.md
  ├── PasswordField (suffixIcon: visibility toggle)
  ├── "Forgot password?" — Align.right TextButton, bodySmall
  ├── AppSpacing.xl
  ├── SignInButton — FilledButton, full width, 52px height
  │     loading: replace label with CircularProgressIndicator 20×20
  │     disabled: 38% opacity
  ├── AppSpacing.md
  ├── BiometricButton — OutlinedButton, full width (hidden if biometric_on=false)
  │     icon: fingerprint + "Sign in with Biometrics"
  └── ErrorCard (AnimatedSwitcher, errorContainer bg)
        error icon + message text, AppRadius.md
```

**Don't:** No card wrapping the whole form. No "create account" link.

**BLoC:** `AuthBLoC`
```
Event: LoginSubmitted(email, password)
States: AuthInitial → AuthLoading → AuthSuccess / AuthFailure
On success → go_router redirects to /dashboard
```

**SQLite tables:** `cached_user` (read biometric_on flag on init)

---

#### Screen 1.2 — Biometric Unlock
**Complexity: S** | **Route:** `/biometric-unlock`

**Feel:** Secure, reassuring. OS lock screen energy.

**Layout:**
```
Full screen, centered column
  ├── User avatar (64×64 circle, initials fallback)
  ├── User name — titleMedium
  ├── AppSpacing.xl
  ├── Biometric icon (72×72, primary color)
  │     soft pulse animation: scale 1.0→1.08→1.0, repeat, 1.5s
  ├── "Touch sensor to unlock" — bodyMedium, onSurfaceVariant
  ├── AppSpacing.xl
  └── "Use password instead" — TextButton → /login
```

**BLoC:** `BiometricBLoC`
```
Event: BiometricRequested
States: BiometricPrompting → BiometricSuccess / BiometricFailure
```

**SQLite tables:** `cached_user` (read biometric_on, last_login_at)

---

#### Screen 1.3 — OTP / MFA Verification
**Complexity: M** | **Route:** `/mfa`

**Feel:** Focused, single-task. Nothing distracting.

**Layout:**
```
Scaffold
  ├── Back arrow (top left)
  ├── padding AppSpacing.lg
  ├── Shield icon (48×48, primaryContainer bg circle)
  ├── "Verification code" — headlineLarge
  ├── "Sent to +66 *** 1234" — bodyMedium, onSurfaceVariant
  ├── AppSpacing.xl
  ├── OtpInputRow — 6 boxes, 48×56 each, AppRadius.md
  │     active: primary border · filled: surfaceVariant bg + titleMedium digit
  │     auto-advance on input, auto-retreat on delete
  ├── AppSpacing.lg
  ├── VerifyButton — FilledButton full width (enabled when 6 digits filled)
  └── "Resend code (29s)" — TextButton, disabled during cooldown timer
```

**BLoC:** `MfaBLoC`
```
Event: OtpSubmitted(code)
States: MfaInitial → MfaLoading → MfaSuccess / MfaFailure
```

**SQLite tables:** None — OTP is memory only (ephemeral)

---

#### Screen 1.4 — Forgot Password
**Complexity: S** | **Route:** `/forgot-password`

**Feel:** One job. Enter email, receive link.

**Layout:**
```
Scaffold
  ├── Back arrow
  ├── padding AppSpacing.lg
  ├── Email icon (48×48, primaryContainer bg)
  ├── "Reset password" — headlineLarge
  ├── "We'll send a reset link to your email" — bodyMedium, onSurfaceVariant
  ├── AppSpacing.xl
  ├── EmailField
  ├── AppSpacing.md
  └── SendResetButton — FilledButton, full width
        success state: swap to green checkmark + "Check your email"
```

**BLoC:** `ForgotPasswordBLoC`
```
Event: ResetRequested(email)
States: ForgotPasswordInitial → ForgotPasswordLoading
      → ForgotPasswordSent / ForgotPasswordFailure
```

**SQLite tables:** None

---

### Module 2 — Dashboard & Home

---

#### Screen 2.1 — Dashboard Home
**Complexity: L** | **Route:** `/dashboard`

**Feel:** Control room. Data-rich, breathing room. KPIs are the hero.

**Layout:**
```
Scaffold
  ├── AppBar: app logo (left) · search icon · NotificationBadge (right)
  ├── SyncStatusBanner (slide-in below AppBar, warningContainer bg)
  │     only visible on SyncPending or SyncFailed state
  └── SingleChildScrollView
        ├── GlobalSearchBar (surfaceVariant fill, AppRadius.md, search icon)
        ├── AppSpacing.md
        ├── SectionHeader "Overview"
        ├── KpiCardGrid — 2-column GridView, shrinkWrap
        │     Each KpiCard (AppCard):
        │       module icon circle (24×24, colored by module)
        │       KPI label — bodySmall, onSurfaceVariant
        │       Value — headlineMedium
        │       Trend row — arrow icon + % change (success/error color)
        │       Sparkline — fl_chart LineChart, 40px height, no axes
        ├── AppSpacing.md
        ├── SectionHeader "Quick Access"
        └── ModuleShortcutGrid — 3-column, permission-filtered
              Each tile: icon (40×40 circle) + module name (bodySmall)
  BottomNavigationBar (mobile) / NavigationRail (tablet)
```

**BLoC:**
- `KpiBLoC` — Event: `KpiRefreshRequested`; streams from `KpiRepository` (WebSocket + SQLite fallback)
- `SyncStatusBLoC` — listens to sync engine; emits `SyncIdle / SyncPending / SyncFailed`
- `NotificationBadgeBLoC` — reads unread count from SQLite

**SQLite tables:** `cached_kpi`, `cached_dashboard_layout`, `cached_notifications` (unread count)

---

#### Screen 2.2 — Global Search
**Complexity: M** | **Route:** `/search`

**Feel:** Fast, instant results as you type.

**Layout:**
```
Scaffold (no AppBar — search IS the top element)
  ├── padding AppSpacing.md
  ├── SearchRow: back arrow + SearchTextField (autofocus) + clear X
  ├── Divider
  ├── RecentSearchesRow — horizontal scroll chips (bodySmall, surfaceVariant)
  └── SearchResultList
        grouped by module with SectionHeader per group
        Each SearchResultTile (ListTile):
          leading: module color icon circle (40×40)
          title: titleMedium
          subtitle: bodySmall, onSurfaceVariant
          trailing: chevron right
        EmptyState if no results: magnifier illustration + "No results found"
```

**BLoC:** `GlobalSearchBLoC`
```
Event: SearchQueryChanged(query)
States: SearchInitial → SearchLoading → SearchResults(results) / SearchEmpty
```

**SQLite tables:** None (search hits remote API; results not cached)

---

#### Screen 2.3 — Notification Center
**Complexity: M** | **Route:** `/notifications`

**Feel:** Inbox. Clear read/unread hierarchy.

**Layout:**
```
Scaffold
  ├── AppBar: "Notifications" · "Mark all read" TextButton trailing
  └── Body
        EmptyState (bell illustration) if empty
        ListView of NotificationTile (AppCard, AppSpacing.sm gap):
          ├── Leading: module icon circle (40×40, color by notification type)
          ├── Unread indicator: 3px primary left border + primaryContainer bg tint
          ├── Title — titleMedium (w600 if unread, w400 if read)
          ├── Body — bodySmall, onSurfaceVariant, max 2 lines
          └── Timestamp — bodySmall, onSurfaceVariant, right-aligned
```

**BLoC:** `NotificationBLoC`
```
Events: NotificationsLoaded, NotificationMarkedRead(id), AllNotificationsMarkedRead
States: NotificationInitial → NotificationLoaded(list) / NotificationEmpty
```

**SQLite tables:** `cached_notifications` (read, update is_read)

---

### Module 3 — Finance & Accounting

---

#### Screen 3.1 — Chart of Accounts
**Complexity: M** | **Route:** `/finance/accounts`

**Feel:** Tree navigator. Hierarchy is the structure.

**Layout:**
```
Scaffold
  ├── AppBar: "Chart of Accounts"
  ├── AccountSearchBar — filters tree inline
  └── ListView (tree structure, indented per level)
        Each AccountNode:
          ├── Expand/collapse chevron (if has children)
          ├── AccountTypeBadge — colored chip (Asset/Liability/Equity/Revenue/Expense)
          ├── Account name — titleMedium
          ├── Account code — bodySmall, onSurfaceVariant
          └── Balance — titleMedium, right-aligned
        Parent nodes: surfaceVariant bg row
        Child nodes: white bg, indented AppSpacing.lg per level
        Tap leaf node → Account Detail
```

**BLoC:** `ChartOfAccountsBLoC`
```
Events: AccountsLoaded, AccountNodeExpanded(id)
States: AccountsLoading → AccountsLoaded(tree) / AccountsFailure
```

**SQLite tables:** `cached_accounts` (id, parent_id, name, type, cached_at)

---

#### Screen 3.2 — Account Detail
**Complexity: M** | **Route:** `/finance/accounts/:id`

**Feel:** Ledger view. Header then scrollable transaction history.

**Layout:**
```
Scaffold
  ├── AppBar: account name · account code (subtitle)
  └── SingleChildScrollView
        ├── AccountHeaderCard (AppCard)
        │     2-column grid: Type · Balance · Code · Status
        ├── AppSpacing.md
        ├── DateRangeFilterRow — "From" + "To" date chips, inline
        ├── AppSpacing.md
        ├── SectionHeader "Transactions"
        └── ListView of TransactionTile (AppCard, AppSpacing.xs gap)
              Date (bodySmall) · Reference (bodyMedium) · Debit · Credit
              Debit: error color · Credit: success color
              Running balance (right, bodySmall, onSurfaceVariant)
```

**BLoC:** `AccountDetailBLoC`
```
Events: AccountDetailLoaded(id), DateRangeChanged(from, to)
States: AccountDetailLoading → AccountDetailLoaded / AccountDetailFailure
```

**SQLite tables:** `cached_accounts`, `cached_transactions`

---

#### Screen 3.3 — Invoice List
**Complexity: M** | **Route:** `/finance/invoices`

**Feel:** Scannable. Status chips carry the meaning at a glance.

**Layout:**
```
Scaffold
  ├── AppBar: "Invoices" · sort icon
  ├── FilterChips row: All · Draft · Pending · Approved · Rejected
  ├── InvoiceSearchBar
  └── ListView of InvoiceTile (AppCard, AppSpacing.sm gap)
        ├── Top row: invoice number (titleMedium) · StatusChip (right)
        ├── Middle: vendor/customer name (bodyMedium)
        └── Bottom: date (bodySmall, onSurfaceVariant) · amount (titleMedium, right)
  FAB: + Create Invoice → /finance/invoices/new
```

**BLoC:** `InvoiceListBLoC`
```
Events: InvoicesLoaded, InvoiceFilterChanged(status), InvoiceSortChanged(field)
States: InvoiceListLoading → InvoiceListLoaded(list) / InvoiceListFailure
```

**SQLite tables:** `cached_invoices`

---

#### Screen 3.4 — Invoice Detail + Approve/Reject
**Complexity: L** | **Route:** `/finance/invoices/:id`

**Feel:** Document view. Header → status → items → actions.

**Layout:**
```
Scaffold
  ├── AppBar: invoice number · overflow menu (PDF, share)
  └── SingleChildScrollView
        ├── InvoiceHeaderCard (AppCard)
        │     2-column grid: Invoice# · Date · Due Date · Vendor · Amount
        ├── AppSpacing.md
        ├── StatusChip — large, centered, pill
        ├── AppSpacing.md
        ├── SectionHeader "Line Items"
        ├── LineItemsTable (AppCard)
        │     rows: description · qty · unit price · total
        │     footer: subtotal · tax · TOTAL (titleMedium bold)
        ├── AppSpacing.lg
        └── ActionRow (sticky bottom, PENDING_APPROVAL + has permission only)
              RejectButton (OutlinedButton, error, half width)
              ApproveButton (FilledButton, success, half width)

RejectBottomSheet (modal, AppRadius.xl top):
  drag handle · "Reason for rejection" headlineMedium
  ReasonTextField (multiline, 3 rows min)
  character count (bodySmall, right)
  ConfirmRejectButton (FilledButton, error, full width)
```

**BLoC:**
- `InvoiceDetailBLoC` — Event: `InvoiceDetailLoaded(id)`
- `InvoiceActionBLoC` — Events: `InvoiceApproved(id)` / `InvoiceRejected(id, reason)`

**SQLite tables:** `cached_invoices` (status, approved_by, rejected_reason, actioned_at)

**Permission:** `ApproveButton` + `RejectButton` wrapped in `PermissionGuard(scope: 'finance.approve')`

---

#### Screen 3.5 — Create / Edit Invoice
**Complexity: L** | **Route:** `/finance/invoices/new` · `/finance/invoices/:id/edit`

**Feel:** Document builder. Dynamic line items, live totals.

**Layout:**
```
Scaffold
  ├── AppBar: "New Invoice" / "Edit Invoice" · "Save Draft" TextButton
  └── SingleChildScrollView, padding AppSpacing.md
        ├── VendorCustomerPickerCard (AppCard)
        │     search icon + selected name / "Select vendor or customer"
        ├── AppSpacing.md
        ├── DatesCard (AppCard, 2-column row)
        │     Invoice date picker · Due date picker
        ├── AppSpacing.md
        ├── SectionHeader "Line Items" · "+ Add Item" trailing
        ├── LineItemsList
        │     Each LineItemCard (AppCard):
        │       Description field (full width)
        │       Qty · Unit Price · Tax % (3-column row)
        │       Line total (bodyMedium, right, primary color)
        │       Remove icon (error color, top-right)
        ├── AppSpacing.md
        ├── TotalSummaryCard (AppCard, right-aligned)
        │     Subtotal · Tax · TOTAL (titleMedium bold)
        └── SubmitForApprovalButton — FilledButton, full width
```

**BLoC:** `InvoiceFormBLoC`
```
Events: FieldChanged(field, value), LineItemAdded, LineItemRemoved(index),
        InvoiceSaved (draft), InvoiceSubmitted
States: InvoiceFormInitial → InvoiceFormValid / InvoiceFormInvalid
      → InvoiceFormSaving → InvoiceFormSuccess
```

**SQLite tables:** `cached_invoices` (upsert on save draft (SQLite))

---

#### Screen 3.6 — Journal Entry List
**Complexity: S** | **Route:** `/finance/journal`

**Feel:** Accounting log. Date + reference + balanced amounts.

**Layout:**
```
Scaffold
  ├── AppBar: "Journal Entries"
  ├── DateRangeFilterRow — from/to date chips
  └── ListView of JournalEntryTile (AppCard, AppSpacing.sm gap)
        ├── Top row: reference (titleMedium) · date (bodySmall, right)
        ├── Description — bodyMedium, onSurfaceVariant
        └── Bottom row: Debit total (error color) · Credit total (success color)
        Tap → Journal Entry Detail bottom sheet
```

**BLoC:** `JournalBLoC`
```
Events: JournalEntriesLoaded, DateRangeChanged
States: JournalLoading → JournalLoaded(list) / JournalFailure
```

**SQLite tables:** `cached_journal_entries`

---

#### Screen 3.7 — Trial Balance Report
**Complexity: M** | **Route:** `/finance/trial-balance`

**Feel:** Financial statement. Paginated table, export action.

**Layout:**
```
Scaffold
  ├── AppBar: "Trial Balance" · export CSV icon
  ├── PeriodSelector — month + year picker row (AppCard)
  └── SingleChildScrollView
        ├── SummaryRow (AppCard, 2-column)
        │     Total Debits (error color) · Total Credits (success color)
        └── TrialBalanceTable (AppCard)
              Header row: Account · Debit · Credit (surfaceVariant bg, sticky)
              Each data row: account name (bodyMedium) · debit · credit
              alternating row tint (surfaceVariant every other row)
```

**BLoC:** `TrialBalanceBLoC`
```
Events: TrialBalanceLoaded(period)
States: TrialBalanceLoading → TrialBalanceLoaded(rows) / TrialBalanceFailure
```

**SQLite tables:** `cached_trial_balance`

---

### Module 4 — Procurement

---

#### Screen 4.1 — Purchase Request List
**Complexity: M** | **Route:** `/procurement/requests`

**Feel:** Approval queue. Status is the priority signal.

**Layout:**
```
Scaffold
  ├── AppBar: "Purchase Requests"
  ├── FilterChips: All · Draft · Pending · Approved · Rejected
  └── ListView of PRTile (AppCard, AppSpacing.sm gap)
        ├── Top row: PR number (titleMedium) · StatusChip (right)
        ├── Middle: requester name + department (bodyMedium)
        └── Bottom: date (bodySmall) · estimated amount (titleMedium, right)
  FAB: + New Request → /procurement/requests/new
```

**BLoC:** `PurchaseRequestListBLoC`
```
Events: PRListLoaded, PRFilterChanged(status)
States: PRListLoading → PRListLoaded(list) / PRListFailure
```

**SQLite tables:** `cached_purchase_requests`

---

#### Screen 4.2 — Create Purchase Request
**Complexity: L** | **Route:** `/procurement/requests/new`

**Feel:** Structured request form. Line items + approver selection.

**Layout:**
```
Scaffold
  ├── AppBar: "New Purchase Request" · "Save Draft" TextButton
  └── SingleChildScrollView, padding AppSpacing.md
        ├── CostCenterCard (AppCard row — building icon + dropdown)
        ├── AppSpacing.md
        ├── ApproverPickerCard (AppCard row — person icon + searchable dropdown)
        ├── AppSpacing.md
        ├── SectionHeader "Items" · "+ Add Item" trailing
        ├── LineItemsList
        │     Each LineItemCard (AppCard):
        │       Description · Qty · Estimated cost (3 fields)
        │       Remove icon (error, top-right)
        ├── AppSpacing.md
        ├── AttachmentRow (AppCard) — paperclip icon + "Attach file" + file list
        └── SubmitButton — FilledButton, full width
```

**BLoC:** `PRFormBLoC`
```
Events: FieldChanged, LineItemAdded, LineItemRemoved, PRSubmitted
States: PRFormInitial → PRFormValid / PRFormInvalid → PRFormSuccess
```

**SQLite tables:** `cached_purchase_requests` (upsert draft)

---

#### Screen 4.3 — Purchase Request Detail + Approval
**Complexity: L** | **Route:** `/procurement/requests/:id`

**Feel:** Document + decision. Timeline shows approval history.

**Layout:**
```
Scaffold
  ├── AppBar: PR number · overflow menu
  └── SingleChildScrollView
        ├── PRHeaderCard (AppCard)
        │     2-column grid: PR# · Date · Requester · Dept · Cost Center
        ├── AppSpacing.md
        ├── StatusChip — large, centered
        ├── AppSpacing.md
        ├── SectionHeader "Requested Items"
        ├── LineItemsTable (AppCard)
        ├── AppSpacing.md
        ├── SectionHeader "Approval History"
        ├── ApprovalTimeline (AppCard)
        │     each step: avatar · name · action chip · date · connector line
        └── ActionRow (sticky bottom, PENDING + has permission only)
              RejectButton (OutlinedButton, error, half width)
              ApproveButton (FilledButton, success, half width)
```

**BLoC:** `PRDetailBLoC`, `PRActionBLoC` (same pattern as Invoice 3.4)

**SQLite tables:** `cached_purchase_requests` (status, approved_by, actioned_at)

**Permission:** `PermissionGuard(scope: 'procurement.approve')`

---

#### Screen 4.4 — Purchase Order List
**Complexity: M** | **Route:** `/procurement/orders`

**Feel:** Order tracker. Same scannable pattern as PRs and invoices.

**Layout:**
```
Scaffold
  ├── AppBar: "Purchase Orders"
  ├── FilterChips: All · Draft · Confirmed · Received · Cancelled
  └── ListView of POTile (AppCard, AppSpacing.sm gap)
        ├── Top row: PO number (titleMedium) · StatusChip (right)
        ├── Middle: vendor name (bodyMedium)
        └── Bottom: order date (bodySmall) · total amount (titleMedium, right)
  FAB: + New Order
```

**BLoC:** `PurchaseOrderListBLoC`

**SQLite tables:** `cached_purchase_orders`

---

#### Screen 4.5 — Purchase Order Detail
**Complexity: M** | **Route:** `/procurement/orders/:id`

**Feel:** Order document. Header + line items + goods receipt trigger.

**Layout:**
```
Scaffold
  ├── AppBar: PO number · overflow menu
  └── SingleChildScrollView
        ├── POHeaderCard (AppCard)
        │     PO# · Vendor · Order date · Expected delivery · Total
        ├── AppSpacing.md
        ├── StatusChip — large, centered
        ├── AppSpacing.md
        ├── SectionHeader "Line Items"
        ├── LineItemsTable (AppCard)
        │     Item · Qty ordered · Qty received · Unit price · Total
        │     Received qty: success color if full, warning if partial
        └── GoodsReceiptButton — OutlinedButton, full width (if status=Confirmed)
              "Record Goods Receipt" + truck icon
```

**BLoC:** `PODetailBLoC`

**SQLite tables:** `cached_purchase_orders`

---

#### Screen 4.6 — Goods Receipt Entry
**Complexity: M** | **Route:** `/procurement/orders/:id/receipt`

**Feel:** Receiving dock form. Large tap targets, confirm quantities per line.

**Layout:**
```
Scaffold
  ├── AppBar: "Goods Receipt" · PO number subtitle
  └── SingleChildScrollView, padding AppSpacing.md
        ├── VendorInfoCard (AppCard, infoContainer bg)
        │     Vendor name · Expected delivery date
        ├── AppSpacing.md
        ├── ReceiptDateCard (AppCard row — calendar icon + date picker)
        ├── AppSpacing.md
        ├── SectionHeader "Received Items"
        ├── ReceivedQtyList
        │     Each ReceivedItemRow (AppCard):
        │       Item name (titleMedium)
        │       Ordered qty (bodySmall, onSurfaceVariant)
        │       ActualQtyInput (48×48 number field, right-aligned)
        │       Variance badge: success=match · warning=over · error=under
        └── ConfirmReceiptButton — FilledButton, success color, full width
```

**BLoC:** `GoodsReceiptBLoC`
```
Event: GoodsReceiptSubmitted(orderId, lines)
States: GoodsReceiptLoading → GoodsReceiptSuccess / GoodsReceiptFailure
```

**SQLite tables:** `cached_purchase_orders` (update received quantities)

---

#### Screen 4.7 — Vendor List
**Complexity: S** | **Route:** `/procurement/vendors`

**Feel:** Supplier directory. Rating stars give instant quality signal.

**Layout:**
```
Scaffold
  ├── AppBar: "Vendors"
  ├── VendorSearchBar
  └── ListView of VendorTile (AppCard, AppSpacing.sm gap)
        ├── Leading: vendor initial circle (40×40, primary bg)
        ├── Title: vendor name — titleMedium
        ├── Subtitle: category chip + payment terms (bodySmall)
        └── Trailing: star rating row (3–5 stars, warning color fill)
  FAB: + Add Vendor
```

**BLoC:** `VendorListBLoC`

**SQLite tables:** `cached_vendors`

---

#### Screen 4.8 — Vendor Detail
**Complexity: M** | **Route:** `/procurement/vendors/:id`

**Feel:** Supplier profile + performance scorecard.

**Layout:**
```
Scaffold
  ├── AppBar: vendor name · edit icon
  └── SingleChildScrollView
        ├── VendorProfileCard (AppCard)
        │     Name · Category · Contact · Email · Payment Terms · Bank info
        ├── AppSpacing.md
        ├── SectionHeader "Performance"
        ├── ScorecardCard (AppCard, 2-column grid)
        │     On-time delivery % (success/warning/error by value)
        │     Quality rating (star row)
        │     Total spend · Active POs
        ├── AppSpacing.md
        ├── SectionHeader "Recent Orders"
        └── ListView of POHistoryTile (AppCard, AppSpacing.xs gap)
              PO# · date · amount · StatusChip
```

**BLoC:** `VendorDetailBLoC`

**SQLite tables:** `cached_vendors`, `cached_purchase_orders`

---

### Module 5 — Inventory & Warehouse

---

#### Screen 5.1 — Item Catalog
**Complexity: M** | **Route:** `/inventory/items`

**Feel:** Warehouse inventory. Low-stock items demand attention.

**Layout:**
```
Scaffold
  ├── AppBar: "Inventory"
  ├── SearchBar + WarehouseFilterDropdown (inline row)
  └── ListView of ItemTile (AppCard, AppSpacing.sm gap)
        ├── Leading: item image or SKU initials circle (40×40)
        ├── Title: item name — titleMedium
        ├── SKU — bodySmall, onSurfaceVariant
        ├── Stock qty badge:
        │     above min: successContainer bg
        │     near min (≤20%): warningContainer bg
        │     below min: errorContainer bg + "LOW" label
        └── Trailing: unit (bodySmall)
  FAB: barcode scan shortcut → Screen 5.3
```

**BLoC:** `ItemCatalogBLoC`
```
Events: ItemsLoaded, WarehouseFilterChanged(warehouseId), SearchQueryChanged
States: ItemCatalogLoading → ItemCatalogLoaded(items) / ItemCatalogFailure
```

**SQLite tables:** `cached_items` (id, sku, name, unit, warehouse_id, stock_qty, min_stock, cached_at)

---

#### Screen 5.2 — Item Detail
**Complexity: M** | **Route:** `/inventory/items/:id`

**Feel:** Stock card. Quantity indicator + movement history.

**Layout:**
```
Scaffold
  ├── AppBar: item name · edit icon
  └── SingleChildScrollView
        ├── ItemHeaderCard (AppCard)
        │     SKU · Category · Unit · Warehouse · Location
        ├── AppSpacing.md
        ├── StockLevelCard (AppCard)
        │     ├── Current qty — headlineLarge, color by level
        │     ├── Min stock level — bodySmall, onSurfaceVariant
        │     └── StockProgressBar (AppRadius.full, colored fill)
        │           below min: error · near min: warning · above: success
        ├── AppSpacing.md
        ├── SectionHeader "Movement History"
        └── ListView of MovementTile (AppCard, AppSpacing.xs gap)
              Date · Type chip (Issue/Receipt/Transfer) · Qty · Reference
              Issue qty: error color · Receipt qty: success color
```

**BLoC:** `ItemDetailBLoC`

**SQLite tables:** `cached_items`, `cached_stock_movements`

---

#### Screen 5.3 — Barcode / QR Scanner
**Complexity: L** | **Route:** `/inventory/scan`

**Feel:** Utility tool. Full camera. Instant result feedback.

**Layout:**
```
Full screen (no AppBar — camera fills screen)
  ├── Camera preview (full screen, mobile_scanner package)
  ├── ScanOverlayPainter (CustomPainter)
  │     dark dim outside scan zone
  │     240×240 frame with white corner brackets
  │     animated scan line (top→bottom, 1.5s loop, primary color)
  │     "Align barcode within frame" bodySmall white below frame
  ├── CloseButton — top-left, white icon on 40% black circle
  └── ResultBottomSheet (slides up 280px on successful scan)
        drag handle
        item name — titleMedium
        SKU — bodySmall, onSurfaceVariant
        StockBadge — qty + color by level
        ActionButtonRow (3 equal OutlinedButtons, icons above labels):
          Goods Issue · Goods Receipt · Transfer
```

**BLoC:** `ScanBLoC`
```
Event: BarcodeDetected(code)
States: ScanIdle → ScanDetected(item) / ScanNotFound / ScanFailure
```

**SQLite tables:** `cached_items` (lookup by SKU/barcode)

---

#### Screen 5.4 — Goods Issue / Receipt Flow
**Complexity: M** | **Route:** `/inventory/transaction`

**Feel:** Step-by-step transaction. Large tap targets for warehouse use.

**Do:** Large inputs — warehouse workers may type with gloves.

**Layout:**
```
Scaffold
  ├── AppBar: "Goods Issue" or "Goods Receipt" · close X
  └── SingleChildScrollView, padding AppSpacing.md
        ├── TypeTag — pill chip (errorContainer=Issue, successContainer=Receipt)
        ├── AppSpacing.md
        ├── SectionHeader "Item"
        ├── ItemScanOrSearchCard (AppCard)
        │     scan icon button (left) · search text field (right)
        │     selected item shows name + SKU below field
        ├── AppSpacing.md
        ├── SectionHeader "Details"
        ├── DetailsCard (AppCard)
        │     QtyInput — large number input (titleMedium, 56px height)
        │     Divider
        │     ReferenceField — "PO# or SO#"
        │     WarehouseLocationPicker — dropdown row
        └── ConfirmButton — FilledButton full width, 52px
              Issue: error color · Receipt: success color
```

**BLoC:** `StockTransactionBLoC`
```
Event: TransactionSubmitted(type, itemId, qty, reference)
Online:  POST to API
Offline: enqueue to sync_queue
```

**SQLite tables:** `cached_items` (optimistic qty update), `sync_queue`

---

#### Screen 5.5 — Stock Transfer
**Complexity: M** | **Route:** `/inventory/transfer`

**Feel:** Two-sided form. Directional flow is the visual anchor.

**Layout:**
```
Scaffold
  ├── AppBar: "Stock Transfer"
  └── SingleChildScrollView, padding AppSpacing.md
        ├── TransferDirectionCard (AppCard)
        │     FromWarehousePicker row (warehouse icon + dropdown)
        │     arrow icon center (primary, pointing down)
        │     ToWarehousePicker row (warehouse icon + dropdown)
        ├── AppSpacing.md
        ├── SectionHeader "Items" · "+ Add Item" trailing
        ├── ItemTransferList
        │     Each ItemTransferRow (AppCard):
        │       item name (titleMedium)
        │       QtyInput (inline, 48px wide)
        │       remove icon (error color, right)
        └── ConfirmTransferButton — FilledButton, full width
```

**BLoC:** `StockTransferBLoC`

**SQLite tables:** `cached_items`, `sync_queue`

---

#### Screen 5.6 — Inventory Count / Cycle Count
**Complexity: L** | **Route:** `/inventory/count`

**Feel:** Counting mode. Variances highlighted immediately as user types.

**Layout:**
```
Scaffold
  ├── AppBar: "Cycle Count" · warehouse · date
  ├── ProgressRow — "12 / 48 counted" LinearProgressIndicator (primary)
  └── ListView of CountItemRow (AppCard, AppSpacing.sm gap)
        ├── SKU (bodySmall, onSurfaceVariant) + name (titleMedium)
        ├── Expected qty badge (surfaceVariant)
        ├── ActualQtyInput (48×48, outlined, numeric keyboard)
        └── VarianceFeedback (shown after input):
              match   → green checkmark
              surplus → warning icon + "+N surplus"
              missing → error icon + "−N missing"
  Bottom sticky:
    "X items have variances" — error color bodyMedium (if any)
    SubmitCountButton — FilledButton, full width
```

**BLoC:** `InventoryCountBLoC`
```
Events: CountStarted, CountItemUpdated(itemId, actualQty), CountSubmitted
States: CountInProgress(items) → CountSubmitting → CountSuccess / CountFailure
```

**SQLite tables:** `cached_items`, `cached_count_sessions`

---

### Module 6 — Sales & CRM

---

#### Screen 6.1 — Customer List
**Complexity: S** | **Route:** `/sales/customers`

**Feel:** CRM directory. Faces first, fast to call.

**Layout:**
```
Scaffold
  ├── AppBar: "Customers"
  ├── SearchBar
  └── ListView of CustomerTile (AppCard, AppSpacing.sm gap)
        ├── Leading: avatar circle 40×40 (photo or initials)
        ├── Title: customer name — titleMedium
        ├── Subtitle: last order date — bodySmall, onSurfaceVariant
        └── Trailing: phone icon button (direct call)
  FAB: + Add Customer
```

**BLoC:** `CustomerListBLoC`

**SQLite tables:** `cached_customers`

---

#### Screen 6.2 — Customer Detail
**Complexity: M** | **Route:** `/sales/customers/:id`

**Feel:** Full profile. Info → contacts → activity history.

**Layout:**
```
Scaffold
  ├── AppBar: customer name · edit icon
  └── SingleChildScrollView
        ├── CustomerProfileCard (AppCard)
        │     avatar (56×56) + name (headlineMedium) + category chip
        │     Divider
        │     2-column grid: Phone · Email · Address · Payment Terms · Credit Limit
        ├── AppSpacing.md
        ├── SectionHeader "Contacts" · "+ Add" trailing
        ├── ContactsList (AppCard)
        │     Each ContactRow: avatar 32×32 · name · role · call+email icons
        ├── AppSpacing.md
        ├── SectionHeader "Activity"
        └── ActivityTimeline
              each item (left border line + dot):
                icon (order/call/note, colored by type)
                title — titleMedium
                date — bodySmall, onSurfaceVariant
  FAB: + New Quotation
```

**BLoC:** `CustomerDetailBLoC`

**SQLite tables:** `cached_customers`, `cached_contacts`, `cached_activities`

---

#### Screen 6.3 — Sales Quotation List
**Complexity: M** | **Route:** `/sales/quotations`

**Feel:** Same scannable pattern as invoices.

**Layout:**
```
Scaffold
  ├── AppBar: "Quotations"
  ├── FilterChips: All · Draft · Sent · Accepted · Rejected
  └── ListView of QuotationTile (AppCard, AppSpacing.sm gap)
        ├── Top row: quotation number (titleMedium) · StatusChip
        ├── Middle: customer name (bodyMedium)
        └── Bottom: validity date (bodySmall) · total (titleMedium, right)
  FAB: + New Quotation
```

**BLoC:** `QuotationListBLoC`

**SQLite tables:** `cached_quotations`

---

#### Screen 6.4 — Create / Edit Quotation
**Complexity: L** | **Route:** `/sales/quotations/new` · `/sales/quotations/:id/edit`

**Feel:** Proposal builder. Live total as items are added.

**Layout:**
```
Scaffold
  ├── AppBar: "New Quotation" · "Save Draft" TextButton
  └── SingleChildScrollView, padding AppSpacing.md
        ├── CustomerPickerCard (AppCard row)
        ├── ValidityDateCard (AppCard row — calendar icon + date)
        ├── AppSpacing.md
        ├── SectionHeader "Line Items" · "+ Add" trailing
        ├── LineItemsList
        │     Each LineItemCard (AppCard):
        │       Product name field
        │       Qty · Unit price · Discount% · Tax% (4-column row)
        │       Line subtotal (bodyMedium right, primary color)
        │       remove icon (error, top-right)
        ├── TotalSummaryCard (AppCard, right-aligned column)
        │     Subtotal · Discount · Tax · TOTAL (titleMedium bold)
        └── SendToCustomerButton — FilledButton, full width
```

**BLoC:** `QuotationFormBLoC`

**SQLite tables:** `cached_quotations` (upsert draft)

---

#### Screen 6.5 — Sales Order Detail
**Complexity: M** | **Route:** `/sales/orders/:id`

**Feel:** Fulfillment tracker. Stepper shows where the order is.

**Layout:**
```
Scaffold
  ├── AppBar: SO number · overflow menu
  └── SingleChildScrollView
        ├── OrderHeaderCard (AppCard)
        │     SO# · Customer · Order date · Delivery date
        ├── AppSpacing.md
        ├── FulfillmentStepper (AppCard)
        │     Confirmed → Picking → Shipped → Delivered
        │     active: primary circle · done: success checkmark · pending: surfaceVariant
        ├── AppSpacing.md
        ├── SectionHeader "Line Items"
        └── LineItemsTable (AppCard)
              Product · Qty ordered · Qty shipped · Status
              Shipped=success · partial=warning · pending=surfaceVariant
```

**BLoC:** `SalesOrderDetailBLoC`

**SQLite tables:** `cached_sales_orders`

---

#### Screen 6.6 — Sales Analytics
**Complexity: L** | **Route:** `/sales/analytics`

**Feel:** Executive dashboard. Period selector controls all charts.

**Layout:**
```
Scaffold
  ├── AppBar: "Sales Analytics"
  ├── PeriodToggle — segmented: Week · Month · Quarter · Year
  └── SingleChildScrollView
        ├── RevenueCard (AppCard)
        │     RevenueLineChart (fl_chart, 200px, primary color line)
        ├── AppSpacing.md
        ├── SectionHeader "Top Customers"
        ├── TopCustomersTable (AppCard)
        │     rank · name · total spend (bodyMedium)
        ├── AppSpacing.md
        ├── SectionHeader "Sales Leaderboard"
        └── SalesRepLeaderboard (AppCard)
              ranked list: avatar (32×32) + name + total sales (right, primary)
```

**BLoC:** `SalesAnalyticsBLoC`
```
Event: AnalyticsLoaded(period)
States: AnalyticsLoading → AnalyticsLoaded(data) / AnalyticsFailure
```

**SQLite tables:** `cached_sales_analytics` (TTL-based, refreshed per period change)

---

#### Screen 6.7 — Create Customer
**Complexity: M** | **Route:** `/sales/customers/new`

**Feel:** Onboarding form. Progressive sections — contact first, then commercial terms.

**Layout:**
```
Scaffold
  ├── AppBar: "New Customer" · "Save Draft" TextButton (top-right)
  └── SingleChildScrollView, padding AppSpacing.md
        ├── SectionHeader "Identity"
        ├── IdentityCard (AppCard)
        │     AvatarPickerRow — circle 72×72 (camera icon overlay, tap to pick photo)
        │     CustomerNameField — "Company or person name" (full width)
        │     CustomerTypeRow — segmented: Company · Individual
        ├── AppSpacing.md
        ├── SectionHeader "Contact"
        ├── ContactCard (AppCard)
        │     PhoneField (prefixIcon: phone)
        │     EmailField (prefixIcon: email)
        │     AddressField (multiline, 2 rows, prefixIcon: location)
        ├── AppSpacing.md
        ├── SectionHeader "Commercial Terms"
        ├── TermsCard (AppCard)
        │     PaymentTermsPicker — dropdown (Net 7 / Net 15 / Net 30 / Net 60 / COD)
        │     CreditLimitField — numeric, prefixText "฿"
        │     CurrencyPicker — dropdown (THB / USD / EUR)
        │     TaxIdField (optional)
        ├── AppSpacing.md
        ├── SectionHeader "Contacts (optional)"
        ├── ContactsCard (AppCard)
        │     "+ Add Contact" OutlinedButton, dashed border
        │     Each ContactRow: name · role · phone · email · remove icon
        └── SaveButton — FilledButton, full width, 52px
              "Create Customer"
```

**Do:** Avatar picker opens image_picker — allow camera or gallery.
**Don't:** Don't require all fields — only name is mandatory.

**BLoC:** `CustomerFormBLoC`
```
Events: FieldChanged(field, value), ContactAdded, ContactRemoved(index),
        AvatarPicked(file), CustomerSaved
States: CustomerFormInitial → CustomerFormValid / CustomerFormInvalid
      → CustomerFormSaving → CustomerFormSuccess / CustomerFormFailure
```

**SQLite tables:** `cached_customers` (upsert on save — SQLite)

**Post-save:** Navigate to Customer Detail (6.2) for newly created customer.

---

#### Screen 6.8 — Edit Customer
**Complexity: M** | **Route:** `/sales/customers/:id/edit`

**Feel:** Identical to Create (6.7) but pre-filled. Clear "Update" intent.

**Layout:** Same as Screen 6.7 with these differences:
```
AppBar: "Edit Customer" · "Discard" TextButton
AvatarPickerRow: shows existing photo if present
All fields pre-filled from CustomerDetailBLoC state
SaveButton label: "Update Customer"
```

**BLoC:** `CustomerFormBLoC` (same as 6.7, initialized with existing data)
```
Additional Event: CustomerLoaded(id) — pre-fills form fields
```

**SQLite tables:** `cached_customers` (upsert on update)

**Notes:**
- Discard shows a confirmation dialog if any field was changed
- Successful update navigates back to Customer Detail and shows a success snackbar

---

### Module 7 — Human Resources

---

#### Screen 7.1 — Employee Directory
**Complexity: S** | **Route:** `/hr/employees`

**Feel:** Company phonebook. Avatar + name + role at a glance.

**Layout:**
```
Scaffold
  ├── AppBar: "Employees"
  ├── EmployeeSearchBar
  ├── DepartmentFilterDropdown
  └── ListView of EmployeeTile (AppCard, AppSpacing.sm gap)
        ├── Leading: avatar circle 40×40 (photo or initials)
        ├── Title: name — titleMedium
        └── Subtitle: title + department — bodySmall, onSurfaceVariant
```

**BLoC:** `EmployeeListBLoC`

**SQLite tables:** `cached_employees`

---

#### Screen 7.2 — Employee Profile
**Complexity: M** | **Route:** `/hr/employees/:id`

**Feel:** HR record. Avatar header, tabbed detail sections.

**Layout:**
```
Scaffold
  ├── AppBar: employee name · overflow menu
  └── SingleChildScrollView
        ├── EmployeeAvatarHeader (AppCard, primaryContainer bg)
        │     photo (72×72 circle) · name (headlineMedium)
        │     title (bodyMedium) · department chip
        │     email + phone row (bodySmall, onSurfaceVariant)
        ├── AppSpacing.md
        ├── TabBar: Personal · Employment · Documents
        └── TabBarView
              Personal: birthdate, address, emergency contact
              Employment: start date, contract type, manager, salary grade
              Documents: list of DocumentTile (name + download icon)
        OrgChartButton — TextButton → /hr/orgchart?focusId=:id
```

**BLoC:** `EmployeeDetailBLoC`

**SQLite tables:** `cached_employees`

---

#### Screen 7.3 — Org Chart
**Complexity: L** | **Route:** `/hr/orgchart`

**Feel:** Company hierarchy. Zoomable, pannable tree.

**Layout:**
```
Scaffold
  ├── AppBar: "Org Chart" · search icon
  └── InteractiveViewer (zoomable, pannable)
        OrgChartTreeWidget (CustomPainter)
          connector lines between nodes (grey, 0.5px)
          Each OrgChartNode:
            avatar (40×40 circle)
            name — titleMedium
            title — bodySmall, onSurfaceVariant
          FocusEmployeeHighlight: primary border on focused node
```

**BLoC:** `OrgChartBLoC`
```
Events: OrgChartLoaded, NodeFocused(id)
States: OrgChartLoading → OrgChartLoaded(tree) / OrgChartFailure
```

**SQLite tables:** `cached_employees` (id, name, title, manager_id, avatar_url)

---

#### Screen 7.4 — Leave Request Form
**Complexity: M** | **Route:** `/hr/leave/new`

**Feel:** Structured request. Balance shown inline to prevent over-requesting.

**Layout:**
```
Scaffold
  ├── AppBar: "New Leave Request"
  └── SingleChildScrollView, padding AppSpacing.md
        ├── LeaveTypeCard (AppCard)
        │     LeaveTypePicker — Annual / Sick / Unpaid / Maternity / etc.
        ├── AppSpacing.md
        ├── DateRangeCard (AppCard)
        │     inline calendar (compact month view, range highlight)
        │     LeaveDayCount: "5 working days" — titleMedium, primary color
        ├── AppSpacing.md
        ├── LeaveBalanceCard (AppCard)
        │     balance bar: used (primary fill) / remaining (surfaceVariant)
        ├── AppSpacing.md
        ├── ReasonTextField (AppCard, multiline 3 rows)
        └── SubmitLeaveButton — FilledButton, full width
```

**BLoC:** `LeaveRequestFormBLoC`
```
Events: LeaveTypeChanged, DateRangeChanged, LeaveSubmitted
States: LeaveFormInitial → LeaveFormValid / LeaveFormInvalid → LeaveFormSuccess
```

**SQLite tables:** `cached_leave_balances`, `cached_leave_requests`

---

#### Screen 7.5 — My Leave List
**Complexity: M** | **Route:** `/hr/leave`

**Feel:** Personal record. Balance summary + history in one view.

**Layout:**
```
Scaffold
  ├── AppBar: "My Leaves"
  ├── LeaveBalanceSummaryRow (horizontal scroll of AppCards)
  │     Each card: icon · type name · "X days left"
  │     success if plenty · warning if low · error if zero
  ├── FilterChips: All · Pending · Approved · Rejected
  └── ListView of LeaveTile (AppCard, AppSpacing.sm gap)
        ├── Top row: LeaveTypeChip · StatusChip (right)
        ├── Date range — bodyMedium
        └── Duration — bodySmall, onSurfaceVariant ("3 working days")
  FAB: + Request Leave
```

**BLoC:** `LeaveListBLoC`

**SQLite tables:** `cached_leave_requests`, `cached_leave_balances`

---

#### Screen 7.6 — Manager Leave Approval
**Complexity: M** | **Route:** `/hr/leave/approvals`

**Feel:** Decision queue. All context in the card — no tap-in required.

**Don't:** No swipe-to-approve — too easy to trigger accidentally while scrolling.

**Layout:**
```
Scaffold
  ├── AppBar: "Leave Approvals" · pending count badge (warningContainer)
  └── ListView of PendingLeaveCard (AppCard, AppSpacing.sm gap)
        ├── Top row: employee avatar (40×40) + name (titleMedium) + date range (right)
        ├── LeaveTypeChip + duration badge
        ├── Reason — bodyMedium, onSurfaceVariant, max 2 lines
        └── ActionRow:
              RejectButton (OutlinedButton, error, half width)
              ApproveButton (FilledButton, success, half width)
```

**BLoC:** `LeaveApprovalBLoC`

**SQLite tables:** `cached_leave_requests` (status update on action)

**Permission:** `PermissionGuard(scope: 'hr.approve')`

---

#### Screen 7.7 — Attendance Log
**Complexity: M** | **Route:** `/hr/attendance`

**Feel:** Personal clock. Today is the hero. History is secondary.

**Layout:**
```
Scaffold
  ├── AppBar: "Attendance"
  └── SingleChildScrollView
        ├── TodayCard (AppCard, primaryContainer bg)
        │     "Today, Mon 12 May" — titleMedium
        │     Clock-in time — headlineLarge (or "Not clocked in" onSurfaceVariant)
        │     Elapsed time — bodyMedium ("4h 23m on shift")
        │     ClockInOutButton — large FilledButton 56px height
        │       "Clock In" (success color) / "Clock Out" (error color)
        ├── AppSpacing.md
        ├── SectionHeader "This Month"
        ├── AttendanceCalendar (AppCard)
        │     compact month view, each day = colored dot:
        │     present=success · absent=error · late=warning · weekend=surfaceVariant
        ├── AppSpacing.md
        ├── SectionHeader "Log"
        └── ListView of AttendanceDayRow (AppCard, AppSpacing.xs gap)
              Date · Clock-in · Clock-out · Total hours · status dot
```

**BLoC:** `AttendanceBLoC`
```
Events: ClockInRequested, ClockOutRequested, AttendanceLoaded(month)
States: AttendanceLoading → AttendanceLoaded(log) / AttendanceFailure
```

**SQLite tables:** `cached_attendance`

---

#### Screen 7.8 — Payslip Viewer
**Complexity: M** | **Route:** `/hr/payslips`

**Feel:** Financial statement. Net pay is the hero. Breakdown below.

**Layout:**
```
Scaffold
  ├── AppBar: "Payslip" · download PDF icon
  ├── MonthPickerRow — horizontal scroll of month chips
  └── SingleChildScrollView
        ├── NetPayCard (AppCard, primaryContainer bg)
        │     "Net Pay" — bodyMedium, onSurfaceVariant
        │     Amount — displayLarge, primary color
        ├── AppSpacing.md
        ├── EarningsCard (AppCard)
        │     SectionHeader "Earnings"
        │     Basic · Overtime · Allowances (each: label + amount right)
        │     Total earnings — titleMedium bold, success color
        ├── AppSpacing.md
        ├── DeductionsCard (AppCard)
        │     SectionHeader "Deductions"
        │     Tax · Social security · Other
        │     Total deductions — titleMedium bold, error color
        └── ViewPdfButton — OutlinedButton, full width, file icon
```

**BLoC:** `PayslipBLoC`
```
Event: PayslipLoaded(month, year)
States: PayslipLoading → PayslipLoaded(data) / PayslipFailure
```

**SQLite tables:** `cached_payslips`

---

#### Screen 7.9 — Leave Approval Detail
**Complexity: M** | **Route:** `/hr/leave/approvals/:id`

**Feel:** Full context before deciding. All employee info visible without navigating away.

**Layout:**
```
Scaffold
  ├── AppBar: "Leave Request" · employee name subtitle
  └── SingleChildScrollView
        ├── EmployeeContextCard (AppCard, primaryContainer bg)
        │     avatar (56×56) · name (headlineMedium)
        │     department chip · "X days remaining this year" (bodySmall)
        ├── AppSpacing.md
        ├── RequestDetailCard (AppCard)
        │     2-column grid:
        │       Leave type (chip with icon) · Duration (titleMedium)
        │       Start date · End date
        │       Working days count (titleMedium, primary color)
        │       Submitted on (bodySmall, onSurfaceVariant)
        ├── AppSpacing.md
        ├── SectionHeader "Reason"
        ├── ReasonCard (AppCard)
        │     bodyLarge text, selectable
        │     AttachedDocRow if employee attached a document (paperclip + filename)
        ├── AppSpacing.md
        ├── SectionHeader "Leave Balance After Approval"
        ├── BalancePreviewCard (AppCard)
        │     BalanceBar: current balance (primary fill, AppRadius.full)
        │     "If approved: X days remaining" — bodyMedium, success color
        │     "If rejected: X days remaining" — bodySmall, onSurfaceVariant
        ├── AppSpacing.md
        ├── SectionHeader "Approval History" (if any prior actions)
        ├── ApprovalTimeline (AppCard)
        ├── AppSpacing.xl
        └── ActionSection (sticky bottom, only if status=PENDING_APPROVAL)
              RejectButton (OutlinedButton, error, half width)
              ApproveButton (FilledButton, success, half width)

RejectBottomSheet (modal):
  drag handle
  "Reason for rejection" — headlineMedium
  ReasonTextField (multiline, 3 rows min)
  character count bodySmall right
  ConfirmRejectButton (FilledButton, error, full width)

ApproveConfirmBottomSheet (modal):
  drag handle
  "Approve this leave request?" — headlineMedium
  leave summary recap (type, dates, days)
  NoteToEmployeeField (optional, 1 row, "Add a note...")
  ConfirmApproveButton (FilledButton, success, full width)
```

**BLoC:** `LeaveApprovalDetailBLoC`, `LeaveApprovalActionBLoC`
```
LeaveApprovalDetailBLoC:
  Event: LeaveRequestLoaded(id)
  States: LeaveDetailLoading → LeaveDetailLoaded(request, employee, balance)
        / LeaveDetailFailure

LeaveApprovalActionBLoC:
  Events: LeaveApproved(id, note?) / LeaveRejected(id, reason)
  States: ApprovalActionIdle → ApprovalActionLoading
        → ApprovalActionSuccess / ApprovalActionFailure
```

**SQLite tables:** `cached_leave_requests` (status, approved_by, rejected_reason, actioned_at), `cached_leave_balances`, `cached_employees`

**Permission:** `PermissionGuard(scope: 'hr.approve')` wraps ActionSection

**Post-action:** Navigate back to Leave Approvals list (7.6), show success snackbar, update badge count.

---

### Module 8 — Project Management

---

#### Screen 8.1 — Project List
**Complexity: S** | **Route:** `/projects`

**Feel:** Portfolio. Progress at a glance.

**Layout:**
```
Scaffold
  ├── AppBar: "Projects"
  ├── FilterChips: All · Active · On Hold · Completed
  └── ListView of ProjectTile (AppCard, AppSpacing.sm gap)
        ├── Top row: project name (titleMedium) · StatusChip
        ├── Manager avatar (24×24) + name (bodySmall)
        ├── ProgressBar — full width, AppRadius.full, success color fill
        └── Bottom row: "Due {date}" (bodySmall) · "X% complete" (bodySmall, right)
  FAB: + New Project
```

**BLoC:** `ProjectListBLoC`

**SQLite tables:** `cached_projects`

---

#### Screen 8.2 — Project Detail / Gantt
**Complexity: L** | **Route:** `/projects/:id`

**Feel:** Planning tool. Timeline is the hero element.

**Layout:**
```
Scaffold
  ├── AppBar: project name · StatusChip · overflow menu
  ├── ProjectHeaderCard (AppCard)
  │     Budget · Start · End (3-column)
  │     ProgressBar full width below
  ├── TabBar: Gantt · Board · Team · Files
  └── TabBarView
        Gantt tab:
          DateRangeHeader (sticky, horizontal scroll)
            week/month column labels, surfaceVariant bg
          GanttRows (horizontal scroll synced with header)
            each row: task name fixed left 140px · bar (colored by status)
              active=primary · done=success · pending=surfaceVariant
            dependency arrows: thin grey lines between bars
        Board tab: renders Screen 8.3 Kanban inline
        Team tab: list of assigned members (avatar + name + role)
        Files tab: list of attached documents
```

**BLoC:** `ProjectDetailBLoC`
```
Event: ProjectDetailLoaded(id)
States: ProjectDetailLoading → ProjectDetailLoaded(project, tasks) / ProjectDetailFailure
```

**SQLite tables:** `cached_projects`, `cached_tasks`

---

#### Screen 8.3 — Task Kanban Board
**Complexity: L** | **Route:** `/projects/:id/board`

**Feel:** Visual workflow. Cards are content. Columns are structure.

**Layout:**
```
Scaffold
  ├── AppBar: project name · filter icon
  └── HorizontalScrollView of columns
        Each column (240px wide, surfaceVariant bg, AppRadius.lg, margin AppSpacing.sm):
          ├── ColumnHeader: status label (titleMedium) · count badge (primary)
          └── DragTarget → ListView of KanbanCard (AppCard, AppSpacing.sm gap)
                ├── Title — titleMedium
                ├── AssigneeAvatarRow (24×24 circles, overlapping -8px)
                ├── PriorityBadge — colored dot + label (High/Medium/Low)
                └── DueDateRow — calendar icon + date
                      overdue: error color · today: warning · future: onSurfaceVariant
          AddTaskButton — dashed border card at bottom of each column
```

**BLoC:** `KanbanBLoC`
```
Events: TaskMoved(taskId, newStatus), TasksLoaded(projectId)
States: KanbanLoading → KanbanLoaded(columns) / KanbanFailure
```

**SQLite tables:** `cached_tasks` (status update on drag)

---

#### Screen 8.4 — Task Detail
**Complexity: M** | **Route:** `/projects/:projectId/tasks/:taskId`

**Feel:** Work item + conversation. Description then comments.

**Layout:**
```
Scaffold
  ├── AppBar: task title (truncated) · overflow menu (edit, delete)
  └── SingleChildScrollView
        ├── TaskHeaderCard (AppCard)
        │     StatusChip + PriorityBadge (row)
        │     AssigneeRow: avatar 32×32 + name + "Assigned to" label
        │     DueDateRow: calendar icon + date (error if overdue)
        ├── AppSpacing.md
        ├── DescriptionCard (AppCard) — bodyLarge, selectable text
        ├── AppSpacing.md
        ├── SectionHeader "Subtasks"
        ├── SubtaskList (AppCard)
        │     Each SubtaskRow: Checkbox · name (strikethrough if done)
        ├── AppSpacing.md
        ├── SectionHeader "Comments"
        └── CommentThread
              Each CommentTile: avatar 32×32 · name+time (bodySmall) · comment text
  Bottom sticky: CommentInputRow
    current user avatar (32×32)
    CommentTextField (surfaceVariant fill, AppRadius.full)
    SendButton (icon, primary, enabled when text not empty)
```

**BLoC:** `TaskDetailBLoC`, `CommentBLoC`

**SQLite tables:** `cached_tasks`, `cached_comments`

---

#### Screen 8.5 — Timesheet Entry
**Complexity: L** | **Route:** `/projects/timesheets`

**Feel:** Spreadsheet adapted for mobile. Every cell is a tap target.

**Layout:**
```
Scaffold
  ├── AppBar: "Timesheet" · week label · prev/next arrows
  ├── StickyHeaderRow (surfaceVariant bg, horizontal scroll)
  │     Mon · Tue · Wed · Thu · Fri · Sat · Sun · Total
  └── ListView of TimesheetTaskRow (AppCard, AppSpacing.xs gap)
        ├── Task name — bodyMedium, fixed left 120px
        └── 7 HoursCells (48×48 each)
              empty: dashed border, "—" onSurfaceVariant
              filled: surfaceVariant bg, titleMedium hours value
              tap → HoursInputBottomSheet (numpad, confirm button)
        Footer row: daily totals + week total (titleMedium bold)
  Bottom sticky: SubmitTimesheetButton — FilledButton, full width
```

**BLoC:** `TimesheetBLoC`
```
Events: TimesheetLoaded(week), HoursUpdated(taskId, day, hours), TimesheetSubmitted
States: TimesheetLoading → TimesheetLoaded(grid) / TimesheetSuccess / TimesheetFailure
```

**SQLite tables:** `cached_timesheets`

---

#### Screen 8.6 — Utilization Report
**Complexity: M** | **Route:** `/projects/utilization`

**Feel:** Team performance dashboard. Charts + ranked list.

**Layout:**
```
Scaffold
  ├── AppBar: "Utilization"
  ├── PeriodSelector — segmented: Week · Month · Quarter
  └── SingleChildScrollView
        ├── TeamSummaryCard (AppCard, primaryContainer bg)
        │     Avg utilization — headlineLarge, primary
        │     "X of Y members above target" — bodyMedium
        ├── AppSpacing.md
        ├── UtilizationBarChart (AppCard, 200px)
        │     fl_chart BarChart · one bar per member
        │     above target: success · below: warning
        │     target: dashed horizontal line (error color)
        ├── AppSpacing.md
        ├── SectionHeader "By Member"
        └── ListView of MemberUtilizationRow (AppCard, AppSpacing.xs gap)
              avatar 40×40 · name (titleMedium) · hours (bodyMedium)
              utilization % bar (AppRadius.full, color by level)
```

**BLoC:** `UtilizationBLoC`

**SQLite tables:** `cached_timesheets` (aggregated)

---

#### Screen 8.7 — Create / Edit Project
**Complexity: L** | **Route:** `/projects/new` · `/projects/:id/edit`

**Feel:** Project charter form. Structured setup that establishes scope, timeline, and team before any task is created.

**Layout:**
```
Scaffold
  ├── AppBar: "New Project" / "Edit Project" · "Save Draft" TextButton
  └── SingleChildScrollView, padding AppSpacing.md
        ├── SectionHeader "Basic Info"
        ├── BasicInfoCard (AppCard)
        │     ProjectNameField (full width, required)
        │     DescriptionField (multiline 3 rows)
        │     ClientField (optional — searchable customer picker)
        ├── AppSpacing.md
        ├── SectionHeader "Timeline"
        ├── TimelineCard (AppCard)
        │     StartDatePicker + EndDatePicker (2-column row)
        │     DurationDisplay — "X weeks" (bodyMedium, primary, computed live)
        ├── AppSpacing.md
        ├── SectionHeader "Budget"
        ├── BudgetCard (AppCard)
        │     BudgetField — numeric, prefixText "฿"
        │     BillingTypePicker — segmented: Fixed · Time & Materials · Retainer
        ├── AppSpacing.md
        ├── SectionHeader "Team"
        ├── TeamCard (AppCard)
        │     ProjectManagerPicker (searchable employee dropdown, required)
        │     MemberPickerRow — searchable multi-select employee field
        │     Each selected member chip: avatar 20×20 + name + remove X
        ├── AppSpacing.md
        ├── SectionHeader "Status"
        ├── StatusCard (AppCard)
        │     StatusPicker — segmented: Active · On Hold · Completed
        │     PriorityPicker — segmented: Low · Medium · High · Critical
        │       High: warning color · Critical: error color
        └── SaveButton — FilledButton, full width, 52px
              "Create Project" / "Update Project"
```

**BLoC:** `ProjectFormBLoC`
```
Events: FieldChanged(field, value), MemberAdded(employeeId),
        MemberRemoved(employeeId), ProjectSaved
States: ProjectFormInitial → ProjectFormValid / ProjectFormInvalid
      → ProjectFormSaving → ProjectFormSuccess / ProjectFormFailure
Additional (edit mode): ProjectLoaded(id) — pre-fills all fields
```

**SQLite tables:** `cached_projects` (upsert on save — SQLite), `cached_employees` (for member picker)

**Post-save (create):** Navigate to Project Detail (8.2). **Post-save (edit):** Pop back to Project Detail.

---

#### Screen 8.8 — Assign / Reassign Task
**Complexity: M** | **Route:** `/projects/:projectId/tasks/:taskId/assign`

**Feel:** Quick decision. See who's available, assign in two taps.

**Layout:**
```
Scaffold
  ├── AppBar: "Assign Task" · task title subtitle (truncated)
  └── SingleChildScrollView, padding AppSpacing.md
        ├── TaskContextCard (AppCard, surfaceVariant bg)
        │     task title (titleMedium)
        │     due date (bodySmall, error if overdue)
        │     current assignee row: avatar 32×32 + name / "Unassigned"
        ├── AppSpacing.md
        ├── SectionHeader "Select Assignee"
        ├── AssigneeSearchBar — filters list as you type
        ├── ListView of TeamMemberTile (AppCard, AppSpacing.sm gap)
        │     ├── Avatar (40×40) + name (titleMedium) + role (bodySmall)
        │     ├── WorkloadBadge — "X open tasks" (info/warning by count)
        │     │     ≤3 tasks: infoContainer · 4–6: warningContainer · 7+: errorContainer
        │     └── AvailabilityDot — green=available, warning=partial, grey=away
        │     Selected: primary border + primaryContainer bg + checkmark
        ├── AppSpacing.md
        ├── SectionHeader "Due Date (optional)"
        ├── DueDateCard (AppCard row)
        │     calendar icon + date picker + "No due date" clear option
        ├── AppSpacing.md
        ├── NoteCard (AppCard)
        │     NoteToAssigneeField (optional, 2 rows, "Add a note to the assignee...")
        └── AssignButton — FilledButton, full width
              "Assign Task" (disabled until assignee selected)
```

**BLoC:** `TaskAssignBLoC`
```
Events: TaskAssignLoaded(projectId, taskId), AssigneeSelected(employeeId),
        DueDateChanged(date), NoteChanged(text), TaskAssigned
States: TaskAssignLoading → TaskAssignLoaded(task, members)
      → TaskAssigning → TaskAssignSuccess / TaskAssignFailure
```

**SQLite tables:** `cached_tasks` (update assignee_id, due_date), `cached_employees`

**Post-assign:** Navigate back to Task Detail (8.4). A push notification is dispatched to the new assignee.

---

#### Screen 8.9 — Task Create / Edit
**Complexity: M** | **Route:** `/projects/:projectId/tasks/new` · `/projects/:projectId/tasks/:taskId/edit`

**Feel:** Fast task entry. Don't slow down the flow with too many required fields.

**Layout:**
```
Scaffold
  ├── AppBar: "New Task" / "Edit Task" · save icon (top-right)
  └── SingleChildScrollView, padding AppSpacing.md
        ├── TaskTitleField — large, 2-row TextField, headlineMedium style
        │     "What needs to be done?" placeholder
        ├── AppSpacing.md
        ├── DetailsCard (AppCard)
        │     StatusPicker row — icon + "To Do / In Progress / Done / Blocked"
        │     PriorityPicker row — icon + "Low / Medium / High / Critical"
        │     AssigneePicker row — avatar 24×24 + name / "Unassigned" + chevron
        │       tap → Task Assign sheet (8.8)
        │     DueDateRow — calendar icon + date / "No due date"
        ├── AppSpacing.md
        ├── DescriptionCard (AppCard)
        │     DescriptionField (multiline, 4 rows min, bodyLarge)
        │     "Add a description..." placeholder
        ├── AppSpacing.md
        ├── SubtaskCard (AppCard)
        │     SectionHeader "Subtasks" · "+ Add" trailing
        │     Each SubtaskRow: Checkbox + TextField (inline)
        │       done: strikethrough · remove icon (right)
        └── SaveButton — FilledButton, full width
              "Create Task" / "Update Task"
```

**BLoC:** `TaskFormBLoC`
```
Events: TitleChanged, DescriptionChanged, StatusChanged, PriorityChanged,
        AssigneeChanged(employeeId), DueDateChanged, SubtaskAdded,
        SubtaskToggled(index), SubtaskRemoved(index), TaskSaved
States: TaskFormInitial → TaskFormValid / TaskFormInvalid
      → TaskFormSaving → TaskFormSuccess / TaskFormFailure
Additional (edit mode): TaskLoaded(id) — pre-fills all fields
```

**SQLite tables:** `cached_tasks` (upsert on save — SQLite)

---

### Module 9 — Settings & Administration

---

#### Screen 9.1 — Settings Home
**Complexity: S** | **Route:** `/settings`

**Feel:** Clean menu. User identity at top, grouped options below.

**Layout:**
```
Scaffold
  ├── AppBar: "Settings"
  └── SingleChildScrollView
        ├── UserProfileCard (AppCard, primaryContainer bg)
        │     avatar 56×56 · name titleMedium · role chip + email bodySmall
        ├── AppSpacing.md
        ├── SectionHeader "Preferences"
        ├── SettingsGroup (AppCard)
        │     ThemeRow · LanguageRow · NotificationsRow
        │     each row: leading icon · label titleMedium · trailing arrow or value
        ├── AppSpacing.md
        ├── SectionHeader "Security"
        ├── SettingsGroup (AppCard)
        │     SessionsRow · AuditLogRow · PinLockRow
        ├── AppSpacing.md
        ├── SectionHeader "Admin" (PermissionGuard — admin only)
        ├── SettingsGroup (AppCard)
        │     UsersRow · RolesRow · EnvironmentRow
        ├── AppSpacing.lg
        └── LogoutButton — OutlinedButton, error color, full width
```

**BLoC:** None (static navigation screen)

**SQLite tables:** `cached_user` (read name, avatar)

---

#### Screen 9.2 — User Preferences
**Complexity: S** | **Route:** `/settings/preferences`

**Feel:** Clean toggles. Theme change previews instantly.

**Layout:**
```
Scaffold
  ├── AppBar: "Preferences"
  └── SingleChildScrollView
        ├── SectionHeader "Appearance"
        ├── ThemeCard (AppCard)
        │     3-option segmented button:
        │     Light (sun icon) · Dark (moon icon) · System (phone icon)
        ├── AppSpacing.md
        ├── SectionHeader "Language"
        ├── LanguageCard (AppCard, ListTile)
        │     current language label + chevron
        │     tap → LanguagePickerBottomSheet (list of locales)
        ├── AppSpacing.md
        ├── SectionHeader "Notifications"
        └── NotificationCard (AppCard)
              Each NotificationPrefRow: icon · label · Switch (right)
              types: Approvals · Inventory alerts · Leave updates · System
```

**BLoC:** `PreferencesBLoC`
```
Events: ThemeChanged(mode), LanguageChanged(locale), NotificationPrefToggled(type)
States: PreferencesLoaded(prefs) → PreferencesUpdated
```

**SQLite tables:** `cached_user_preferences` (theme, locale, notif_prefs JSON)

---

#### Screen 9.3 — Active Sessions
**Complexity: M** | **Route:** `/settings/sessions`

**Feel:** Security panel. Current device highlighted, easy revoke.

**Layout:**
```
Scaffold
  ├── AppBar: "Active Sessions"
  ├── CurrentSessionBanner (infoContainer bg, AppSpacing.md padding)
  │     "This device" label · device name + OS
  └── ListView of SessionTile (AppCard, AppSpacing.sm gap)
        ├── Device icon circle (40×40, surfaceVariant): phone/tablet/desktop
        ├── Device name — titleMedium
        ├── OS + "Last active {time}" — bodySmall, onSurfaceVariant
        └── RevokeButton — TextButton, error color (hidden for current device)
  Bottom: "Revoke all other sessions" OutlinedButton, error, full width
```

**BLoC:** `SessionManagementBLoC`
```
Events: SessionsLoaded, SessionRevoked(sessionId), AllOtherSessionsRevoked
States: SessionsLoading → SessionsLoaded(list) / SessionsFailure
```

**SQLite tables:** None (reads from API only — no local cache for security)

---

#### Screen 9.4 — Audit Log Viewer
**Complexity: M** | **Route:** `/settings/audit`

**Feel:** Read-only record. Filterable, tappable for full detail.

**Layout:**
```
Scaffold
  ├── AppBar: "Audit Log"
  ├── FilterRow (horizontal scroll chips):
  │     User · Module · Action type · Date range
  └── ListView of AuditLogTile (AppCard, AppSpacing.xs gap)
        ├── Leading: action icon circle (40×40, color by action type)
        │     create=success · update=info · delete=error · approve=primary
        ├── Center: action label (titleMedium) · user + module (bodySmall)
        └── Trailing: timestamp (bodySmall, onSurfaceVariant)
        tap → AuditLogDetailBottomSheet (360px):
          full action description
          record reference (tappable deep link)
          raw payload (monospace bodySmall, scrollable)
```

**BLoC:** `AuditLogBLoC`
```
Event: AuditLogsLoaded(filters)
States: AuditLogLoading → AuditLogLoaded(entries) / AuditLogFailure
```

**SQLite tables:** `cached_audit_logs`

---

#### Screen 9.5 — User Management (Admin)
**Complexity: M** | **Route:** `/settings/admin/users`

**Feel:** Admin directory. Status badge is the key signal.

**Layout:**
```
Scaffold
  ├── AppBar: "Users" · invite icon button
  └── ListView of UserManagementTile (AppCard, AppSpacing.sm gap)
        ├── Avatar (40×40 circle)
        ├── Name — titleMedium
        ├── Role chip + email — bodySmall, onSurfaceVariant
        └── StatusBadge: Active (successContainer) / Inactive (surfaceVariant)
        trailing overflow menu: Edit role · Reset password · Deactivate
```

**BLoC:** `UserManagementBLoC`

**SQLite tables:** None (admin reads from API only)

**Permission:** `PermissionGuard(scope: 'admin.users')`

---

#### Screen 9.6 — Role & Permission Editor (Admin)
**Complexity: L** | **Route:** `/settings/admin/roles`

**Feel:** Admin matrix. Dense but readable. Switches over checkboxes.

**Layout:**
```
Scaffold
  ├── AppBar: "Roles & Permissions" · Save TextButton (top-right)
  └── Body
        ├── RoleFilterChips — horizontal scroll (filter visible roles)
        └── PermissionMatrix (2D scroll: horizontal roles, vertical scopes)
              Header row: role names (surfaceVariant bg, titleMedium, fixed height)
              Left column: scope labels (fixed 140px width, bodyMedium)
              Each cell: Switch widget (compact)
                on: primary color · off: surfaceVariant
              Save → PATCH full matrix → invalidate + re-fetch SQLite user_permissions
```

**BLoC:** `RoleEditorBLoC`
```
Events: RolesLoaded, PermissionToggled(role, scope), RolesSaved
States: RoleEditorLoading → RoleEditorLoaded(matrix) → RoleEditorSaving
      → RoleEditorSuccess
```

**SQLite tables:** `user_permissions` (invalidated and re-fetched after save)

---

#### Screen 9.7 — API / Environment Config (Admin)
**Complexity: S** | **Route:** `/settings/admin/config`

**Feel:** Developer settings. Functional, no decoration.

**Layout:**
```
Scaffold
  ├── AppBar: "Environment Config"
  └── SingleChildScrollView, padding AppSpacing.md
        ├── EnvironmentCard (AppCard)
        │     3-option segmented button:
        │     Production (lock icon) · Staging (flask icon) · Custom (edit icon)
        ├── AppSpacing.md
        ├── ConnectionCard (AppCard, visible for Custom only)
        │     BaseUrlTextField · TenantIdTextField
        ├── AppSpacing.md
        ├── TestConnectionButton — OutlinedButton, full width
        │     idle: "Test Connection"
        │     success: success color + checkmark + "Connected"
        │     failure: error color + "Connection failed · check URL"
        └── SaveButton — FilledButton, full width
```

**BLoC:** `EnvConfigBLoC`
```
Events: ConfigLoaded, ConfigSaved(env, baseUrl, tenantId), ConnectionTested
States: ConfigLoading → ConfigLoaded / ConfigSaving / ConfigTestSuccess / ConfigTestFailure
```

**SQLite tables:** `cached_env_config` (baseUrl, tenantId, environment, updated_at)

---

#### Screen 9.8 — PIN Lock / Biometric Re-Auth
**Complexity: M** | **Route:** `/lock`

**Feel:** Secure gate. Minimal UI. Phone lock screen energy.

**Layout:**
```
Full screen, surface bg, centered column
  ├── App icon (48×48, top area)
  ├── User name — titleMedium, onSurfaceVariant
  ├── "Enter your PIN to continue" — bodyMedium
  ├── AppSpacing.xl
  ├── PinDotsRow (4–6 dots)
  │     each dot 14×14 circle: primary=filled, surfaceVariant=empty
  │     failure: dots shake (horizontal 300ms) + momentary error color then clear
  ├── AppSpacing.lg
  ├── PinPad — 3-column grid
  │     each button: 72×72, surfaceVariant bg, AppRadius.xl, headlineMedium
  │     0–9 · backspace icon · biometric icon (if available)
  ├── "X attempts remaining" — error color bodySmall (after 3rd fail)
  └── "Log out instead" — TextButton, error color, bodySmall
```

**BLoC:** `AppLockBLoC`
```
Events: PinSubmitted(pin), BiometricRequested, LogoutRequested
States: AppLocked → AppUnlocking → AppUnlocked / AppLockFailure(attemptsRemaining)
```

**SQLite tables:** `cached_user` (read biometric_on); PIN hash in `flutter_secure_storage`

**SQLite tables:** `cached_user` (read biometric_on); PIN hash in `flutter_secure_storage`

---

#### Screen 9.9 — My Profile Info
**Complexity: M** | **Route:** `/settings/profile`

**Feel:** Personal card. Own identity. Editable but protected — sensitive fields require re-auth.

**Layout:**
```
Scaffold
  ├── AppBar: "My Profile" · "Edit" TextButton (top-right)
  └── SingleChildScrollView
        ├── ProfileHeroCard (AppCard, primaryContainer bg)
        │     AvatarEditRow:
        │       avatar 80×80 circle (photo or initials)
        │       camera overlay icon (bottom-right, primaryContainer bg)
        │       tap → image picker (camera or gallery)
        │     name — headlineLarge
        │     role chip + department chip (row)
        ├── AppSpacing.md
        ├── SectionHeader "Contact"
        ├── ContactCard (AppCard)
        │     Each InfoRow: leading icon · label (bodySmall, onSurfaceVariant) · value (bodyMedium)
        │       email · phone · employee ID · hire date
        ├── AppSpacing.md
        ├── SectionHeader "Personal"
        ├── PersonalCard (AppCard)
        │     Each InfoRow: birthdate · address · emergency contact · emergency phone
        ├── AppSpacing.md
        ├── SectionHeader "Account Security"
        └── SecurityCard (AppCard)
              ChangePasswordRow → re-auth + change password flow
              ChangePinRow → /lock re-auth → PIN setup
              BiometricToggle — Switch (re-auth required to enable)
              LastLoginRow — "Last login: {date} from {device}"

Edit mode (activated by "Edit" AppBar button):
  All InfoRow values become InputFields
  AppBar shows "Cancel" (left) + "Save" FilledButton (right)
  Sensitive fields (email, phone) show ⚠ "Requires verification" below field
  Save → PATCH /me → update cached_user in SQLite
```

**BLoC:** `ProfileBLoC`
```
Events: ProfileLoaded, ProfileEditing, FieldChanged(field, value),
        AvatarChanged(file), ProfileSaved
States: ProfileLoading → ProfileLoaded(user) → ProfileEditing(draftUser)
      → ProfileSaving → ProfileSaved / ProfileFailure
```

**SQLite tables:** `cached_user` (all fields: name, email, phone, avatar_url, birthdate, address, emergency_contact, last_login_at)

**Notes:**
- Avatar upload: POST multipart/form-data to `/me/avatar`
- Email change triggers a verification link to the new address before taking effect

---

#### Screen 9.10 — My Roles & Permissions
**Complexity: M** | **Route:** `/settings/roles`

**Feel:** Read-only transparency. Users see exactly what they can and cannot do.

**Layout:**
```
Scaffold
  ├── AppBar: "My Roles & Permissions"
  └── SingleChildScrollView
        ├── RoleSummaryCard (AppCard, primaryContainer bg)
        │     "Your assigned roles:" — bodySmall, onSurfaceVariant
        │     RoleChipRow — horizontal scroll of RoleChips
        │       each chip: shield icon + role name (labelLarge, primaryContainer)
        │     "Last updated: {date}" — bodySmall, onSurfaceVariant
        ├── AppSpacing.md
        ├── SearchBar — "Search permissions..." (surfaceVariant fill)
        ├── AppSpacing.md
        ├── SectionHeader "Granted Permissions"
        ├── GrantedList (AppCard)
        │     Each PermissionRow:
        │       checkmark icon (success color) · scope label (titleMedium)
        │       module tag (labelSmall chip, right)
        │       bodySmall description below label
        ├── AppSpacing.md
        ├── SectionHeader "Not Granted"
        └── DeniedList (AppCard)
              Each PermissionRow:
                lock icon (onSurfaceVariant) · scope label (bodyMedium, onSurfaceVariant)
                module tag (labelSmall chip, surfaceVariant, right)
```

**Do:** Keep it read-only. Users cannot modify their own roles here — that goes through 9.6 (admin only).
**Don't:** Don't show raw scope strings like `finance.approve` — render as "Approve invoices (Finance)".

**BLoC:** `MyRolesBLoC`
```
Events: RolesLoaded, PermissionSearchChanged(query)
States: RolesLoading → RolesLoaded(roles, granted, denied) / RolesFailure
```

**SQLite tables:** `user_permissions` (read-only; scope, module, description, granted)

---

### Module 10 — Chat & Voice / Video

> Real-time internal communication built on WebSocket + SQLite for offline message persistence.
> Voice and video calls use WebRTC peer-to-peer via `flutter_webrtc`.
> Package dependencies: `flutter_webrtc`, `record`, `just_audio`, `image_picker`, `file_picker`.

---

**SQLite schema for Module 10:**

```sql
chat_conversations (
  id, name, avatar_url, is_group, is_muted,
  last_message_body, last_message_sender_id, last_message_at,
  unread_count, created_at, updated_at
)

chat_participants (
  conversation_id, employee_id, is_admin, joined_at, last_read_at
)

chat_messages (
  id, conversation_id, sender_id,
  body,                        -- null for voice/file messages
  type,                        -- text | voice | image | file | system
  reply_to_id,                 -- null if not a reply
  edited_body,                 -- null if never edited
  edited_at,                   -- null if never edited
  is_deleted,                  -- soft delete; body replaced with "Message deleted"
  file_url, file_name, file_size_bytes,
  voice_url, voice_duration_seconds,
  sent_at, delivered_at, read_at,
  reactions                    -- JSON: [{emoji, employee_ids[]}]
)

chat_call_log (
  id, conversation_id, caller_id, call_type,  -- voice | video
  started_at, answered_at, ended_at,
  duration_seconds, status                    -- missed | answered | rejected | no_answer
)
```

---

**Shared Chat components — define once, reuse everywhere:**

```
── OnlineStatusDot ──────────────────────────────────────────────────────
8×8 circle, bottom-right of avatar
  success=online · warning=away · surfaceVariant=offline
  AnimatedSwitcher crossfade on status change

── ChatBubble ───────────────────────────────────────────────────────────
Own messages:  right-aligned, primaryContainer bg, AppRadius.lg (top-left sharp)
Other messages: left-aligned, surfaceVariant bg,  AppRadius.lg (top-right sharp)
System messages: centered, no bg, bodySmall onSurfaceVariant italic

Content variants:
  TextBubble:  bodyLarge text, selectable
  VoiceBubble: play/pause icon + waveform bars (40px) + duration (bodySmall)
               playing: waveform animates, primary color progress
  ImageBubble: rounded image (AppRadius.md), tap → full-screen viewer
  FileBubble:  file icon circle + filename (bodyMedium) + size (bodySmall)
               download progress bar if not yet cached

Bubble footer (always, bottom-right of bubble):
  timestamp — bodySmall, onSurfaceVariant
  Read receipt (own messages only):
    single grey check  = sent
    double grey checks = delivered
    double primary checks = read (seen by all)
  EditedLabel — "(edited)" bodySmall, onSurfaceVariant (if edited)

DeletedBubble: italic "Message deleted" bodyMedium onSurfaceVariant
  no footer, no reactions, no reply affordance

ReactionRow (below bubble, AnimatedSwitcher):
  Each EmojiChip: emoji + count (labelSmall)
    own reaction: primaryContainer bg, primary border
    others: surfaceVariant bg
    tap: toggle own reaction · long-press: see who reacted (bottom sheet)

ReplyQuote (above bubble content, if reply_to_id set):
  left accent bar (3px, primary color) · sender name (labelLarge, primary)
  quoted body preview (bodySmall, onSurfaceVariant, 1 line max)
  tap: scroll to quoted message + highlight 400ms

── MessageContextMenu ───────────────────────────────────────────────────
Long-press on any non-deleted bubble → modal bottom sheet (240px):
  EmojiQuickBar: 6 common emoji + "+" button (opens full picker)
  Divider
  ReplyRow     — reply icon + "Reply"
  CopyRow      — copy icon + "Copy text" (text messages only)
  EditRow      — edit icon + "Edit" (own messages, text only, ≤15min old)
  DeleteRow    — delete icon + "Delete" (error color)
                   own messages: always available → soft delete
                   others' messages: admin only → soft delete
  PinRow       — pin icon + "Pin" (group admin only)
  ForwardRow   — forward icon + "Forward" (future scope, show as disabled)

── TypingIndicator ──────────────────────────────────────────────────────
3 animated dots (scale pulse, staggered 150ms each)
"Name is typing..." bodySmall onSurfaceVariant
"Name1, Name2 are typing..." for multiple
AnimatedSwitcher: slides in/out from bottom
```

---

#### Screen 10.1 — Chat Inbox (Conversation List)
**Complexity: M** | **Route:** `/chat`

**Feel:** The entry point. Familiar messaging-app pattern. Unread conversations demand attention with bold text and badges. Seen conversations recede quietly.

**Layout:**
```
Scaffold
  ├── AppBar: "Messages"
  │     trailing: compose icon → /chat/new
  ├── TabBar: All · Unread · Groups (sticky below AppBar)
  ├── SearchBar (surfaceVariant fill, AppRadius.md, search icon)
  │     active: shows SearchResultList across all conversations
  │     inactive: shows ConversationList per active tab
  └── Body
        LoadingShimmer (3 shimmer tiles) while InboxLoading
        EmptyState if InboxEmpty:
          chat-bubble illustration + "No conversations yet"
          "Start a chat" FilledButton → /chat/new
        ListView of ConversationTile (no card wrapper, Divider separator)
          Each ConversationTile:
            ├── Leading:
            │     Direct: avatar 52×52 circle (photo or initials)
            │               OnlineStatusDot bottom-right
            │     Group:   3-avatar cluster
            │               front: 40×40 · back two: 28×28, offset -8px
            ├── Title row:
            │     name — titleMedium (w600 if unread, w400 if read)
            │     timestamp — bodySmall, onSurfaceVariant (right)
            │     MutedIcon — bell-off 14×14, onSurfaceVariant (if muted)
            ├── Subtitle row:
            │     last message preview — bodySmall, onSurfaceVariant, 1 line
            │       "You: ..." prefix for own last message
            │       "📎 Photo" / "📎 File: filename" / "🎤 Voice message"
            │       "📞 Voice call · 5:23" / "📹 Video call · 5:23" (call logs)
            │       "✏ Name edited a message" (system)
            │     UnreadBadge — right (warningContainer bg, labelSmall, min 20×20)
            │       "99+" if count > 99
            └── Swipe actions:
                  swipe right: MuteToggle (bell icon, infoContainer)
                  swipe left: DeleteConversation (trash icon, errorContainer)
                                confirmation dialog before delete
```

**BLoC:** `ChatInboxBLoC`
```
Events: InboxLoaded, TabChanged(tab), SearchChanged(query),
        ConversationMuted(id), ConversationDeleted(id),
        NewMessageReceived(conversationId, message) [WebSocket push]
States: InboxLoading → InboxLoaded(all, unread, groups) / InboxEmpty / InboxFailure
```

**SQLite tables:** `chat_conversations`, `chat_participants`

**WebSocket:** Subscribes to `/ws/inbox` on mount for real-time conversation list updates (new messages, read receipts, typing from any conversation).

---

#### Screen 10.2 — Chat Conversation
**Complexity: L** | **Route:** `/chat/:conversationId`

**Feel:** The core experience. Real-time, fluid, expressive. Every interaction is instant — optimistic updates, no waiting.

**Layout:**
```
Scaffold
  ├── AppBar (custom):
  │     Leading: avatar 36×36 + OnlineStatusDot (direct) /
  │               group avatar cluster (group)
  │     Title column:
  │       name — titleMedium
  │       status row — bodySmall, onSurfaceVariant:
  │         direct: "Online" / "Away" / "Last seen {relative time}"
  │         group:  "X members · Y online"
  │     Trailing:
  │       VoiceCallButton (phone icon)
  │       VideoCallButton (video icon) [direct only]
  │       overflow menu → conversation info (10.5)
  │
  ├── PinnedMessageBanner (AnimatedSwitcher, surfaceVariant bg, AppSpacing.sm)
  │     pin icon · truncated pinned message (bodySmall)
  │     tap: scroll to pinned message · × to dismiss banner (not unpin)
  │     visible only when a message is pinned
  │
  └── Body (Column, fills remaining height)
        ├── MessageList (Expanded)
        │     reverse: true (newest at bottom, scroll starts at bottom)
        │     physics: BouncingScrollPhysics
        │     LoadingShimmer while ConversationLoading
        │     Lazy-load older messages on scroll to top (PagedListView)
        │
        │     Per group of messages from same sender (≤5 min apart):
        │       sender avatar 28×28 (left side, group only, first message only)
        │       sender name bodySmall (above first bubble, group + others only)
        │
        │     DateSeparator — centered chip, surfaceVariant bg, bodySmall
        │       "Today" / "Yesterday" / "Mon 12 May 2025"
        │
        │     ChatBubble (per message — see shared components above)
        │
        │     SystemMessage — centered italic bodySmall, onSurfaceVariant
        │       "Name joined" / "Name left" / "Name changed the group name"
        │       "📞 Voice call ended · 5:23" / "📞 Missed voice call"
        │       "📹 Video call ended · 12:04" / "📹 Missed video call"
        │
        │     TypingIndicator (bottom of list, AnimatedSwitcher)
        │
        │     ScrollToBottomFAB (bottom-right, 40×40)
        │       shown when scrolled up > 200px
        │       UnreadBadge on FAB if new messages while scrolled up
        │
        ├── ReplyPreviewBar (surfaceVariant bg, 52px, AnimatedSwitcher)
        │     left accent (3px, primary)
        │     "Replying to Name" — labelLarge, primary
        │     quoted body preview — bodySmall, onSurfaceVariant, 1 line
        │     × close button (right, removes reply context)
        │
        ├── EditPreviewBar (infoContainer bg, 52px, AnimatedSwitcher)
        │     pencil icon · "Editing message" — labelLarge
        │     × cancel edit (right)
        │     only visible when editing an existing message
        │
        └── InputRow (surface bg, top border 0.5px surfaceVariant)
              padding: AppSpacing.sm horizontal, AppSpacing.xs vertical
              ├── AttachButton (paperclip icon, 40×40)
              │     tap → AttachmentBottomSheet
              ├── MessageTextField (Expanded)
              │     surfaceVariant fill, AppRadius.full
              │     padding: 10px horizontal, 8px vertical
              │     minLines: 1, maxLines: 6 (auto-expands)
              │     "Message..." placeholder
              │     onChanged: emit TypingStarted (debounced 2s → TypingStopped)
              │     Edit mode: pre-filled with message body
              └── SendButton / VoiceButton (40×40, primary color)
                    text not empty → SendButton (send icon, FilledButton circle)
                    text empty     → VoiceButton (mic icon, OutlinedButton circle)
                                     hold-to-record (see VoiceRecordingOverlay)
                    edit mode      → SaveEditButton (check icon, success color)

── AttachmentBottomSheet (300px) ────────────────────────────────────────
drag handle
2×2 grid of AttachOption tiles (AppCard, 80×80):
  Camera      — camera icon (primary)    → image_picker (camera)
  Gallery     — image icon (info)        → image_picker (gallery, multiple)
  File        — file icon (warning)      → file_picker (any type)
  Location    — pin icon (error)         → show map + send coordinates
each tile: icon 36×36 circle + label bodySmall below

── VoiceRecordingOverlay (replaces InputRow while recording) ────────────
surface bg, same height as InputRow
├── CancelZone (left half): "< Slide to cancel" bodySmall onSurfaceVariant
│     sliding left past threshold cancels recording (no send)
├── Center:
│     MicIcon (32×32, error color, pulse scale animation)
│     WaveformBars (80px wide, real-time amplitude bars, primary color)
│     RecordingTimer — "0:04" bodyMedium (counts up)
└── ReleaseHint (right): "Release to send" bodySmall onSurfaceVariant
Haptic feedback on recording start.

── MessageContextMenu (bottom sheet, 260px) ─────────────────────────────
drag handle · "Message options" labelLarge, centered
EmojiQuickBar (horizontal, 52px height):
  6 fixed emoji: 👍 ❤️ 😂 😮 😢 🙏
  + button → EmojiPickerFullSheet (320px, grid, searchable)
  tap emoji: toggle reaction · already reacted: removes reaction
Divider
MenuItems (each: icon + label, 48px height):
  Reply      (reply icon)   — always shown
  Copy text  (copy icon)    — text messages only
  Edit       (edit icon)    — own text messages ≤15 min old
  Pin        (pin icon)     — group admin only
  Delete     (trash, error) — own: always · others: admin only
    own message delete → ConfirmDeleteSheet:
      "Delete for everyone?" / "Delete for me only" / "Cancel"

── SeenBySheet (bottom sheet, 280px) ────────────────────────────────────
Shown on tap of read checkmarks on own messages
"Seen by" headlineMedium
ListView of SeenRow:
  avatar 36×36 · name (titleMedium) · "Seen at {time}" (bodySmall, right)
```

**BLoC:** `ConversationBLoC`
```
Events:
  ConversationLoaded(id)
  OlderMessagesRequested                  -- pagination
  MessageSent(body, replyToId?)
  VoiceMessageSent(filePath, durationSec)
  ImageSent(filePath)
  FileSent(filePath, fileName, sizeBytes)
  MessageEdited(messageId, newBody)
  MessageDeleted(messageId, deleteForEveryone)
  ReactionToggled(messageId, emoji)
  ReplyStarted(messageId)
  ReplyCancelled
  EditStarted(messageId)
  EditCancelled
  MessagePinned(messageId)
  MessageUnpinned
  TypingStarted                           -- local user typing
  TypingStopped
  NewMessageReceived(message)             -- from WebSocket
  TypingIndicatorReceived(senderId, isTyping)  -- from WebSocket
  MessagesSeenByRemote(messageIds)        -- from WebSocket
  ScrolledToBottom

States:
  ConversationLoading
  ConversationLoaded(
    messages,       -- paginated list, newest first
    participants,
    pinnedMessage?,
    replyingTo?,    -- message being replied to
    editingMessage? -- message being edited
  )
  ConversationPaginating   -- loading older messages
  ConversationFailure
```

**SQLite tables:** `chat_messages` (full schema), `chat_conversations` (update last_message, unread_count), `chat_participants` (update last_read_at on seen)

**WebSocket:** Subscribes to `/ws/chat/:conversationId`. Handles: `message.new`, `message.edited`, `message.deleted`, `message.reaction`, `typing.start`, `typing.stop`, `message.seen`.

**Optimistic updates:** MessageSent immediately appends bubble with `pending` state (single grey clock icon). Server ACK upgrades to `sent`. Failure shows retry button on bubble.

---

#### Screen 10.3 — New Conversation / Group Chat
**Complexity: M** | **Route:** `/chat/new`

**Feel:** Contact picker. Lightweight and fast. Two taps to start a direct chat, five taps to create a named group.

**Layout:**
```
Scaffold
  ├── AppBar: "New Message"
  │     trailing: "Create" TextButton (disabled until ≥1 selected + group name filled)
  ├── TypeToggle (AppCard, segmented row)
  │     Direct · Group (switches UI mode)
  ├── GroupSetupSection (AnimatedSwitcher, Group mode only)
  │     GroupNameField (InputField, "Group name..." required)
  │     GroupAvatarRow:
  │       camera-circle (56×56, surfaceVariant) + "Add group photo" bodySmall
  │       tap → image_picker
  ├── SearchBar — "Search employees..."
  └── Body
        SelectedChipsRow (surfaceVariant bg, 48px, horizontal scroll)
          visible when ≥1 selected
          Each chip: avatar 20×20 + name + × remove
        Divider
        LoadingShimmer while loading
        ListView of SelectableMemberTile (AppSpacing.xs gap)
          ├── Avatar 44×44 + OnlineStatusDot
          ├── Name — titleMedium
          ├── Role + department — bodySmall, onSurfaceVariant
          └── Trailing: Checkbox (primary color when checked)
          selected: primaryContainer bg row tint
        EmptyState if search returns nothing: "No employees found"
  Bottom: CreateButton — FilledButton, full width, 52px
    Direct: "Start Chat" (enabled when exactly 1 selected)
    Group:  "Create Group" (enabled when ≥2 selected + name non-empty)
```

**BLoC:** `NewConversationBLoC`
```
Events: ModeChanged(type), SearchChanged(query), MemberToggled(employeeId),
        GroupNameChanged(name), GroupAvatarChanged(file), ConversationCreateRequested
States: NewConversationLoading → NewConversationReady(employees, selected, mode)
      → ConversationCreating → ConversationCreated(conversationId) / ConversationCreateFailure
```

**SQLite tables:** `cached_employees`, `chat_conversations` (insert), `chat_participants` (insert)

**Post-create:** Push to Chat Conversation (10.2). New group shows system message "Name created this group".

---

#### Screen 10.4 — Message Search
**Complexity: M** | **Route:** `/chat/:conversationId/search`

**Feel:** Archive lookup. Find that file someone sent two months ago without infinite scroll.

**Layout:**
```
Scaffold
  ├── AppBar (no title): SearchTextField (autofocus, full width, AppRadius.md)
  │     clear × button · back arrow
  └── Body
        EmptyState (initial): magnifier illustration + "Search messages"
        LoadingShimmer while searching
        EmptyState (no results): "No messages found for '{query}'"
        ListView of MessageSearchResultTile (AppCard, AppSpacing.sm gap)
          ├── SenderAvatar 40×40 + sender name (titleMedium)
          ├── Timestamp — bodySmall, onSurfaceVariant, right
          ├── MessagePreview — bodyMedium, 2 lines max
          │     matched term highlighted (primary color, w600)
          └── MediaPreview (if file/image): file icon + filename
          tap → navigate to Conversation (10.2) + scroll to + highlight message
```

**BLoC:** `MessageSearchBLoC`
```
Events: SearchChanged(query)
States: SearchInitial → SearchLoading → SearchResults(messages) / SearchEmpty / SearchFailure
```

**SQLite tables:** `chat_messages` (FTS5 full-text search on body column)

---

#### Screen 10.5 — Voice Call
**Complexity: L** | **Route:** `/chat/:conversationId/voice-call` (full-screen route, no back gesture)

**Feel:** Telephone. Familiar controls. Dark, focused. Nothing competes with the call.

**Incoming Call sheet** (shown over any screen when a call arrives):
```
Modal bottom sheet, 280px, dark bg (Color(0xFF1A1D23)), AppRadius.xl top
  CallerAvatar 64×64 + name headlineMedium (white) + "Incoming voice call" bodyMedium
  Row (equal width, 96px height):
    DeclineButton — 64×64 circle, error bg, phone-down icon (white)
    AcceptButton  — 64×64 circle, success bg, phone icon (white)
  Labels below: "Decline" / "Accept" (bodySmall, white 70%)
```

**In-Call screen layout:**
```
Full screen, gradient bg (Color(0xFF0F1117) → Color(0xFF1A2035))
  ├── SafeArea top
  │     CallTypeLabel — "Voice Call" bodySmall white 60%, centered
  │
  ├── Center section (flex 1, verticalCenter)
  │     CallerAvatar — 112×112 circle
  │       Calling state: pulse glow ring (primary 30%), scale 1.0→1.08→1.0, 1.2s loop
  │       Connected state: static, glow stops
  │     AppSpacing.lg
  │     CallerName — headlineLarge, white
  │     AppSpacing.sm
  │     CallStatusRow:
  │       Calling:   "Calling..." bodyMedium white 70% + pulsing dots
  │       Ringing:   "Ringing..." bodyMedium white 70%
  │       Connected: live timer "00:04:23" bodyMedium white 70%
  │       Ended:     "Call ended" bodyMedium white 70% + duration
  │
  ├── WaveformRow (visible in Connected state only, 48px height)
  │     Animated waveform bars (20 bars, primary color 40% opacity)
  │     bars animate to voice amplitude (from WebRTC audio stats)
  │
  └── ControlsGrid (bottom, padding-bottom: 56px)
        Row 1 — secondary controls (64×64 circles, surfaceVariant 30% bg):
          MuteButton   (mic-off icon)    active=error bg    label "Mute"/"Unmuted"
          SpeakerButton (volume icon)   active=primary bg   label "Speaker"/"Earpiece"
          KeypadButton  (keypad icon)   → DTMF keypad sheet label "Keypad"
        AppSpacing.xl
        Row 2 — primary control (centered):
          EndCallButton — 72×72 circle, error bg, phone-down icon (white)
          label "End" bodySmall white below
```

**BLoC:** `VoiceCallBLoC`
```
Events:
  CallInitiated(conversationId)         -- outgoing
  IncomingCallReceived(callId, callerId) -- push notification triggers this
  CallAnswered
  CallDeclined
  CallEnded
  MuteToggled
  SpeakerToggled
  CallTimerTick                         -- every second, emitted internally

States:
  CallIdle
  CallCalling(conversationId)           -- outgoing, waiting for answer
  CallRinging(callId, caller)           -- incoming, waiting for local action
  CallConnected(duration, isMuted, isSpeaker)
  CallEnded(duration, endedBy)
  CallFailure(reason)                   -- network error, permission denied
```

**WebRTC:** `flutter_webrtc`. Signalling over WebSocket `/ws/voice/:callId`. ICE: STUN `stun:stun.l.google.com:19302` + TURN from `EnvConfig.turnServers`.

**SQLite tables:** `chat_call_log` (insert on call start, update on end)

**Permissions:** `Permission.microphone` — request before `CallInitiated`. If denied: show error snackbar "Microphone permission required", do not initiate.

**Background:** Use `flutter_background_service` + FCM `high-priority` for incoming calls when app is backgrounded.

---

#### Screen 10.6 — Video Call
**Complexity: L** | **Route:** `/chat/:conversationId/video-call` (full-screen route)

**Feel:** FaceTime-style. Remote video fills the screen. Local preview is a small PiP. Controls auto-hide after 3s of inactivity.

**Incoming Video Call sheet** (same pattern as voice but with video camera icon and "Incoming video call" label):
```
Same structure as Voice incoming sheet (Screen 10.5)
DeclineButton + AcceptVideoButton (video-camera icon, success bg)
```

**In-Call screen layout:**
```
Full screen, black bg
  ├── RemoteVideoView (full screen)
  │     RTCVideoRenderer — fills entire screen, objectFit: cover
  │     Placeholder when remote video off:
  │       dark bg + CallerAvatar 96×96 + name headlineMedium white
  │
  ├── LocalVideoPreview (PiP, draggable)
  │     Initial position: top-right, margin AppSpacing.md
  │     Size: 120×160, AppRadius.lg, white border 1.5px
  │     RTCVideoRenderer — mirrored (front camera)
  │     tap: switch PiP position (4 corners)
  │     Placeholder when camera off: surfaceVariant bg + person icon
  │
  ├── TopBar (auto-hide after 3s, AnimatedOpacity)
  │     SafeArea top
  │     Row:
  │       CallTypeLabel "Video Call" bodySmall white 70% (left)
  │       CallTimer "00:12:45" bodySmall white 70% (right)
  │
  └── ControlsBar (bottom, auto-hide after 3s, AnimatedOpacity)
        gradient overlay: transparent → black 60%
        padding-bottom: 48px (safe area)
        Row of control buttons (64×64 circles):
          MuteButton     (mic-off)     active=error bg     "Mute"
          CameraButton   (camera-off)  active=surfaceVar    "Camera"
          FlipButton     (flip-camera) no active state      "Flip"
          SpeakerButton  (volume)      active=primary       "Speaker"
          EndCallButton  (phone-down)  always error bg 72×72 "End"
        tap anywhere on screen: show/re-hide controls (3s timer reset)
```

**BLoC:** `VideoCallBLoC`
```
Events:
  VideoCallInitiated(conversationId)
  IncomingVideoCallReceived(callId, callerId)
  CallAnswered
  CallDeclined
  CallEnded
  MuteToggled
  CameraToggled          -- on/off
  CameraFlipped          -- front/back
  SpeakerToggled
  ControlsVisibilityToggled
  RemoteVideoStateChanged(isEnabled)
  CallTimerTick

States:
  VideoCallIdle
  VideoCallCalling(conversationId)
  VideoCallRinging(callId, caller)
  VideoCallConnected(
    duration, isMuted, isCameraOn, isFrontCamera,
    isSpeaker, isRemoteVideoOn, controlsVisible
  )
  VideoCallEnded(duration)
  VideoCallFailure(reason)
```

**WebRTC:** Same as Voice (10.5) but with both audio + video tracks. `RTCVideoRenderer` for local + remote. Negotiate `video/H264` codec preference in SDP.

**SQLite tables:** `chat_call_log` (call_type = 'video')

**Permissions:** `Permission.microphone` + `Permission.camera` — request both before initiating. Handle partial grant (e.g. camera denied but mic granted) gracefully: start call with camera off, show warning snackbar.

---

#### Screen 10.7 — Chat Settings / Conversation Info
**Complexity: M** | **Route:** `/chat/:conversationId/info`

**Feel:** Full context for the conversation. Members, media, actions.

**Layout:**
```
Scaffold
  ├── AppBar: "Conversation Info"
  └── SingleChildScrollView
        ── Direct conversation ──────────────────────────────────────────
        ├── ProfileCard (AppCard, primaryContainer bg)
        │     avatar 72×72 + OnlineStatusDot
        │     name headlineMedium · role chip
        │     "Online" / "Last seen {time}" bodySmall onSurfaceVariant
        ├── AppSpacing.md
        ├── QuickActionsCard (AppCard)
        │     VoiceCallRow → Screen 10.5
        │     VideoCallRow → Screen 10.6
        │     SearchMessagesRow → Screen 10.4
        ── Group conversation ───────────────────────────────────────────
        ├── GroupHeaderCard (AppCard, primaryContainer bg)
        │     GroupAvatarWidget 80×80 (editable, admin only)
        │     group name headlineMedium
        │     "X members · Y online" bodySmall onSurfaceVariant
        │     edit-name pencil icon (admin only) → inline rename field
        ├── AppSpacing.md
        ├── QuickActionsCard (AppCard)
        │     SearchMessagesRow → Screen 10.4
        │     AddMembersRow → member picker sheet (admin only)
        ── Shared ───────────────────────────────────────────────────────
        ├── AppSpacing.md
        ├── MediaCard (AppCard)
        │     SectionHeader "Shared Media" · "See all" trailing
        │     3-column photo grid (preview first 6 images, 80×80 each, AppRadius.sm)
        │     tap → MediaGalleryViewer
        ├── AppSpacing.md
        ├── SettingsCard (AppCard)
        │     MuteRow: "Mute notifications" · Switch
        │     PinnedMessageRow → scroll to pinned message in conversation
        ├── AppSpacing.md
        ├── (Group only) MembersCard (AppCard)
        │     SectionHeader "Members ({count})" · "Add" TextButton (admin)
        │     ListView of MemberRow (non-scrolling, shrinkWrap):
        │       avatar 40×40 + OnlineStatusDot
        │       name titleMedium + role bodySmall
        │       AdminBadge "Admin" (labelSmall, primaryContainer, if admin)
        │       long-press (admin only) → MemberOptionsSheet:
        │         "Make admin" / "Remove admin" / "Remove from group"
        │     "+ X more" TextButton if >5 members → full members sheet
        ├── AppSpacing.md
        └── DangerCard (AppCard)
              (Group) LeaveGroupRow — "Leave Group" OutlinedButton, error, full width
              ClearHistoryRow — "Clear Chat History" TextButton, error
                → confirmation dialog: "This clears history on your device only"
```

**BLoC:** `ChatInfoBLoC`
```
Events: InfoLoaded(conversationId), GroupRenamed(name), GroupAvatarChanged(file),
        MuteToggled, MemberAdded(employeeId), MemberRemoved(employeeId),
        AdminGranted(employeeId), AdminRevoked(employeeId), GroupLeft, HistoryCleared
States: InfoLoading → InfoLoaded(conversation, participants, pinnedMessage) / InfoFailure
```

**SQLite tables:** `chat_conversations`, `chat_participants`, `chat_messages` (media query)

---

## 8. Screen Complexity Summary

| Module | S | M | L | Total |
|---|---|---|---|---|
| Module 0 — App Entry | 0 | 1 | 0 | 1 |
| Module 1 — Auth & Identity | 2 | 2 | 0 | 4 |
| Module 2 — Dashboard & Home | 0 | 2 | 1 | 3 |
| Module 3 — Finance & Accounting | 1 | 3 | 3 | 7 |
| Module 4 — Procurement | 1 | 4 | 3 | 8 |
| Module 5 — Inventory & Warehouse | 0 | 3 | 3 | 6 |
| Module 6 — Sales & CRM *(+2)* | 1 | 5 | 2 | **8** |
| Module 7 — Human Resources *(+1)* | 1 | 7 | 1 | **9** |
| Module 8 — Project Management *(+3)* | 1 | 4 | 4 | **9** |
| Module 9 — Settings & Admin *(+2)* | 3 | 6 | 1 | **10** |
| Module 10 — Chat & Voice/Video *(expanded)* | 0 | 3 | 4 | **7** |
| **Total** | **10** | **40** | **22** | **72** |

> Note: Screen count changed from 76 → 72 because Module 10 was restructured: 5 old screens replaced with 7 richer screens (10.1–10.7), net +2.

### Effort guide
- **S — Simple (10 screens):** 1–2 days each. Single BLoC, 1–3 widgets, straightforward read/display.
- **M — Medium (40 screens):** 3–5 days each. Multiple widgets, form validation or list+detail, 1–2 BLoCs.
- **L — Large (22 screens):** Full sprint per screen. Custom painters, multi-BLoC, offline sync, WebRTC, real-time state machines.

---

## 9. Claude Code Prompt Template

Place this file as `DESIGN_GUIDE.md` in your repo root.

Use this prompt for every screen:

```
Build [Screen X.X — Name] for the ERP Mobile Flutter app.

Context file in this repo:
- DESIGN_GUIDE.md — complete reference: design tokens, component patterns,
  coding rules, per-screen layout + BLoC + SQLite spec for all 72 screens

Rules:
- Use AppTheme, AppLabel, AppSpacing, AppRadius — no hardcoded values
- Split into small private widget classes, one per visual section
- buildWhen on every BlocBuilder to minimise rebuilds
- AppCard for every content block
- StatusChip from the shared status color map
- EmptyState widget when list is empty
- LoadingShimmer while data loads (not CircularProgressIndicator alone on lists)
- PermissionGuard wraps any action requiring a specific scope
- BLoC pattern: use the Events/States specified in DESIGN_GUIDE.md §7
- SQLite: read from the tables listed in the screen spec; never query SQLite in build()
- Chat screens: subscribe/unsubscribe WebSocket in BLoC, not in widget lifecycle
- Chat optimistic updates: append message immediately, upgrade state on server ACK
- Voice/Video calls: request permissions before initiating; handle denial gracefully
- Video call: use RTCVideoRenderer for both local (mirrored) and remote streams
- Auto-hide controls (video call): use Timer(3s) + AnimatedOpacity, reset on tap
- Form screens: show discard confirmation dialog if user navigates back with unsaved changes

Screen complexity: [S / M / L]
```

### Quick reference — common mistakes to avoid

| Wrong | Right |
|---|---|
| `Color(0xFF3B4FE8)` hardcoded | `AppTheme.primary` |
| `TextStyle(fontSize: 16)` | `AppLabel.bodyLarge` |
| `SizedBox(height: 16)` | `SizedBox(height: AppSpacing.md)` |
| `BorderRadius.circular(16)` | `BorderRadius.circular(AppRadius.lg)` |
| `Container()` as content block | `AppCard()` |
| `CircularProgressIndicator()` on list | `LoadingShimmer()` |
| Empty `SizedBox()` when list empty | `EmptyState()` |
| Admin button without guard | `PermissionGuard(scope: '...') { button }` |
| Reading SQLite in `build()` | Read in BLoC from SQLite, expose via stream |
| `BlocBuilder` without `buildWhen` | Always add `buildWhen` |
| WebSocket in widget `initState` | Subscribe in BLoC; dispose in BLoC's `close()` |
| Waiting for server before showing sent message | Optimistic insert → upgrade on ACK |
| Starting call without checking permissions | `await Permission.microphone.request()` first |
| Navigating back without checking unsaved form | Use `WillPopScope` / `PopScope` + discard dialog |
