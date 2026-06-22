# `features/` — feature-first modules

Every feature owns a **full vertical slice**: its own entities, DTOs,
repositories, services, and controllers — all in one folder. There is no
shared `controllers/`, `services/`, or `entities/` package at the project
root. If you want to know everything about "chats" or "employees", you
open *one* folder.

```
features/
├── auth/         ← login, register, refresh, logout (token lifecycle)
├── users/        ← user CRUD + roles + permissions (the RBAC reference module)
├── employees/    ← HR-side employee profile (optionally linked to a user)
└── chats/        ← Telegram-style conversations + messages + voice/video calls + presence
```

---

## The shape every feature follows

```
features/<name>/
├── entity/      ← JPA @Entity classes (extend core.database.BaseEntity)
├── dto/         ← request + response records (jakarta.validation annotations)
├── repository/  ← Spring Data JpaRepository interfaces
├── service/     ← @Service @Transactional — business rules live here
└── controller/  ← @RestController @RequestMapping("/api/v1/<name>")
```

### What each subfolder is for

| Folder | What goes in it | Notes |
|---|---|---|
| **`entity/`** | `@Entity` classes mapped to DB tables, plus the enums they reference. Each entity extends [`core.database.BaseEntity`](../core/database/BaseEntity.java) so it inherits `Long id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy` automatically. | Do NOT put business logic here. Methods on entities should be limited to small derived getters (e.g. `User.allPermissions()`). |
| **`dto/`** | Request bodies (`CreateXRequest`, `UpdateXRequest`) and response shapes (`XDto`). Almost always Java `record`s. Bean Validation (`@NotBlank`, `@Email`, `@Size`) lives here so 400 errors come back before any service code runs. | DTOs are the **stable wire contract**. Entities are NOT exposed — `XDto.from(entity)` is the only bridge. Treat changes to a DTO as a breaking API change. |
| **`repository/`** | `JpaRepository<Entity, ID>` interfaces. Custom `@Query` JPQL, `@EntityGraph` hints, derived method names. | Repositories are the **only** layer that talks to the database. Services never use `EntityManager` directly. |
| **`service/`** | `@Service @Transactional` classes that hold business rules — uniqueness checks, role / membership enforcement, multi-step writes, cascade decisions, etc. | This is where the *decisions* live: "can this user kick that one?", "is this message inside its 15-minute edit window?", "should this call auto-end?". Services return entities, **not** DTOs — the controller maps. |
| **`controller/`** | `@RestController` with `@PreAuthorize` per method, request validation via `@Valid`, and the entity→DTO mapping for responses. Each one has a short Javadoc that surfaces in SwaggerUI. | Controllers do as little as possible — typically: pull `me` from `AuthenticatedUser`, call a service, map to DTO, optionally broadcast over STOMP, return. No business logic, no transactions, no SQL. |

### One-line rule of thumb

> If the HTTP shape changes, edit a **DTO**.
> If the rule changes, edit a **service**.
> If the storage changes, edit the **entity** + a migration.
> If the query changes, edit the **repository**.
> Controllers should rarely change at all.

### Optional extras a feature can add

Some modules need scaffolding that doesn't fit the five canonical
folders. By convention these live alongside as siblings:

| Subfolder | Used by | What it holds |
|---|---|---|
| `ws/` | `chats/` | STOMP plumbing — `WebSocketConfig`, `StompAuthChannelInterceptor`, `ChatBroadcaster`. |
| `presence/` | `chats/` | Online/Busy/Offline tracker — `PresenceService`, `PresenceController`, `WebSocketSessionListener`. Lives next to `ws/` because it consumes STOMP events. |

If a new piece of cross-cutting infra appears in a feature, give it a
descriptive sibling folder rather than overloading `service/`.

---

## The existing modules

### `auth/` — token lifecycle

The login / register / refresh / logout cycle. Issues short-lived access
tokens and rotating refresh tokens; the refresh JTI is persisted in
`refresh_tokens` so it can be revoked.

| Subfolder | Files |
|---|---|
| `entity/` | `RefreshToken` |
| `dto/` | `LoginRequest`, `RegisterRequest`, `RefreshRequest`, `LogoutRequest`, `AuthResponse` |
| `repository/` | `RefreshTokenRepository` |
| `service/` | `AuthService`, `RefreshTokenCleanupJob` (`@Scheduled` sweep of expired tokens) |
| `controller/` | `AuthController` (`/api/v1/auth/{login,register,refresh,logout}`) |

