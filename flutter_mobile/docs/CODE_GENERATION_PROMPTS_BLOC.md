# Code Generation Prompts — ERP Mobile (BLoC + API edition)

> Use this document to prompt an AI (Claude, Cursor, Copilot, …) to
> generate code for **this** project.
>
> **No `get_it`, no `injectable`** — DI flows through `RepositoryProvider`
> + `BlocProvider` from `flutter_bloc`. Repositories are built at
> `main.dart` and provided at the app root; BLoCs receive them via
> `context.read<X>()`.
>
> Paste the sections you need into your prompt; they encode this
> project's architectural rules, design tokens, file conventions, API
> integration shape, and UI field specs so the AI doesn't have to guess.

---

## Table of contents

1. [How to use this doc](#1-how-to-use-this-doc)
2. [Project context block (paste this always)](#2-project-context-block-paste-this-always)
3. [Architectural rules](#3-architectural-rules)
4. [Wiring without `get_it`](#4-wiring-without-get_it)
5. [API integration pattern](#5-api-integration-pattern)
6. [BLoC contract shape](#6-bloc-contract-shape)
7. [UI field reference (detailed specs per control)](#7-ui-field-reference-detailed-specs-per-control)
8. [Common task templates](#8-common-task-templates)
   - [8.1 New feature module from scratch (page + BLoC + repo + API)](#81-new-feature-module-from-scratch-page--bloc--repo--api)
   - [8.2 List page with filter chips and search](#82-list-page-with-filter-chips-and-search)
   - [8.3 Detail page with header card and sections](#83-detail-page-with-header-card-and-sections)
   - [8.4 Form page with field validation and save](#84-form-page-with-field-validation-and-save)
   - [8.5 Approval flow with modal sheet](#85-approval-flow-with-modal-sheet)
9. [Anti-patterns to reject](#9-anti-patterns-to-reject)
10. [Output verification checklist](#10-output-verification-checklist)
11. [Reference snippets](#11-reference-snippets)
12. [Module + screen catalog (all 72 screens)](#12-module--screen-catalog-all-72-screens)
13. [Wire field reference (API field → UI location)](#13-wire-field-reference-api-field--ui-location)
    - [12.0 Module 0 — App Entry](#120-module-0--app-entry)
    - [12.1 Module 1 — Authentication & Identity](#121-module-1--authentication--identity)
    - [12.2 Module 2 — Dashboard & Home](#122-module-2--dashboard--home)
    - [12.3 Module 3 — Finance & Accounting](#123-module-3--finance--accounting)
    - [12.4 Module 4 — Procurement](#124-module-4--procurement)
    - [12.5 Module 5 — Inventory & Warehouse](#125-module-5--inventory--warehouse)
    - [12.6 Module 6 — Sales & CRM](#126-module-6--sales--crm)
    - [12.7 Module 7 — Human Resources](#127-module-7--human-resources)
    - [12.8 Module 8 — Project Management](#128-module-8--project-management)
    - [12.9 Module 9 — Settings & Administration](#129-module-9--settings--administration)
    - [12.10 Module 10 — Chat & Voice / Video](#1210-module-10--chat--voice--video)

---

## 1. How to use this doc

1. Open the section that matches your task (e.g. "List page" or "Form page").
2. Copy the **project context block** (§2) plus the **task template** (§8).
3. Paste into your AI prompt, fill the `{{placeholders}}`, and let it generate.
4. Run the **verification checklist** (§10) before merging.

The templates produce code that compiles against this repo's existing
conventions (theme tokens, label widget, route paths, error mapper). They
do NOT pull in `get_it`, `injectable`, `build_runner`, or any code-gen.

---

## 2. Project context block (paste this always)

```text
PROJECT
- Flutter (Dart) enterprise ERP mobile app.
- Backend: Spring Boot 3.3 + PostgreSQL. Every endpoint wraps payloads in
  ApiResponse<T>: { success, message, data, errorCode, traceId }.
- State management: flutter_bloc (BLoC pattern).
- DI: NO service locator. Repositories built in main.dart and provided
  at the root via MultiRepositoryProvider; BLoCs created via BlocProvider
  with context.read<RepositoryX>().
- HTTP: dio with an AuthInterceptor that attaches Bearer tokens from
  flutter_secure_storage.
- Local DB: drift (SQLite). Tokens never in SQLite — always
  flutter_secure_storage.
- Navigation: go_router.
- Architecture: flat MVVM for new code (one concrete repository, no
  abstract interface, no UseCase classes). Modules 1–9 still ship the
  older Clean Architecture (usecases + abstract repos) — keep that
  convention only when editing those modules.

DESIGN TOKENS (must use, never hardcode)
- AppTheme         — colors
- AppLabel         — text styles  (replaces raw TextStyle)
- AppFontSize      — typography sizes (value11 / value12 / value14 / value18 / etc.)
- AppSpacing       — xs(4) / sm(8) / md(16) / lg(24) / xl(32) / xxl(48)
- AppRadii         — sm(8) / md(12) / lg(16) / xl(24) / pill(999)
- AppCard          — every content block (never raw Container)
- StatusChip       — every status pill
- EmptyState       — every empty list
- LoadingScreen    — every loading state (never bare CircularProgressIndicator)
- PermissionGuard  — every admin-only action

ROUTING
- Pre-auth pages (splash/login/register) push via context.goNamed.
- Within-shell sub-page pushes (Settings → My Profile, etc.) use
  ConfigRouter.pushPageAnimation(context, Page()).

FAILURE TYPES (lib/core/error/failure.dart)
- Failure.network / timeout / server / unauthorized / forbidden /
  notFound / validation / conflict / rateLimited / cancelled / unknown.
- Repositories return Result<T> = Either<Failure, T>.

L10N
- All UI strings use l10n keys from lib/l10n/app_*.arb. After adding a
  key, run `flutter gen-l10n` (auto-runs on hot reload too).
```

---

## 3. Architectural rules

### What TO do

- Keep BLoC events **immutable** (use `freezed` or plain `final` records).
- Business rules live in the Repository (or, when stateful, the BLoC) — not in widgets.
- Repository is a single concrete class; it owns the `dio` / `drift` calls directly.
- All forms use a dedicated `FormBloc` (or a feature BLoC with form sub-state) for validation.
- Pass dependencies via constructor; provide at app root with `RepositoryProvider`.
- One BLoC per page (or per logical state slice). Scope it with `BlocProvider`.
- Use `buildWhen` on every `BlocBuilder` so unrelated state changes don't rebuild the whole screen.

### What NOT to do

- ❌ No `get_it`, `injectable`, `@lazySingleton`, `@module`, or `GetIt.I<X>()`.
- ❌ No `build_runner` for DI. (`freezed`/`json_serializable` for models is fine.)
- ❌ No business logic in widgets or ViewModels.
- ❌ No direct API calls from BLoC — always through the Repository.
- ❌ No `BuildContext` inside a BLoC or Repository.
- ❌ No hardcoded strings, colors, sizes, or fonts.
- ❌ No raw `Container` as a content block — use `AppCard`.
- ❌ No `CircularProgressIndicator` standalone — use `LoadingScreen`.

---

## 4. Wiring without `get_it`

### `main.dart` builds the graph

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Infrastructure singletons ─────────────────────────────────
  const secrets = FlutterSecureStorage();
  final tokenStorage = SecureTokenStorage(secrets);
  final dio = Dio(BaseOptions(
    baseUrl: Environments.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ))
    ..interceptors.add(AuthInterceptor(storage: tokenStorage));

  // ── Data sources ──────────────────────────────────────────────
  final authRemote = AuthRemoteDataSource(dio: dio);
  final customersRemote = CustomersRemoteDataSource(dio: dio);
  // … one line per data source

  // ── Repositories ──────────────────────────────────────────────
  final authRepo = AuthRepository(
    tokenStorage: tokenStorage,
    remote: authRemote,
  );
  final customersRepo = CustomersRepository(remote: customersRemote);

  runApp(AppRoot(
    authRepo: authRepo,
    customersRepo: customersRepo,
  ));
}
```

### App root provides them to the widget tree

```dart
class AppRoot extends StatelessWidget {
  const AppRoot({
    super.key,
    required this.authRepo,
    required this.customersRepo,
  });

  final AuthRepository authRepo;
  final CustomersRepository customersRepo;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepo),
        RepositoryProvider<CustomersRepository>.value(value: customersRepo),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter().config,
        // …
      ),
    );
  }
}
```

### Pages scope their BLoC with `BlocProvider`

```dart
class CustomersListPage extends StatelessWidget {
  const CustomersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CustomersListBloc(
        repo: ctx.read<CustomersRepository>(), // ← DI without get_it
      )..add(const CustomersListLoaded()),
      child: const _CustomersListView(),
    );
  }
}
```

**Rule of thumb:** if a repository is needed in more than one page, register
it at the app root. If it's only used by one BLoC tree, register it via a
`RepositoryProvider` higher up in that BLoC's scope.

---

## 5. API integration pattern

Every endpoint follows the same four-layer flow:

```
HTTP wire
   ↓ Dio
DataSource (concrete class) ── translates HTTP ↔ DTO via ApiEnvelope
   ↓
Repository (concrete class) ── translates DTO ↔ Entity, wraps in Result<T>
   ↓
BLoC                         ── translates Result → state
   ↓
Page                          ← rebuilds via BlocBuilder
```

### Step 1 — Response DTO (`features/{module}/data/models/{x}_dto.dart`)

Tolerant parser; accepts multiple field-name aliases the backend
might ship.

```dart
class CustomerDto {
  const CustomerDto({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime? createdAt;

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    String? firstString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    DateTime? parseDate(String key) {
      final raw = json[key];
      if (raw == null) return null;
      try { return DateTime.parse(raw.toString()); } catch (_) { return null; }
    }

    return CustomerDto(
      id: (json['id'] ?? '').toString(),
      fullName: firstString(['fullName', 'name', 'displayName']) ?? '',
      email: firstString(['workEmail', 'email']),
      phone: firstString(['phone', 'phoneNumber']),
      createdAt: parseDate('createdAt'),
    );
  }
}
```

### Step 2 — Request DTO (`features/{module}/data/models/{x}_requests.dart`)

Only serialise fields the caller actually set; null = "leave untouched".

```dart
class UpdateCustomerRequest {
  const UpdateCustomerRequest({this.fullName, this.email, this.phone});

  final String? fullName;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    void put(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        json[key] = value.trim();
      }
    }
    put('fullName', fullName);
    put('email', email);
    put('phone', phone);
    return json;
  }
}
```

### Step 3 — DataSource (`features/{module}/data/datasources/{x}_remote_data_source.dart`)

Plain class — no `abstract` interface unless you have multiple
implementations to swap (rare in this codebase).

```dart
class CustomersRemoteDataSource {
  CustomersRemoteDataSource({required Dio dio}) : _dio = dio;

  static const String basePath = '/customers';
  final Dio _dio;

  Future<PageResponse<CustomerDto>> list({int page = 1, int pageSize = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      basePath,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return ApiEnvelope.parse(
      res.data!,
      (data) => PageResponse.fromJson<CustomerDto>(data, CustomerDto.fromJson),
    );
  }

  Future<CustomerDto> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('$basePath/$id');
    return ApiEnvelope.parse(res.data!, CustomerDto.fromJson);
  }

  Future<CustomerDto> update(String id, UpdateCustomerRequest body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '$basePath/$id',
      data: body.toJson(),
    );
    return ApiEnvelope.parse(res.data!, CustomerDto.fromJson);
  }
}
```

### Step 4 — Repository (`features/{module}/data/repositories/{x}_repository.dart`)

Translates DTOs to Entities and wraps everything in `Result<T>`.

```dart
class CustomersRepository {
  CustomersRepository({required CustomersRemoteDataSource remote})
      : _remote = remote;

  final CustomersRemoteDataSource _remote;

  Future<Result<List<Customer>>> list({int page = 1, int pageSize = 20}) async {
    try {
      final page = await _remote.list(page: page, pageSize: pageSize);
      return ok(page.items.map(_toDomain).toList(growable: false));
    } on DioException catch (e) {
      return err(failureFromDioException(e));
    } on ApiEnvelopeException catch (e) {
      return err(Failure.server(message: e.message));
    }
  }

  Customer _toDomain(CustomerDto d) => Customer(
        id: d.id,
        fullName: d.fullName,
        email: d.email ?? '',
        phone: d.phone ?? '',
        createdAt: d.createdAt,
      );
}
```

### Step 5 — Entity (`features/{module}/entities/{x}.dart`)

Pure Dart, no Flutter, no annotations.

```dart
class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? createdAt;
}
```

---

## 6. BLoC contract shape

### Events (immutable)

```dart
sealed class CustomersListEvent {
  const CustomersListEvent();
}

class CustomersListLoaded extends CustomersListEvent {
  const CustomersListLoaded();
}

class CustomersFilterChanged extends CustomersListEvent {
  const CustomersFilterChanged(this.status);
  final CustomerStatus status;
}

class CustomersSearchChanged extends CustomersListEvent {
  const CustomersSearchChanged(this.query);
  final String query;
}
```

### States (sealed → exhaustive switch)

```dart
sealed class CustomersListState {
  const CustomersListState();
}

class CustomersListInitial extends CustomersListState { const CustomersListInitial(); }
class CustomersListLoading extends CustomersListState { const CustomersListLoading(); }

class CustomersListReady extends CustomersListState {
  const CustomersListReady({
    required this.all,
    required this.filter,
    required this.query,
  });
  final List<Customer> all;
  final CustomerStatus filter;
  final String query;

  List<Customer> get visible => all
      .where((c) => filter == CustomerStatus.all || c.status == filter)
      .where((c) => query.isEmpty || c.fullName.toLowerCase().contains(query.toLowerCase()))
      .toList(growable: false);
}

class CustomersListFailure extends CustomersListState {
  const CustomersListFailure(this.failure);
  final Failure failure;
}
```

### BLoC

```dart
class CustomersListBloc extends Bloc<CustomersListEvent, CustomersListState> {
  CustomersListBloc({required CustomersRepository repo})
      : _repo = repo,
        super(const CustomersListInitial()) {
    on<CustomersListLoaded>(_onLoaded);
    on<CustomersFilterChanged>(_onFilterChanged);
    on<CustomersSearchChanged>(_onSearchChanged);
  }

  final CustomersRepository _repo;

  Future<void> _onLoaded(_, Emitter<CustomersListState> emit) async {
    emit(const CustomersListLoading());
    final result = await _repo.list();
    emit(result.fold(
      (f) => CustomersListFailure(f),
      (list) => CustomersListReady(
        all: list,
        filter: CustomerStatus.all,
        query: '',
      ),
    ));
  }

  void _onFilterChanged(CustomersFilterChanged e, Emitter emit) {
    final s = state;
    if (s is CustomersListReady) {
      emit(CustomersListReady(all: s.all, filter: e.status, query: s.query));
    }
  }

  void _onSearchChanged(CustomersSearchChanged e, Emitter emit) {
    final s = state;
    if (s is CustomersListReady) {
      emit(CustomersListReady(all: s.all, filter: s.filter, query: e.query));
    }
  }
}
```

---

## 7. UI field reference (detailed specs per control)

> Every form field in this project follows ONE of these eight patterns.
> Each spec lists: visual shape, controller management, validation,
> error display, l10n keys, and the BLoC integration.

### 7.1 Text input — `_TextInputField`

**Use for:** single-line text (name, code, search).

```
┌──────────────────────────────────────────┐
│ [icon] Label                             │
│ ┌──────────────────────────────────────┐ │
│ │ Hint text…                          │ │ ← TextField, surfaceVariant fill
│ └──────────────────────────────────────┘ │
│ Helper text (or error if invalid)        │
└──────────────────────────────────────────┘
```

**Spec:**
- Outer: `AppCard` with `AppSpacing.md` padding, `AppRadii.md`.
- `TextField` with:
  - `controller`: held at state level (survive rebuilds, keep caret position).
  - `decoration: InputDecoration`:
    - `labelText`: from l10n (e.g. `l10n.customerFormNameLabel`).
    - `hintText`: from l10n.
    - `prefixIcon`: optional `Icon` from Material set.
    - `filled: true`, `fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)`.
    - `border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide.none)`.
    - `errorText`: derived from BLoC state's `fieldErrors[fieldKey]`.
  - `keyboardType`: `TextInputType.text` / `.emailAddress` / `.phone` / `.number`.
  - `textInputAction`: `.next` for forms (advances focus); `.done` on last field.
  - `onChanged`: dispatches `FieldChanged(key, value)` to the BLoC.
- Helper text below the field: `AppLabel(text: helper, fontSize: AppFontSize.value12, color: theme.colorScheme.onSurfaceVariant)`.
- Error text replaces helper when present: same widget, color `theme.colorScheme.error`.

**Validation triggers:** on blur (default) AND on submit. BLoC owns the rules.

### 7.2 Multi-line text — `_MultilineField`

**Use for:** description, address, notes.

Same as 7.1 but with:
- `minLines: 2, maxLines: 6` (auto-expand).
- `textInputAction: TextInputAction.newline`.
- `keyboardType: TextInputType.multiline`.

### 7.3 Email / phone / numeric — `_TypedInputField`

Same as 7.1 with the right `keyboardType`:
- Email: `TextInputType.emailAddress` + validator checking `@` and `.`.
- Phone: `TextInputType.phone` + only allow `[0-9 +\-()]`.
- Numeric: `TextInputType.number` + `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`.

For currency: prefix with `Text(currencySymbol)` inside `prefixIcon` slot.

### 7.4 Picker — `_DropdownField`

**Use for:** picking one of N known options (role, status, country).

```
┌──────────────────────────────────────────┐
│ [icon] Label                       ▾     │
└──────────────────────────────────────────┘
```

**Spec:**
- `DropdownButtonFormField<T>` (NOT `DropdownButton` directly — needs the form decoration).
- `isExpanded: true` so it fills the column width.
- `initialValue`: from BLoC state, NOT held at widget level.
- `items`: list of `DropdownMenuItem<T>` with:
  - leading `Icon` (optional)
  - `AppLabel(text: option.label, fontSize: AppFontSize.value14, fontWeight: FontWeight.w700, maxLines: 1, overflow: TextOverflow.ellipsis)` wrapped in `Flexible`.
  - optional trailing badge (e.g. SYSTEM chip).
- `onChanged`: dispatches event to BLoC.
- `hint`: shown when value is null; uses l10n.
- `decoration: InputDecoration(labelText: …, prefixIcon: …, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)))`.

**Disabling:** pass `null` to `onChanged` to make it read-only; BLoC state's `editable` flag drives this.

### 7.5 Segmented picker — `_SegmentedField`

**Use for:** small enums (2–4 options) where visual scan matters more than the dropdown collapse (mode picker, theme switch).

```
┌─────┐ ┌──────────┐ ┌────────┐
│ Add │ │ Replace✓ │ │ Remove │
└─────┘ └──────────┘ └────────┘
```

**Spec:**
- `SegmentedButton<T>` (Material 3).
- `segments`: `ButtonSegment<T>(value: T, label: Text(l10n.…), icon: Icon(…, size: 18))`.
- `selected: {currentValue}` (single-element `Set<T>` for single-select).
- `onSelectionChanged: enabled ? (s) => bloc.add(…(s.first)) : null`.
- `showSelectedIcon: false` (we use the segment fill instead).
- `style: SegmentedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10))` — tightens for narrow phones.

### 7.6 Date / date-range picker — `_DateField`

**Use for:** birthdate, hire date, due date.

```
┌──────────────────────────────────────────┐
│ [📅] Hire date     12 May 2026     ❯    │
└──────────────────────────────────────────┘
```

**Spec:**
- Tap-to-open `showDatePicker`; render as a tappable `InkWell` styled like a `TextField`.
- `Container`: `padding 12px h / 14px v`, `theme.colorScheme.surface` fill, `BorderRadius.circular(AppRadii.md)`, `Border.all(color: theme.colorScheme.outlineVariant)`.
- Inside, `Row` with:
  - leading `Icon(Icons.calendar_today_outlined, color: enabled ? primary : outline)`.
  - middle `Expanded` → `AppLabel(text: formattedDate ?? l10n.fieldNoDate, fontSize: AppFontSize.value14, fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500, color: hasValue ? null : onSurfaceVariant)`.
  - trailing `Icon(Icons.chevron_right, size: 18, color: onSurfaceVariant)`.
- Date format: `DateFormat('d MMM yyyy')` (from `intl`).
- BLoC stores `DateTime?`; null means unset.

### 7.7 Multi-select sheet — `_MultiPickerField`

**Use for:** picking many users, many tags, many permissions.

```
┌──────────────────────────────────────────┐
│ [👥] Pick users…                    ⇕   │ ← compact field
└──────────────────────────────────────────┘
```

Tap → opens a full-screen modal sheet with:
- Drag handle (40×4, surfaceVariant, AppRadii.sm).
- Header row: count + "Select all" + "Clear" `TextButton`s.
- Search `TextField` (autofocus, surfaceVariant fill).
- Optional `_FilterChip` row (horizontal scroll).
- `ListView.separated` of `_PickerRow` (avatar / icon + title + subtitle + checkbox).
- Sticky bottom `FilledButton("Done")` pops with the selection.

**Field spec (compact form):**
- Same outer shape as `_DateField` (InkWell + Container).
- Leading: domain icon (`Icons.group_outlined` / `Icons.label_outline` / etc.).
- Middle: smart summary
  - 0 selected → hint l10n.
  - 1 selected → display name.
  - 2–3 selected → comma-joined names.
  - 4+ selected → `"Name +N others"` + count line.
- Trailing: `Icon(Icons.unfold_more_rounded, size: 20)`.

See [assignments_page.dart](../lib/features/settings/presentation/pages/assignments_page.dart) `_UserPickerField` + `_UserPickerSheet` for a reference impl.

### 7.8 File / image picker — `_FilePickerField`

**Use for:** avatar, attachments.

```
┌──────────────────────────────────────────┐
│  ┌─────────┐  No photo                   │
│  │  (📷)   │  Tap to upload              │
│  └─────────┘                              │
└──────────────────────────────────────────┘
```

**Spec:**
- `InkWell` opens an `AvatarPickerSheet` with Camera / Gallery / Remove options.
- Use `image_picker` (`maxWidth: 1024, maxHeight: 1024, imageQuality: 85`) for images; `file_picker` for arbitrary files.
- After pick, dispatch `AvatarPicked(filePath)` to the BLoC.
- BLoC optimistically updates state, then fires the multipart upload in the repo.
- Display priority: local file path (just picked) > server URL > placeholder.

For server URLs that require auth, pass the bearer token as a header:

```dart
NetworkImage(url, headers: {'Authorization': 'Bearer $accessToken'})
```

(Read the token via the repository, NOT via a service locator — pass it through state.)

---

## 8. Common task templates

### 8.1 New feature module from scratch (page + BLoC + repo + API)

Paste the context block (§2), then:

```
TASK
Build the {{ModuleName}} module — list + detail screens.

ENDPOINTS
- GET    /api/v1/{{module-path}}              — paginated list
- GET    /api/v1/{{module-path}}/{id}         — single record
- POST   /api/v1/{{module-path}}              — create (requires `{{module}}:write`)
- PATCH  /api/v1/{{module-path}}/{id}         — update (requires `{{module}}:write`)
- DELETE /api/v1/{{module-path}}/{id}         — delete (requires `{{module}}:write`)

FILE LAYOUT (create exactly these)
lib/features/{{module}}/
├── data/
│   ├── datasources/{{module}}_remote_data_source.dart
│   ├── models/{{module}}_dto.dart
│   ├── models/{{module}}_requests.dart
│   └── repositories/{{module}}_repository.dart
├── entities/{{entity_name}}.dart
└── presentation/
    ├── bloc/{{module}}_list_bloc.dart
    ├── bloc/{{module}}_list_event.dart
    ├── bloc/{{module}}_list_state.dart
    ├── pages/{{module}}_list_page.dart
    └── pages/{{module}}_detail_page.dart

DI WIRING (no get_it)
- Add the repository to main.dart's manual graph.
- Add it to MultiRepositoryProvider at the app root.
- The list page reads it via `context.read<{{Module}}Repository>()` inside
  a BlocProvider.create.

UI per §7 of this doc. Use AppCard / AppLabel / StatusChip / EmptyState /
LoadingScreen / PermissionGuard exclusively.

Follow §3 architectural rules. Do not use get_it, injectable, or any
service locator. No build_runner for DI.
```

### 8.2 List page with filter chips and search

```
TASK
Build {{ModuleName}}ListPage:
- AppBar with title "{{l10n.{{module}}ListTitle}}".
- Horizontal scrollable filter chip row (use _FilterChip from §7).
  Filters: All · {{Filter1}} · {{Filter2}} · {{Filter3}}.
- SearchBar (surfaceVariant fill) — fires CustomersSearchChanged on each
  keystroke with no debounce (BLoC does in-memory filter).
- ListView.separated of _ItemTile (AppCard, AppSpacing.sm gap):
  - Leading: avatar/icon circle (40×40, primary 0.15 alpha bg).
  - Title: titleMedium / w700.
  - Subtitle: bodySmall onSurfaceVariant.
  - Trailing: StatusChip from the shared status color map.
- LoadingScreen while state is Loading.
- EmptyState (l10n.{{module}}EmptyTitle, illustration) when filter result empty.
- FAB: + l10n.{{module}}CreateAction → push the form page.

BLOC
- States: Initial → Loading → Ready(items, filter, query) → Failure(failure).
- Events: Loaded, FilterChanged(status), SearchChanged(query),
  RefreshRequested (pull-to-refresh).
- RefreshIndicator wraps the ListView; onRefresh awaits a single-shot
  RefreshRequested + completion stream.

Follow §6 for the BLoC shape and §7.1 / 7.5 for the field specs.
```

### 8.3 Detail page with header card and sections

```
TASK
Build {{ModuleName}}DetailPage:
- AppBar with title = entity name; overflow menu (Edit, Delete).
- HeroCard (AppCard, primaryContainer gradient bg):
  - Avatar/icon (96×96 circle).
  - Name (displayLarge, onPrimary).
  - 2-column key-value grid below (Phone · Email · Status).
- SectionLabel "{{Section title}}" (uppercase, primary, labelSmall).
- SectionCard (AppCard) per section. Each row is _InfoRow:
  - Leading icon (Icons.x, 18px, onSurfaceVariant).
  - Title (bodySmall onSurfaceVariant).
  - Value (bodyMedium w600).
- Sticky bottom ActionRow (visible only when state allows it and
  PermissionGuard(scope: '{{module}}:write') passes):
  - DeleteButton (OutlinedButton, error color, half width).
  - EditButton (FilledButton, primary, half width).

BLOC
- Single fetch on init. States: Loading → Ready(entity) / NotFound / Failure.
- Edit button pushes the form page with the entity preloaded.

ROUTING
- ConfigRouter.pushPageAnimation(context, {{Module}}FormPage(initial: entity))
  for the edit jump.
```

### 8.4 Form page with field validation and save

```
TASK
Build {{ModuleName}}FormPage(initial: {{Entity}}?):
- AppBar: "{{New ...}}" or "{{Edit ...}}". Save TextButton in actions.
- ScrollView with sectioned fields (use §7 specs):
  - Section "Identity": fullName (7.1), code (7.1, monospace).
  - Section "Contact": email (7.3), phone (7.3), address (7.2).
  - Section "Status": status segmented picker (7.5).
  - Section "Avatar": file picker (7.8).
- Sticky bottom _SaveBar (FilledButton, full width, 52px).
- WillPopScope: if dirty, show "Discard changes?" dialog.

BLOC (FormBloc shape)
- State: FormState(values: Map<String, dynamic>, fieldErrors: Map<String, String>, saving: bool, savedOk: bool, failure: Failure?).
- Events: FieldChanged(key, value), Submitted, Reset.
- On Submitted:
  1. Re-run all validators; if any fail, emit state with fieldErrors and stop.
  2. emit(saving: true).
  3. Call repo.create() or repo.update(); fold Result onto state.
  4. On success → emit(savedOk: true), page pops with the saved entity.
- Validation rules live in the BLoC (or extracted validators in a sibling
  file). NEVER in the widget.

UI rules per §7. Each field reads its value from BLoC state and reports
changes via FieldChanged. Controllers stay at widget state level to
preserve caret position.
```

### 8.5 Approval flow with modal sheet

```
TASK
Build approval action row + RejectBottomSheet for {{Entity}}:
- ActionRow (sticky bottom, visible when status=PENDING AND user has
  permission '{{module}}.approve'):
  - RejectButton (OutlinedButton, error color, half width).
  - ApproveButton (FilledButton, success color, half width).
- Approve → confirmation bottom sheet → on confirm fires ApprovedEvent.
- Reject → RejectBottomSheet:
  - Drag handle.
  - "Reason for rejection" headlineMedium.
  - Multiline TextField (3 rows min, char count, validator: required).
  - ConfirmRejectButton (FilledButton, error, full width) — disabled until
    reason non-empty.

BLOC
- ActionBloc separate from DetailBloc (so a single failed action doesn't
  blow away the detail data).
- Events: Approved(id), Rejected(id, reason).
- States: ActionIdle → ActionLoading → ActionSuccess / ActionFailure(failure).
- On Success: DetailBloc fires Refresh.

WRAPPING
- Wrap ActionRow with PermissionGuard(scope: '{{module}}.approve') so
  unauthorized users don't even see the buttons.
```

---

## 9. Anti-patterns to reject

Reject any output that:

- ❌ Imports `package:get_it/get_it.dart` or `package:injectable/injectable.dart`.
- ❌ Adds `@injectable` / `@lazySingleton` / `@module` annotations.
- ❌ Calls `GetIt.I<X>()` or `GetIt.instance.get<X>()`.
- ❌ Generates `build_runner` config files for DI.
- ❌ Hardcodes colors (`Color(0xFF…)`), sizes (`16.0`), or fonts (`TextStyle(…)`).
- ❌ Uses raw `Container` for content blocks (should be `AppCard`).
- ❌ Uses `CircularProgressIndicator` on a list (should be `LoadingScreen`).
- ❌ Skips `PermissionGuard` on admin actions.
- ❌ Puts business logic in widgets or ViewModels.
- ❌ Calls Dio directly from a BLoC (must go through the repository).
- ❌ Stores tokens in drift / SQLite / shared_preferences. (Tokens → `flutter_secure_storage` ONLY.)
- ❌ Uses `BlocBuilder` without a `buildWhen`.
- ❌ Misses `EmptyState` on an empty list.
- ❌ Imports `BuildContext` into a BLoC or Repository.

---

## 10. Output verification checklist

Run through these before merging AI-generated code:

- [ ] No `get_it` / `injectable` imports anywhere in the diff.
- [ ] `pubspec.yaml` unchanged unless adding a runtime package (NOT a DI library).
- [ ] Repository is constructed in `main.dart` and provided via `RepositoryProvider`.
- [ ] Page wraps its BLoC in `BlocProvider`, reads the repo via `context.read<X>()`.
- [ ] Every `BlocBuilder` has a `buildWhen`.
- [ ] All visual constants come from `AppTheme` / `AppLabel` / `AppSpacing` / `AppRadii`.
- [ ] Content blocks are `AppCard`, loading is `LoadingScreen`, empty is `EmptyState`.
- [ ] All UI strings come from `l10n.<key>`.
- [ ] Form fields match one of the §7 patterns; controllers held at widget state.
- [ ] Form fields read values from BLoC state; changes dispatched via events.
- [ ] Validation lives in the BLoC, NOT the widget.
- [ ] Repository methods return `Result<T>` (Either<Failure, T>).
- [ ] DioException is translated via `failureFromDioException`.
- [ ] Admin actions are wrapped in `PermissionGuard`.
- [ ] No `BuildContext` references inside BLoC or Repository.
- [ ] `flutter analyze` clean (zero new warnings).
- [ ] Hot-reload: open the page, exercise the happy path + one error path.

---

## 11. Reference snippets

### Result type

```dart
// lib/core/error/result.dart (or wherever it lives)
import 'package:dartz/dartz.dart';

typedef Result<T> = Either<Failure, T>;

Result<T> ok<T>(T value) => Right(value);
Result<T> err<T>(Failure failure) => Left(failure);
```

### Failure-to-message helper for snackbars

```dart
String failureMessage(Failure f, AppLocalizations l10n) {
  return switch (f) {
    NetworkFailure(:final message) ||
    TimeoutFailure(:final message)
        => message ?? l10n.commonNetworkErrorFallback,
    UnauthorizedFailure() => l10n.commonSessionExpired,
    ForbiddenFailure(:final message)
        => message ?? l10n.commonForbiddenFallback,
    ValidationFailure(:final message)
        => message ?? l10n.commonValidationFallback,
    NotFoundFailure() => l10n.commonNotFound,
    ServerFailure(:final statusCode, :final message)
        => '${statusCode ?? ''} — ${message ?? l10n.commonServerErrorFallback}',
    _ => l10n.commonUnknownErrorFallback,
  };
}
```

### Snackbar with "Copy error" action

```dart
messenger.showSnackBar(
  SnackBar(
    content: Text('${l10n.savedFailedFallback}: ${failureMessage(f, l10n)}'),
    backgroundColor: Theme.of(context).colorScheme.error,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 6),
    action: SnackBarAction(
      label: l10n.commonCopyAction,
      textColor: Colors.white,
      onPressed: () => Clipboard.setData(ClipboardData(text: f.toString())),
    ),
  ),
);
```

### Boilerplate: `BlocProvider` + `BlocBuilder` for a list page

```dart
class CustomersListPage extends StatelessWidget {
  const CustomersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CustomersListBloc(
        repo: ctx.read<CustomersRepository>(),
      )..add(const CustomersListLoaded()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: DynamicAppBar(title: l10n.customersListTitle),
      body: BlocBuilder<CustomersListBloc, CustomersListState>(
        buildWhen: (a, b) => a.runtimeType != b.runtimeType ||
            (a is CustomersListReady &&
                b is CustomersListReady &&
                a.visible != b.visible),
        builder: (context, state) {
          return switch (state) {
            CustomersListInitial() ||
            CustomersListLoading() => const LoadingScreen(),
            CustomersListReady(:final visible) => visible.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    message: l10n.customersEmpty,
                  )
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _CustomerTile(customer: visible[i]),
                  ),
            CustomersListFailure(:final failure) => _ErrorPanel(
                failure: failure,
                onRetry: () => context.read<CustomersListBloc>()
                    .add(const CustomersListLoaded()),
              ),
          };
        },
      ),
    );
  }
}
```

---

## 12. Module + screen catalog (all 72 screens)

> Per-screen prompt-ready spec: route, complexity (S/M/L), permission
> scope, endpoints, BLoC contract, UI field references back to §7, and
> any module-specific notes. Paste a module's intro + one screen spec
> + §2 (context block) + §3 (rules) and you have a complete prompt.
>
> **Endpoint conventions** — every backend endpoint lives under
> `/api/v1/`. Where the actual Spring controller is documented (auth,
> users, roles, employees), the exact paths are listed. Where it
> isn't yet, the table uses the project's standard pattern
> (`/{resource}` for list, `/{resource}/{id}` for detail, etc.) — adjust
> when the real controller lands.
>
> Per-screen spec layout:
> ```
> ### N.M — Screen Name
> Route · Complexity · Permission · one-line purpose
> Endpoints · BLoC events / states · UI field refs · Notes
> ```

---

### 12.0 Module 0 — App Entry

> Single screen. Cold-start probe of `flutter_secure_storage` (via
> `TokenStorage`) decides whether to skip login.

**Repositories needed:** `TokenStorage` (already wired in `main.dart`),
`AuthSession` (root-provided).

**Wiring:** splash uses `context.read<TokenStorage>()` +
`context.read<AuthSession>()` directly — no feature repo needed.

#### 0.1 — Splash
**Route:** `/` · **Complexity:** M · **Permission:** none

**Feel:** Brand moment. Probe stored tokens → decide where to send the user.

**Endpoints:** none (offline-only check).

**BLoC (`SplashBloc`):**
- Events: `SplashStarted`
- States: `SplashInitial → SplashProbing → SplashAuthenticated / SplashUnauthenticated / SplashLocked`
- On `SplashStarted`: read `TokenStorage`. If non-null + access token present, call `AuthSession.markAuthenticated()` and emit `SplashAuthenticated`. Else emit `SplashUnauthenticated`. If `biometric_on` flag is set in cached_user, emit `SplashLocked` (route to `/biometric-unlock`).

**UI patterns:** centered logo + spinner + version footer. No fields.

**Notes:** No network calls in this BLoC. Animation duration ~1.5s max. The redirect target is the ONLY place the "should I auto-login?" decision lives.

---

### 12.1 Module 1 — Authentication & Identity

> 4 screens. JWT auth against `/api/v1/auth/*`. Tokens persist to
> `flutter_secure_storage` (never SQLite). Refresh handled by
> `AuthInterceptor`.

**Repositories needed:** `AuthRepository` (constructs from `AuthRemoteDataSource` + `TokenStorage` + `CachedUserDao` + `BiometricService` + `AnalyticsService`). Root-provided.

**Wiring snippet** — add to `main.dart`:
```dart
final authRemote = AuthRemoteDataSource(dio: dio);
final authRepo = AuthRepository(
  tokenStorage: tokenStorage,
  remote: authRemote,
  cachedUserDao: db.cachedUserDao,
  biometricSettingsDao: db.biometricSettingsDao,
  biometric: biometricService,
  analytics: analytics,
);
```

#### 1.1 — Login
**Route:** `/login` · **Complexity:** M · **Permission:** none

**Feel:** Welcome back. Single column, no clutter.

**Endpoints:**
- `POST /auth/login` — body `{email, password}` → `{accessToken, refreshToken, accessExpiresAt, user}`

**BLoC (`LoginBloc`):**
- Events: `LoginEmailChanged(value)`, `LoginPasswordChanged(value)`, `LoginSubmitted`, `LoginBiometricRequested`
- States: `LoginInitial / LoginEditing(email, password, emailError?, passwordError?) → LoginSubmitting → LoginSuccess(user) / LoginFailure(failure)`
- On `LoginSubmitted`: validate, call `repo.login()`, on success persist tokens (repo handles), flip `AuthSession.markAuthenticated()`, navigate via `refreshListenable`.

**UI patterns (§7):**
- 7.3 Email field (validator: contains `@` and `.`)
- 7.3 Password field (suffixIcon: visibility toggle, `obscureText`)
- FilledButton "Sign in" (52px height, disabled while submitting)
- OutlinedButton "Sign in with Biometrics" (visible only if `biometric_on`)
- ErrorCard banner (`errorContainer` bg, AnimatedSwitcher in)

**Notes:** No "Remember me" — tokens persist by default. Auth success triggers go_router's `redirect` via `AuthSession` notify → routes to `/dashboard`.

#### 1.2 — Biometric Unlock
**Route:** `/biometric-unlock` · **Complexity:** S · **Permission:** none

**Feel:** OS lock screen energy. One job.

**Endpoints:** none (local biometric check + token already in storage).

**BLoC (`BiometricBloc`):**
- Events: `BiometricRequested`, `BiometricFallback`
- States: `BiometricPrompting → BiometricSuccess / BiometricFailure(reason) / BiometricUnavailable`
- On `BiometricRequested`: call `local_auth.authenticate(...)`. Success flips `AuthSession.markAuthenticated()`.

**UI patterns:** Avatar circle, biometric icon (72×72, pulse animation), `TextButton` "Use password instead" → `/login`.

**Notes:** Read `biometric_on` + cached avatar from `CachedUserDao` for the hero. Failure shake on the avatar (300ms horizontal).

#### 1.3 — OTP / MFA Verification
**Route:** `/mfa` · **Complexity:** M · **Permission:** none

**Feel:** Focused, single-task.

**Endpoints:**
- `POST /auth/verify-otp` — body `{otpCode}` → tokens

**BLoC (`MfaBloc`):**
- Events: `OtpDigitChanged(index, value)`, `OtpSubmitted`, `OtpResendRequested`
- States: `MfaInitial(digits, cooldownSec) → MfaSubmitting → MfaSuccess / MfaFailure(failure)`
- Resend cooldown timer ticks every second; emits new state with `cooldownSec - 1`.

**UI patterns:**
- Custom 6-box `OtpInputRow` (48×56 each, AppRadii.md, auto-advance focus on input, auto-retreat on delete)
- FilledButton "Verify" (enabled when 6 digits filled)
- TextButton "Resend code (29s)" disabled during cooldown

**Notes:** OTP code is **ephemeral** — memory only, never persisted.

#### 1.4 — Forgot Password
**Route:** `/forgot-password` · **Complexity:** S · **Permission:** none

**Feel:** One job. Enter email, receive link.

**Endpoints:**
- `POST /auth/forgot-password` — body `{email}` → `{success, message}`

**BLoC (`ForgotPasswordBloc`):**
- Events: `EmailChanged(value)`, `ResetRequested`
- States: `Initial(email, error?) → Sending → Sent / Failure(failure)`

**UI patterns:**
- 7.3 Email field with validator
- FilledButton "Send reset link" (swaps to green checkmark + "Check your email" on success)

---

### 12.2 Module 2 — Dashboard & Home

> 3 screens. Control room. WebSocket-driven KPI refresh + push
> notifications.

**Repositories needed:** `KpiRepository`, `NotificationsRepository`, `GlobalSearchRepository`. Root-provided.

#### 2.1 — Dashboard Home
**Route:** `/dashboard` · **Complexity:** L · **Permission:** none (per-tile gated)

**Feel:** Control room. Data-rich, breathing room.

**Endpoints:**
- `GET /dashboard/kpis` — list of KPI cards
- `WS /ws/dashboard` — real-time KPI updates
- `GET /notifications?unread=true&pageSize=1` — for badge count

**BLoCs** (three coexisting on this page):
- `KpiBloc` — Events: `KpiRefreshRequested`. States: `Loading → Ready(kpis) → Failure`. Subscribes to WS in `_onStart`, unsubscribes in `close()`.
- `SyncStatusBloc` — Listens to sync engine. States: `SyncIdle / SyncPending / SyncFailed`. Banner visible only on pending/failed.
- `NotificationBadgeBloc` — Events: `UnreadCountChanged`. States: `BadgeReady(count)`.

**UI patterns:**
- KPI card grid (2-col, shrinkWrap): icon circle + label + headlineMedium value + trend arrow + sparkline (`fl_chart`, 40px, no axes)
- Module shortcut grid (3-col) wrapped in `PermissionGuard` per-module
- 7.1 Global SearchBar (tap → `/search`)
- Pull-to-refresh on the scroll view

**Notes:** WebSocket reconnects on `AppLifecycleState.resumed`. Use `BlocBuilder.buildWhen` on KpiBloc to avoid full rebuild on sparkline tick.

#### 2.2 — Global Search
**Route:** `/search` · **Complexity:** M · **Permission:** none

**Feel:** Fast, instant results as you type.

**Endpoints:**
- `GET /search?q={term}` — federated results, grouped by `module`

**BLoC (`GlobalSearchBloc`):**
- Events: `SearchQueryChanged(query)`, `RecentTapped(query)`
- States: `Initial(recent) → Searching → Results(items) / Empty / Failure`
- Debounce 250ms in the BLoC before firing the call.

**UI patterns:**
- 7.1 SearchTextField (autofocus, back arrow, clear ×)
- Recent searches chips (horizontal scroll)
- Grouped result list with module SectionHeaders
- EmptyState with magnifier illustration

#### 2.3 — Notification Center
**Route:** `/notifications` · **Complexity:** M · **Permission:** none

**Feel:** Inbox. Clear read/unread hierarchy.

**Endpoints:**
- `GET /notifications?page=1&pageSize=20`
- `PATCH /notifications/{id}/read`
- `POST /notifications/mark-all-read`

**BLoC (`NotificationBloc`):**
- Events: `NotificationsLoaded`, `NotificationMarkedRead(id)`, `AllMarkedRead`, `NotificationTapped(notification)`
- States: `Loading → Loaded(items) / Empty / Failure`

**UI patterns:**
- ListView of NotificationTile (AppCard) with leading module icon + unread indicator (3px primary left border + primaryContainer tint)
- AppBar action: "Mark all read" `TextButton`

**Notes:** Tap navigates to the linked record via the deep-link `route` field on the notification.

---

### 12.3 Module 3 — Finance & Accounting

> 7 screens. Chart of accounts, invoices with approval, journals,
> reports. The biggest module by surface area.

**Repositories needed:** `AccountsRepository`, `InvoicesRepository`, `JournalRepository`, `ReportsRepository`.

**Permission scopes:** `finance:read`, `finance:write`, `finance:approve`.

#### 3.1 — Chart of Accounts
**Route:** `/finance/accounts` · **Complexity:** M · **Permission:** `finance:read`

**Feel:** Tree navigator. Hierarchy is the structure.

**Endpoints:**
- `GET /finance/accounts` — flat list with `parentId` for client-side tree build

**BLoC (`ChartOfAccountsBloc`):**
- Events: `AccountsLoaded`, `NodeExpanded(id)`, `NodeCollapsed(id)`, `SearchQueryChanged(q)`
- States: `Loading → Loaded(tree, expandedIds, query) / Failure`

**UI patterns:**
- 7.1 SearchBar (in-tree filter)
- Custom indented ListView with expand/collapse chevrons
- AccountTypeBadge (5 variants: Asset/Liability/Equity/Revenue/Expense — colored chips)

#### 3.2 — Account Detail
**Route:** `/finance/accounts/:id` · **Complexity:** M · **Permission:** `finance:read`

**Feel:** Ledger view. Header then scrollable transactions.

**Endpoints:**
- `GET /finance/accounts/{id}` — single account
- `GET /finance/accounts/{id}/transactions?from=&to=&page=1`

**BLoC (`AccountDetailBloc`):**
- Events: `Loaded(id)`, `DateRangeChanged(from, to)`, `LoadMore`
- States: `Loading → Loaded(account, transactions, paging) / Failure`

**UI patterns:**
- AppCard header (2-col grid)
- 7.6 DateField pair (from/to chips inline)
- ListView of TransactionTile with running balance (right-aligned bodySmall)

#### 3.3 — Invoice List
**Route:** `/finance/invoices` · **Complexity:** M · **Permission:** `finance:read`

**Feel:** Scannable. Status chips carry the meaning.

**Endpoints:**
- `GET /finance/invoices?status=&search=&sort=&page=1&pageSize=20`

**BLoC (`InvoiceListBloc`):** see §6 shape (Customers example). Events add `SortChanged(field)`. Filter chips: All / Draft / Pending / Approved / Rejected.

**UI patterns:**
- Filter chip row (§7.5 segmented? No — use horizontal scroll `_FilterChip` per §7's reference impl)
- 7.1 SearchBar
- ListView of InvoiceTile (AppCard) + StatusChip
- FAB → `/finance/invoices/new`

#### 3.4 — Invoice Detail + Approve/Reject
**Route:** `/finance/invoices/:id` · **Complexity:** L · **Permission:** `finance:read` (view), `finance:approve` (action)

**Feel:** Document view. Header → status → items → actions.

**Endpoints:**
- `GET /finance/invoices/{id}`
- `PATCH /finance/invoices/{id}/approve` — body `{}`
- `PATCH /finance/invoices/{id}/reject` — body `{reason}`

**BLoCs:**
- `InvoiceDetailBloc` — Events: `Loaded(id)`. States: `Loading → Loaded(invoice) / Failure`.
- `InvoiceActionBloc` — Events: `InvoiceApproved(id)`, `InvoiceRejected(id, reason)`. States: `ActionIdle → ActionLoading → ActionSuccess / ActionFailure(failure)`.
- On success, ActionBloc dispatches `Refresh` to DetailBloc via the page.

**UI patterns:**
- HeaderCard (AppCard, 2-col grid)
- StatusChip (large, centered)
- Line items table (AppCard with bordered rows + footer totals)
- Sticky bottom ActionRow (per §8.5)
- RejectBottomSheet (multiline TextField + char count)

**Notes:** Approve/reject buttons wrapped in `PermissionGuard(scope: 'finance:approve')`. Offline → enqueue to `sync_queue` table; show pending badge on the row.

#### 3.5 — Create / Edit Invoice
**Route:** `/finance/invoices/new` · `/finance/invoices/:id/edit` · **Complexity:** L · **Permission:** `finance:write`

**Feel:** Document builder. Dynamic line items, live totals.

**Endpoints:**
- `POST /finance/invoices` (create)
- `PATCH /finance/invoices/{id}` (edit)
- `GET /finance/customers?search=` (picker)

**BLoC (`InvoiceFormBloc`):**
- Events: `FieldChanged(key, value)`, `LineItemAdded`, `LineItemRemoved(index)`, `LineItemFieldChanged(index, key, value)`, `Saved`, `SubmittedForApproval`
- States: `FormReady(values, lineItems, totals, fieldErrors, saving, savedOk, failure?)`
- Live total recomputed inside the BLoC on every line-item change.

**UI patterns:**
- 7.7 Customer/vendor picker (modal sheet with search)
- 7.6 Date fields (invoice date, due date)
- Dynamic line-item list (each row: 7.1 description + 7.3 qty + 7.3 unit price + 7.3 tax%)
- TotalSummaryCard (right-aligned column)
- 7.8-style "Attachment" file picker
- _SaveBar with two buttons: "Save Draft" + "Submit for Approval"

#### 3.6 — Journal Entry List
**Route:** `/finance/journal` · **Complexity:** S · **Permission:** `finance:read`

**Endpoints:** `GET /finance/journal?from=&to=&page=1`

**BLoC:** `JournalBloc` — same shape as InvoiceListBloc minus filter chips.

**UI patterns:** ListView of JournalEntryTile (date · reference · debit · credit). Tap → JournalEntryDetail bottom sheet.

#### 3.7 — Trial Balance Report
**Route:** `/finance/trial-balance` · **Complexity:** M · **Permission:** `finance:read`

**Endpoints:** `GET /finance/reports/trial-balance?period=YYYY-MM`

**BLoC (`TrialBalanceBloc`):**
- Events: `PeriodChanged(year, month)`, `ExportCsvRequested`
- States: `Loading → Loaded(rows, totals) / Failure`

**UI patterns:**
- 7.4 Period picker (month + year)
- AppCard with sticky-header table + alternating row tint
- AppBar action: export CSV (writes to `dart:io` temp file → share intent)

---

### 12.4 Module 4 — Procurement

> 8 screens. Purchase requests with approval flow, purchase orders,
> vendor management. Mirrors finance structure but for procurement.

**Repositories needed:** `PurchaseRequestRepository`, `PurchaseOrderRepository`, `VendorRepository`.

**Permission scopes:** `procurement:read`, `procurement:write`, `procurement:approve`.

#### 4.1 — Purchase Request List
**Route:** `/procurement/requests` · **Complexity:** M · **Permission:** `procurement:read`

**Endpoints:** `GET /procurement/requests?status=&page=1`

**BLoC:** Same shape as InvoiceListBloc. Filter chips: All / Draft / Pending / Approved / Rejected.

**UI patterns:** ListView of PRTile (AppCard) + StatusChip. FAB → create.

#### 4.2 — Create Purchase Request
**Route:** `/procurement/requests/new` · **Complexity:** L · **Permission:** `procurement:write`

**Endpoints:**
- `POST /procurement/requests`
- `GET /procurement/cost-centers` (picker)
- `GET /users?role=approver` (approver picker)

**BLoC (`PRFormBloc`):** Same shape as InvoiceFormBloc.

**UI patterns:**
- 7.4 CostCenter dropdown
- 7.7 Approver picker (sheet)
- Dynamic line items (7.1 description + 7.3 qty + 7.3 estimated cost)
- 7.8 Attachment row
- _SaveBar "Submit"

#### 4.3 — Purchase Request Detail + Approval
**Route:** `/procurement/requests/:id` · **Complexity:** L · **Permission:** `procurement:read` (view), `procurement:approve` (action)

**Endpoints:**
- `GET /procurement/requests/{id}`
- `PATCH /procurement/requests/{id}/approve`
- `PATCH /procurement/requests/{id}/reject` body `{reason}`

**BLoCs:** Identical pattern to Invoice 3.4 — `PRDetailBloc` + `PRActionBloc`.

**UI patterns:** Same as 3.4 plus an `ApprovalTimeline` (vertical list of approval steps with avatar + action chip + timestamp).

#### 4.4 — Purchase Order List
**Route:** `/procurement/orders` · **Complexity:** M · **Permission:** `procurement:read`

Same shape as PR List. Filter chips: All / Draft / Confirmed / Received / Cancelled.

#### 4.5 — Purchase Order Detail
**Route:** `/procurement/orders/:id` · **Complexity:** M · **Permission:** `procurement:read`

**Endpoints:** `GET /procurement/orders/{id}`

**BLoC (`PODetailBloc`):** Loaded → Ready(order, lineItems) / Failure.

**UI patterns:**
- HeaderCard
- StatusChip
- LineItemsTable with received-qty progress (success/warning/error tint by completeness)
- "Record Goods Receipt" OutlinedButton (visible if status=Confirmed) → 4.6

#### 4.6 — Goods Receipt Entry
**Route:** `/procurement/orders/:id/receipt` · **Complexity:** M · **Permission:** `procurement:write`

**Endpoints:** `POST /procurement/orders/{id}/receipt` — body `{date, lines: [{itemId, qty}]}`

**BLoC (`GoodsReceiptBloc`):**
- Events: `ItemQtyChanged(itemId, qty)`, `DateChanged(date)`, `Submitted`
- States: `Editing(lines, date, fieldErrors) → Submitting → Success / Failure`

**UI patterns:**
- 7.6 Date field
- ReceivedQtyList — large 48×48 numeric inputs per row with variance badge (match/over/under)
- FilledButton (success color, full width)

**Notes:** Large tap targets — warehouse workers may type with gloves.

#### 4.7 — Vendor List
**Route:** `/procurement/vendors` · **Complexity:** S · **Permission:** `procurement:read`

**Endpoints:** `GET /procurement/vendors?search=&page=1`

**BLoC (`VendorListBloc`):** standard list pattern.

**UI patterns:** ListView with leading initials circle + trailing star rating row.

#### 4.8 — Vendor Detail
**Route:** `/procurement/vendors/:id` · **Complexity:** M · **Permission:** `procurement:read`

**Endpoints:**
- `GET /procurement/vendors/{id}`
- `GET /procurement/vendors/{id}/scorecard`
- `GET /procurement/vendors/{id}/orders?page=1`

**BLoC (`VendorDetailBloc`):** Loaded(vendor, scorecard, recentOrders).

**UI patterns:** ProfileCard + ScorecardCard (2-col grid) + recent orders ListView (POHistoryTile).

---

### 12.5 Module 5 — Inventory & Warehouse

> 6 screens. Stock management + barcode scan + offline sync. Lots of
> optimistic UI here.

**Repositories needed:** `ItemsRepository`, `StockTransactionRepository`, `BarcodeScanService`, `SyncQueue`.

**Permission scopes:** `inventory:read`, `inventory:write`.

#### 5.1 — Item Catalog
**Route:** `/inventory/items` · **Complexity:** M · **Permission:** `inventory:read`

**Endpoints:**
- `GET /inventory/items?warehouseId=&search=&page=1`
- `GET /inventory/warehouses` (filter picker)

**BLoC (`ItemCatalogBloc`):**
- Events: `Loaded`, `WarehouseChanged(id)`, `SearchChanged(q)`
- States: `Loading → Loaded(items, warehouse, query) / Failure`

**UI patterns:**
- 7.1 SearchBar
- 7.4 Warehouse dropdown (inline next to search)
- ListView with stock-level badge (success/warning/error by min stock threshold)
- FAB → `/inventory/scan`

#### 5.2 — Item Detail
**Route:** `/inventory/items/:id` · **Complexity:** M · **Permission:** `inventory:read`

**Endpoints:**
- `GET /inventory/items/{id}`
- `GET /inventory/items/{id}/movements?page=1`

**BLoC:** Loaded(item, movements).

**UI patterns:**
- ItemHeaderCard
- StockLevelCard with `StockProgressBar` (AppRadii.pill, colored fill by level)
- ListView of MovementTile (Issue/Receipt/Transfer chips with success/error tint)

#### 5.3 — Barcode / QR Scanner
**Route:** `/inventory/scan` · **Complexity:** L · **Permission:** `inventory:read`

**Endpoints:** `GET /inventory/items?barcode={code}` — lookup by SKU/barcode

**BLoC (`ScanBloc`):**
- Events: `BarcodeDetected(code)`, `Reset`
- States: `ScanIdle → ScanDetected(item) / ScanNotFound(code) / ScanFailure`

**UI patterns:**
- Full-screen `mobile_scanner` camera preview
- Custom `ScanOverlayPainter` (240×240 frame + animated scan line)
- ResultBottomSheet (slides up 280px) with action row: Goods Issue / Goods Receipt / Transfer

**Notes:** Camera permission requested via `permission_handler` before mount. Handle denial gracefully with an action sheet.

#### 5.4 — Goods Issue / Receipt Flow
**Route:** `/inventory/transaction` · **Complexity:** M · **Permission:** `inventory:write`

**Endpoints:**
- `POST /inventory/transactions` — body `{type: ISSUE|RECEIPT, itemId, qty, reference, locationId}`

**BLoC (`StockTransactionBloc`):**
- Events: `TypeChanged`, `ItemSelected(itemId)`, `QtyChanged(qty)`, `ReferenceChanged(text)`, `Submitted`
- States: `Editing(form, fieldErrors) → Submitting → Success / Failure(failure, offlineQueued?)`
- Offline path: enqueue to `sync_queue` instead of POST; emit `Success(offlineQueued: true)`.

**UI patterns:**
- TypeTag pill (errorContainer=Issue, successContainer=Receipt)
- 7.7 Item picker (scan-or-search row)
- 7.3 Qty input (large, 56px height for gloved fingers)
- 7.1 Reference field
- 7.4 Location dropdown
- FilledButton 52px (success/error color by type)

#### 5.5 — Stock Transfer
**Route:** `/inventory/transfer` · **Complexity:** M · **Permission:** `inventory:write`

**Endpoints:** `POST /inventory/transfers` — body `{fromWarehouseId, toWarehouseId, lines: [...]}`

**BLoC (`StockTransferBloc`):**
- Events: `FromWarehouseChanged`, `ToWarehouseChanged`, `LineAdded`, `LineQtyChanged(idx, qty)`, `LineRemoved(idx)`, `Submitted`

**UI patterns:**
- 7.4 Warehouse pickers (from, to) with directional arrow icon between
- Dynamic line list (item name + 7.3 qty input + remove icon)
- FilledButton "Confirm Transfer"

#### 5.6 — Inventory Count / Cycle Count
**Route:** `/inventory/count` · **Complexity:** L · **Permission:** `inventory:write`

**Endpoints:**
- `GET /inventory/count-sessions/active` — current session items
- `POST /inventory/count-sessions/{id}/submit` — body `{lines: [{itemId, actualQty}]}`

**BLoC (`InventoryCountBloc`):**
- Events: `Started`, `ItemCountUpdated(itemId, qty)`, `Submitted`
- States: `Loading → InProgress(items, progress, variances) → Submitting → Success / Failure`
- Variance computed inline: `actual - expected`.

**UI patterns:**
- ProgressRow (LinearProgressIndicator + "12 / 48 counted")
- ListView with per-item ActualQtyInput + variance feedback (match/surplus/missing)
- Sticky bottom: variance summary banner + Submit button

---

### 12.6 Module 6 — Sales & CRM

> 8 screens. Customer management, quotations, sales orders, analytics.

**Repositories needed:** `CustomersRepository`, `QuotationsRepository`, `SalesOrdersRepository`, `SalesAnalyticsRepository`.

**Permission scopes:** `customer:read`, `customer:write`, `order:read`, `order:write`.

#### 6.1 — Customer List
**Route:** `/sales/customers` · **Complexity:** S · **Permission:** `customer:read`

**Endpoints:** `GET /sales/customers?search=&page=1`

**BLoC:** Standard list pattern (see §6).

**UI patterns:** ListView with avatar + name + last-order date + phone-call trailing icon. FAB → 6.7.

#### 6.2 — Customer Detail
**Route:** `/sales/customers/:id` · **Complexity:** M · **Permission:** `customer:read`

**Endpoints:**
- `GET /sales/customers/{id}`
- `GET /sales/customers/{id}/contacts`
- `GET /sales/customers/{id}/activity?page=1`

**BLoC:** Loaded(customer, contacts, activity).

**UI patterns:** ProfileCard + ContactsList + ActivityTimeline (left border line + dot per item). FAB → "New Quotation".

#### 6.3 — Sales Quotation List
**Route:** `/sales/quotations` · **Complexity:** M · **Permission:** `order:read`

**Endpoints:** `GET /sales/quotations?status=&page=1`

**BLoC:** Standard list. Filter chips: All / Draft / Sent / Accepted / Rejected.

#### 6.4 — Create / Edit Quotation
**Route:** `/sales/quotations/new` · `/sales/quotations/:id/edit` · **Complexity:** L · **Permission:** `order:write`

**Endpoints:**
- `POST /sales/quotations` / `PATCH /sales/quotations/{id}`

**BLoC (`QuotationFormBloc`):** Same shape as InvoiceFormBloc with quotation-specific fields (validityDate, discount%).

**UI patterns:** Customer picker + 7.6 ValidityDate + dynamic line items + TotalSummaryCard + "Send to Customer" button.

#### 6.5 — Sales Order Detail
**Route:** `/sales/orders/:id` · **Complexity:** M · **Permission:** `order:read`

**Endpoints:** `GET /sales/orders/{id}`

**BLoC:** Loaded(order, fulfillmentSteps, lineItems).

**UI patterns:**
- OrderHeaderCard
- FulfillmentStepper (Confirmed → Picking → Shipped → Delivered with primary/success/surfaceVariant per state)
- LineItemsTable

#### 6.6 — Sales Analytics
**Route:** `/sales/analytics` · **Complexity:** L · **Permission:** `order:read`

**Endpoints:** `GET /sales/analytics?period=week|month|quarter|year`

**BLoC (`SalesAnalyticsBloc`):**
- Events: `PeriodChanged(period)`
- States: `Loading → Loaded(revenue, topCustomers, leaderboard) / Failure`

**UI patterns:**
- 7.5 Period segmented button (Week/Month/Quarter/Year)
- RevenueCard with `fl_chart` LineChart (200px)
- TopCustomersTable
- SalesRepLeaderboard

#### 6.7 — Create Customer
**Route:** `/sales/customers/new` · **Complexity:** M · **Permission:** `customer:write`

**Endpoints:** `POST /sales/customers`

**BLoC (`CustomerFormBloc`):** Standard FormBloc shape.

**UI patterns:**
- 7.8 Avatar picker (camera/gallery)
- 7.1 Name field (required)
- 7.5 CustomerType segmented (Company / Individual)
- 7.3 Contact fields (phone, email, address)
- 7.4 Payment terms dropdown (Net 7 / Net 15 / Net 30 / Net 60 / COD)
- 7.3 Credit limit (numeric, currency prefix)
- 7.4 Currency dropdown
- Dynamic contacts list ("+ Add Contact" with dashed-border OutlinedButton)

#### 6.8 — Edit Customer
**Route:** `/sales/customers/:id/edit` · **Complexity:** M · **Permission:** `customer:write`

Same as 6.7 with `CustomerLoaded(id)` event pre-filling. AppBar shows "Discard" + dirty-check dialog (WillPopScope).

---

### 12.7 Module 7 — Human Resources

> 9 screens. Employee directory, leave management, attendance, payroll.

**Repositories needed:** `EmployeesRepository` (already exists per Module 9 work), `LeaveRepository`, `AttendanceRepository`, `PayslipRepository`, `OrgChartRepository`.

**Permission scopes:** `employee:read`, `employee:write`, `hr:approve`, `attendance:read`, `attendance:write`.

#### 7.1 — Employee Directory
**Route:** `/hr/employees` · **Complexity:** S · **Permission:** `employee:read`

**Endpoints:** `GET /employees?search=&department=&page=1`

**BLoC:** Standard list with department filter.

**UI patterns:** 7.1 SearchBar + 7.4 Department dropdown + ListView with avatar + name + title/department.

#### 7.2 — Employee Profile
**Route:** `/hr/employees/:id` · **Complexity:** M · **Permission:** `employee:read`

**Endpoints:** `GET /employees/{id}`, `GET /employees/{id}/documents`

**BLoC:** Loaded(employee, documents). Tab state managed via DefaultTabController, not BLoC.

**UI patterns:**
- EmployeeAvatarHeader (AppCard, primaryContainer bg)
- TabBar (Personal / Employment / Documents) with TabBarView
- OrgChartButton → `/hr/orgchart?focusId={id}`

#### 7.3 — Org Chart
**Route:** `/hr/orgchart` · **Complexity:** L · **Permission:** `employee:read`

**Endpoints:** `GET /employees/org-chart` — list with `managerId` for tree build

**BLoC (`OrgChartBloc`):**
- Events: `Loaded`, `NodeFocused(id)`
- States: `Loading → Loaded(tree, focusedId) / Failure`

**UI patterns:** `InteractiveViewer` (zoomable, pannable) wrapping a `CustomPainter`-based tree.

**Notes:** Custom painter for connector lines. Node positions calculated client-side (recursive layout).

#### 7.4 — Leave Request Form
**Route:** `/hr/leave/new` · **Complexity:** M · **Permission:** none (anyone can request)

**Endpoints:**
- `POST /hr/leave-requests`
- `GET /hr/leave-balances/me` — for the inline balance bar

**BLoC (`LeaveRequestFormBloc`):**
- Events: `TypeChanged(LeaveType)`, `DateRangeChanged(from, to)`, `ReasonChanged(text)`, `Submitted`
- States: `Editing(form, balance, computedDays, fieldErrors, saving) → Success / Failure`
- Computed: `workingDays` between from/to (excludes weekends).

**UI patterns:**
- 7.4 LeaveType dropdown
- Inline calendar (range highlight) — `table_calendar` package
- LeaveBalanceCard with progress bar (used/remaining)
- 7.2 Reason multiline field
- _SaveBar "Submit"

#### 7.5 — My Leave List
**Route:** `/hr/leave` · **Complexity:** M · **Permission:** none

**Endpoints:**
- `GET /hr/leave-requests?userId=me&status=&page=1`
- `GET /hr/leave-balances/me`

**BLoC:** Standard list + balance summary.

**UI patterns:** Horizontal-scroll BalanceSummaryRow (AppCards) + filter chips + ListView. FAB → 7.4.

#### 7.6 — Manager Leave Approval
**Route:** `/hr/leave/approvals` · **Complexity:** M · **Permission:** `hr:approve`

**Endpoints:** `GET /hr/leave-requests?status=PENDING&forManager=me`

**BLoC:** Standard list pattern with no swipe-to-approve (tap each row → 7.9).

**UI patterns:** ListView of PendingLeaveCard with all-context (employee avatar + date range + reason + ActionRow).

**Notes:** No swipe-to-approve — too risky on scroll. Tap → 7.9 for full context first.

#### 7.7 — Attendance Log
**Route:** `/hr/attendance` · **Complexity:** M · **Permission:** none (own data)

**Endpoints:**
- `GET /hr/attendance?userId=me&month=YYYY-MM`
- `POST /hr/attendance/clock-in`
- `POST /hr/attendance/clock-out`

**BLoC (`AttendanceBloc`):**
- Events: `Loaded(month)`, `ClockInRequested`, `ClockOutRequested`, `MonthChanged(month)`
- States: `Loading → Loaded(today, log) / Failure`

**UI patterns:**
- TodayCard (primaryContainer bg) with large ClockInOutButton (56px)
- AttendanceCalendar (compact month view with colored day dots)
- ListView of AttendanceDayRow

#### 7.8 — Payslip Viewer
**Route:** `/hr/payslips` · **Complexity:** M · **Permission:** none (own data)

**Endpoints:**
- `GET /hr/payslips?userId=me&month=YYYY-MM`
- `GET /hr/payslips/{id}/pdf` — binary stream

**BLoC:** `PayslipBloc` Loaded(payslip).

**UI patterns:**
- Horizontal MonthPickerRow (chip per month)
- NetPayCard (primaryContainer, displayLarge primary)
- EarningsCard + DeductionsCard (totals in success/error)
- "View PDF" OutlinedButton → external viewer

#### 7.9 — Leave Approval Detail
**Route:** `/hr/leave/approvals/:id` · **Complexity:** M · **Permission:** `hr:approve`

**Endpoints:**
- `GET /hr/leave-requests/{id}` (includes employee + balance preview)
- `PATCH /hr/leave-requests/{id}/approve` body `{note?}`
- `PATCH /hr/leave-requests/{id}/reject` body `{reason}`

**BLoCs:** `LeaveApprovalDetailBloc` + `LeaveApprovalActionBloc` (separated per §8.5 pattern).

**UI patterns:** Same approval pattern as Invoice 3.4 + BalancePreviewCard ("If approved: X days remaining").

---

### 12.8 Module 8 — Project Management

> 9 screens. Projects, Gantt, Kanban, tasks, timesheets, utilization.

**Repositories needed:** `ProjectsRepository`, `TasksRepository`, `TimesheetsRepository`, `UtilizationRepository`.

**Permission scopes:** `project:read`, `project:write`, `task:read`, `task:write`.

#### 8.1 — Project List
**Route:** `/projects` · **Complexity:** S · **Permission:** `project:read`

**Endpoints:** `GET /projects?status=&page=1`

**BLoC:** Standard list with status filter (All / Active / On Hold / Completed).

**UI patterns:** ListView with manager avatar + name + ProgressBar (AppRadii.pill, success fill).

#### 8.2 — Project Detail / Gantt
**Route:** `/projects/:id` · **Complexity:** L · **Permission:** `project:read`

**Endpoints:**
- `GET /projects/{id}`
- `GET /projects/{id}/tasks?page=1`
- `GET /projects/{id}/members`
- `GET /projects/{id}/files`

**BLoC (`ProjectDetailBloc`):**
- Events: `Loaded(id)`, `TabChanged(tab)`
- States: `Loading → Loaded(project, tasks, members, files, tab) / Failure`

**UI patterns:**
- ProjectHeaderCard
- TabBar: Gantt / Board / Team / Files
- Gantt: horizontal-scroll with sticky date header + custom-painted bars
- Board tab: renders 8.3 inline
- Team/Files: simple lists

#### 8.3 — Task Kanban Board
**Route:** `/projects/:id/board` · **Complexity:** L · **Permission:** `task:read`

**Endpoints:**
- `GET /projects/{id}/tasks`
- `PATCH /tasks/{taskId}` body `{status: NEW_STATUS}`

**BLoC (`KanbanBloc`):**
- Events: `Loaded(projectId)`, `TaskMoved(taskId, newStatus)`
- States: `Loading → Loaded(columns) / Failure`
- Optimistic move: update column locally first, rollback on PATCH failure.

**UI patterns:**
- Horizontal `ListView` of columns (240px wide, surfaceVariant bg, AppRadii.lg)
- `DragTarget` + `Draggable` per `KanbanCard` (AppCard) — uses `flutter_reorderable_list` or built-in `Draggable`
- Each card: title + AssigneeAvatarRow (overlapping -8px) + PriorityBadge + DueDateRow

#### 8.4 — Task Detail
**Route:** `/projects/:projectId/tasks/:taskId` · **Complexity:** M · **Permission:** `task:read`

**Endpoints:**
- `GET /tasks/{id}`
- `GET /tasks/{id}/comments?page=1`
- `POST /tasks/{id}/comments`

**BLoCs:** `TaskDetailBloc` + `CommentBloc`.

**UI patterns:**
- TaskHeaderCard with StatusChip + PriorityBadge + AssigneeRow + 7.6 DueDateRow
- DescriptionCard (selectable bodyLarge)
- SubtaskList (each row: Checkbox + name with strikethrough when done)
- CommentThread (avatar + name + comment text)
- Sticky bottom CommentInputRow (avatar + 7.1 TextField pill + send icon)

#### 8.5 — Timesheet Entry
**Route:** `/projects/timesheets` · **Complexity:** L · **Permission:** none (own data)

**Endpoints:**
- `GET /timesheets?weekStart=YYYY-MM-DD`
- `POST /timesheets` body `{week, cells: [{taskId, day, hours}]}`

**BLoC (`TimesheetBloc`):**
- Events: `WeekChanged(weekStart)`, `HoursUpdated(taskId, day, hours)`, `Submitted`
- States: `Loading → Editing(grid, totals, dirty) → Submitting → Success / Failure`

**UI patterns:**
- StickyHeaderRow with day labels
- ListView of TimesheetTaskRow (task name fixed left + 7 HoursCells)
- Tap cell → HoursInputBottomSheet (numpad + confirm)
- _SaveBar "Submit Timesheet"

#### 8.6 — Utilization Report
**Route:** `/projects/utilization` · **Complexity:** M · **Permission:** `project:read`

**Endpoints:** `GET /utilization?period=week|month|quarter`

**BLoC:** `UtilizationBloc` Loaded(summary, perMember, target).

**UI patterns:**
- 7.5 Period segmented
- TeamSummaryCard
- UtilizationBarChart (`fl_chart` BarChart, 200px) with target dashed line
- ListView of MemberUtilizationRow with progress bar (color by level)

#### 8.7 — Create / Edit Project
**Route:** `/projects/new` · `/projects/:id/edit` · **Complexity:** L · **Permission:** `project:write`

**Endpoints:**
- `POST /projects` / `PATCH /projects/{id}`
- `GET /sales/customers?search=` (client picker)
- `GET /employees?search=` (member picker)

**BLoC (`ProjectFormBloc`):** Standard FormBloc with `MemberAdded` / `MemberRemoved` events.

**UI patterns:**
- 7.1 ProjectName field
- 7.2 Description multiline
- 7.7 Client picker (searchable)
- 7.6 StartDate + EndDate (live-computed duration shown as bodyMedium primary)
- 7.3 Budget field (currency prefix)
- 7.5 BillingType segmented (Fixed / T&M / Retainer)
- 7.4 ProjectManager dropdown
- 7.7 Members multi-picker
- 7.5 Status + Priority segmented

#### 8.8 — Assign / Reassign Task
**Route:** `/projects/:projectId/tasks/:taskId/assign` · **Complexity:** M · **Permission:** `task:write`

**Endpoints:**
- `GET /tasks/{id}` (task context)
- `GET /projects/{projectId}/members?withWorkload=true` (workload counts)
- `PATCH /tasks/{id}` body `{assigneeId, dueDate?, noteToAssignee?}`

**BLoC (`TaskAssignBloc`):**
- Events: `Loaded(taskId)`, `AssigneeSelected(employeeId)`, `DueDateChanged(date)`, `NoteChanged(text)`, `Submitted`
- States: `Loading → Loaded(task, members) → Submitting → Success / Failure`

**UI patterns:**
- TaskContextCard (surfaceVariant bg)
- 7.1 SearchBar
- ListView of TeamMemberTile with WorkloadBadge (X open tasks, info/warning by count) + AvailabilityDot
- 7.6 DueDate field
- 7.2 NoteToAssignee multiline

**Notes:** Post-assign: navigate back to 8.4 + dispatch push notification to new assignee (backend handles).

#### 8.9 — Task Create / Edit
**Route:** `/projects/:projectId/tasks/new` · `/projects/:projectId/tasks/:taskId/edit` · **Complexity:** M · **Permission:** `task:write`

**Endpoints:**
- `POST /projects/{projectId}/tasks` / `PATCH /tasks/{id}`

**BLoC (`TaskFormBloc`):** Standard FormBloc with subtask add/toggle/remove events.

**UI patterns:**
- Large 7.1 TitleField (headlineMedium style)
- 7.5 Status segmented
- 7.5 Priority segmented
- AssigneePicker row → opens 8.8 sheet
- 7.6 DueDate field
- 7.2 Description multiline (4 rows min)
- SubtaskCard with dynamic checkbox+TextField rows

---

### 12.9 Module 9 — Settings & Administration

> 10 screens. Preferences, security, admin, profile, assignments.
> Several already wired in this codebase — references provided.

**Repositories needed:** `PreferencesRepository`, `MyProfileRepository`, `RolesRemoteDataSource`, `UsersRemoteDataSource`, `EmployeesRemoteDataSource`, `DeviceSessionsRepository`, `AuditLogRepository`, `AppLockSettingsRepository`, `ApiEnvironmentsRepository`.

**Permission scopes:** `user:read`, `user:write`, `role:read`, `role:write`, `audit:read`, `settings:read`, `settings:write`.

#### 9.1 — Settings Home
**Route:** `/settings` · **Complexity:** S · **Permission:** none (per-tile gated)

**No BLoC** — static navigation page. Reads cached user via `StreamBuilder<User?>` on `CachedUserDao` for the hero card. Administration section wrapped in a StreamBuilder that filters via `isSuperAdmin(user.roles)`.

**UI patterns:** UserProfileCard + grouped `_Tile` lists. Sign-out at the bottom uses `AuthRepository.signOut()`.

**Reference impl:** [settings_home_page.dart](../lib/features/settings/presentation/pages/settings_home_page.dart).

#### 9.2 — User Preferences
**Route:** `/settings/preferences` · **Complexity:** S · **Permission:** none

**Endpoints:** none (local-only via `PreferencesRepository` backed by `shared_preferences`).

**BLoC (`PreferencesBloc`):**
- Events: `ThemeChanged(mode)`, `LanguageChanged(locale)`, `NotificationPrefToggled(type, enabled)`
- States: `Loaded(prefs) → Updating → Loaded(prefs)`

**UI patterns:**
- 7.5 Theme segmented (Light / Dark / System)
- 7.4 Language picker (opens bottom sheet)
- 7.5 / Switch rows for notification types

#### 9.3 — Active Sessions
**Route:** `/settings/sessions` · **Complexity:** M · **Permission:** none (own data)

**Endpoints:**
- `GET /auth/sessions/me`
- `DELETE /auth/sessions/{id}`
- `DELETE /auth/sessions/me?keepCurrent=true`

**BLoC (`SessionManagementBloc`):**
- Events: `Loaded`, `SessionRevoked(id)`, `AllOtherSessionsRevoked`
- States: `Loading → Loaded(sessions, currentId) / Failure`

**UI patterns:** ListView of SessionTile (device icon + name + last-active + RevokeButton) + bottom "Revoke all other sessions" OutlinedButton.

**Notes:** **No local cache** — security-sensitive.

#### 9.4 — Audit Log Viewer
**Route:** `/settings/audit` · **Complexity:** M · **Permission:** `audit:read`

**Endpoints:** `GET /audit?user=&module=&actionType=&from=&to=&page=1`

**BLoC (`AuditLogBloc`):**
- Events: `Loaded`, `FilterChanged(filter)`, `LoadMore`
- States: `Loading → Loaded(entries, filter, paging) / Failure`

**UI patterns:** FilterRow (horizontal chips) + ListView of AuditLogTile + tap → AuditLogDetailBottomSheet (full payload monospace).

#### 9.5 — User Management (Admin)
**Route:** `/settings/admin/users` · **Complexity:** M · **Permission:** `user:write`

**Endpoints:**
- `GET /users?page=1&pageSize=20&search=`
- `POST /users` body `{email, password, fullName, phone, roles}`
- `PATCH /users/{id}` body `{fullName?, phone?, enabled?, roles?}`
- `DELETE /users/{id}`

**BLoC (`UserManagementBloc`):** Standard list + per-row action events.

**UI patterns:** ListView of UserManagementTile with overflow menu (Edit role / Reset password / Deactivate).

**Notes:** **No local cache** — reads from API only.

#### 9.6 — Role & Permission Editor (Admin)
**Route:** `/settings/admin/roles` · **Complexity:** L · **Permission:** `role:write`

**Endpoints:**
- `GET /roles`
- `GET /roles/permissions`
- `POST /roles` body `{code, name, description, permissions}`
- `PATCH /roles/{id}` body `{name?, description?, permissions?}`

**BLoC (`RoleEditorBloc`):**
- Events: `Loaded`, `PermissionToggled(roleId, scope)`, `Saved`
- States: `Loading → Loaded(matrix, dirty) → Saving → Success / Failure`

**UI patterns:** 2D scroll matrix — horizontal roles header, vertical scopes column, switch grid cells. Save button in AppBar.

**Notes:** On save success, `getIt`-free way: dispatch `UserPermissionsInvalidated` event upstream so the dashboard's permission gates re-evaluate.

#### 9.7 — API / Environment Config (Admin)
**Route:** `/settings/admin/config` · **Complexity:** S · **Permission:** `settings:write`

**Endpoints:** none (local — drives Dio base URL).

**BLoC (`EnvConfigBloc`):**
- Events: `Loaded`, `EnvChanged(env)`, `BaseUrlChanged(url)`, `TenantIdChanged(id)`, `ConnectionTested`, `Saved`
- States: `Loaded(env, baseUrl, tenantId) / Testing / TestSuccess / TestFailure / Saving`

**UI patterns:**
- 7.5 Environment segmented (Production / Staging / Custom)
- 7.1 BaseUrl + TenantId fields (visible only when Custom)
- OutlinedButton "Test Connection" with state-aware label
- FilledButton "Save"

#### 9.8 — PIN Lock / Biometric Re-Auth
**Route:** `/lock` · **Complexity:** M · **Permission:** none

**Endpoints:** none (local PIN hash in `flutter_secure_storage`).

**BLoC (`AppLockBloc`):**
- Events: `PinDigitTyped(digit)`, `PinBackspace`, `PinSubmitted`, `BiometricRequested`, `LogoutRequested`
- States: `Locked(digits, attemptsRemaining) → Unlocking → Unlocked / Failure(attemptsRemaining)`

**UI patterns:**
- PinDotsRow (4–6 14×14 dots)
- Custom PinPad grid (72×72 per button, AppRadii.xl, surfaceVariant)
- Shake animation on dots on failure (300ms horizontal)
- "X attempts remaining" error text after 3rd fail
- "Log out instead" TextButton (error color)

#### 9.9 — My Profile Info
**Route:** `/settings/profile` · **Complexity:** M · **Permission:** none (own data)

**Endpoints:**
- `GET /employees/me`
- `PATCH /employees/{id}` (requires `employee:write`)
- `POST /employees/me/avatar` (multipart)
- `DELETE /employees/me/avatar`

**BLoC (`ProfileBloc`):**
- Events: `Loaded`, `EditingStarted`, `FieldChanged(key, value)`, `AvatarPicked(filePath)`, `AvatarCleared`, `Saved`, `EditCancelled`
- States: `Loading → Viewing(profile) ↔ Editing(profile, draft, fieldErrors, saving) → Saved / Failure`

**UI patterns:**
- HeroCard with 7.8 avatar picker + initials fallback
- View mode: SectionCards with _InfoRow per field
- Edit mode: same sections with 7.1/7.2/7.3/7.6 fields swapped in
- Sticky _SaveBar in edit mode

**Reference impl:** [my_profile_page.dart](../lib/features/settings/presentation/pages/my_profile_page.dart) + [my_profile_repository.dart](../lib/features/settings/data/repositories/my_profile_repository.dart) (already wired to backend).

#### 9.10 — My Roles & Permissions
**Route:** `/settings/roles` · **Complexity:** M · **Permission:** none (own data)

**Endpoints:** `GET /users/me` — returns `{roles: [code...], permissions: [token...]}`

**BLoC (`MyRolesBloc`):**
- Events: `Loaded`, `PermissionSearchChanged(query)`
- States: `Loading → Loaded(assignedRoles, grantedPermissions, query) / Failure`

**UI patterns:** RoleSummaryCard (gradient bg, role chips) + 7.1 SearchBar + grouped granted-permission list (no comparison against full catalog — that would 403 for non-super-admins).

**Reference impl:** [my_roles_page.dart](../lib/features/settings/presentation/pages/my_roles_page.dart).

---

### 12.10 Module 10 — Chat & Voice / Video

> 7 screens. Real-time chat over WebSocket + WebRTC voice/video.
> Heaviest module — coexists with drift for offline message persistence.

**Repositories needed:** `ConversationsRepository`, `ChatMessagesRepository`, `CallLogRepository`, `ChatTransport` (WebSocket), `CallSignalingService`, `ChatSettings`, `ActiveConversationTracker`.

**Permission scopes:** `chat:read`, `chat:write`.

#### 10.1 — Chat Inbox
**Route:** `/chat` · **Complexity:** M · **Permission:** `chat:read`

**Endpoints:**
- `GET /chat/conversations?page=1`
- `WS /ws/inbox` — real-time updates

**BLoC (`ChatInboxBloc`):**
- Events: `Loaded`, `TabChanged(tab)`, `SearchChanged(query)`, `ConversationMuted(id)`, `ConversationDeleted(id)`, `RemoteUpdate(conversationId, lastMessage)` (from WS)
- States: `Loading → Loaded(all, unread, groups, tab, query) / Failure`

**UI patterns:**
- TabBar (All / Unread / Groups / Calls)
- 7.1 SearchBar
- ListView of ConversationTile with avatar + name + last-message preview + unread badge + swipe actions (mute/delete)

#### 10.2 — Chat Conversation
**Route:** `/chat/:conversationId` · **Complexity:** L · **Permission:** `chat:write`

**Endpoints:**
- `GET /chat/conversations/{id}/messages?cursor=&pageSize=30`
- `POST /chat/conversations/{id}/messages` — body `{type, body?, fileUrl?, voiceUrl?, replyToId?}`
- `PATCH /chat/messages/{id}` — body `{body}` (edit)
- `DELETE /chat/messages/{id}?forEveryone=true|false`
- `POST /chat/messages/{id}/reactions` — body `{emoji}`
- `WS /ws/chat/{conversationId}` — message/typing/seen events

**BLoC (`ConversationBloc`):**
- Events: `Loaded(id)`, `OlderRequested`, `MessageSent(body, replyToId?)`, `VoiceMessageSent(path, durationSec)`, `ImageSent(path)`, `FileSent(path, name, sizeBytes)`, `MessageEdited(id, body)`, `MessageDeleted(id, forEveryone)`, `ReactionToggled(id, emoji)`, `ReplyStarted(messageId)`, `ReplyCancelled`, `EditStarted(messageId)`, `EditCancelled`, `MessagePinned(id)`, `TypingStarted`, `TypingStopped`, `RemoteMessageReceived(message)`, `RemoteTyping(senderId, isTyping)`, `RemoteSeen(ids)`
- States: `Loading → Loaded(messages, participants, pinned?, replyingTo?, editing?, paging) / Failure`
- **Optimistic insert**: append with `pending` state, upgrade on ACK.

**UI patterns:**
- Custom AppBar (avatar + online status + voice/video call icons)
- PinnedMessageBanner (AnimatedSwitcher)
- Reverse-scroll MessageList with ChatBubble (TextBubble/VoiceBubble/ImageBubble/FileBubble)
- ReplyPreviewBar / EditPreviewBar (AnimatedSwitcher above input)
- InputRow: AttachButton + 7.1 MessageTextField (auto-expand) + Send/Voice toggle button
- AttachmentBottomSheet (2×2 grid: Camera/Gallery/File/Location)
- VoiceRecordingOverlay (hold-to-record with slide-to-cancel)
- MessageContextMenu (long-press → emoji bar + actions)

**Reference impl:** chat module already has many of these in `lib/features/chat/`.

#### 10.3 — New Conversation / Group Chat
**Route:** `/chat/new` · **Complexity:** M · **Permission:** `chat:write`

**Endpoints:**
- `POST /chat/conversations` body `{type: DIRECT|GROUP, name?, participantIds, avatarUrl?}`

**BLoC (`NewConversationBloc`):**
- Events: `ModeChanged(type)`, `SearchChanged(q)`, `MemberToggled(id)`, `GroupNameChanged(name)`, `GroupAvatarPicked(path)`, `CreateRequested`
- States: `Loading → Ready(employees, selected, mode, groupName?, groupAvatar?) → Creating → Created(conversationId) / Failure`

**UI patterns:**
- 7.5 Mode segmented (Direct / Group)
- GroupSetupSection (visible in Group mode): 7.1 group name + 7.8 group avatar picker
- 7.1 SearchBar
- 7.7 Multi-select via SelectableMemberTile (checkbox)
- _SaveBar "Start Chat" / "Create Group"

#### 10.4 — Message Search
**Route:** `/chat/:conversationId/search` · **Complexity:** M · **Permission:** `chat:read`

**Endpoints:** local SQLite FTS5 search (no API).

**BLoC (`MessageSearchBloc`):**
- Events: `SearchChanged(query)`
- States: `Initial → Searching → Results(matches) / Empty / Failure`

**UI patterns:** 7.1 SearchTextField (autofocus) + ListView of MessageSearchResultTile (tap → navigate to conversation + scroll to + highlight match).

#### 10.5 — Voice Call
**Route:** `/chat/:conversationId/voice-call` · **Complexity:** L · **Permission:** `chat:write`

**Endpoints:**
- WS signalling envelopes via `ChatTransport`: `call.invite`, `call.accept`, `call.reject`, `call.hangup`
- `POST /chat/call-log` — write entry on call end

**BLoC (`VoiceCallBloc`):**
- Events: `CallInitiated(conversationId)`, `IncomingCallReceived(callId, caller)`, `CallAnswered`, `CallDeclined`, `CallEnded`, `MuteToggled`, `SpeakerToggled`, `TimerTick`
- States: `Idle → Calling / Ringing / Connected(duration, isMuted, isSpeaker) → Ended(duration, reason) / Failure`

**UI patterns:** Full-screen gradient bg + CallerAvatar (pulsing glow) + CallStatusRow + ControlsGrid (Mute/Speaker/Keypad + End).

**Notes:** Requires `Permission.microphone` before initiating. Background calls need FCM high-priority push (out of scope for the demo).

#### 10.6 — Video Call
**Route:** `/chat/:conversationId/video-call` · **Complexity:** L · **Permission:** `chat:write`

Same as 10.5 with both audio + video tracks. Uses `flutter_webrtc` `RTCVideoRenderer` for local (mirrored) + remote streams. Auto-hide controls after 3s.

**BLoC (`VideoCallBloc`):** Additional events: `CameraToggled`, `CameraFlipped`, `RemoteVideoStateChanged(enabled)`, `ControlsToggled`.

**UI patterns:** Full-screen black bg + RemoteVideoView + draggable LocalVideoPreview PiP + auto-hide TopBar + ControlsBar with FilledButton circles.

#### 10.7 — Chat Settings / Conversation Info
**Route:** `/chat/:conversationId/info` · **Complexity:** M · **Permission:** `chat:write` (some actions admin-only)

**Endpoints:**
- `GET /chat/conversations/{id}`
- `PATCH /chat/conversations/{id}` body `{name?, avatarUrl?, isMuted?}`
- `POST /chat/conversations/{id}/members` body `{employeeIds}`
- `DELETE /chat/conversations/{id}/members/{memberId}`
- `POST /chat/conversations/{id}/leave`

**BLoC (`ChatInfoBloc`):**
- Events: `Loaded(id)`, `Renamed(name)`, `AvatarChanged(path)`, `MuteToggled`, `MemberAdded(id)`, `MemberRemoved(id)`, `AdminGranted(id)`, `AdminRevoked(id)`, `LeftGroup`, `HistoryCleared`
- States: `Loading → Loaded(conversation, participants, pinned) / Failure`

**UI patterns:**
- Direct: ProfileCard + QuickActionsCard (voice/video/search)
- Group: GroupHeaderCard with editable 7.8 avatar + tap-to-rename
- MediaCard (3-col preview grid → MediaGalleryViewer)
- SettingsCard with Switch rows
- MembersCard with AdminBadges + admin-only options
- DangerCard with Leave Group + Clear History

---

## 13. Wire field reference (API field → UI location)

> Per-screen mapping of **every API field the screen consumes** to its
> **exact UI location**. Use this alongside §12 when writing a prompt:
> §12 gives you BLoC + endpoints + UI patterns, §13 tells the AI which
> JSON key feeds which widget.
>
> **Notation:**
> - `field: Type` — JSON key + Dart/JVM type
> - `?` after a type → nullable / optional on the wire
> - `[conventional]` tag → backend not yet confirmed; field name follows
>   common Spring/Jackson convention and may need adjustment
> - "Hidden / nav handle" → field consumed but not displayed (e.g. id
>   used to build the detail route)
>
> Where the actual backend record is documented (auth, users, roles,
> employees), the field names are byte-exact. Tables list **response
> shape**; for request bodies see §12's endpoint section per screen.

---

### 13.0 Module 0 — App Entry

#### 0.1 Splash
No API. Reads from `TokenStorage` + `CachedUserDao` (drift).

| Local read | Type | Used for |
|---|---|---|
| `accessToken` | String | decision: present → `/dashboard`; absent → `/login` |
| `cached_user.biometric_on` | bool | decision: route to `/biometric-unlock` if true |

---

### 13.1 Module 1 — Authentication & Identity

> Auth backend confirmed: `POST /auth/login` returns
> `{accessToken, refreshToken, accessExpiresAt, user: UserDto}` where
> `UserDto = {id: Long, email, fullName, phone?, roles: Set<String>, permissions: Set<String>}`.

#### 1.1 Login

| API field | Type | UI location |
|---|---|---|
| `accessToken` | String | Hidden — persisted to `flutter_secure_storage` |
| `refreshToken` | String | Hidden — persisted to `flutter_secure_storage` |
| `accessExpiresAt` | Instant? | Hidden — used by interceptor for proactive refresh |
| `user.id` | Long | Hidden — cached in drift for offline routing |
| `user.email` | String | Hidden — cached, surfaces on Settings home + My Profile |
| `user.fullName` | String | Hidden — cached, surfaces on Settings home avatar header |
| `user.roles` | Set<String> | Hidden — feeds `PermissionsSnapshot` for route guards |
| `user.permissions` | Set<String> | Hidden — feeds `PermissionsSnapshot` |

UI-visible at login time: only the success → redirect or error → snackbar.

#### 1.2 Biometric Unlock

| Local read | Type | UI location |
|---|---|---|
| `cached_user.avatar_url` | String? | Avatar circle (64×64) |
| `cached_user.full_name` | String | "Name" label (titleMedium) |
| `cached_user.last_login_at` | DateTime | bodyMedium under name ("Last seen …") |

#### 1.3 OTP / MFA Verification

| API field | Type | UI location |
|---|---|---|
| `accessToken` / `refreshToken` / `user.*` | (same as 1.1) | Hidden — persisted |
| `errorCode` (envelope) | String? | Drives the error banner copy ("Code expired" etc.) |

UI input: 6-digit OTP, sent as `{otpCode: "123456"}` request body.

#### 1.4 Forgot Password

| API field | Type | UI location |
|---|---|---|
| `success` (envelope) | bool | Swaps button to green checkmark on `true` |
| `message` (envelope) | String? | Snackbar text on failure |

---

### 13.2 Module 2 — Dashboard & Home

> Endpoints conventional pending backend confirmation.

#### 2.1 Dashboard Home — `GET /dashboard/kpis` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | String | Hidden — list key |
| `title` | String | KpiCard label (bodySmall onSurfaceVariant) |
| `value` | String | KpiCard value (headlineMedium) |
| `module` | String | KpiCard icon color (Finance=indigo, Inventory=orange, etc.) |
| `trend.deltaPct` | double? | Arrow + "+3.2%" (success/error color) |
| `trend.direction` | "up"\|"down"\|"flat" | Arrow icon (up_rounded / down_rounded / horizontal_rule) |
| `sparkline` | List<num> | `fl_chart` LineChart, 40px, no axes |
| `lastUpdatedAt` | Instant? | bodySmall footer "Updated 2m ago" |

Also reads `GET /notifications?unread=true&pageSize=1` → `total` field drives the AppBar bell badge.

#### 2.2 Global Search — `GET /search?q=` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | String | Hidden — list key |
| `module` | String | Group header + leading icon color |
| `title` | String | SearchResultTile title (titleMedium) |
| `subtitle` | String? | SearchResultTile subtitle (bodySmall onSurfaceVariant) |
| `route` | String | Hidden — tap navigates here |

#### 2.3 Notification Center — `GET /notifications` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — list key + mark-read PATCH path |
| `title` | String | NotificationTile title (titleMedium, w600 if unread) |
| `body` | String | NotificationTile body (bodySmall, max 2 lines) |
| `module` | String | Leading icon circle (color by module) |
| `createdAt` | Instant | Timestamp right-aligned (bodySmall onSurfaceVariant) |
| `isRead` | bool | Drives unread indicator (3px primary left border + tint) |
| `route` | String? | Hidden — tap deep-links to record |

---

### 13.3 Module 3 — Finance & Accounting

> Endpoints + DTOs conventional pending backend confirmation.

#### 3.1 Chart of Accounts — `GET /finance/accounts` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `parentId` | Long? | Hidden — drives tree indentation |
| `code` | String | AccountNode subtitle (bodySmall onSurfaceVariant, monospace) |
| `name` | String | AccountNode title (titleMedium) |
| `type` | enum | AccountTypeBadge color + label (Asset=success, Liability=warning, Equity=info, Revenue=primary, Expense=error) |
| `balance` | Decimal | Right-aligned titleMedium |
| `hasChildren` | bool | Expand/collapse chevron visibility |

#### 3.2 Account Detail — `GET /finance/accounts/{id}` + `/transactions` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `code` / `name` / `type` | (per 3.1) | HeaderCard 2-col grid |
| `balance` | Decimal | HeaderCard "Balance" cell |
| `status` | enum | StatusChip (Active/Inactive) |
| `transactions[].id` | Long | Hidden — list key |
| `transactions[].date` | LocalDate | TransactionTile leading (bodySmall) |
| `transactions[].reference` | String | TransactionTile title (bodyMedium) |
| `transactions[].debit` | Decimal? | TransactionTile center (error color) |
| `transactions[].credit` | Decimal? | TransactionTile center (success color) |
| `transactions[].runningBalance` | Decimal | TransactionTile right (bodySmall onSurfaceVariant) |

#### 3.3 Invoice List — `GET /finance/invoices` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `invoiceNo` | String | InvoiceTile title (titleMedium) |
| `partyName` | String | InvoiceTile middle row (bodyMedium) — vendor or customer name |
| `date` | LocalDate | InvoiceTile bottom-left (bodySmall onSurfaceVariant) |
| `dueDate` | LocalDate | (Hidden — drives "Overdue" red tint on amount when past) |
| `amount` | Decimal | InvoiceTile bottom-right (titleMedium) |
| `currency` | String | Prefix on amount ("$ 1,234") |
| `status` | enum | StatusChip top-right (DRAFT / PENDING_APPROVAL / APPROVED / REJECTED / PAID) |

#### 3.4 Invoice Detail — `GET /finance/invoices/{id}` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| (header fields per 3.3) | | HeaderCard 2-col grid |
| `status` | enum | Large StatusChip centered + drives ActionRow visibility |
| `lineItems[].id` | Long | Hidden — row key |
| `lineItems[].description` | String | Item row title |
| `lineItems[].qty` | Decimal | Qty column |
| `lineItems[].unitPrice` | Decimal | Unit price column |
| `lineItems[].taxPct` | Decimal? | Tax column ("12%") |
| `lineItems[].total` | Decimal | Line total column |
| `subtotal` / `taxTotal` / `total` | Decimal | Footer summary row (titleMedium bold on total) |
| `approvalHistory[].actorName` | String | ApprovalTimeline avatar + name |
| `approvalHistory[].action` | enum | ApprovalTimeline action chip (SUBMITTED/APPROVED/REJECTED) |
| `approvalHistory[].actionedAt` | Instant | ApprovalTimeline timestamp |
| `approvalHistory[].comment` | String? | ApprovalTimeline body |

#### 3.5 Create/Edit Invoice — `POST /finance/invoices` / `PATCH /finance/invoices/{id}` `[conventional]`

Request body shape (echoed back on response):

| Field | Type | UI input |
|---|---|---|
| `customerId` / `vendorId` | Long | 7.7 Picker (modal sheet with search) |
| `invoiceDate` | LocalDate | 7.6 DateField |
| `dueDate` | LocalDate | 7.6 DateField |
| `lineItems[].description` | String | 7.1 TextField per row |
| `lineItems[].qty` | Decimal | 7.3 Numeric field per row |
| `lineItems[].unitPrice` | Decimal | 7.3 Numeric field per row |
| `lineItems[].taxPct` | Decimal? | 7.3 Numeric field per row |
| `attachments[]` | URL[] | 7.8 File picker (multi) |

#### 3.6 Journal Entry List — `GET /finance/journal` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `reference` | String | Tile title (titleMedium) |
| `date` | LocalDate | Tile top-right (bodySmall) |
| `description` | String | Tile middle (bodyMedium onSurfaceVariant) |
| `debitTotal` | Decimal | Tile bottom-left (error color) |
| `creditTotal` | Decimal | Tile bottom-right (success color) |

#### 3.7 Trial Balance Report — `GET /finance/reports/trial-balance` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `period` | String (YYYY-MM) | AppBar subtitle |
| `rows[].accountCode` | String | Table column 1 (bodyMedium, monospace) |
| `rows[].accountName` | String | Table column 2 (bodyMedium) |
| `rows[].debit` | Decimal | Table column 3 (right-aligned) |
| `rows[].credit` | Decimal | Table column 4 (right-aligned) |
| `totals.debit` | Decimal | SummaryRow left (titleMedium error color) |
| `totals.credit` | Decimal | SummaryRow right (titleMedium success color) |

---

### 13.4 Module 4 — Procurement

> Endpoints + DTOs conventional. Same pattern as Finance (3.3–3.5).

#### 4.1 Purchase Request List — `GET /procurement/requests` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `prNumber` | Long / String | Hidden + Tile title |
| `requesterName` / `department` | String | Tile middle (bodyMedium) |
| `date` / `estimatedAmount` | LocalDate / Decimal | Tile bottom row |
| `status` | enum | StatusChip |

#### 4.2 Create Purchase Request — `POST /procurement/requests` `[conventional]`

Request fields (echoed on response):

| Field | Type | UI input |
|---|---|---|
| `costCenterId` | Long | 7.4 Dropdown |
| `approverId` | Long | 7.7 Searchable picker |
| `items[].description` / `qty` / `estimatedCost` | String / Decimal / Decimal | Dynamic line-item rows (7.1 + 7.3 + 7.3) |
| `attachments[]` | URL[] | 7.8 File picker |

#### 4.3 Purchase Request Detail — `GET /procurement/requests/{id}` `[conventional]`

Same shape as Invoice Detail (3.4) — fields go into HeaderCard, line items table, ApprovalTimeline.

#### 4.4 Purchase Order List — `GET /procurement/orders` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `poNumber` | Long / String | Hidden + Tile title |
| `vendorName` | String | Tile middle (bodyMedium) |
| `orderDate` | LocalDate | Tile bottom-left (bodySmall) |
| `totalAmount` | Decimal | Tile bottom-right (titleMedium) |
| `status` | enum | StatusChip (DRAFT/CONFIRMED/RECEIVED/CANCELLED) |

#### 4.5 Purchase Order Detail — `GET /procurement/orders/{id}` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `poNumber` / `vendorName` / `orderDate` / `expectedDeliveryDate` / `total` | | HeaderCard 2-col grid |
| `status` | enum | Large StatusChip centered |
| `lineItems[].itemName` / `qtyOrdered` / `qtyReceived` / `unitPrice` / `total` | | LineItemsTable rows; received qty tinted success (full) / warning (partial) |
| `canRecordReceipt` | bool | Drives visibility of "Record Goods Receipt" button |

#### 4.6 Goods Receipt Entry — `POST /procurement/orders/{id}/receipt` `[conventional]`

Request:

| Field | Type | UI input |
|---|---|---|
| `receiptDate` | LocalDate | 7.6 DateField |
| `lines[].itemId` | Long | Hidden — row key from PO |
| `lines[].qtyReceived` | Decimal | 7.3 Large numeric input (48×48) |

#### 4.7 Vendor List — `GET /procurement/vendors` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `name` | Long / String | Hidden + Tile title |
| `category` | String | Tile subtitle chip |
| `paymentTerms` | String | Tile subtitle (bodySmall) |
| `rating` | int (0-5) | Trailing star row (warning color) |
| `avatarUrl` | String? | Leading circle (NetworkImage + auth headers) |

#### 4.8 Vendor Detail — `GET /procurement/vendors/{id}` + `/scorecard` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| Profile fields | | ProfileCard 2-col grid |
| `scorecard.onTimeDeliveryPct` | double | ScorecardCard cell with success/warning/error color |
| `scorecard.qualityRating` | double | ScorecardCard star row |
| `scorecard.totalSpend` | Decimal | ScorecardCard cell (titleMedium) |
| `scorecard.activePoCount` | int | ScorecardCard cell |
| `recentOrders[]` | (per 4.4) | POHistoryTile ListView |

---

### 13.5 Module 5 — Inventory & Warehouse

> Endpoints conventional. Item DTO confirmed in schema discussions.

#### 5.1 Item Catalog — `GET /inventory/items` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `sku` | String | Tile subtitle (bodySmall onSurfaceVariant, monospace) |
| `name` | String | Tile title (titleMedium) |
| `imageUrl` | String? | Leading 40×40 image (NetworkImage + auth); fallback SKU initials |
| `stockQty` | Decimal | Stock badge — color by ratio to minStock |
| `minStock` | Decimal | Hidden — drives badge tint |
| `unit` | String | Trailing (bodySmall) |
| `warehouseName` | String | Hidden — drives the per-row filter |

#### 5.2 Item Detail — `GET /inventory/items/{id}` + `/movements` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `sku` / `category` / `unit` / `warehouseName` / `location` | | ItemHeaderCard 2-col grid |
| `stockQty` | Decimal | StockLevelCard hero value (headlineLarge, color by level) |
| `minStock` | Decimal | StockLevelCard footer ("Min: 20") |
| (computed) stockPct | double | StockProgressBar fill (success/warning/error) |
| `movements[].date` / `type` / `qty` / `reference` | | MovementTile (type chip color: Issue=error, Receipt=success, Transfer=info) |

#### 5.3 Barcode Scanner — `GET /inventory/items?barcode={code}` `[conventional]`

Response on hit:

| API field | Type | UI location |
|---|---|---|
| `name` / `sku` | String | ResultBottomSheet title + subtitle |
| `stockQty` / `unit` | Decimal / String | ResultBottomSheet StockBadge |

#### 5.4 Goods Issue/Receipt — `POST /inventory/transactions` `[conventional]`

Request:

| Field | Type | UI input |
|---|---|---|
| `type` | enum (ISSUE/RECEIPT) | 7.5 Segmented (or pill if pre-selected) |
| `itemId` | Long | 7.7 Scan-or-search picker |
| `qty` | Decimal | 7.3 Large numeric (56px) |
| `reference` | String | 7.1 Text field ("PO# or SO#") |
| `locationId` | Long | 7.4 Dropdown |

#### 5.5 Stock Transfer — `POST /inventory/transfers` `[conventional]`

Request:

| Field | Type | UI input |
|---|---|---|
| `fromWarehouseId` / `toWarehouseId` | Long | 7.4 Dropdowns with directional arrow between |
| `lines[].itemId` / `qty` | Long / Decimal | Dynamic item rows (each: name + 7.3 qty) |

#### 5.6 Cycle Count — `GET /inventory/count-sessions/active` + `POST /submit` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `sessionId` | Long | Hidden — submit path |
| `warehouseName` / `date` | String / LocalDate | AppBar subtitle |
| `items[].itemId` / `sku` / `name` / `expectedQty` | | CountItemRow leading + title + expected badge |
| (input) `actualQty` | Decimal | 7.3 ActualQtyInput (48×48) per row |
| (computed) variance | Decimal | VarianceFeedback (match/surplus/missing icon + label) |
| `progress` | "12 / 48" | ProgressRow (LinearProgressIndicator) |

---

### 13.6 Module 6 — Sales & CRM

> Endpoints conventional.

#### 6.1 Customer List — `GET /sales/customers` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `fullName` / `companyName` | String | Tile title (titleMedium) |
| `lastOrderDate` | LocalDate? | Tile subtitle (bodySmall onSurfaceVariant) |
| `avatarUrl` | String? | Leading avatar circle |
| `phone` | String? | Trailing phone-call icon button (`tel:` intent) |

#### 6.2 Customer Detail — `GET /sales/customers/{id}` + `/contacts` + `/activity` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| Profile fields | | ProfileCard 2-col grid (Phone/Email/Address/Payment Terms/Credit Limit) |
| `category` | String | Category chip in hero |
| `contacts[].name` / `role` / `phone` / `email` | | ContactRow (avatar 32×32 + name + call/email icons) |
| `activity[].type` | enum | Timeline icon (order/call/note, colored by type) |
| `activity[].title` / `date` | String / Instant | Timeline title + relative time |

#### 6.3 Sales Quotation List — `GET /sales/quotations` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `quotationNo` | Long / String | Hidden + Tile title |
| `customerName` | String | Tile middle |
| `validityDate` | LocalDate | Tile bottom-left (bodySmall) |
| `total` | Decimal | Tile bottom-right (titleMedium) |
| `status` | enum | StatusChip (DRAFT/SENT/ACCEPTED/REJECTED) |

#### 6.4 Create/Edit Quotation — `POST/PATCH /sales/quotations` `[conventional]`

| Field | Type | UI input |
|---|---|---|
| `customerId` | Long | 7.7 Customer picker (modal) |
| `validityDate` | LocalDate | 7.6 DateField |
| `lineItems[].productName` / `qty` / `unitPrice` / `discountPct` / `taxPct` | | Dynamic line-item rows |
| Computed `subtotal` / `discount` / `tax` / `total` | Decimal | TotalSummaryCard right-aligned |

#### 6.5 Sales Order Detail — `GET /sales/orders/{id}` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `orderNo` / `customerName` / `orderDate` / `deliveryDate` | | OrderHeaderCard |
| `fulfillmentSteps[].name` / `status` | String / enum | FulfillmentStepper (Confirmed→Picking→Shipped→Delivered) with active/done/pending tint |
| `lineItems[].name` / `qtyOrdered` / `qtyShipped` / `status` | | LineItemsTable rows |

#### 6.6 Sales Analytics — `GET /sales/analytics?period=` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `revenueSeries[].date` / `amount` | LocalDate / Decimal | `fl_chart` LineChart |
| `topCustomers[].name` / `totalSpend` | String / Decimal | TopCustomersTable rows |
| `leaderboard[].avatarUrl` / `name` / `totalSales` | | SalesRepLeaderboard rows |

#### 6.7 Create Customer — `POST /sales/customers` `[conventional]`

| Field | Type | UI input |
|---|---|---|
| `avatarFile` | multipart | 7.8 Avatar picker |
| `fullName` / `companyName` | String | 7.1 Name field |
| `customerType` | enum (COMPANY/INDIVIDUAL) | 7.5 Segmented |
| `phone` / `email` / `address` | String | 7.3 + 7.3 + 7.2 |
| `paymentTerms` | enum | 7.4 Dropdown (Net 7 / Net 15 / Net 30 / Net 60 / COD) |
| `creditLimit` | Decimal | 7.3 Numeric (currency prefix) |
| `currency` | String | 7.4 Dropdown (THB / USD / EUR) |
| `taxId` | String? | 7.1 (optional) |
| `contacts[]` | array | Dynamic ContactRow list (each: name + role + phone + email) |

#### 6.8 Edit Customer — `PATCH /sales/customers/{id}` `[conventional]`

Same fields as 6.7, pre-filled from `GET /sales/customers/{id}`.

---

### 13.7 Module 7 — Human Resources

> Employee DTO confirmed (see Module 9.9 / employees feature). Leave +
> attendance + payroll endpoints conventional.

#### 7.1 Employee Directory — `GET /employees` `[partially confirmed]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `fullName` | String | Tile title (titleMedium) |
| `position` | String? | Tile subtitle ("· " separator) |
| `department` | String? | Tile subtitle |
| `avatarUrl` | String? | Leading avatar (NetworkImage + auth headers) |

#### 7.2 Employee Profile — `GET /employees/{id}` + `/documents` `[confirmed for /me]`

Personal tab:

| API field | Type | UI location |
|---|---|---|
| `dateOfBirth` | LocalDate? | InfoRow |
| `address` | String? | InfoRow |
| `emergencyContact` | String? | InfoRow |
| `emergencyPhone` | String? | InfoRow |

Employment tab:

| API field | Type | UI location |
|---|---|---|
| `employeeNo` | String | InfoRow |
| `hireDate` | LocalDate? | InfoRow |
| `position` | String? | InfoRow |
| `department` | String? | InfoRow |
| `status` | enum | InfoRow + StatusChip |

Documents tab:

| API field | Type | UI location |
|---|---|---|
| `documents[].name` / `url` | String | DocumentTile + download icon |

#### 7.3 Org Chart — `GET /employees/org-chart` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `managerId` | Long / Long? | Hidden — drives tree layout |
| `name` | String | OrgChartNode title |
| `position` | String? | OrgChartNode subtitle |
| `avatarUrl` | String? | OrgChartNode avatar |

#### 7.4 Leave Request Form — `POST /hr/leave-requests` `[conventional]`

Request:

| Field | Type | UI input |
|---|---|---|
| `leaveType` | enum | 7.4 Dropdown (Annual/Sick/Unpaid/Maternity/...) |
| `fromDate` / `toDate` | LocalDate | Inline calendar (range highlight) |
| Computed `workingDays` | int | LeaveDayCount label (titleMedium primary) |
| `reason` | String | 7.2 Multiline (3 rows) |

`GET /hr/leave-balances/me` feeds:

| API field | Type | UI location |
|---|---|---|
| `balances[].type` / `total` / `used` / `remaining` | | LeaveBalanceCard progress bar |

#### 7.5 My Leave List — `GET /hr/leave-requests?userId=me` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `leaveType` | enum | LeaveTypeChip top-left |
| `fromDate` / `toDate` | LocalDate | "12 May → 16 May" (bodyMedium) |
| `workingDays` | int | bodySmall onSurfaceVariant ("3 working days") |
| `status` | enum | StatusChip top-right |

#### 7.6 Manager Leave Approval — `GET /hr/leave-requests?status=PENDING&forManager=me` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `employee.avatarUrl` / `fullName` | | PendingLeaveCard top row |
| `leaveType` / `workingDays` | enum / int | LeaveTypeChip + duration badge |
| `reason` | String | Card body (bodyMedium, max 2 lines) |
| `fromDate` / `toDate` | LocalDate | Right-aligned date range |

#### 7.7 Attendance Log — `GET /hr/attendance?userId=me&month=` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `today.clockInAt` | Instant? | TodayCard hero (headlineLarge or "Not clocked in") |
| `today.elapsedSec` | int? | TodayCard subtitle ("4h 23m on shift") |
| `today.isClockedIn` | bool | Drives button color/text (Clock In success / Clock Out error) |
| `daily[].date` / `clockInAt` / `clockOutAt` / `totalHours` / `status` | | AttendanceDayRow + calendar dot color |

#### 7.8 Payslip Viewer — `GET /hr/payslips?userId=me&month=` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `netPay` | Decimal | NetPayCard (displayLarge primary) |
| `earnings[].label` / `amount` | String / Decimal | EarningsCard rows |
| `earningsTotal` | Decimal | EarningsCard footer (success color) |
| `deductions[].label` / `amount` | String / Decimal | DeductionsCard rows |
| `deductionsTotal` | Decimal | DeductionsCard footer (error color) |
| `pdfUrl` | String | "View PDF" OutlinedButton href |

#### 7.9 Leave Approval Detail — `GET /hr/leave-requests/{id}` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `employee.avatarUrl` / `fullName` / `department` | | EmployeeContextCard hero |
| `employee.remainingDaysThisYear` | int | bodySmall under name |
| `leaveType` / `fromDate` / `toDate` / `workingDays` / `submittedAt` | | RequestDetailCard 2-col grid |
| `reason` | String | ReasonCard body (selectable bodyLarge) |
| `attachedDocumentUrl` | String? | AttachedDocRow (paperclip + filename) |
| `balanceBefore` / `balanceIfApproved` | int | BalancePreviewCard ("If approved: X days remaining") |
| `history[]` | array | ApprovalTimeline |

---

### 13.8 Module 8 — Project Management

> Endpoints conventional.

#### 8.1 Project List — `GET /projects` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `name` | Long / String | Hidden + Tile title |
| `manager.avatarUrl` / `fullName` | | ProjectTile manager row (24×24 + bodySmall) |
| `dueDate` | LocalDate | "Due {date}" (bodySmall) |
| `progressPct` | int (0-100) | ProgressBar fill + "{N}% complete" |
| `status` | enum | StatusChip |

#### 8.2 Project Detail / Gantt — `GET /projects/{id}` + `/tasks` + `/members` + `/files` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `name` / `code` / `client.name` | String | ProjectHeaderCard |
| `budget` / `startDate` / `endDate` / `progressPct` | | HeaderCard 3-col + ProgressBar |
| `status` | enum | StatusChip in AppBar |
| `tasks[].id` / `name` / `startDate` / `endDate` / `status` / `dependsOn[]` | | Gantt bars (color by status); connector lines from `dependsOn` |
| `members[].avatarUrl` / `fullName` / `role` | | Team tab list |
| `files[].name` / `url` / `sizeBytes` | | Files tab list |

#### 8.3 Task Kanban Board — `GET /projects/{id}/tasks` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` / `title` | Long / String | KanbanCard title (titleMedium) |
| `status` | enum | Determines column placement |
| `assignees[].avatarUrl` | array | AssigneeAvatarRow (24×24, overlapping -8px) |
| `priority` | enum (LOW/MED/HIGH/CRITICAL) | PriorityBadge (colored dot + label) |
| `dueDate` | LocalDate? | DueDateRow (overdue=error, today=warning, future=onSurfaceVariant) |

#### 8.4 Task Detail — `GET /tasks/{id}` + `/comments` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `title` | String | AppBar (truncated) |
| `status` / `priority` | enum | TaskHeaderCard chips |
| `assignee.avatarUrl` / `fullName` | | AssigneeRow (32×32 + name) |
| `dueDate` | LocalDate? | DueDateRow (error color if overdue) |
| `description` | String | DescriptionCard (selectable bodyLarge) |
| `subtasks[].id` / `title` / `done` | | SubtaskList (Checkbox + name with strikethrough when done) |
| `comments[].author.avatarUrl` / `fullName` / `createdAt` / `body` | | CommentTile (avatar 32×32 + name+time + body) |

#### 8.5 Timesheet Entry — `GET /timesheets?weekStart=` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `weekStart` | LocalDate | AppBar week label |
| `tasks[].id` / `name` | Long / String | TimesheetTaskRow leading (fixed 120px) |
| `tasks[].cells[].day` / `hours` | int (0-6) / Decimal | HoursCell per day (48×48) |
| Computed `dailyTotals[7]` / `weekTotal` | Decimal | Footer row (titleMedium bold) |

#### 8.6 Utilization Report — `GET /utilization?period=` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `summary.avgUtilizationPct` | double | TeamSummaryCard hero (headlineLarge) |
| `summary.aboveTargetCount` / `totalCount` | int | TeamSummaryCard body ("X of Y members above target") |
| `target.pct` | double | BarChart dashed horizontal line |
| `members[].avatarUrl` / `fullName` / `hours` / `utilizationPct` | | MemberUtilizationRow + progress bar |

#### 8.7 Create/Edit Project — `POST/PATCH /projects` `[conventional]`

| Field | Type | UI input |
|---|---|---|
| `name` | String | 7.1 Required |
| `description` | String? | 7.2 Multiline (3 rows) |
| `clientId` | Long? | 7.7 Customer picker |
| `startDate` / `endDate` | LocalDate | 7.6 + 7.6 with computed duration |
| `budget` | Decimal | 7.3 Numeric (currency prefix) |
| `billingType` | enum (FIXED/T_AND_M/RETAINER) | 7.5 Segmented |
| `projectManagerId` | Long | 7.4 Searchable dropdown (required) |
| `memberIds[]` | Long[] | 7.7 Multi-picker (chips with remove ×) |
| `status` | enum (ACTIVE/ON_HOLD/COMPLETED) | 7.5 Segmented |
| `priority` | enum (LOW/MED/HIGH/CRITICAL) | 7.5 Segmented (High=warning, Critical=error) |

#### 8.8 Assign / Reassign Task — `PATCH /tasks/{id}` `[conventional]`

Context fetched via `GET /projects/{projectId}/members?withWorkload=true`:

| API field | Type | UI location |
|---|---|---|
| `members[].avatarUrl` / `fullName` / `role` | | TeamMemberTile |
| `members[].openTaskCount` | int | WorkloadBadge (≤3=info, 4-6=warning, 7+=error) |
| `members[].availability` | enum (AVAILABLE/PARTIAL/AWAY) | AvailabilityDot (green/warning/grey) |

Request:

| Field | Type | UI input |
|---|---|---|
| `assigneeId` | Long | Tap-to-select row |
| `dueDate` | LocalDate? | 7.6 DateField |
| `noteToAssignee` | String? | 7.2 Multiline (optional) |

#### 8.9 Task Create / Edit — `POST/PATCH /tasks` `[conventional]`

| Field | Type | UI input |
|---|---|---|
| `title` | String | 7.1 Large 2-row TextField |
| `status` | enum | 7.5 Segmented icons |
| `priority` | enum | 7.5 Segmented icons |
| `assigneeId` | Long? | Tap row → opens 8.8 sheet |
| `dueDate` | LocalDate? | 7.6 DateField |
| `description` | String? | 7.2 Multiline (4 rows min) |
| `subtasks[].title` / `done` | String / bool | Dynamic Checkbox + TextField rows |

---

### 13.9 Module 9 — Settings & Administration

> Repository contracts confirmed (RoleDto / UserDto / EmployeeDto /
> AssignRolesRequest pasted in source).

#### 9.1 Settings Home

No new API — reads from `CachedUserDao` (drift).

| Local read | Type | UI location |
|---|---|---|
| `name` / `email` / `avatarUrl` | String | UserProfileCard hero |
| `roles` | List<String> | Role chip (uses `isSuperAdmin()` to gate Administration section) |

#### 9.2 User Preferences

No API — `PreferencesRepository` reads/writes `shared_preferences`.

| Local field | Type | UI input |
|---|---|---|
| `themeMode` | enum (LIGHT/DARK/SYSTEM) | 7.5 Segmented |
| `locale` | String | 7.4 Bottom sheet picker |
| `notifPrefs[type]` | bool | Switch row per type |

#### 9.3 Active Sessions — `GET /auth/sessions/me` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — revoke path |
| `deviceName` / `os` | String | SessionTile title + subtitle |
| `lastActiveAt` | Instant | Subtitle "Last active …" |
| `isCurrent` | bool | Drives "This device" banner + hides RevokeButton |

#### 9.4 Audit Log Viewer — `GET /audit?...` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — list key |
| `actionType` | enum (CREATE/UPDATE/DELETE/APPROVE) | Leading icon color (success/info/error/primary) |
| `actionLabel` | String | Tile title (titleMedium) |
| `userName` / `module` | String | Tile subtitle |
| `createdAt` | Instant | Tile trailing (bodySmall) |
| `recordRef` | String | DetailBottomSheet deep link |
| `payload` | JSON | DetailBottomSheet (monospace bodySmall, scrollable) |

#### 9.5 User Management — `GET /users` **[confirmed]**

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — nav handle |
| `email` | String | UserManagementTile subtitle |
| `fullName` | String | UserManagementTile title |
| `phone` | String? | (Not shown in list) |
| `enabled` | bool | StatusBadge (Active=successContainer / Inactive=surfaceVariant) |
| `roles` | Set<String> | Role chip (formatted via `_formatRoleCode`) |

#### 9.6 Role & Permission Editor — `GET /roles` + `/roles/permissions` **[confirmed]**

| API field | Type | UI location |
|---|---|---|
| `roles[].id` / `code` / `name` | Long / String / String | Matrix header columns |
| `roles[].permissions` | Set<String> | Drives checkbox states per row |
| `roles[].isSystem` / `system` | bool? | SYSTEM badge in header (locks editing) |
| `permissions[].token` (or string) | String | Matrix row labels |
| `permissions[].description` | String? | Row tooltip / subtitle |

#### 9.7 API / Environment Config

No backend — local storage via `ApiEnvironmentsRepository`.

| Local field | Type | UI input |
|---|---|---|
| `environment` | enum (PRODUCTION/STAGING/CUSTOM) | 7.5 Segmented |
| `baseUrl` | String | 7.1 (visible only when CUSTOM) |
| `tenantId` | String | 7.1 (visible only when CUSTOM) |

#### 9.8 PIN Lock / Biometric Re-Auth

No API — PIN hash in `flutter_secure_storage`.

| Local read | Type | UI location |
|---|---|---|
| `cached_user.name` | String | "Hello Name" label |
| `pinHash` (from secure storage) | String | Compared to entered digits |
| `attemptsRemaining` | int (state) | Error text "X attempts remaining" |

#### 9.9 My Profile Info — `GET /employees/me` **[confirmed]**

| API field | Type | UI location |
|---|---|---|
| `id` | Long | Hidden — used as PATCH path param |
| `employeeNo` | String | Contact section · _InfoRow |
| `fullName` | String | HeroCard name (headlineLarge, onPrimary) |
| `workEmail` | String? | Contact section · _InfoRow ("Email") + 7.3 Edit field |
| `phone` | String? | Contact section · _InfoRow ("Phone") + 7.3 Edit field |
| `position` | String? | HeroCard subtitle (inline with department) |
| `department` | String? | HeroCard subtitle (with "·" separator) |
| `dateOfBirth` | LocalDate? | Personal section · _InfoRow + 7.6 Edit field |
| `address` | String? | Personal section · _InfoRow + 7.2 Edit field (multiline) |
| `emergencyContact` | String? | Personal section · _InfoRow + 7.1 Edit field |
| `emergencyPhone` | String? | Personal section · _InfoRow + 7.3 Edit field |
| `avatarUrl` | String? | HeroCard avatar via NetworkImage (with `Authorization: Bearer …` headers) |
| `avatarUploadedAt` | Instant? | Hidden — used for cache busting |
| `lastLoginAt` | Instant | Account Security · LastLoginRow ("Last login: {date}") |
| `status` | enum (ACTIVE/INACTIVE/...) | (Reserved — not displayed yet) |
| `tenure` | String? | Hero subtitle chip ("2y 5m" via backend-computed display) |

PATCH `/employees/{id}` request body (echoed on response):

| Field | Type | UI input |
|---|---|---|
| `fullName` | String | 7.1 Edit mode |
| `workEmail` | String? | 7.3 Edit mode |
| `phone` | String? | 7.3 Edit mode |
| `address` | String? | 7.2 Edit mode |
| `dateOfBirth` | LocalDate? | 7.6 Edit mode |
| `position` | String? | (Not in current form — admin-only via 9.5) |
| `emergencyContact` | String? | 7.1 Edit mode |
| `emergencyPhone` | String? | 7.3 Edit mode |

Avatar upload: `POST /employees/me/avatar` multipart, key `file`. Response returns updated EmployeeDto with new `avatarUrl`.

#### 9.10 My Roles & Permissions — `GET /users/me` **[confirmed]**

| API field | Type | UI location |
|---|---|---|
| `roles` | Set<String> | RoleChipRow (each chip = role code formatted to "Super Admin") |
| `permissions` | Set<String> | Granted permission list (searchable, grouped by module) |

(No comparison list — would require `/roles/permissions` which is super-admin only.)

---

### 13.10 Module 10 — Chat & Voice / Video

> WebSocket message envelopes + SQLite-backed offline cache.

#### 10.1 Chat Inbox — `GET /chat/conversations` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | String | Hidden — nav handle |
| `name` | String | ConversationTile title (titleMedium, w600 if unread) |
| `avatarUrl` | String? | Leading avatar 52×52 (direct) OR group cluster |
| `isGroup` | bool | Drives avatar shape (single vs 3-avatar cluster) |
| `isMuted` | bool | MutedIcon (bell-off 14×14) |
| `lastMessageBody` | String | Tile subtitle (with type prefix: 📎 / 🎤 / "You: " etc.) |
| `lastMessageSenderId` | String | Hidden — drives "You: " prefix |
| `lastMessageAt` | Instant | Timestamp right-aligned (bodySmall) |
| `unreadCount` | int | UnreadBadge (warningContainer, "99+" cap) |
| `onlineStatus` | enum | OnlineStatusDot bottom-right of avatar |

#### 10.2 Chat Conversation — `GET /chat/conversations/{id}/messages` `[conventional]`

| API field | Type | UI location |
|---|---|---|
| `id` | String | Hidden — reply/edit/delete handle |
| `senderId` / `senderName` / `senderAvatarUrl` | String | Avatar 28×28 (left, group only) + name above first bubble |
| `body` | String? | TextBubble content (bodyLarge, selectable) |
| `type` | enum (text/voice/image/file/system) | Drives bubble variant |
| `replyToId` / `replyToBody` / `replyToSenderName` | | ReplyQuote above bubble |
| `editedBody` / `editedAt` | | "(edited)" label |
| `isDeleted` | bool | DeletedBubble fallback |
| `fileUrl` / `fileName` / `fileSizeBytes` | | FileBubble (icon + name + size) |
| `voiceUrl` / `voiceDurationSec` | | VoiceBubble (waveform + duration) |
| `sentAt` / `deliveredAt` / `readAt` | Instant | Bubble footer + read-receipt checkmarks |
| `reactions[].emoji` / `employeeIds[]` | array | ReactionRow below bubble |

#### 10.3 New Conversation — `POST /chat/conversations` `[conventional]`

| Field | Type | UI input |
|---|---|---|
| `type` | enum (DIRECT/GROUP) | 7.5 Segmented |
| `name` | String? | 7.1 (GROUP only, required) |
| `avatarFile` | multipart | 7.8 Avatar picker (GROUP only) |
| `participantIds[]` | array | 7.7 Multi-picker via SelectableMemberTile |

#### 10.4 Message Search

No API — local SQLite FTS5.

| Local read | Type | UI location |
|---|---|---|
| `chat_messages.body` (FTS) | String | MessageSearchResultTile preview (matched term highlighted primary w600) |
| `sender_id` → `senderName` | String | Result tile title |
| `sent_at` | Instant | Result tile timestamp |

#### 10.5 Voice Call

No REST. WebSocket envelopes:

| Wire envelope | Fields | UI consequence |
|---|---|---|
| `call.invite` | `{callId, callerId, callerName, targetIds, callType}` | Shows incoming sheet on every callee in `targetIds` |
| `call.accept` | `{callId, accepterId}` | Caller transitions to Connected; timer starts both sides |
| `call.reject` | `{callId, reason?}` | Caller's call ends; snackbar reason on reject |
| `call.hangup` | `{callId, hangerUpperId}` | All non-caller peers stay if caller is the one who hung up |

Also writes to `chat_call_log`:

| Field | Type | UI location |
|---|---|---|
| `callerId` / `callType` | String / enum | Call hero (avatar + "Voice Call" label) |
| `startedAt` / `answeredAt` / `endedAt` | Instant | In-call timer (counts from answeredAt) |
| `durationSeconds` | int | Post-call snackbar + chat call-log entry |
| `status` | enum (missed/answered/rejected/no_answer) | Call-log row tint (missed=error red) |

#### 10.6 Video Call

Same envelopes as 10.5, plus:

| UI element | Source |
|---|---|
| RemoteVideoView | `RTCVideoRenderer` from WebRTC stream (signalled out-of-band) |
| LocalVideoPreview PiP | Local `RTCVideoRenderer`, mirrored when front camera |
| CameraToggleButton | Local state — toggles `isCameraOn` on the `MediaStreamTrack` |
| FlipCameraButton | Local state — calls `Helper.switchCamera()` on the video track |

#### 10.7 Chat Settings / Conversation Info — `GET /chat/conversations/{id}` `[conventional]`

Direct view:

| API field | Type | UI location |
|---|---|---|
| `otherParticipant.avatarUrl` / `fullName` / `role` | | ProfileCard hero |
| `otherParticipant.onlineStatus` / `lastSeenAt` | enum / Instant | Status line under name |

Group view:

| API field | Type | UI location |
|---|---|---|
| `name` / `avatarUrl` | String / String? | GroupHeaderCard (editable for admins) |
| `memberCount` / `onlineCount` | int | "X members · Y online" |
| `pinnedMessage` | object? | PinnedMessageRow (jumps to message on tap) |
| `participants[].employeeId` / `fullName` / `avatarUrl` / `isAdmin` | | MemberRow + AdminBadge |
| `mediaPreview[].thumbnailUrl` | array | MediaCard 3-col grid (80×80) |
| `isMuted` | bool | MuteRow Switch |

---
- Architectural rules → §3
- Wiring without `get_it` → §4
- API layers (DTO → DataSource → Repository → BLoC → Page) → §5
- BLoC contract → §6
- UI field reference (8 patterns) → §7
- Task templates → §8
- Anti-patterns → §9
- Verification checklist → §10
- Reference snippets → §11
- **Module + screen catalog (all 72 screens) → §12**
  - Module 0 App Entry → §12.0
  - Module 1 Auth → §12.1
  - Module 2 Dashboard → §12.2
  - Module 3 Finance → §12.3
  - Module 4 Procurement → §12.4
  - Module 5 Inventory → §12.5
  - Module 6 Sales → §12.6
  - Module 7 HR → §12.7
  - Module 8 Projects → §12.8
  - Module 9 Settings → §12.9
  - Module 10 Chat & Voice → §12.10
- **Wire field reference (API → UI per screen) → §13**
  - same module subsections as §12 (13.0 … 13.10)
