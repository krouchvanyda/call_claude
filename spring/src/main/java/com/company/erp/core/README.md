# `core/` — framework-level concerns

Cross-cutting infrastructure used by every feature module under
`features/<name>/`. Nothing here owns business logic — it's the
scaffolding that lets each feature stay small.

```
core/
├── audit/        ← who/when wrote each row (Spring Data JPA auditing)
├── bootstrap/    ← runs once on first boot (seed admin, backfill employees)
├── config/       ← typed @ConfigurationProperties binding for app.* in application.yml
├── database/     ← base entity + paged-list query convention
├── exceptions/   ← typed app exceptions + global @RestControllerAdvice handler
├── response/     ← the API envelope every endpoint returns
├── security/     ← JWT auth, RBAC permissions, security filter chain
└── web/          ← request-id MDC, rate limiter, OpenAPI, health, static uploads
```

---

## `audit/` — JPA auditing

| File | Purpose |
|---|---|
| `AuditorAwareConfig.java` | Tells Spring Data JPA who the "current auditor" is, so `@CreatedBy` / `@LastModifiedBy` on [`database/BaseEntity`](database/BaseEntity.java) get populated automatically from the authenticated user on every insert / update. |

---

## `bootstrap/` — one-shot startup tasks

`ApplicationRunner` beans that idempotently seed required state on boot.
Each one logs and is safe to leave enabled forever.

| File | What it does |
|---|---|
| `AdminBootstrap.java` | On first boot, creates `admin@company.local` / `Admin@12345` with the `SUPER_ADMIN` role. Idempotent — skips if already present. Required because bcrypt can't be produced in SQL. |
| `EmployeeBackfillBootstrap.java` | On every boot, creates an `Employee` row for any `User` without one. Numbers them `EMP-<userId padded to 5>`. Skips users that already have an employee. |

---

## `config/` — typed configuration

| File | Purpose |
|---|---|
| `AppProperties.java` | A single `@ConfigurationProperties(prefix = "app")` record that binds every `app.*` key in [`application.yml`](../../../../../resources/application.yml). Includes nested records for `Security.Jwt`, `Cors`, `RateLimit`, `Stream`, `Fcm`, and `Uploads.Avatar`. Inject this anywhere you need to read tuned values — never `@Value(...)` directly. |

---

## `database/` — JPA conventions

| File | Purpose |
|---|---|
| `BaseEntity.java` | `@MappedSuperclass` every entity extends. Adds `Long id` (IDENTITY generation), `createdAt` / `updatedAt` (via Spring auditing), and `createdBy` / `updatedBy` (via `audit/AuditorAwareConfig`). |
| `PageQuery.java` | Shared request shape for paginated list endpoints — `page` (1-indexed), `pageSize` (clamped 1–100), `search`, `sort=field:asc|desc`. Converts to a Spring `Pageable` against an explicit per-controller whitelist of sort fields. Used by every controller's list method. |

---

## `exceptions/` — typed errors + global handler

Domain exceptions extend `AppException` and carry an HTTP status + stable
error code. The global handler converts them into the standard envelope
defined in `response/`.

| File | Purpose |
|---|---|
| `AppException.java` | Base — wraps `HttpStatus` + `errorCode` + message. |
| `BadRequestException.java` | 400 — validation rules, malformed input. |
| `UnauthorizedException.java` | 401 — missing / invalid / expired credentials. |
| `ForbiddenException.java` | 403 — authenticated but lacks permission or membership. |
| `NotFoundException.java` | 404 — entity not found. |
| `ConflictException.java` | 409 — uniqueness or version conflict (e.g. email already in use). |
| `GlobalExceptionHandler.java` | `@RestControllerAdvice` — maps `AppException`, Bean Validation errors, Spring's framework exceptions (`HttpMessageNotReadableException`, `MissingServletRequestParameterException`, etc.), and uncaught `Throwable`s into the `ApiResponse` envelope with a stable `errorCode`. |

---

## `response/` — the API envelope

Every endpoint returns this exact shape:

```json
{ "success": true, "message": "Success",
  "data": { ... }, "errorCode": null, "traceId": "0f1c…" }
```

