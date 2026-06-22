# Enterprise ERP Mobile — Project Plan

## Core Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| UI Framework | Flutter (Dart) | Cross-platform iOS/Android |
| State Management | flutter_bloc (open source) | BLoC pattern |
| Architecture | MVVM + Clean Architecture | Separation of concerns |
| DI | get_it + injectable | Service locator |
| Networking | dio | HTTP client |
| Local DB | drift (moor) | SQLite ORM, open source |
| Secure Storage | flutter_secure_storage | Tokens/credentials |
| Navigation | go_router | Declarative routing |
| Serialization | freezed + json_serializable | Immutable models |
| Offline Sync | Custom sync engine (drift + dio) | No commercial deps |
| Localization | flutter_localizations (built-in) | i18n |
| Testing | bloc_test, mocktail, flutter_test | Unit + widget tests |

---

## Project Architecture

```
lib/
├── core/                      # Shared infrastructure
│   ├── network/               # Dio client, interceptors, error handler
│   ├── database/              # Drift DB setup, DAOs
│   ├── sync/                  # Offline-first sync engine
│   ├── di/                    # Dependency injection setup
│   ├── router/                # go_router configuration
│   ├── error/                 # Failures, exceptions, Either type
│   ├── utils/                 # Extensions, helpers
│   └── theme/                 # Design tokens, typography
│
├── features/                  # One folder per ERP module
│   └── [module]/
│       ├── data/
│       │   ├── datasources/   # Remote (API) + Local (Drift DAO)
│       │   ├── models/        # JSON ↔ Dart (freezed)
│       │   └── repositories/  # Implements domain contracts
│       ├── domain/
│       │   ├── entities/      # Pure business objects
│       │   ├── repositories/  # Abstract interfaces
│       │   └── usecases/      # Single-responsibility business logic
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
UseCase (domain logic)
   │  calls
   ▼
Repository (abstract interface)
   │  implemented by
   ▼
DataSource (Remote API / Local DB)
```

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
- Slice 0.3.1: `drift` database setup, migration strategy
- Slice 0.3.2: Generic DAO base class
- Slice 0.3.3: Cache invalidation policy (TTL-based)

#### Phase 0.4 — Offline-First Sync Engine
- Slice 0.4.1: Sync queue (pending operations stored in drift)
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
- Slice 1.1.2: JWT token storage (`flutter_secure_storage`)
- Slice 1.1.3: Token refresh logic in interceptor
- Slice 1.1.4: Logout + token revocation

#### Phase 1.2 — Multi-Factor & SSO
- Slice 1.2.1: TOTP/OTP input screen
- Slice 1.2.2: OAuth2 PKCE flow (`oauth2` package)
- Slice 1.2.3: Biometric unlock (`local_auth`)

#### Phase 1.3 — Role-Based Access Control (RBAC)
- Slice 1.3.1: Permission model (roles, scopes) from API
- Slice 1.3.2: Permission-aware route guard
- Slice 1.3.3: Widget-level permission gating (`PermissionGuard` widget)

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
- Slice 5.3.1: Download item master to local drift DB
- Slice 5.3.2: Queue scanned transactions offline
- Slice 5.3.3: Batch sync on reconnect

---

### MODULE 6 — Sales & CRM

#### Phase 6.1 — Customer Management
- Slice 6.1.1: Customer list + detail
- Slice 6.1.2: Contact management (linked contacts per customer)
- Slice 6.1.3: Customer activity timeline

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

#### Phase 9.2 — System Config (Admin)
- Slice 9.2.1: User management (admin only, RBAC-gated)
- Slice 9.2.2: Role & permission editor
- Slice 9.2.3: API endpoint configuration (multi-tenant/environment)

#### Phase 9.3 — Security
- Slice 9.3.1: Session management (active devices list)
- Slice 9.3.2: Audit log viewer
- Slice 9.3.3: App PIN lock / biometric re-auth on resume

---

## Development Guardrails

### What TO do
- Keep BLoC events **immutable** (use `freezed`)
- One UseCase = one business action, no logic leakage into BLoC
- Repository interface lives in **domain**, never imports `dio` or `drift`
- All forms use a dedicated `FormBLoC` with field-level validation
- Write unit tests per slice before moving to the next
- Version your drift DB with explicit migrations from day one

### What NOT to do
- No business logic in widgets or ViewModels
- No direct API calls from BLoC — always through UseCase → Repository
- No `BuildContext` inside BLoC or ViewModel
- No hardcoded strings — always use l10n ARB keys
- No commercial/paid packages — validate every package on pub.dev for open-source license (MIT, BSD, Apache 2.0)
- Don't share BLoC instances across unrelated modules — use scoped BLoC providers

---

## Recommended Build Order

```
Phase 0 (Core) → Module 1 (Auth) → Module 2 (Dashboard)
   → Module 3 (Finance) + Module 4 (Procurement)  [parallel]
   → Module 5 (Inventory)
   → Module 6 (Sales)
   → Module 7 (HR) + Module 8 (Projects)  [parallel]
   → Module 9 (Settings)
```