### `users/` — CRUD + RBAC reference module

The canonical example of the feature layout. Users + roles +
permissions. Every other feature wires `@PreAuthorize` against the
codes seeded here.

| Subfolder | Files |
|---|---|
| `entity/` | `User`, `Role`, `Permission` |
| `dto/` | `UserDto`, `CreateUserRequest`, `UpdateUserRequest`, `RoleDto`, `CreateRoleRequest`, `UpdateRoleRequest`, `PermissionDto`, `AssignRolesRequest` |
| `repository/` | `UserRepository` (with eager-roles entity graphs), `RoleRepository`, `PermissionRepository` |
| `service/` | `UserService`, `RoleService` |
| `controller/` | `UserController` (`/api/v1/users`), `RoleController` (`/api/v1/roles`) |

### `employees/` — HR-side profile + avatar upload

Each employee may link to a login `User` (one-to-one, nullable). Adds
upload-able avatar bytes on disk.

| Subfolder | Files |
|---|---|
| `entity/` | `Employee`, `EmployeeStatus` (enum: ACTIVE/INACTIVE/ON_LEAVE/TERMINATED) |
| `dto/` | `EmployeeDto`, `CreateEmployeeRequest`, `UpdateEmployeeRequest` |
| `repository/` | `EmployeeRepository` |
| `service/` | `EmployeeService`, `EmployeeAvatarService` (multipart upload, validation, replaces prior file on disk) |
| `controller/` | `EmployeeController` (`/api/v1/employees` + `/me/avatar` + `/{id}/avatar`) |

### `chats/` — conversations + messages + calls + presence

The biggest module. Covers Module 10 from `CHAT_MODULE_GUIDE.md`. Adds
two non-canonical sibling folders: `ws/` for STOMP plumbing and
`presence/` for online/busy/offline.

| Subfolder | Files |
|---|---|
| `entity/` | `Conversation`, `ConversationMember(+Id)`, `Message`, `MessageReaction(+Id)`, `ChatCall`, `ChatCallParticipant(+Id)`, enums `ConversationType` / `MessageType` / `MemberRole` / `CallType` / `CallStatus` / `ParticipantStatus` |
| `dto/` | `ConversationDto`, `MessageDto`, `ReactionDto`, `MemberDto`, `ChatCallDto`, `CallParticipantDto`, request bodies (`CreateConversationRequest`, `SendMessageRequest`, `EditMessageRequest`, `ToggleReactionRequest`, `AddMembersRequest`, `UpdateConversationRequest`, `StartCallRequest`, `MarkReadRequest`), and the generic STOMP envelope `ChatEvent` |
| `repository/` | `ConversationRepository`, `ConversationMemberRepository`, `MessageRepository`, `MessageReactionRepository`, `ChatCallRepository`, `ChatCallParticipantRepository` |
| `service/` | `ConversationService`, `MessageService`, `ChatCallService` |
| `controller/` | `ConversationController`, `MessageController`, `ChatCallController` |
| `ws/` (extra) | `WebSocketConfig`, `StompAuthChannelInterceptor` (JWT on CONNECT), `ChatBroadcaster` |
| `presence/` (extra) | `PresenceStatus`, `PresenceDto`, `PresenceService`, `WebSocketSessionListener`, `PresenceController` |

---

## Adding a new feature

The Users module is the working reference. To add `foo`:

1. **Migration** — `src/main/resources/db/migration/V<N>__foo.sql` for the tables.
2. **`features/foo/entity/Foo.java`** — `@Entity` extending `BaseEntity`.
3. **`features/foo/repository/FooRepository.java`** — `JpaRepository<Foo, Long>` (add `JpaSpecificationExecutor` for filtering).
4. **`features/foo/service/FooService.java`** — `@Service @Transactional`, business rules.
5. **`features/foo/dto/`** — request + response records with validation annotations.
6. **`features/foo/controller/FooController.java`** — `@RestController @RequestMapping("/api/v1/foo")` with `@PreAuthorize` per endpoint.
7. **`core.security.Permissions`** — add new permission codes, and seed them in `V3__seed_roles_and_admin.sql` (or a new migration).

