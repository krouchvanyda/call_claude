# ERP Mobile — Project Guide & Test Cases

> Single-doc overview of the entire **Enterprise ERP Mobile** app, with
> module-by-module reference + critical-path test cases. Cross-references:
> [`CLAUDE.md`](../CLAUDE.md) for slice-level history,
> [`ERP_MOBILE_DESIGN_GUIDE.md`](../ERP_MOBILE_DESIGN_GUIDE.md) for the
> visual spec, [`CHAT_MODULE_GUIDE.md`](./CHAT_MODULE_GUIDE.md) for the
> deep dive on Module 10, [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md)
> for the planned backgrounded-call work.

## Table of Contents

1. [Overview](#1-overview)
2. [Tech stack](#2-tech-stack)
3. [Architecture](#3-architecture)
4. [Running the app](#4-running-the-app)
5. [Modules at a glance](#5-modules-at-a-glance)
6. [Module-by-module reference + test cases](#6-module-by-module-reference--test-cases)
   - [Module 0 — Core Foundation](#module-0--core-foundation)
   - [Module 1 — Authentication & Identity](#module-1--authentication--identity)
   - [Module 2 — Dashboard & Home](#module-2--dashboard--home)
   - [Module 3 — Finance & Accounting](#module-3--finance--accounting)
   - [Module 4 — Procurement](#module-4--procurement)
   - [Module 5 — Inventory & Warehouse](#module-5--inventory--warehouse)
   - [Module 6 — Sales & CRM](#module-6--sales--crm)
   - [Module 7 — Human Resources](#module-7--human-resources)
   - [Module 8 — Project Management](#module-8--project-management)
   - [Module 9 — Settings & Administration](#module-9--settings--administration)
   - [Module 10 — Chat & Voice / Video](#module-10--chat--voice--video)
7. [Cross-cutting concerns](#7-cross-cutting-concerns)
8. [Known limitations & scope deferrals](#8-known-limitations--scope-deferrals)
9. [Cross-module smoke-test checklist](#9-cross-module-smoke-test-checklist)

---

## 1. Overview

**Enterprise ERP Mobile** is a cross-platform Flutter app that surfaces
the everyday operational workflows of an ERP system on phones and
tablets — for accountants, warehouse staff, HR managers, sales reps,
project managers, and admins. It's offline-aware, RBAC-gated, and built
as 11 vertical modules sharing a common shell.

### Status (as of this doc)

| Module | Implemented? | Notes |
|---|---|---|
| 0 — Core Foundation | ✅ | Networking, theme, DI, router, error handling |
| 1 — Authentication | ✅ | Login + OTP + biometric + forgot password |
| 2 — Dashboard | ✅ | KPIs, shortcuts, global search, notification center |
| 3 — Finance | ✅ | Chart of accounts, invoices, journals, trial balance |
| 4 — Procurement | ✅ | PR / PO / Goods Receipt / Vendors |
| 5 — Inventory | ✅ | Items, scanner, movements, transfers, cycle count |
| 6 — Sales | ✅ | Customers, quotations, orders, analytics |
| 7 — HR | ✅ | Employees, leave (with approval), attendance, payslips |
| 8 — Projects | ✅ | List, Kanban board, tasks, timesheets, utilization |
| 9 — Settings | ✅ | Profile, preferences, sessions, audit log, admin pages |
| 10 — Chat & Voice/Video | ✅ | LAN-relay demo — see [`CHAT_MODULE_GUIDE.md`](./CHAT_MODULE_GUIDE.md) |

All data is **in-memory + seeded** for the demo. Repositories expose the
same Stream / Future contracts a drift-backed or HTTP-backed
implementation would.

---

## 2. Tech stack

| Layer | Package | Notes |
|---|---|---|
| UI | Flutter / Material 3 | `flutter ">=3.35.0"`, Dart SDK `^3.9.2` |
| State | `flutter_bloc` + `equatable` | BLoC pattern for stateful pages |
| DI | `get_it` + `injectable` | Manual `register*Module(getIt)` per module |
| Routing | `go_router` + `page_transition` | Stateful shell with auth-aware redirects |
| Networking | `dio`, `connectivity_plus`, `pretty_dio_logger` | Plus `web_socket_channel` for chat |
| Local DB | `drift` + `sqlite3_flutter_libs` | Used by some modules; chat stays in-memory |
| Secure storage | `flutter_secure_storage` | JWT/refresh tokens only — never SQLite |
| Models | `freezed` + `json_serializable` | Immutable value classes |
| Camera / pickers | `mobile_scanner`, `image_picker` | Inventory scanner, chat / profile photos |
| Push (planned) | `firebase_messaging` + `flutter_local_notifications` | See [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md) |
| Auth helpers | `local_auth`, `oauth2`, `jwt_decoder` | Biometric, PKCE, token parsing |
| Charts | `fl_chart` | Sales analytics, utilization |
| Localization | `flutter_localizations` + `intl` | ARB-based, EN + KM scaffolded |

---

## 3. Architecture

### 3.1 MVVM + BLoC data flow

```
View (Flutter Widget)
   │  dispatches events to / listens to
   ▼
BLoC  (or ViewModel wrapping a BLoC)
   │  calls
   ▼
Repository (concrete — business rules live here)
   │  calls
   ▼
DataSource (Remote API via dio  /  Local DB via drift)
```

### 3.2 Two coexisting layouts

| Layout | Used by | Why |
|---|---|---|
| **Flat MVVM** (single concrete repo, no UseCase classes) | Module 10 (chat) + any new feature | Less ceremony, faster to iterate |
| **MVVM + Clean** (abstract repo + UseCase classes + concrete repo) | Modules 1–9 (legacy) | Original architectural choice; preserved to avoid pointless churn |

> **Rule:** never mix flat and layered styles inside the same feature.
> When editing Modules 1–9, follow their existing pattern. New work goes
> flat. (Documented in CLAUDE.md guardrails section.)

### 3.3 Folder layout

```
lib/
├── core/                       # cross-cutting infrastructure
│   ├── network/                # dio client, interceptors
│   ├── database/               # drift setup, base DAO
│   ├── di/                     # get_it wiring
│   ├── router/                 # go_router config + AppRouter.rootNavigatorKey
│   ├── theme/                  # AppTheme, AppRadii, AppLabel
│   └── error/                  # Failure, Either, exception mapping
│
├── features/                   # 11 module folders
│   └── <module>/
│       ├── data/               # datasources + models + concrete repo
│       ├── entities/           # value objects
│       └── presentation/
│           ├── bloc/           # events / states / blocs
│           ├── pages/          # screens
│           └── widgets/        # module-specific widgets
│
├── shared/                     # cross-module UI primitives
│   └── widgets/
│       ├── app_background_gradient.dart
│       ├── avatar_picker_sheet.dart
│       └── permission_guard.dart
│
└── main.dart
```

---

## 4. Running the app

### 4.1 Prerequisites

- Flutter `>=3.35.0` with Dart `^3.9.2`
- Android Studio + SDK (for Android builds)
- For Module 10 chat sync: a second device + the LAN relay (see
  [`tools/chat_relay/README.md`](../tools/chat_relay/README.md))

### 4.2 First-run flow

```bash
flutter pub get
flutter run --release   # release mode avoids dev-tool socket noise
```

Sequence the user sees on cold launch:

```
Splash (~900ms fade-in)
   │
   ▼
not signed in?  →  Login page  →  (stub) successful sign-in →  Dashboard
signed in + biometric_on?      →  Biometric Unlock           →  Dashboard
signed in + PIN policy?         →  PIN Lock                   →  Dashboard
signed in + valid token?        →  Dashboard
```

### 4.3 Seeded demo user

The login page has a single tap-to-sign-in path. After it succeeds, the
app loads:

| Field | Value |
|---|---|
| User id | `user-demo` |
| Name | `Demo Approver` |
| Role | `Administrator` |
| Email | `demo@erp.example` |
| Granted scopes | `finance.approve`, `hr.approve`, `procurement.approve`, `admin.users`, etc. (all modules) |

This user can access every screen. To test RBAC denial paths, the
identity switcher in the chat module is the only built-in way to swap
identities; deeper RBAC testing requires hand-editing seed permissions.

### 4.4 Navigation shell

Bottom navigation (mobile) — three sibling branches:

| Tab | Branch root |
|---|---|
| **Home** | `/dashboard` |
| **Modules** | `/modules` (grid of module shortcuts) |
| **Settings** | `/settings` |

The Chat module is reached through the Modules grid → Chat (or any
notification deep-link). Pre-auth routes (`/splash`, `/login`, `/mfa/otp`)
sit outside the shell.

---

## 5. Modules at a glance

| Module | Routes | Pages | Key dependencies |
|---|---|---|---|
| 1 Auth | `/login`, `/biometric-unlock`, `/mfa`, `/forgot-password` | 5 | `flutter_secure_storage`, `local_auth`, `dio` |
| 2 Dashboard | `/dashboard`, `/notifications`, `/search` | 4 | `fl_chart`, `connectivity_plus` |
| 3 Finance | `/finance/...` | 8 | `dio`, `drift` |
| 4 Procurement | `/procurement/...` | 10 | `dio`, `drift` |
| 5 Inventory | `/inventory/...` | 7 | `mobile_scanner`, `drift`, sync queue |
| 6 Sales | `/sales/...` | 11 | `fl_chart`, `image_picker` |
| 7 HR | `/hr/...` | 10 | `drift` |
| 8 Projects | `/projects/...` | 10 | drag/drop, `fl_chart`, custom Gantt painter |
| 9 Settings | `/settings/...` | 13 | `local_auth`, `flutter_secure_storage` |
| 10 Chat & Voice/Video | `/chat/...` | 8 | `web_socket_channel`, `image_picker`, `path_provider` |

---

## 6. Module-by-module reference + test cases

Each test follows the same shape used in the other docs:
- **Pre-conditions** — state required before running
- **Steps** — numbered mechanical actions
- **Expected** — what should happen, with timing
- **If it fails** — the most likely root cause

---

### Module 0 — Core Foundation

Infrastructure only — no user-facing screens. Provides:

- `dio` client with auth interceptor, error interceptor, connectivity check
- Drift database setup with migrations
- `get_it` DI container + per-module `register*Module(getIt)` helpers
- `go_router` configuration with auth redirect policy
- Theme tokens (`AppTheme`, `AppRadii`, `AppLabel`)
- `Failure` + `Either` for error handling
- Localization scaffolding (EN + KM)

No direct test cases — exercised implicitly by every module test below.
The router-level test that matters lives in [`auth_redirect_policy_test.dart`](../test/core/router/auth_redirect_policy_test.dart) if present.

---

### Module 1 — Authentication & Identity

**Pages:** [`login_page.dart`](../lib/features/auth/presentation/pages/login_page.dart),
[`biometric_unlock_page.dart`](../lib/features/auth/presentation/pages/biometric_unlock_page.dart),
[`otp_entry_page.dart`](../lib/features/auth/presentation/pages/otp_entry_page.dart),
[`forgot_password_page.dart`](../lib/features/auth/presentation/pages/forgot_password_page.dart),
[`splash_page.dart`](../lib/features/auth/presentation/pages/splash_page.dart)

**Storage boundary:**

```
flutter_secure_storage:  access_token, refresh_token, PIN hash, biometric key
SQLite (cached_user):    id, name, email, avatar_url, biometric_on, last_login_at
SQLite (user_permissions): user_id, module, scope, cached_at
Memory only:             OTP code, PKCE verifier/challenge
```

#### TC-AUTH.1 Cold-start splash → dashboard for signed-in user

**Pre-conditions:** App freshly installed. (Or: cleared app data.)

**Steps:**
1. Launch app.
2. Tap the (stub) sign-in button on login.
3. Wait.

**Expected:** Splash fades in (~900 ms), login page replaces it, after
the demo sign-in succeeds the app router lands on `/dashboard`. Bottom
nav is visible.

**If it fails:**
- Stuck on splash → splash isn't replaced; check the auth-init logic.
- Login → dashboard never happens → `AuthSession` listenable not
  emitting; see `auth_session.dart`.

---

#### TC-AUTH.2 Biometric unlock on resume

**Pre-conditions:** Signed in once, `biometric_on` flag set in
`cached_user` (Slice 1.2.3 toggles it from Settings → My Profile).

**Steps:**
1. Close the app (don't sign out).
2. Re-launch.

**Expected:** Splash → `/biometric-unlock` (NOT login). System biometric
prompt appears. On success → `/dashboard`.

**If it fails:**
- Goes to login instead → `biometric_on` flag not persisted; check
  `MyProfileRepository.toggleBiometric()` writes through to drift.
- Biometric prompt never appears → `local_auth` integration not
  initialised, or device lacks enrolled biometric.

---

#### TC-AUTH.3 Forgot password — happy path

**Steps:**
1. Login page → tap "Forgot password?".
2. Enter `demo@erp.example` → tap Send.

**Expected:** Within ~1 s the button swaps to a green checkmark with
"Check your email" text. (Demo: no real email is sent.)

---

#### TC-AUTH.4 OTP entry — auto-advance + verify

**Pre-conditions:** Reach `/mfa` after sign-in (currently a manual nav).

**Steps:**
1. Type 6 digits.
2. Tap Verify.

**Expected:**
- Each digit auto-advances to the next input box.
- Delete key auto-retreats.
- Verify button is disabled until 6 digits are entered.
- On verify, transitions to `/dashboard` (demo accepts any 6 digits).

---

#### TC-AUTH.5 Logout wipes state

**Steps:**
1. From `/settings`, tap **Logout** at the bottom of the page.

**Expected:**
- App returns to `/login`.
- `flutter_secure_storage.deleteAll()` was called.
- `cached_user` row + `user_permissions` cleared from drift.
- Biometric prompt no longer appears on next launch.

---

### Module 2 — Dashboard & Home

**Pages:** [`dashboard_page.dart`](../lib/features/dashboard/presentation/pages/dashboard_page.dart),
[`notification_inbox_page.dart`](../lib/features/notifications/presentation/pages/notification_inbox_page.dart),
[`global_search_page.dart`](../lib/features/search/presentation/pages/global_search_page.dart),
[`modules_page.dart`](../lib/features/dashboard/presentation/pages/modules_page.dart)

#### TC-DASH.1 KPI cards render with sparkline + trend

**Steps:**
1. Sign in → Dashboard tab.

**Expected:** 2-column grid of KPI cards. Each shows:
- Module-colored icon circle
- Bold value
- Trend arrow + % (success or error colored)
- 40-px-tall sparkline (`fl_chart`)

LoadingShimmer placeholder shows for ~300 ms then resolves to live data
(seeded).

---

#### TC-DASH.2 Module shortcuts respect RBAC

**Steps:**
1. Dashboard → scroll to "Quick Access" → look at the shortcut grid.

**Expected:** Each tile is visible only if the demo user holds the
corresponding module scope. Tapping any tile navigates to that
module's landing route.

---

#### TC-DASH.3 Global search

**Steps:**
1. Tap the search icon (top-right of AppBar) → `/search`.
2. Type "INV-001".

**Expected:** Results group by module under section headers. Tap any
result → deep-links to its detail page. Empty query shows recent
searches.

---

#### TC-DASH.4 Notification inbox unread → mark-all read

**Steps:**
1. Tap the bell icon (notification badge shows N>0).
2. Notification Center opens; tap **Mark all read** in the AppBar.

**Expected:** All tiles lose their bold + primary left-border;
badge count on the bell becomes 0.

---

### Module 3 — Finance & Accounting

**Pages:** chart of accounts, account detail, invoice list / detail /
form, journal entries list / detail, trial balance.

**RBAC scopes used:** `finance.read`, `finance.write`, `finance.approve`.

#### TC-FIN.1 Chart of accounts — tree expand

**Steps:**
1. Modules → Finance → Chart of Accounts.

**Expected:**
- Account tree renders with type badges (Asset/Liability/Equity/Revenue/Expense).
- Tap a parent → children indent and reveal.
- Tap a leaf → Account Detail page opens with transactions list.

---

#### TC-FIN.2 Invoice list — filter chips

**Steps:**
1. Finance → Invoices.
2. Tap each chip: All / Draft / Pending / Approved / Rejected.

**Expected:** List filters in place (no reload spinner — state-only).
StatusChip on each row matches the active filter.

---

#### TC-FIN.3 Create invoice — line item dynamic + live total

**Steps:**
1. Invoices → **+ Create Invoice** FAB.
2. Pick a vendor.
3. Tap **+ Add Item** twice → fill 2 line items.

**Expected:** Total summary updates as you type. Save Draft persists to
SQLite (upsert), back-out preserves draft.

---

#### TC-FIN.4 Approve invoice — golden path

**Pre-conditions:** An invoice in `PENDING_APPROVAL` status. Demo user
holds `finance.approve`.

**Steps:**
1. Open the invoice detail.
2. Sticky bottom action row shows **Reject** + **Approve**.
3. Tap Approve → confirmation bottom sheet → Confirm.

**Expected:**
- Status chip animates to `APPROVED` (success).
- Action row hides.
- Invoice list re-renders the row's chip on return.
- SQLite `cached_invoices.status` updated; `approved_by` and `actioned_at`
  set.

**If offline:** Action enqueues to `sync_queue` (Phase 0.4.1); UI shows
the optimistic state. On reconnect, the queue drains.

---

#### TC-FIN.5 Reject invoice — mandatory reason

**Steps:**
1. From same invoice in `PENDING_APPROVAL`, tap **Reject**.

**Expected:** Bottom sheet with a 3-row reason TextField. Confirm button
disabled until the field is non-empty. On submit, status → `REJECTED`,
`rejected_reason` saved.

---

#### TC-FIN.6 Trial balance — period change + CSV export

**Steps:**
1. Finance → Trial Balance.
2. Change the month/year selector.
3. Tap the export icon.

**Expected:** Table re-fetches for the new period (LoadingShimmer
visible). CSV download triggers an OS share sheet with a `.csv` file
attached.

---

### Module 4 — Procurement

**Pages:** PR list / form / detail, PO list / detail, Goods Receipt
form, vendor list / detail / form / scorecard.

**RBAC scopes used:** `procurement.read`, `procurement.write`,
`procurement.approve`.

#### TC-PROC.1 Purchase Request — submit for approval

**Steps:**
1. Procurement → Purchase Requests → FAB **+ New Request**.
2. Fill cost center, approver, add 2 line items, tap Submit.

**Expected:** Request appears in the list with `PENDING_APPROVAL` chip.

---

#### TC-PROC.2 PR detail — approval timeline + action row

**Steps:**
1. Open a `PENDING_APPROVAL` PR.

**Expected:** Header card, line items table, ApprovalTimeline below.
Action row (Reject / Approve) shown only when status is pending AND user
has `procurement.approve`.

---

#### TC-PROC.3 Convert PR → PO

**Pre-conditions:** A PR in `APPROVED` status.

**Steps:**
1. Open the PR detail → menu → **Convert to PO**.

**Expected:** Pre-filled PO form opens with line items copied. On save,
a new PO appears in the PO list.

---

#### TC-PROC.4 Record goods receipt

**Pre-conditions:** A PO in `CONFIRMED` status.

**Steps:**
1. PO detail → **Record Goods Receipt** button.
2. Enter actual qty per line.

**Expected:** Variance badge appears per line (success / warning /
error). On confirm, PO's qty-received fields update; inventory
movements are written.

---

#### TC-PROC.5 Vendor scorecard

**Steps:**
1. Procurement → Vendors → tap a vendor → scroll to Performance.

**Expected:** Scorecard card shows on-time delivery %, quality rating
stars, total spend, active PO count.

---

### Module 5 — Inventory & Warehouse

**Pages:** items list, item detail, scanner, stock movement form, stock
transfer, cycle count, low-stock alerts.

#### TC-INV.1 Item catalog — low stock badge

**Steps:**
1. Inventory → Items.

**Expected:** Each tile shows a colored stock badge: success (above min),
warning (≤20% above min), error (below min, plus "LOW" label).

---

#### TC-INV.2 Barcode scan → result sheet

**Pre-conditions:** Camera permission granted.

**Steps:**
1. Inventory → tap the scanner FAB.
2. Point at a known barcode (or use a printed test code).

**Expected:**
- Camera preview fills the screen, dimmed outside the 240×240 frame.
- Scan line animates top→bottom.
- On detection, bottom sheet slides up showing item name, SKU, stock
  badge, and 3 action buttons (Goods Issue / Goods Receipt / Transfer).

**If it fails:**
- No camera preview → permission not granted; check `mobile_scanner`
  init.
- Scans but nothing happens → SKU not in `cached_items`; demo seed
  has a fixed list.

---

#### TC-INV.3 Goods issue — offline queue

**Pre-conditions:** Device offline (airplane mode).

**Steps:**
1. From scan result, tap **Goods Issue**.
2. Enter qty + reference.
3. Tap Confirm.

**Expected:**
- Item's stock qty updates optimistically (UI).
- A row is written to `sync_queue` with `operation: "stock.issue"`.
- The Sync status banner on Dashboard shows "X pending".
- On reconnect, the queue drains; status banner clears.

---

#### TC-INV.4 Stock transfer between warehouses

**Steps:**
1. Inventory → Transfer.
2. Pick from-warehouse + to-warehouse + 1+ items.
3. Confirm.

**Expected:** Both warehouses' qty fields update (subtract from source,
add to destination). Movement history shows two paired rows.

---

#### TC-INV.5 Cycle count — variance highlight

**Steps:**
1. Inventory → Cycle Count.
2. Enter actual qty for 5 items — 2 matching, 2 over, 1 under.

**Expected:** Real-time variance badge per row (green check / warning /
error icon). Footer counts "2 items have variances" (or similar).
SubmitCount button enabled when at least one entry exists.

---

### Module 6 — Sales & CRM

**Pages:** customer list / detail / form (Slices 6.1.4–6.1.5),
contact form, quotation list / form / detail, sales order list /
detail, sales analytics.

#### TC-SAL.1 Customer list — search + call action

**Steps:**
1. Sales → Customers.
2. Type a name in the search bar.
3. Tap the phone icon on a row.

**Expected:** List filters live. Phone icon launches the dialer with
the customer's number pre-filled (or shows it for tap-to-call).

---

#### TC-SAL.2 Create customer (Slice 6.1.4)

**Steps:**
1. Customers → FAB **+ Add Customer**.
2. Fill Identity (name + Company/Individual segmented).
3. Fill Contact (phone + email).
4. Tap the avatar circle → pick a photo.
5. Set Commercial Terms (payment terms, credit limit, currency).
6. Optionally add a contact under "Contacts".
7. Tap **Create Customer**.

**Expected:** Navigates to Customer Detail (Screen 6.2) showing the new
record. Inbox/list also reflects.

---

#### TC-SAL.3 Edit customer — discard confirmation when dirty (Slice 6.1.5)

**Steps:**
1. Customer Detail → AppBar edit.
2. Change the name.
3. Tap **Discard** in the AppBar.

**Expected:** Confirmation dialog "Discard unsaved changes?". Cancel
returns to edit; Discard pops back to detail without saving.

---

#### TC-SAL.4 Quotation form — live total

**Steps:**
1. Sales → Quotations → **+ New Quotation**.
2. Pick a customer.
3. Add 2 line items with qty / price / discount / tax.

**Expected:** Subtotal / Discount / Tax / TOTAL update reactively as
each field changes.

---

#### TC-SAL.5 Sales order fulfillment stepper

**Steps:**
1. Sales → Orders → open an order.

**Expected:** Fulfillment stepper renders the 4 states:
`Confirmed → Picking → Shipped → Delivered`. Active stage uses primary
color; done stages show a checkmark.

---

#### TC-SAL.6 Sales analytics — period toggle

**Steps:**
1. Sales → Analytics.
2. Tap each Period chip: Week / Month / Quarter / Year.

**Expected:** Revenue chart re-renders with the new period's data.
Top customers and sales rep leaderboard also re-fetch.

---

### Module 7 — Human Resources

**Pages:** employee list / detail, org chart, leave request form,
leave list, leave approvals list + detail (Slice 7.2.4), attendance,
payslip detail / list.

#### TC-HR.1 Employee directory — filter by department

**Steps:**
1. HR → Employees.
2. Tap the department dropdown → pick one.

**Expected:** List filters in place.

---

#### TC-HR.2 Submit a leave request

**Steps:**
1. HR → My Leaves → FAB **+ Request Leave**.
2. Pick leave type, date range (calendar updates day-count), reason.
3. Submit.

**Expected:** Request appears in My Leaves list with `PENDING`
chip. Balance preview reflects the working-day count.

---

#### TC-HR.3 Leave approval detail (Slice 7.2.4)

**Pre-conditions:** Demo user has `hr.approve` scope. At least one
leave request in `PENDING_APPROVAL`.

**Steps:**
1. HR → Leave Approvals → tap a pending request.

**Expected:**
- Employee context card (avatar, name, dept, remaining days)
- Request detail (type, dates, working days, submitted timestamp)
- Reason card
- Balance preview ("If approved: X days remaining")
- Approval timeline (if prior actions exist)
- Sticky action row: **Reject** (outlined error) + **Approve** (filled success)

---

#### TC-HR.4 Approve leave — write + return

**Steps:**
1. From TC-HR.3, tap Approve → confirmation bottom sheet → Confirm.

**Expected:**
- Status updates to `APPROVED` in `cached_leave_requests`.
- `approved_by` + `actioned_at` set.
- Pops back to Leave Approvals list; pending badge count drops by 1;
  success snackbar shown.

---

#### TC-HR.5 Clock in/out

**Steps:**
1. HR → Attendance.
2. Tap the large **Clock In** button.

**Expected:** Button label swaps to **Clock Out** (error color); start
time captured; elapsed-time counter starts ticking. Clock-out writes
end time and total hours.

---

#### TC-HR.6 Payslip viewer + PDF

**Steps:**
1. HR → Payslips → tap a month chip.

**Expected:** Net pay card shows large primary-colored amount. Earnings
+ Deductions cards expanded. Tap **View PDF** opens the OS PDF viewer.

---

### Module 8 — Project Management

**Pages:** project list / detail / form (Slice 8.1.4), Kanban board,
task detail / form (8.1.5) / assign (8.1.6), timesheet form / list,
utilization.

#### TC-PRJ.1 Create a project (Slice 8.1.4)

**Steps:**
1. Projects → FAB **+ New Project**.
2. Fill name, description, timeline (live "X weeks" computed), budget
   + billing type, project manager, team members, status, priority.
3. Save.

**Expected:** Navigates to Project Detail. Newly created project shows
on the list.

---

#### TC-PRJ.2 Kanban drag-and-drop

**Steps:**
1. Project detail → Board tab.
2. Long-press a card → drag from "To Do" to "In Progress".

**Expected:** Card lands in the new column; `cached_tasks.status`
updates; column count badges adjust.

---

#### TC-PRJ.3 Assign task — workload-aware picker (Slice 8.1.6)

**Steps:**
1. Open a task → AppBar → **Assign / Reassign**.
2. Look at the member list.

**Expected:** Each row shows the member's open-task count badge
(infoContainer ≤3, warningContainer 4–6, errorContainer 7+) and an
availability dot. Selecting a member + tapping Assign updates the
task. Push notification dispatched to the new assignee.

---

#### TC-PRJ.4 Timesheet entry

**Steps:**
1. Projects → Timesheets → current week.
2. Tap a cell → enter hours → confirm.

**Expected:** Cell shows the hours value; daily + weekly totals at the
bottom update reactively. Submit posts the week.

---

#### TC-PRJ.5 Utilization chart

**Steps:**
1. Projects → Utilization → change Period.

**Expected:** Bar chart shows one bar per team member with target line
overlaid. Above-target bars use success color, below uses warning.
Member list below shows hours + utilization % bar per row.

---

### Module 9 — Settings & Administration

**Pages:** settings home, appearance (theme), language, notification
preferences, my profile (Slice 9.1.4), my roles (Slice 9.1.5),
sessions, audit log, user management, role editor, API config,
app lock / PIN.

#### TC-SET.1 Theme toggle — Light / Dark / System

**Steps:**
1. Settings → Appearance.
2. Tap each option in the segmented control.

**Expected:** Theme changes instantly across the app. The choice
persists across restarts.

---

#### TC-SET.2 Language switch — EN ↔ KM

**Steps:**
1. Settings → Language.
2. Pick the other locale.

**Expected:** App strings refresh immediately (no restart needed).
ARB lookup falls back to English for keys missing in Khmer.

---

#### TC-SET.3 My Profile — view + edit + avatar picker

**Steps:**
1. Settings → My Profile.
2. Tap the avatar (without entering Edit) → bottom sheet opens with
   Take photo / Choose from gallery [+ Remove photo if one is set].
3. Pick / take an image.

**Expected:**
- Hero card avatar updates immediately.
- Sheet wording: "Add a profile photo" when none set, "Change profile
  photo" when set, with the destructive Remove tile only when there's
  something to remove.
- Subtitle: "Photo only changes on this device."

**Slice references:** 9.1.4 (page), 10.3.5 (shared `AvatarPickerSheet`).

---

#### TC-SET.4 Change password requires re-auth

**Steps:**
1. My Profile → Account Security → **Change password**.

**Expected:** Re-auth sheet appears (PIN or biometric). On success,
change-password form opens.

---

#### TC-SET.5 My Roles & Permissions (Slice 9.1.5)

**Steps:**
1. Settings → My Roles & Permissions.

**Expected:** Read-only screen. Top card lists assigned roles as chips.
Search bar filters the granted/denied permission lists below. Granted
rows have a success checkmark; denied rows have a lock icon.

---

#### TC-SET.6 Sessions list — revoke

**Steps:**
1. Settings → Active Sessions.

**Expected:**
- Current device pinned at top in an `infoContainer` banner.
- Other sessions listed with device icon + last-active.
- Each row has a Revoke button (except current); tapping revokes that
  session.

---

#### TC-SET.7 Audit log — filter + detail sheet

**Steps:**
1. Settings → Audit Log.
2. Tap a row.

**Expected:** Bottom sheet opens with full action description, record
reference (tappable deep-link), and a raw payload monospace pane.

---

#### TC-SET.8 PIN lock on resume

**Pre-conditions:** Settings → Security → PIN lock enabled.

**Steps:**
1. Press home → screen off for 30+ seconds.
2. Re-open the app.

**Expected:** App routes to `/lock`. PIN pad shown. Wrong PIN → dots
shake, attempts remaining counter. Correct PIN → returns to last route.

---

#### TC-SET.9 User management (admin only — RBAC gate)

**Steps:**
1. Settings → User Management.

**Expected:** Visible only if user has `admin.users` scope. Each row
shows avatar + email + role chip + active/inactive badge. Overflow menu
offers Edit role / Reset password / Deactivate.

---

### Module 10 — Chat & Voice / Video

Module 10 has its own dedicated doc with 70+ test cases:

→ **[`CHAT_MODULE_GUIDE.md`](./CHAT_MODULE_GUIDE.md)**

Highlights:
- Real-time text/image/voice messaging across 3 devices via LAN relay
- Direct + group conversations
- Voice + video call signalling state machine (no real audio/video)
- Group calls with independent accept, multi-party hangup, last-callee
  auto-end
- Telegram-style inline call history on the chat timeline
- Group avatar sync across devices (base64 broadcast)
- Profile rename sync

What's deferred:
- Backgrounded/killed-app call delivery → see [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md)
- Real WebRTC audio/video
- Binary file / image / voice transfer (only metadata syncs today)

---

## 7. Cross-cutting concerns

### 7.1 RBAC & permission gating

| Layer | How it works |
|---|---|
| Route-level | `RouteAccess` table maps each path → required `Permission`; `AppRouter` redirect checks `PermissionsSnapshot.holds(perm)` |
| Widget-level | `PermissionGuard(scope: 'finance.approve', child: ...)` from `lib/shared/widgets/permission_guard.dart` — renders nothing (or a disabled state) if the user lacks the scope |
| Repo-level | UseCase / repo throws `PermissionFailure` if invoked without the scope (defense in depth) |

`PermissionsSnapshot` is an in-memory mirror of the drift
`user_permissions` table — refreshes on login + on permission edit.

#### TC-RBAC.1 Forbidden action is invisible

**Pre-conditions:** Identity without `finance.approve`.

**Steps:**
1. Open an invoice in `PENDING_APPROVAL`.

**Expected:** Sticky action row (Approve/Reject) does NOT render. The
status chip is visible but no actions are offered.

---

#### TC-RBAC.2 Forbidden route falls back to /forbidden

**Steps:**
1. Manually deep-link to `/settings/admin/users` as a non-admin
   (`adb shell am start -W -a android.intent.action.VIEW -d "app://settings/admin/users"`).

**Expected:** Lands on `/forbidden` page with shell intact. Bottom nav
still works for recovery.

---

### 7.2 Offline sync engine

| Component | File | Purpose |
|---|---|---|
| Sync queue | drift `sync_queue` table | Pending operations stored when offline |
| Conflict resolution | `SyncEngine` | last-write-wins or server-wins (configurable) |
| Trigger | `connectivity_plus` listener | Drain queue on connectivity restore |
| UI surface | `SyncStatusBLoC` + Dashboard banner | "X pending" warning |

#### TC-SYNC.1 Action persists offline + drains on reconnect

**Steps:**
1. Airplane mode on.
2. Approve an invoice (TC-FIN.4 flow).
3. Verify optimistic UI updated; Sync banner says "1 pending".
4. Airplane mode off.

**Expected:** Within 5 s, banner clears. Invoice status confirmed
server-side (no rollback). If server rejects, optimistic state reverts.

---

### 7.3 Theming & design tokens

| Token | File | Notes |
|---|---|---|
| `AppTheme.light()` / `dark()` | `core/theme/app_theme.dart` | ColorScheme.fromSeed(0xFF3B4FE8) |
| `AppRadii` | `core/theme/app_radii.dart` | `sm/md/lg/xl/pill` |
| `AppLabel` | `core/theme/app_label.dart` | Inter font, fixed text-style sizes |
| `AppSpacing` | `core/theme/app_spacing.dart` | `xs(4)/sm(8)/md(16)/lg(24)/xl(32)/xxl(48)` |

Rule: never hardcode colors / sizes / fonts in pages — always reference
the token. See CLAUDE.md guardrails.

---

### 7.4 Localization

- ARB files under `lib/l10n/` (EN seeded; KM scaffolded with English
  fallbacks).
- `flutter_localizations` + `intl` for plurals/date formats.
- All user-visible strings should be ARB keys, never hardcoded.

---

## 8. Known limitations & scope deferrals

| Area | Limitation | Tracked in |
|---|---|---|
| Backgrounded calls | No FCM/APNs wake-up — calls in background show as missed | [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md) |
| Real audio/video | No WebRTC — call timer ticks but no media flows | CLAUDE.md slice 10.2.3 comment |
| Image/voice/file binaries | Only metadata syncs; bytes don't transfer between devices | CLAUDE.md slice 10.1.5 |
| Group avatar bytes | Base64 over WebSocket works for small images; needs upload endpoint for production | CLAUDE.md slice 10.3.6 |
| Persistence | Most modules use in-memory seeds with stream contracts shaped like drift repos | Per module |
| Auth | Demo sign-in only — no real OAuth / OIDC integration | Module 1 |
| iOS calls | CallKit + PushKit not wired | Future epic |
| Tests | `widget_tester.dart` is commented out in local Flutter 3.35.7 SDK — widget tests can't run locally | User memory `feedback_flutter_sdk_broken` |

---

## 9. Cross-module smoke-test checklist

Run after any cross-cutting change (auth, router, theme, DI). ~15
minutes total.

**Auth & shell**
- [ ] Cold-start lands on `/dashboard` if signed in (TC-AUTH.1)
- [ ] Logout → `/login`, all state cleared (TC-AUTH.5)
- [ ] Bottom-nav switches between Home / Modules / Settings smoothly

**Dashboard**
- [ ] KPI cards render with sparkline (TC-DASH.1)
- [ ] Notification badge clears on Mark all read (TC-DASH.4)

**Critical-path approvals**
- [ ] Approve an invoice (TC-FIN.4)
- [ ] Reject a PR with reason (TC-PROC.2 + Reject flow)
- [ ] Approve a leave request (TC-HR.4)

**Inventory operations**
- [ ] Scan → result sheet (TC-INV.2)
- [ ] Stock transfer + cycle count both write to history

**Forms**
- [ ] Create customer + edit → discard dialog (TC-SAL.2 + TC-SAL.3)
- [ ] Create project + assign task (TC-PRJ.1 + TC-PRJ.3)

**Settings**
- [ ] Theme switch instant; persists across restart (TC-SET.1)
- [ ] My Profile avatar picker (TC-SET.3) — covers shared `AvatarPickerSheet`
- [ ] Audit log + sessions both load (TC-SET.6, TC-SET.7)

**Chat (Module 10)**
- [ ] 3-device smoke from [`CHAT_MODULE_GUIDE.md` §6](./CHAT_MODULE_GUIDE.md#6-smoke-test-checklist)

**RBAC**
- [ ] Approve buttons hidden for users without the scope (TC-RBAC.1)
- [ ] Manual deep-link to admin route as non-admin → `/forbidden`
      (TC-RBAC.2)

---

> **Where to add new tests**: keep them in the module section of this
> doc with the same Pre-conditions / Steps / Expected / If-it-fails
> shape. Cross-module flows go in §9. Module 10 stays in
> [`CHAT_MODULE_GUIDE.md`](./CHAT_MODULE_GUIDE.md).
