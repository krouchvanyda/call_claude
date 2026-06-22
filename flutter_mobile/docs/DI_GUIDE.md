# Dependency Injection Guide — `get_it` + `injectable`

> Why this project uses `get_it` + `injectable`, when to use what, and the
> alternatives that have been considered. Read this before proposing a
> refactor of the DI layer.

---

## 1. What each library does (in one sentence)

| Library | Job |
|---|---|
| **`get_it`** | A global service locator. Register an instance/factory by type, ask for it later via `GetIt.I<X>()`. |
| **`injectable`** | A code generator that emits `get_it.register*` calls for any class annotated `@injectable` / `@lazySingleton` / etc. — so you don't hand-write the wiring. |
| **`flutter_bloc`** | UI state management. **Not a DI mechanism** — BLoCs still need to be told where their repositories come from. |

These solve **different** problems. BLoCs do not replace `get_it`. DI is about *who gets what*; BLoC is about *what state the UI should render*.

---

## 2. Why this project uses them

1. **Cross-cutting deps without prop-drilling.** The `AuthInterceptor` needs `TokenStorage`, `TokenRefresher`, and `SessionSignal`. The dashboard BLoCs need `UsersRemoteDataSource`. The splash needs `AuthSession` + `TokenStorage`. Threading those through six constructor layers is painful — a service locator skips it.

2. **Abstraction-first wiring.** Repos depend on abstract interfaces (`UsersRemoteDataSource`), not concrete implementations (`DioUsersRemoteDataSource`). The DI module decides which implementation to bind:

   ```dart
   getIt.registerLazySingleton<UsersRemoteDataSource>(
     () => DioUsersRemoteDataSource(dio: getIt<Dio>()),
   );
   ```

   In a test you'd register a `MockUsersRemoteDataSource` instead. Zero changes at the call sites.

3. **Lazy cold-start.** `registerLazySingleton` only constructs the object on **first** `GetIt.I<X>()` call. The full graph isn't built upfront — just the splash + login chain runs on cold start.

4. **Auto-wiring via annotations.** `injectable` reads `@injectable` / `@lazySingleton` annotations and generates the registration code. Adding a new repository = add the annotation + run `dart run build_runner build`. No DI module to edit by hand.

---

## 3. How the wiring is laid out in this codebase

| File | Role |
|---|---|
| [`lib/core/di/register_module.dart`](../lib/core/di/register_module.dart) | Hand-written `@module` factories for things that need parameters — `Dio` with its base URL, `TokenStorage(secrets)`, etc. |
| [`lib/core/di/injection.dart`](../lib/core/di/injection.dart) | `configureDependencies()` — called once from `main.dart` to run every registration. |
| [`lib/core/di/injection.config.dart`](../lib/core/di/injection.config.dart) | **Generated.** Every `@injectable` class gets a `registerLazySingleton(...)` line here. Don't edit by hand. |
| `lib/features/<module>/<module>_di.dart` | Per-module manual registration. Used for repos that need conditional or compositional wiring (e.g. [`settings_di.dart`](../lib/features/settings/settings_di.dart) registers `MyProfileRepository(employees: …, tokens: …)`). |
| Consumers | `GetIt.I<UsersRemoteDataSource>()` / `GetIt.I<AuthRepository>()` — reads instances without constructor plumbing. |

The codebase mixes the two styles deliberately:
- **`injectable` for stateless things** with a constructor that takes other registered types — let the generator handle it.
- **Manual `getIt.register*` in module DI files** when explicit control reads better than chasing annotations across files.

### Common annotations cheat-sheet

| Annotation | Lifetime | When to use |
|---|---|---|
| `@injectable` | New instance every request | Per-call factories (e.g. a fresh `ChangeNotifier`) |
| `@lazySingleton` | One instance, created on first request | **Default for most things** — repos, data sources, services |
| `@singleton` | One instance, created at startup | Things that must exist before anyone asks (rare here) |
| `@module` + factory methods | Whatever each factory returns | When the constructor needs runtime parameters (env config, base URLs) |

---

## 4. Alternatives considered

If you're thinking about removing `get_it` or `injectable`, read this section first — these are the four real options.

### Option A — Replace `get_it` with `RepositoryProvider` / `BlocProvider`