Don't add per-feature `config/` or `exceptions/` folders — those concerns
belong in [`core/`](../core/README.md) so every feature shares the same
plumbing. If you need a non-standard piece of infra (STOMP, presence,
upload pipeline, …), follow the `chats/ws/` and `chats/presence/`
pattern: a descriptive sibling folder.

---

## Worked example: building Products CRUD

A complete step-by-step walkthrough.

### First, a clarification on order

It's tempting to start at the controller ("the user types the URL, so
that's where I start"), but **the cleanest path is bottom-up**:

> **schema → entity → repository → DTO → service → controller**

Why bottom-up?

- **Each layer depends on the one before it.** The controller imports
  the service, which imports the repository, which imports the entity,
  which maps to the schema. Building in the opposite direction means
  you write controllers that can't compile until you go back and fill
  in the layers underneath.
- **You can compile and run after every step.** After Step 2 the DB
  has a table. After Step 3 Hibernate validates the mapping on boot.
  After Step 4 you can fire a unit test against the repo. After Step 5
  you have a wire shape. After Step 6 the business rules work. After
  Step 7 the endpoint is live. No half-broken intermediate state.
- **You stop guessing at API shape too early.** Designing the DB and
  service first forces you to make the data decisions before you've
  committed to a public URL contract.

If you ever do want to design **top-down** (sketch the URL first,
prototype the DTOs, then go fill in), that's fine for whiteboard work —
but commit code bottom-up so the build never breaks halfway through.

### The request flow you're building

```
                      HTTP request (POST /api/v1/products)
                                 │
                                 ▼
              ┌───────────────────────────────────┐
              │   Spring filter chain (core/web)  │
              │   RequestIdFilter (stamps traceId)│
              │   RateLimitFilter (Bucket4j)      │
              │   JwtAuthFilter   (sets principal)│
              └───────────────┬───────────────────┘
                              │
                              ▼
              ┌───────────────────────────────────┐
              │   ProductController               │   @PreAuthorize
              │   @Valid → reject bad body 400    │   AuthenticatedUser.require()
              └───────────────┬───────────────────┘
                              │ calls service
                              ▼
              ┌───────────────────────────────────┐
              │   ProductService                  │   @Transactional
              │   business rules                  │   "SKU unique?"
              └───────────────┬───────────────────┘
                              │ calls repository
                              ▼
              ┌───────────────────────────────────┐
              │   ProductRepository               │   JpaRepository
              │   JPQL / @EntityGraph             │
              └───────────────┬───────────────────┘
                              │ JPA → SQL
                              ▼
              ┌───────────────────────────────────┐
              │   Product entity (extends         │   audit columns
              │     core.database.BaseEntity)     │   filled automatically
              └───────────────┬───────────────────┘
                              │
                              ▼
                       PostgreSQL  (chat_products)
                              │
                              ▼
                  ── transaction commits ──
                              │
                              ▼
              ProductController maps Product → ProductDto
                              │
                              ▼
              ResponseEnvelopeAdvice wraps as ApiResponse
                              │
                              ▼
                          JSON response
```

### Step 1 — Plan the API

Before touching code, write down what you're committing to:

| Method | Path | Auth | Body in | Body out |
|---|---|---|---|---|
| `GET` | `/api/v1/products` | `product:read` | — | `PageResponse<ProductDto>` |
| `GET` | `/api/v1/products/{id}` | `product:read` | — | `ProductDto` |
| `POST` | `/api/v1/products` | `product:write` | `CreateProductRequest` | `ProductDto` |
| `PATCH` | `/api/v1/products/{id}` | `product:write` | `UpdateProductRequest` | `ProductDto` |
| `DELETE` | `/api/v1/products/{id}` | `product:write` | — | empty |

### Step 2 — Migration (schema first)

Create `src/main/resources/db/migration/V15__products.sql`:

```sql
CREATE TABLE products (
    id              BIGSERIAL    PRIMARY KEY,
    sku             VARCHAR(64)  NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           NUMERIC(12,2) NOT NULL DEFAULT 0,
    stock_quantity  INTEGER      NOT NULL DEFAULT 0,
    enabled         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by      BIGINT,
    updated_by      BIGINT
);
CREATE INDEX idx_products_name ON products (name);
```

