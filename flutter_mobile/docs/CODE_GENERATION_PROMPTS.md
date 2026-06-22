# Code Generation Prompts — ERP Mobile

> Use this document to prompt an AI (Claude, Cursor, Copilot, etc.) to
> generate code that fits **this** project. Paste the relevant sections
> into your prompt — they encode the project's architectural rules,
> design tokens, file conventions, and gotchas so the AI doesn't have
> to guess.

## Table of Contents

1. [How to use this doc](#1-how-to-use-this-doc)
2. [Project context block (always paste this)](#2-project-context-block-always-paste-this)
3. [Architectural rules](#3-architectural-rules)
4. [Code style rules](#4-code-style-rules)
5. [Common task templates](#5-common-task-templates)
   - [5.1 Add a new screen to an existing module](#51-add-a-new-screen-to-an-existing-module)
   - [5.2 Add a new BLoC](#52-add-a-new-bloc)
   - [5.3 Add a new repository](#53-add-a-new-repository)
   - [5.4 Add a new field to an entity](#54-add-a-new-field-to-an-entity)
   - [5.5 Add a reusable widget to `lib/shared/widgets/`](#55-add-a-reusable-widget-to-libsharedwidgets)
   - [5.6 Add a new wire envelope to the chat module](#56-add-a-new-wire-envelope-to-the-chat-module)
   - [5.7 Add a new permission scope](#57-add-a-new-permission-scope)
   - [5.8 Fix a bug](#58-fix-a-bug)
6. [Output verification checklist](#6-output-verification-checklist)
7. [Anti-patterns to reject](#7-anti-patterns-to-reject)
8. [Reference snippets](#8-reference-snippets)

---

## 1. How to use this doc

For any AI prompt, build it in three layers:

```
┌─────────────────────────────────────────────────────────┐
│  1. PROJECT CONTEXT (§2)        ← always paste verbatim │
├─────────────────────────────────────────────────────────┤
│  2. TASK TEMPLATE (§5)          ← pick the closest one  │
├─────────────────────────────────────────────────────────┤
│  3. YOUR SPECIFIC REQUEST        ← what you actually want│
└─────────────────────────────────────────────────────────┘
```

The AI's output should then be checked against **§6 verification
checklist** before you accept the diff.

---

## 2. Project context block (always paste this)

Copy this entire fenced block into the start of any code-gen prompt.
It tells the AI what tools to use, what rules to follow, and where to
find the rest.

```
PROJECT: Enterprise ERP Mobile — Flutter app.

PRIMARY DOCS (read first):
- CLAUDE.md — slice-level history, guardrails, module/phase/slice plan.
- ERP_MOBILE_DESIGN_GUIDE.md — visual spec: tokens, components, per-screen layouts, BLoC contracts.
- docs/PROJECT_GUIDE.md — whole-project reference + test cases.
- docs/CHAT_MODULE_GUIDE.md — Module 10 functional reference.
- docs/CODE_GENERATION_PROMPTS.md — this doc.

TECH STACK:
- Flutter ">=3.35.0", Dart "^3.9.2"
- flutter_bloc + equatable for state
- get_it (manual register*Module per feature) — NOT injectable codegen for new code
- go_router with AppRouter.rootNavigatorKey
- dio for HTTP, web_socket_channel for chat relay
- drift for local DB (some modules); chat stays in-memory
- flutter_secure_storage for tokens (NEVER store tokens in drift)
- freezed + json_serializable for models
- image_picker, mobile_scanner, fl_chart, path_provider

ARCHITECTURE — TWO LAYOUTS COEXIST:
- Modules 1–9: legacy MVVM + Clean (abstract repo + UseCase classes). When EDITING these, keep that pattern.
- Module 10 + any NEW feature: flat MVVM (single concrete repo, NO UseCase classes, NO abstract interface).

NEVER MIX styles inside the same feature.

DESIGN TOKENS — never hardcode:
- Colors: AppTheme.* (lib/core/theme/app_theme.dart)
- Radii:  AppRadii.sm/md/lg/xl/pill
- Spacing: AppSpacing.xs(4)/sm(8)/md(16)/lg(24)/xl(32)/xxl(48)
- Text:   AppLabel.* (NEVER raw TextStyle)
- Shadows: AppShadow.card / .modal

CONTENT CONTAINERS:
- Use AppCard for content blocks, never raw Container with decoration.
- Empty list state: shared/widgets EmptyState; never blank.
- Loading on lists: LoadingShimmer; never CircularProgressIndicator alone.

RBAC:
- Permission scopes are strings like 'finance.approve', 'hr.approve'.
- Wrap admin-only widgets with PermissionGuard(scope: '...').
- Repos that mutate must also enforce the scope (defense in depth).

CHAT TRANSPORT (Module 10 only):
- Wire envelopes carry targetIds: List<String> for routing.
- Sender includes participantIds; receiver drops if its userId not in targetIds.
- For new envelopes, follow the pattern in lib/features/chat/data/chat_transport.dart.

OUT OF SCOPE for the demo:
- Real WebRTC, FCM background push, encryption, real auth.
- These are noted as "production path" in CLAUDE.md slices.
```

---

## 3. Architectural rules

Hard rules — paste these verbatim if the AI ignores them on first pass.

### 3.1 Repository pattern

| Doing | Module 10 + new code | Modules 1–9 |
|---|---|---|
| Repo type | Single concrete class | Abstract interface + concrete impl |
| Business rules location | Inside the concrete repo | UseCase classes under `domain/usecases/` |
| Stream contract | Expose `Stream<List<X>>` for lists, `Stream<X?>` for single records | Same |
| Mutation | `Future<X>` returning the new state, then `_emit()` on a broadcast `StreamController` | Same |

### 3.2 BLoC contract (where used)

```dart
// Events
sealed class XEvent {}
class XLoaded extends XEvent { final String id; }
class XActionRequested extends XEvent { ... }

// States
sealed class XState {}
class XInitial extends XState {}
class XLoading extends XState {}
class XLoaded extends XState { final ... data; }
class XFailure extends XState { final String message; }

// BLoC
class XBloc extends Bloc<XEvent, XState> {
  XBloc(this._repo) : super(XInitial()) {
    on<XLoaded>(_onLoaded);
    on<XActionRequested>(_onAction);
  }
  final XRepository _repo;
  ...
}
```

**Rule:** every `BlocBuilder` must use `buildWhen:` to minimise rebuilds.

### 3.3 Storage boundary

| Data | Goes in |
|---|---|
| JWT / refresh tokens | `flutter_secure_storage` — NEVER drift, NEVER shared_preferences |
| User profile (name, avatar URL, biometric flag, last_login_at) | drift `cached_user` table |
| Permissions | drift `user_permissions` table |
| Offline transactions | drift `sync_queue` table |
| OTP code, PKCE verifier | memory only — never persisted |
| Chat conversations / messages / call log | in-memory (will be drift in production) |
| App preferences (theme, locale, notif prefs) | drift `cached_user_preferences` |

### 3.4 No-`BuildContext`-in-BLoC

A BLoC, ViewModel, or repository must never accept a `BuildContext`.
Pass plain data in, return plain data out.

---

## 4. Code style rules

### 4.1 File naming

| Item | Convention | Example |
|---|---|---|
| Page | `<feature>_page.dart` | `invoice_detail_page.dart` |
| BLoC | `<feature>_bloc.dart` + `_event.dart` + `_state.dart` | `invoice_action_bloc.dart` |
| Repository | `<entity>_repository.dart` | `conversations_repository.dart` |
| Entity | `<entity>.dart` (singular) | `chat_message.dart` |
| Widget | `<widget>.dart` (snake_case) | `avatar_picker_sheet.dart` |
| Shared widget | `lib/shared/widgets/<widget>.dart` | `permission_guard.dart` |

### 4.2 Imports

Group order (Dart convention):

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// 4. Project — absolute paths only (NEVER relative ../../ except inside the same feature folder)
import 'package:erp_mobile/core/theme/app_theme.dart';

// 5. Relative — only within the same feature
import '../data/repositories/...';
import '../entities/...';
```

### 4.3 Widget composition

- Split into small private widget classes (one per visual section).
- One file per page; private widgets at the bottom of the same file
  unless they exceed ~80 lines (then split).
- Const constructors wherever possible.

### 4.4 Comments

- Default: no comments. Code should be self-documenting.
- Add a comment only when the **why** is non-obvious — a hidden
  constraint, a subtle invariant, a workaround for a specific bug
  (cite the slice if applicable).
- Never describe what the code does. Never reference the current task
  or PR.

### 4.5 Documentation references

When the change is part of a tracked slice (CLAUDE.md), name it in
the relevant comment:

```dart
// Slice 10.3.6 — base64-encode the picked file so peer devices can
// reconstruct the avatar in their own cache dir.
```

---

## 5. Common task templates

For each template:
- Paste **§2 project context** first.
- Then paste the template.
- Then add your specific request.

### 5.1 Add a new screen to an existing module

```
TASK: Add a new screen [SCREEN NAME] to Module [N] ([MODULE NAME]).

REFERENCE the existing pages under lib/features/<module>/presentation/pages/
to match style, navigation patterns, AppBar usage, and BLoC wiring.

DELIVERABLES:
1. New page file at lib/features/<module>/presentation/pages/<name>_page.dart
2. Route entry in lib/core/router/app_router.dart (+ RoutePaths if new)
3. If new state: BLoC at lib/features/<module>/presentation/bloc/<name>_bloc.dart
4. If new data: repository method on the existing repo (don't create a new repo unless data is genuinely separate)
5. Wire DI in the module's register*Module function

RULES:
- Pattern: [flat MVVM | legacy Clean] — use the same one as the rest of this module.
- AppBar: use DynamicAppBar from core/widgets if the page uses the gradient background, else MaterialApp default.
- Background: AppBackgroundGradient + DynamicStatusBar wrapper if the design calls for the gradient.
- Loading state: LoadingShimmer placeholder, NEVER CircularProgressIndicator on lists.
- Empty state: EmptyState widget.
- Permission gating: PermissionGuard wrapper if the screen or its actions require a scope.

OUTPUT:
- The full new file(s).
- Diffs for any edited file (router, repo, DI registration).
- Run `flutter analyze lib/features/<module>` mentally and report any issues.
```

### 5.2 Add a new BLoC

```
TASK: Add a BLoC for [WHAT].

PATTERN (flat MVVM):
- Events: sealed class with named subclasses (Loaded, ActionRequested, FilterChanged, etc.).
- States: sealed class with Initial, Loading, Loaded(data), Failure(message).
- Forms use a separate FormBLoC variant with FieldChanged + Valid/Invalid/Saving/Success/Failure states.
- Constructor takes the repository (or repos); no BuildContext.

DELIVERABLES:
- lib/features/<module>/presentation/bloc/<name>_event.dart
- lib/features/<module>/presentation/bloc/<name>_state.dart
- lib/features/<module>/presentation/bloc/<name>_bloc.dart
- Register in the module's register*Module function as registerFactory.

USE in the page with BlocProvider + BlocBuilder. EVERY BlocBuilder must have buildWhen.
```

### 5.3 Add a new repository

```
TASK: Add a repository for [ENTITY].

NEW CODE → flat MVVM:
- File: lib/features/<module>/data/repositories/<entity>_repository.dart
- Single concrete class, no abstract interface.
- Construct with its data dependencies (dio, dao, transport, etc.).
- Expose:
  - Future<List<X>> getAll()
  - Stream<List<X>> watchAll() async* { yield await getAll(); yield* _changes.stream; }
  - Future<X?> findById(String id)
  - Future<X> create(X draft) (with id auto-gen if empty)
  - Future<X> update(...) (mutation methods)
  - All mutations emit on a broadcast StreamController.

LEGACY CODE (Modules 1–9) → Clean:
- domain/repositories/<entity>_repository.dart (abstract)
- data/repositories/<entity>_repository_impl.dart (concrete)
- domain/usecases/<verb>_<entity>_usecase.dart per business operation

Register in the module's register*Module function as registerLazySingleton.
```

### 5.4 Add a new field to an entity

```
TASK: Add a [FIELD NAME] field of type [TYPE] to the [ENTITY] entity.

ENTITY LOCATION: lib/features/<module>/entities/<entity>.dart

STEPS:
1. Add the field to the constructor (as required if mandatory, else nullable + named).
2. Add to copyWith (with a clearX bool flag if it's a nullable field that needs explicit clearing).
3. If the entity is freezed-generated, run `dart run build_runner build`.
4. Update every constructor call site (use grep).
5. Update the wire encoder/decoder if the entity goes over the wire (chat: _encodeMessage / _decodeMessage in chat_transport.dart).
6. Update the seed if it's seeded (chat_seed.dart for chat).

GOTCHAS:
- Sealed class switches will break if the entity is part of one — they're exhaustive.
- copyWith for nullable fields needs `bool clearX = false` to differentiate "leave alone" from "set to null".
- If used by a Stream-watching widget, no extra work — the stream emits the new instance.
```

### 5.5 Add a reusable widget to `lib/shared/widgets/`

```
TASK: Extract [WIDGET] into a reusable widget at lib/shared/widgets/<name>.dart.

PATTERN:
- Public widget with named parameters.
- Sensible defaults; only `required` what truly has no default.
- Const constructor.
- No imports from any specific feature — only core/theme, shared/widgets, and Flutter SDK.
- If it's a sheet/dialog: expose a static `show(...)` helper that returns the user's choice, NOT a callback approach (see AvatarPickerSheet for example).

DELIVERABLES:
- The new widget file.
- Edits to every CALL SITE — replace the inline duplicate with a call to the new widget.
- DELETE the now-dead local widget classes (don't leave them lying around).
- Run flutter analyze on each touched file.

EXAMPLES already in the codebase:
- lib/shared/widgets/avatar_picker_sheet.dart (sheet pattern with enum result)
- lib/shared/widgets/permission_guard.dart (gating wrapper)
- lib/shared/widgets/app_background_gradient.dart (decorative)
```

### 5.6 Add a new wire envelope to the chat module

```
TASK: Add a new wire envelope `[type.name]` carrying [WHAT].

REFERENCE: lib/features/chat/data/chat_transport.dart — copy the pattern of ConversationCreatedEvent (Slice 10.1.7) or CallAcceptEvent.

STEPS:
1. Add the typed event class at the top of chat_transport.dart:

   class XYZEvent extends ChatTransportEvent {
     const XYZEvent({ required ..., this.targetIds = const <String>[] });
     final ...;
     final List<String> targetIds; // include if directed
   }

2. Add to the `_decode` switch:

   case '<type.name>':
     return XYZEvent(
       ...: payload['...'] as ...,
       targetIds: (payload['targetIds'] as List?)?.cast<String>() ?? const <String>[],
     );

3. Add a send method:

   void sendXyz({ required ..., List<String> targetIds = const <String>[] }) {
     _send('<type.name>', {
       '...': ...,
       if (targetIds.isNotEmpty) 'targetIds': targetIds,
     });
   }

4. In lib/features/chat/chat_di.dart, extend the transport.events.listen
   block with an `else if (event is XYZEvent) { ... }` branch that calls
   a new private handler function.

5. Add the no-op case in lib/features/chat/data/repositories/messages_repository.dart applyInbound switch (it's exhaustive).
6. Add the no-op case in lib/features/chat/data/call_signaling_service.dart _onEvent switch if applicable.
7. Add a call site in the appropriate page/repo that actually broadcasts.
8. Document the new slice in CLAUDE.md under the appropriate phase.
9. Update docs/CHAT_MODULE_GUIDE.md wire-envelope table.

RUN: `flutter analyze lib/features/chat`
```

### 5.7 Add a new permission scope

```
TASK: Add permission scope `[module.action]` and gate [WIDGET / ROUTE].

STEPS:
1. Add the scope to the seed in lib/features/auth/data/demo_sign_in.dart (or wherever permissions are seeded).
2. If gating a ROUTE: add to lib/core/router/route_access.dart mapping.
3. If gating a WIDGET: wrap with PermissionGuard(scope: 'module.action', child: ...).
4. Add the human label to lib/features/settings/.../my_roles_page.dart label map (Slice 9.1.5).
5. If a repo enforces it (defense in depth), add a check that throws PermissionFailure when violated.

TEST: TC-RBAC.1 / TC-RBAC.2 from docs/PROJECT_GUIDE.md.
```

### 5.8 Fix a bug

```
TASK: Fix [BUG DESCRIPTION].

REPRODUCTION:
[Concrete steps you followed and what went wrong.]

EXPECTED:
[What should have happened.]

INVESTIGATE FIRST:
- Read the relevant files end-to-end before changing anything.
- Identify the root cause — don't patch symptoms.
- Check CLAUDE.md slices touching the affected area; the bug may be a regression of a documented fix.

FIX:
- Minimal change.
- Comment with the WHY (especially if it looks weird — what was the prior bug?).
- Document the fix as a new slice in CLAUDE.md if it's notable.

VERIFY:
- Run `flutter analyze` on the touched path.
- Write the test case for it in docs/CHAT_MODULE_GUIDE.md or docs/PROJECT_GUIDE.md.
```

---

## 6. Output verification checklist

Before accepting AI-generated code, check:

**Structure**
- [ ] Files are in the right module folder (`lib/features/<module>/...`).
- [ ] Naming matches §4.1.
- [ ] No new `domain/usecases/` or abstract repo in new code (would
      mix layouts; only legitimate when editing Modules 1–9).

**Tokens**
- [ ] No hardcoded colors — only `AppTheme.*` / `Theme.of(context)`.
- [ ] No hardcoded sizes — only `AppSpacing.*` / `AppRadii.*`.
- [ ] No raw `TextStyle` — only `AppLabel.*` or `theme.textTheme.*`.

**Patterns**
- [ ] Lists use `LoadingShimmer` while loading, `EmptyState` if empty.
- [ ] Content blocks use `AppCard`, not raw `Container` with decoration.
- [ ] Permission-gated UI wrapped in `PermissionGuard`.
- [ ] Every `BlocBuilder` has `buildWhen`.

**BLoC / repo**
- [ ] No `BuildContext` in any BLoC / repo / use case.
- [ ] Streams properly closed in `close()` / `dispose()`.
- [ ] No business logic in `build()` — read from BLoC / stream only.

**Chat module specifically**
- [ ] New wire events filter by `targetIds`.
- [ ] Sealed switches in `messages_repository.dart` and
      `call_signaling_service.dart` updated (they're exhaustive).
- [ ] CLAUDE.md updated with the new slice description.

**Process**
- [ ] `flutter analyze lib/features/<module>` clean.
- [ ] Test cases added to `docs/PROJECT_GUIDE.md` (or chat guide).

---

## 7. Anti-patterns to reject

If the AI generates any of these, push back:

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| `Color(0xFF...)` in a widget | Hardcoded; breaks theme switching | `Theme.of(context).colorScheme.X` or `AppTheme.X` |
| `TextStyle(fontSize: 16, ...)` | Hardcoded; breaks typography hierarchy | `AppLabel.X` or `theme.textTheme.X` |
| `SizedBox(height: 16)` | Off-grid spacing | `SizedBox(height: AppSpacing.md)` |
| `Container(decoration: BoxDecoration(...))` as a content block | Bypasses the `AppCard` convention | `AppCard(child: ...)` |
| `CircularProgressIndicator()` directly in a list area | Loading state should be shimmer | `LoadingShimmer(...)` |
| New abstract `XRepository` interface in a new module | Wrong layout for new code | Single concrete class |
| New `UseCase` class in a new module | Wrong layout for new code | Business rule lives in the repo or BLoC |
| `Navigator.of(context, rootNavigator: true)` from a widget outside the router subtree | The context can't find a Navigator there (Slice 10.2.9 lesson) | `AppRouter.rootNavigatorKey.currentState!.push(...)` |
| New `BlocBuilder` without `buildWhen` | Rebuilds on every state | Add `buildWhen: (prev, next) => ...` |
| Storing JWT in drift "for caching" | Security boundary violation (user memory: `feedback_secure_storage_for_tokens`) | `flutter_secure_storage` only |
| `'You: $body'` prefix passed to `updateLastMessage` | Inbox tile re-prepends, causing "You: You: …" (Slice 10.1.8 Bug C) | Pass raw body; inbox `_previewFor` adds the prefix |
| New chat wire event without `targetIds` filtering | Cross-user leakage (Slice 10.1.8 Bug A) | Always include `targetIds` and filter on receive |
| Wiring DI with `@injectable` codegen for new code | Project uses manual `register*Module` now | Add to the existing `register*Module(getIt)` function |
| Files / dirs created with `mkdir`-style commands instead of via Write tool | Bypasses harness file tracking | Use Write tool |
| Test files written (Flutter widget tests) | Local Flutter 3.35.7 has `widget_tester.dart` commented out — tests fail at SDK level (user memory) | Skip widget tests unless explicitly requested |

---

## 8. Reference snippets

### 8.1 BLoC skeleton (flat MVVM)

```dart
// events
sealed class InvoiceListEvent {}
class InvoiceListLoaded extends InvoiceListEvent {}
class InvoiceListFilterChanged extends InvoiceListEvent {
  const InvoiceListFilterChanged(this.status);
  final InvoiceStatus? status;
}

// states
sealed class InvoiceListState {}
class InvoiceListInitial extends InvoiceListState {}
class InvoiceListLoading extends InvoiceListState {}
class InvoiceListReady extends InvoiceListState {
  const InvoiceListReady(this.invoices);
  final List<Invoice> invoices;
}
class InvoiceListFailure extends InvoiceListState {
  const InvoiceListFailure(this.message);
  final String message;
}

// bloc
class InvoiceListBloc extends Bloc<InvoiceListEvent, InvoiceListState> {
  InvoiceListBloc(this._repo) : super(InvoiceListInitial()) {
    on<InvoiceListLoaded>(_onLoaded);
    on<InvoiceListFilterChanged>(_onFilter);
  }

  final InvoiceRepository _repo;
  InvoiceStatus? _filter;

  Future<void> _onLoaded(_, Emitter emit) async {
    emit(InvoiceListLoading());
    try {
      final all = await _repo.getAll(status: _filter);
      emit(InvoiceListReady(all));
    } catch (e) {
      emit(InvoiceListFailure(e.toString()));
    }
  }

  Future<void> _onFilter(InvoiceListFilterChanged e, Emitter emit) async {
    _filter = e.status;
    add(InvoiceListLoaded());
  }
}
```

### 8.2 Repository skeleton (flat MVVM)

```dart
class InvoiceRepository {
  InvoiceRepository(this._api, this._dao);
  final InvoiceApi _api;
  final InvoiceDao _dao;

  final _changes = StreamController<List<Invoice>>.broadcast();

  Stream<List<Invoice>> watchAll() async* {
    yield await getAll();
    yield* _changes.stream;
  }

  Future<List<Invoice>> getAll({InvoiceStatus? status}) async {
    final remote = await _api.list(status: status).catchError((_) => null);
    if (remote != null) {
      await _dao.upsertAll(remote);
      _changes.add(remote);
      return remote;
    }
    return await _dao.getAll(status: status);
  }

  Future<Invoice> approve(String id, String approverId) async {
    final updated = await _api.approve(id, approverId);
    await _dao.upsert(updated);
    _changes.add(await _dao.getAll());
    return updated;
  }
}
```

### 8.3 Page scaffold with gradient + dynamic AppBar

```dart
class InvoiceListPage extends StatelessWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(title: 'Invoices', centerTitle: true),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            BlocProvider(
              create: (_) => InvoiceListBloc(GetIt.I())..add(InvoiceListLoaded()),
              child: BlocBuilder<InvoiceListBloc, InvoiceListState>(
                buildWhen: (prev, next) => prev.runtimeType != next.runtimeType,
                builder: (context, state) => switch (state) {
                  InvoiceListLoading() => const LoadingShimmer(),
                  InvoiceListFailure(:final message) =>
                    Center(child: Text(message)),
                  InvoiceListReady(:final invoices) when invoices.isEmpty =>
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No invoices',
                      subtitle: 'Tap + to create one.',
                    ),
                  InvoiceListReady(:final invoices) =>
                    _InvoiceList(invoices: invoices),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: PermissionGuard(
        scope: 'finance.write',
        child: FloatingActionButton.extended(
          onPressed: () => ConfigRouter.pushPageAnimation(
            context,
            const InvoiceFormPage(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('New Invoice'),
        ),
      ),
    );
  }
}
```

### 8.4 New chat wire envelope (end-to-end)

```dart
// 1. lib/features/chat/data/chat_transport.dart — add event class
class MessagePinnedEvent extends ChatTransportEvent {
  const MessagePinnedEvent({
    required this.conversationId,
    required this.messageId,
    required this.participantIds,
  });
  final String conversationId;
  final String messageId;
  final List<String> participantIds;
}

// 2. Add to _decode switch
case 'message.pin':
  return MessagePinnedEvent(
    conversationId: payload['conversationId'] as String,
    messageId: payload['messageId'] as String,
    participantIds:
        (payload['participantIds'] as List?)?.cast<String>() ?? const <String>[],
  );

// 3. Add send method
void sendMessagePinned({
  required String conversationId,
  required String messageId,
  required List<String> participantIds,
}) {
  _send('message.pin', {
    'conversationId': conversationId,
    'messageId': messageId,
    'participantIds': participantIds,
  });
}

// 4. lib/features/chat/chat_di.dart — handle inbound
} else if (event is MessagePinnedEvent) {
  unawaited(_applyInboundPin(event, conversations, messages, settings));
}

Future<void> _applyInboundPin(
  MessagePinnedEvent event,
  ConversationsRepository conversations,
  MessagesRepository messages,
  ChatSettings settings,
) async {
  if (event.participantIds.isNotEmpty &&
      !event.participantIds.contains(settings.userId)) {
    return;
  }
  try {
    await conversations.setPinnedMessage(event.conversationId, event.messageId);
  } catch (_) {}
}

// 5. Add no-op cases in the sealed switches (messages_repository.dart, call_signaling_service.dart)
case MessagePinnedEvent():
  break;

// 6. Call site (where the user actually pins)
GetIt.I<ChatTransport>().sendMessagePinned(
  conversationId: convId,
  messageId: msgId,
  participantIds: participantIdsForConv,
);
```

---

> When in doubt, **read the existing slice that does something similar**
> (CLAUDE.md is your index) and copy its pattern. The codebase already
> contains the right answer for almost every common task.