| File | Purpose |
|---|---|
| `ApiResponse.java` | The envelope record itself. |
| `PageResponse.java` | Wrapper for paginated `data` — `{ items[], page, pageSize, totalItems, totalPages }`. Has a `from(Page, mapper)` helper that does the entity → DTO conversion. |
| `ResponseEnvelopeAdvice.java` | `ResponseBodyAdvice` that auto-wraps any controller return value in the envelope, so controllers can `return UserDto.from(u)` and the wrapping happens transparently. |
| `ErrorCodes.java` | String constants used in `errorCode` (`VALIDATION_FAILED`, `BAD_REQUEST`, `UNAUTHORIZED`, …). Keep clients pinned to these — they're the contract. |
| `FieldError.java` | One row of `{ field, message }` returned in validation errors. |
| `ValidationErrorPayload.java` | `{ fieldErrors: FieldError[] }` — the `data` payload of a `VALIDATION_FAILED` response. |

---

## `security/` — authentication + authorisation

JWT-based, stateless, RBAC.

| File | Purpose |
|---|---|
| `SecurityConfig.java` | The Spring Security filter chain — CSRF disabled, stateless sessions, CORS from `AppProperties`, the `permitAll` list (auth endpoints, `/health`, `/docs`, `/ws`, `/uploads`, …), and registers the JWT filter. Also defines the `BCryptPasswordEncoder` and the CORS configuration source. |
| `Permissions.java` | Compile-time string constants for every permission code (`user:read`, `chat:write`, …). Referenced by every `@PreAuthorize("hasAuthority(Permissions.X)")` in controllers. Keep in sync with the `V3` seed migration. |
| `JwtService.java` | Issues and parses access + refresh JWTs (jjwt). TTL + secret come from `AppProperties.Security.Jwt`. Access tokens carry `sub`, `email`, `pms[]`, `typ=access`. Refresh tokens carry `sub`, `jti`, `typ=refresh`. |
| `JwtAuthFilter.java` | `OncePerRequestFilter` — reads `Authorization: Bearer …`, validates via `JwtService`, builds an `AuthenticatedUser` principal, and places it on the `SecurityContext` so `@PreAuthorize` and `AuthenticatedUser.require()` work. |
| `AuthenticatedUser.java` | The principal record on the `SecurityContext` — `{userId, email, permissions}`. `AuthenticatedUser.require()` is the canonical accessor inside controllers. |
| `RestAuthenticationEntryPoint.java` | Returns a JSON `UNAUTHORIZED` envelope (not the default HTML page) when the filter chain rejects an anonymous request to a protected endpoint. |
| `RestAccessDeniedHandler.java` | Returns a JSON `FORBIDDEN` envelope when an authenticated user lacks the required permission. |

---

## `web/` — HTTP-layer plumbing

| File | Purpose |
|---|---|
| `RequestIdFilter.java` | Reads or generates `X-Request-Id` per request, puts it in MDC so every log line is correlated, and echoes it back as a response header. The `traceId` field in the API envelope comes from here. |
| `RateLimitFilter.java` | In-memory Bucket4j token bucket per client IP. Two buckets: a tighter one in front of `/api/v1/auth/*`, a normal one for everything else. TTL + limits come from `AppProperties.RateLimit`. Single-instance only — multi-instance needs Redis. |
| `OpenApiConfig.java` | Configures springdoc-openapi — sets the SwaggerUI at `/docs`, declares the `Bearer` security scheme, and tags the auth endpoints as public. |
| `HealthController.java` | `GET /health` — lightweight liveness probe. Returns `{status: "UP"}`. Use `/actuator/health` for richer details. |
| `UploadsWebConfig.java` | Maps the upload public URL prefix (`/uploads/avatars/**`) to the on-disk directory configured in `app.uploads.avatar.dir`. That's how avatars survive the round-trip from "store in `./uploads/avatars/<file>`" to "served via `Image.network(avatarUrl)`". |

---

## How a feature uses `core/`

A typical request flow exercises almost everything here:

1. **`web/RequestIdFilter`** stamps the request with a `traceId`.
2. **`web/RateLimitFilter`** decides whether to admit it.
3. **Spring Security chain** (`security/SecurityConfig`) routes it to `security/JwtAuthFilter`, which decodes the token and puts `security/AuthenticatedUser` on the context.
4. The controller method runs. It calls `AuthenticatedUser.require().userId()`, hands a `database/PageQuery` to a `JpaRepository`, and returns an entity that extends `database/BaseEntity`.
5. **`audit/AuditorAwareConfig`** populates `createdBy` / `updatedBy` on save.
6. If anything throws, **`exceptions/GlobalExceptionHandler`** maps it to an `ErrorCodes` value.
7. **`response/ResponseEnvelopeAdvice`** wraps the result in `ApiResponse` with the `traceId`.
8. The response goes out — the client sees the standard envelope.

If you're adding a new feature, you typically don't add anything here.
Everything in `core/` is meant to be consumed, not extended.