Flyway will apply it on the next boot.

### Step 3 — Entity (`features/products/entity/Product.java`)

```java
package com.company.erp.features.products.entity;

import com.company.erp.core.database.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter; import lombok.NoArgsConstructor; import lombok.Setter;

import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor
@Entity @Table(name = "products")
public class Product extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String sku;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "stock_quantity", nullable = false)
    private Integer stockQuantity = 0;

    @Column(nullable = false)
    private boolean enabled = true;
}
```

`id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy` are inherited
from `BaseEntity` — nothing extra to declare.

### Step 4 — Repository (`features/products/repository/ProductRepository.java`)

```java
package com.company.erp.features.products.repository;

import com.company.erp.features.products.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository extends JpaRepository<Product, Long> {

    boolean existsBySku(String sku);

    @Query("""
           SELECT p FROM Product p
           WHERE (:q IS NULL OR :q = ''
                  OR LOWER(p.name) LIKE LOWER(CONCAT('%', :q, '%'))
                  OR LOWER(p.sku)  LIKE LOWER(CONCAT('%', :q, '%')))
           """)
    Page<Product> search(@Param("q") String q, Pageable pageable);
}
```

### Step 5 — DTOs (`features/products/dto/`)

`ProductDto.java`:

```java
package com.company.erp.features.products.dto;

import com.company.erp.features.products.entity.Product;
import java.math.BigDecimal;
import java.time.Instant;

public record ProductDto(
        Long id, String sku, String name, String description,
        BigDecimal price, Integer stockQuantity, boolean enabled,
        Instant createdAt, Instant updatedAt
) {
    public static ProductDto from(Product p) {
        return new ProductDto(p.getId(), p.getSku(), p.getName(), p.getDescription(),
                p.getPrice(), p.getStockQuantity(), p.isEnabled(),
                p.getCreatedAt(), p.getUpdatedAt());
    }
}
```

`CreateProductRequest.java`:

```java
package com.company.erp.features.products.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record CreateProductRequest(
        @NotBlank @Size(max = 64)  String sku,
        @NotBlank @Size(max = 255) String name,
        @Size(max = 4000)          String description,
        @NotNull @DecimalMin("0")  BigDecimal price,
        @NotNull @Min(0)           Integer stockQuantity,
        Boolean enabled
) {}
```

`UpdateProductRequest.java` — all fields optional, partial update:

```java
package com.company.erp.features.products.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record UpdateProductRequest(
        @Size(max = 64)   String sku,
        @Size(max = 255)  String name,
        @Size(max = 4000) String description,
        @DecimalMin("0")  BigDecimal price,
        @Min(0)           Integer stockQuantity,
        Boolean enabled
) {}
```

### Step 6 — Service (`features/products/service/ProductService.java`)

```java
package com.company.erp.features.products.service;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.exceptions.ConflictException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.products.dto.CreateProductRequest;
import com.company.erp.features.products.dto.UpdateProductRequest;
import com.company.erp.features.products.entity.Product;
import com.company.erp.features.products.repository.ProductRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Service @Transactional
public class ProductService {

    private static final Set<String> ALLOWED_SORT = Set.of("name", "price", "createdAt");
    private final ProductRepository products;

    public ProductService(ProductRepository products) { this.products = products; }

    @Transactional(readOnly = true)
    public Page<Product> list(PageQuery q) {
        return products.search(q.search(),
                q.toPageable(ALLOWED_SORT, Sort.by("name")));
    }

    @Transactional(readOnly = true)
    public Product getById(Long id) {
        return products.findById(id)
                .orElseThrow(() -> new NotFoundException("Product not found"));
    }

    public Product create(CreateProductRequest req) {
        if (products.existsBySku(req.sku())) throw new ConflictException("SKU already in use");
        Product p = new Product();
        p.setSku(req.sku());
        p.setName(req.name());
        p.setDescription(req.description());
        p.setPrice(req.price());
        p.setStockQuantity(req.stockQuantity());
        if (req.enabled() != null) p.setEnabled(req.enabled());
        return products.save(p);
    }

    public Product update(Long id, UpdateProductRequest req) {
        Product p = getById(id);
        if (req.sku() != null && !req.sku().equals(p.getSku())) {
            if (products.existsBySku(req.sku())) throw new ConflictException("SKU already in use");
            p.setSku(req.sku());
        }
        if (req.name()          != null) p.setName(req.name());
        if (req.description()   != null) p.setDescription(req.description());
        if (req.price()         != null) p.setPrice(req.price());
        if (req.stockQuantity() != null) p.setStockQuantity(req.stockQuantity());
        if (req.enabled()       != null) p.setEnabled(req.enabled());
        return p;
    }

    public void delete(Long id) { products.delete(getById(id)); }
}
```