Use `flutter_bloc`'s built-in providers at the app root:

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<TokenStorage>(create: (_) => SecureTokenStorage(secrets)),
    RepositoryProvider<AuthRepository>(create: (ctx) => AuthRepository(
      tokens: ctx.read<TokenStorage>(),
      // ... 12 more dependencies
    )),
    // ... 100+ more
  ],
  child: MaterialApp(...),
)
```

Then read with `context.read<AuthRepository>()` instead of `GetIt.I<AuthRepository>()`.

**Cost**: ~100+ files changed. The app root becomes a 500-line provider tree.

**Showstopper**: `AuthInterceptor` runs in the Dio layer — no `BuildContext`, can't reach `context.read`. With `RepositoryProvider` you'd have to plumb it as a constructor dep through four layers of Dio setup, which is exactly the problem `get_it` solves. Same issue for any push-handler / background-isolate code.

**Verdict**: ❌ Not recommended.

### Option B — Pure constructor injection (no DI library)

Wire everything by hand in `main.dart`. Every class takes its deps as constructor parameters.

**Cost**: ~150+ files. `main.dart` becomes huge. Cross-cutting infra (interceptors, push, analytics) gets awkward because it lives outside the widget tree.

**Verdict**: ❌ Not recommended at this scale.

### Option C — Keep `get_it`, drop only `injectable`

Hand-write the registrations in module DI files (the pattern `settings_di.dart` already uses). No annotations, no `build_runner`.

**Cost**: ~30 files. Annotations become explicit `register*` calls. Call sites unchanged.

**When to consider**: if `build_runner` is meaningfully slowing your dev loop, OR if you want every registration visible without grepping for annotations across files.

**Verdict**: 🟡 Reasonable trade-off, not urgent.

### Option D — Status quo (keep both)

What we have now.

**Cost**: Zero.

**Verdict**: ✅ Current default.

---

## 5. Decision matrix

| Your situation | Recommendation |
|---|---|
| "I don't understand `get_it` / `injectable`" | Re-read sections 1–3 of this doc; don't refactor |
| "`build_runner` is slow / I hate code-gen" | Option C — drop `injectable`, keep `get_it` |
| "Service locator is an anti-pattern, on principle" | It's debatable. Option A *would* hurt this codebase concretely — talk it through before committing |
| "I want fewer pub deps" | `get_it` is ~50KB and zero runtime cost. Not worth a 100-file refactor |
| Anything else | Default: keep both. They're doing the job correctly. |

---

## 6. Recipe — adding a new dependency

### Stateless class with auto-wireable constructor

```dart
@lazySingleton
class CustomersRepository {
  CustomersRepository({
    required CustomersRemoteDataSource remote,
    required AppLogger logger,
  })  : _remote = remote,
        _logger = logger;

  final CustomersRemoteDataSource _remote;
  final AppLogger _logger;
}
```

Then:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Use it:

```dart
final repo = GetIt.I<CustomersRepository>();
```

### Class that needs a runtime parameter (env, base URL, custom config)

Hand-write in the module DI file:

```dart
// lib/features/customers/customers_di.dart
void registerCustomersModule(GetIt getIt) {
  if (!getIt.isRegistered<CustomersRemoteDataSource>()) {
    getIt.registerLazySingleton<CustomersRemoteDataSource>(
      () => DioCustomersRemoteDataSource(
        dio: getIt<Dio>(),
        // anything else with runtime config
      ),
    );
  }
}
```

Then call `registerCustomersModule(getIt)` from `main.dart` after `configureDependencies()`.

### Binding an abstract interface to an implementation

```dart
@LazySingleton(as: PaymentGateway)
class StripePaymentGateway implements PaymentGateway { ... }
```

Consumers ask for the abstract type; DI hands back the concrete one:

```dart
final gateway = GetIt.I<PaymentGateway>(); // returns StripePaymentGateway
```

In tests, register a mock implementation before the test runs:

```dart
getIt.registerSingleton<PaymentGateway>(MockPaymentGateway());
```

---

## 7. Don'ts

- ❌ **Don't edit `injection.config.dart`** — it's regenerated by `build_runner`. Your changes will be wiped on the next build.
- ❌ **Don't `GetIt.I<X>()` inside `build()`** — fetch in `initState` (for widgets) or constructor (for BLoCs/repos). Calling on every rebuild works but obscures dependencies.
- ❌ **Don't register the same type twice** without an `isRegistered` guard. The hot-restart scenario will throw. Manual modules use `if (!getIt.isRegistered<X>())` for exactly this reason.
- ❌ **Don't use `GetIt.I` as a `Map<String, dynamic>`** — that's `GetIt.I.get<X>(instanceName: 'name')` territory, only used here for tagged singletons (rare, e.g. multiple `Dio` instances).

---

## 8. Further reading

- [`get_it` README](https://pub.dev/packages/get_it) — official docs
- [`injectable` README](https://pub.dev/packages/injectable) — annotation reference
- Project layout: see [`CLAUDE.md`](../CLAUDE.md) §"Project Architecture" for where DI sits in the overall MVVM + BLoC structure