### Step 7 — Controller (`features/products/controller/ProductController.java`)

```java
package com.company.erp.features.products.controller;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.response.PageResponse;
import com.company.erp.core.security.Permissions;
import com.company.erp.features.products.dto.*;
import com.company.erp.features.products.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    private final ProductService products;

    public ProductController(ProductService products) { this.products = products; }

    /** List products, paginated; substring search on name / sku. */
    @GetMapping
    @PreAuthorize("hasAuthority('" + Permissions.PRODUCT_READ + "')")
    public PageResponse<ProductDto> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sort) {
        return PageResponse.from(
                products.list(new PageQuery(page, pageSize, search, sort)),
                ProductDto::from);
    }

    /** Get one product by id. */
    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.PRODUCT_READ + "')")
    public ProductDto get(@PathVariable Long id) {
        return ProductDto.from(products.getById(id));
    }

    /** Create a new product. SKU must be unique. */
    @PostMapping
    @PreAuthorize("hasAuthority('" + Permissions.PRODUCT_WRITE + "')")
    public ProductDto create(@Valid @RequestBody CreateProductRequest body) {
        return ProductDto.from(products.create(body));
    }

    /** Partial update — only fields present in body are touched. */
    @PatchMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.PRODUCT_WRITE + "')")
    public ProductDto update(@PathVariable Long id,
                             @Valid @RequestBody(required = false) UpdateProductRequest body) {
        if (body == null) return ProductDto.from(products.getById(id));
        return ProductDto.from(products.update(id, body));
    }

    /** Delete a product. */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('" + Permissions.PRODUCT_WRITE + "')")
    public void delete(@PathVariable Long id) {
        products.delete(id);
    }
}
```

### Step 8 — Permissions

`PRODUCT_READ` / `PRODUCT_WRITE` already exist in
[`core/security/Permissions.java`](../core/security/Permissions.java) and
are seeded for `SUPER_ADMIN` / `ADMIN`. If you add a **new** permission
code, also seed it in a fresh `V<N>__permissions_<feature>.sql`
migration that inserts into `permissions` + `role_permissions`.

### Step 9 — Test it

```bash
TOK=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@company.local","password":"Admin@12345"}' \
  | jq -r .data.accessToken)

# Create
curl -X POST http://localhost:8080/api/v1/products \
  -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d '{"sku":"SKU-001","name":"Coffee","price":3.50,"stockQuantity":100}'

# List
curl "http://localhost:8080/api/v1/products?page=1&pageSize=20" \
  -H "Authorization: Bearer $TOK" | jq

# Patch
curl -X PATCH http://localhost:8080/api/v1/products/1 \
  -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d '{"price":4.00}'

# Delete
curl -X DELETE http://localhost:8080/api/v1/products/1 \
  -H "Authorization: Bearer $TOK"
```

### Files created (tree)

```
src/main/resources/db/migration/
└── V15__products.sql

src/main/java/com/company/erp/features/products/
├── entity/
│   └── Product.java
├── repository/
│   └── ProductRepository.java
├── dto/
│   ├── ProductDto.java
│   ├── CreateProductRequest.java
│   └── UpdateProductRequest.java
├── service/
│   └── ProductService.java
└── controller/
    └── ProductController.java
```

Seven files. That's the whole module.

---

## MVC vs MVVM

This backend is **MVC** — specifically Spring MVC plus an N-tier
extension (Controller → Service → Repository → Entity). There is no
ViewModel anywhere on the server. The Flutter mobile app *on top of*
this API is **MVVM** — its screens use a View ↔ ViewModel ↔ Model
split with observable state.

The project root README calls the folder layout "MVVM-style", but that
refers to the *folder shape* (every feature has its own self-contained
slice, the way MVVM frontends keep each screen together), not the
runtime pattern. The runtime pattern here is plain MVC.

If you're editing Java files in this repo, think MVC. If you're
editing Dart files in the Flutter app, think MVVM. It's useful to keep
the two straight because they describe different sides of the same
product.

### MVC — what this Spring backend does

```
   ┌────────────┐    HTTP     ┌────────────────┐
   │   Client   │ ─────────▶  │  Controller    │  ← @RestController
   │ (browser/  │             │   (Spring MVC) │     routes, validates,
   │  Flutter/  │             └────────┬───────┘     calls service
   │  curl)     │                      │
   └─────▲──────┘                      ▼
         │                     ┌────────────────┐
         │   JSON (the "View") │   Service      │  ← business rules,
         │                     │  (Transactional)│     @Transactional
         │                     └────────┬───────┘
         │                              ▼
         │                     ┌────────────────┐
         │                     │  Repository    │  ← Spring Data JPA
         │                     └────────┬───────┘
         │                              ▼
         │                     ┌────────────────┐
         └─────────────────────│  Model (Entity)│  ← @Entity, the data
                               │     + DTO      │
                               └────────────────┘
```

| MVC piece | What it is here |
|---|---|
| **Model** | `entity/` + `dto/` — the data shape and its mapping to DB tables |
| **View** | The JSON returned by the controller (no Thymeleaf, no HTML — for a REST API the "View" is the serialized response) |
| **Controller** | `controller/` — HTTP routing, validation, mapping to/from DTOs |

The Service and Repository layers are **N-tier extensions** Spring
encourages on top of plain MVC. The result is: Controller → Service →
Repository → Entity → DB.

### MVVM — what the Flutter app does

```
   ┌───────────────┐        ┌─────────────────┐         ┌──────────┐
   │  View         │  ────▶ │  ViewModel      │  ────▶  │  Model   │
   │  (Widget tree)│ ◀────  │ (ChangeNotifier,│ ◀────   │ (repos / │
   │               │ binds  │  Provider, etc.)│  reads  │  API DTOs)│
   └───────────────┘        └─────────────────┘         └──────────┘
        ▲                                                   │
        │                                                   ▼
        │                                          REST + STOMP
        │                                          to THIS backend
        └────── user input fires commands ───────────────────┘
```

| MVVM piece | What it is in Flutter |
|---|---|
| **Model** | Plain Dart classes (`Product`, `Conversation`) hydrated from the API. Includes repositories that call the API. |
| **ViewModel** | Holds observable state for one screen (`ChangeNotifier`, `Provider`, `Riverpod` notifier, `Bloc`, …). The View binds to it; the View never talks to the API directly. |
| **View** | The widget tree. Rebuilds when the ViewModel emits change. |

### Side-by-side

| Aspect | MVC (this backend) | MVVM (Flutter client) |
|---|---|---|
| **Where it runs** | Server, JVM | Phone / desktop |
| **What "View" means** | JSON output | Widget tree on screen |
| **Lifecycle** | Per-request, stateless | Long-lived, observable state |
| **Talks to DB** | Yes, via Repository → JPA | No — talks to this API instead |
| **Common state holder** | None — controllers are stateless | `ViewModel` / `Provider` / `Riverpod` notifier |
| **Common input** | HTTP request | User gesture (tap, swipe) |
| **Threading concern** | One request per worker thread; `@Transactional` boundary | UI thread vs isolate; `await` and notify back |
| **Source of truth** | Postgres | Local cache hydrated from the backend |

### Why this backend isn't MVVM (even though the README says "MVVM-style")

The "MVVM-style" label in the project description is referring to the
*folder layout* — every feature has its own self-contained slice, like
how MVVM frontends keep each screen's view/viewmodel/model together.
But the **runtime pattern** here is classic Spring MVC + N-tier
(controller → service → repository → entity). There's no ViewModel —
controllers are stateless and serve JSON, not bind observable state to a
UI.

If you're working on the Flutter app, use MVVM. If you're working on
this backend, use MVC + the layered conventions documented above.
