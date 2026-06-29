# iOS Killed + Locked Call Flow — **Laravel Backend** Implementation

> The **backend side** of the iOS killed-app + locked-screen call flow,
> implemented in **Laravel**. This replaces the Spring backend
> (`172.26.17.118:8080`) the Flutter app currently talks to.
>
> The Flutter client is unchanged — Laravel just has to honour the **exact
> same HTTP + realtime contract**. This doc gives you the contract, the
> Stream Video server integration, the endpoints, the DB schema, and the
> realtime layer.

---

## 0. What the backend is actually responsible for

The backend does **NOT** send the iOS VoIP push itself. **Stream Video
sends the push** to Apple APNs, because the callee's device is registered
with Stream. The backend's jobs are:

1. **Mint Stream tokens** so each device can register with Stream (and thus
   become reachable by a VoIP push).
2. **Create / ring / accept / reject / end calls** via the Stream Video
   server SDK — this is what makes Stream fire the VoIP push to a callee
   whose app is dead.
3. **Track presence** (online/offline). This is the lever that decides
   *push vs socket*: a callee reported **OFFLINE** is rung via the **VoIP
   push**; an **ONLINE** callee is rung over the live socket/overlay.
4. **Broadcast realtime events** (call.invite/accept/reject/hangup,
   messages, presence) to online clients.

```
Caller ──POST /chats/conversations/{id}/calls──► Laravel
                                                   │
                                   ┌───────────────┼────────────────┐
                                   │ ring callee via Stream SDK      │
                                   │ broadcast call.invite to online │
                                   ▼ participants                    ▼
                            Stream Video                       Laravel Reverb
                            coordinator                        (realtime)
                                   │                                 │
                  callee OFFLINE → │ APNs VoIP push          callee ONLINE → socket
                                   ▼                                 ▼
                         iOS PushKit→CallKit               in-app incoming overlay
                         (killed/locked)
```

> So: **the iOS native CallKit/PushKit work lives in the Flutter app**
> (see `IOS_KILLED_LOCKED_CALL_FLOW.md`). The Laravel backend only needs to
> drive Stream correctly and report presence honestly.

---

## 1. Stream Video setup

You need a Stream account (the same app/keys the iOS entitlement's APNs
provider is configured against).

### 1.1 `.env`

```dotenv
STREAM_API_KEY=your_stream_api_key
STREAM_API_SECRET=your_stream_api_secret
STREAM_VIDEO_BASE_URL=https://video.stream-io-api.com
```

### 1.2 `config/services.php`

```php
'stream' => [
    'key'    => env('STREAM_API_KEY'),
    'secret' => env('STREAM_API_SECRET'),
    'video_base_url' => env('STREAM_VIDEO_BASE_URL', 'https://video.stream-io-api.com'),
],
```

### 1.3 Token minting (no SDK needed — it's a JWT)

A Stream user token is just an HS256 JWT signed with the API secret. Create
a small service:

```php
// app/Services/StreamTokenService.php
namespace App\Services;

use Firebase\JWT\JWT;          // composer require firebase/php-jwt

class StreamTokenService
{
    public function userToken(string $userId, int $ttlSeconds = 86400): string
    {
        $now = time();
        $payload = [
            'user_id' => $userId,
            'iat'     => $now,
            'exp'     => $now + $ttlSeconds,
        ];
        return JWT::encode($payload, config('services.stream.secret'), 'HS256');
    }

    /** Server-side admin token (no user_id) for server→Stream REST calls. */
    public function serverToken(): string
    {
        $payload = ['server' => true, 'iat' => time()];
        return JWT::encode($payload, config('services.stream.secret'), 'HS256');
    }
}
```

### 1.4 Calling Stream's Video REST from the server

There is no first-party PHP Video SDK, so call the REST API with the HTTP
client. The base is `https://video.stream-io-api.com`, auth is the server
JWT, and `api_key` is a query param.

```php
// app/Services/StreamVideoClient.php
namespace App\Services;

use Illuminate\Support\Facades\Http;

class StreamVideoClient
{
    public function __construct(private StreamTokenService $tokens) {}

    private function http()
    {
        return Http::baseUrl(config('services.stream.video_base_url'))
            ->withHeaders([
                'Authorization'    => $this->tokens->serverToken(),
                'stream-auth-type' => 'jwt',
                'Content-Type'     => 'application/json',
            ])
            ->withQueryParameters(['api_key' => config('services.stream.key')]);
    }

    /**
     * Create + ring a call. callType = "default" (audio) or "default" with video.
     * memberIds = every participant (caller + callees) as Stream user ids.
     * Setting "ring: true" is what makes Stream fire the VoIP/APNs push to
     * offline members — this is the killed/locked ring.
     */
    public function ring(string $cid, string $callerId, array $memberIds): array
    {
        [$type, $id] = explode(':', $cid, 2);
        $members = array_map(fn ($uid) => ['user_id' => (string) $uid], $memberIds);

        $res = $this->http()->post("/video/call/{$type}/{$id}", [
            'data' => [
                'created_by_id' => (string) $callerId,
                'members'       => $members,
            ],
            'ring'   => true,   // ← triggers the push to offline callees
            'notify' => true,
        ]);

        return $res->json();
    }

    /** Register an APNs VoIP device for a user (mirrors the app's re-register). */
    public function upsertApnDevice(string $userToken, string $voipToken): array
    {
        return Http::baseUrl(config('services.stream.video_base_url'))
            ->withHeaders([
                'Authorization'    => $userToken,
                'stream-auth-type' => 'jwt',
                'Content-Type'     => 'application/json',
            ])
            ->withQueryParameters(['api_key' => config('services.stream.key')])
            ->post('/video/devices', [
                'id'                 => $voipToken,
                'push_provider'      => 'apn',
                'push_provider_name' => 'apn',   // must match the Stream Dashboard provider name
                'voip_token'         => true,
            ])->json();
    }
}
```

> **Stream Dashboard config (one-time):** add an **APN push provider** named
> `apn`, upload your **APNs auth key (.p8)** + Key ID + Team ID, set the
> **bundle id**, and set the environment (**sandbox** for dev builds —
> matching `aps-environment` in `Runner.entitlements`). Without this Stream
> can't deliver the VoIP push and killed/locked calls never ring.

---

## 2. The response envelope (match this exactly)

The Flutter app unwraps **every** REST response through `ApiEnvelope`:

```json
{
  "success": true,
  "message": "OK",
  "data": { ... },
  "errorCode": null,
  "traceId": "uuid"
}
```

Rules the app enforces:
- `success: false` → the app throws a business error (so set it on failures).
- `data` must be an object for `parse`, or an array for `parseList`.
- Lists/pages use `data` as an array; paginated lists use the **PageResponse** shape (§6).

Add one helper so every controller returns it consistently:

```php
// app/Support/ApiEnvelope.php
namespace App\Support;

class ApiEnvelope
{
    public static function ok($data = null, string $message = 'OK')
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
            'traceId' => request()->header('X-Trace-Id', \Str::uuid()->toString()),
        ]);
    }

    public static function fail(string $message, string $code = 'ERROR', int $status = 400)
    {
        return response()->json([
            'success'   => false,
            'message'   => $message,
            'errorCode' => $code,
            'traceId'   => \Str::uuid()->toString(),
        ], $status);
    }
}
```

---

## 3. Routes

```php
// routes/api.php  (prefix the group with /v1 so the base is /api/v1)
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {

    Route::prefix('chats')->group(function () {

        // ── Calls ──────────────────────────────────────────────
        Route::get   ('calls/stream-token',           [CallController::class, 'streamToken']);
        Route::get   ('calls',                         [CallController::class, 'index']);
        Route::get   ('calls/{call}',                  [CallController::class, 'show']);
        Route::post  ('calls/{call}/accept',           [CallController::class, 'accept']);
        Route::post  ('calls/{call}/reject',           [CallController::class, 'reject']);
        Route::post  ('calls/{call}/end',              [CallController::class, 'end']);
        Route::get   ('conversations/{conversation}/calls', [CallController::class, 'conversationCalls']);
        Route::post  ('conversations/{conversation}/calls', [CallController::class, 'start']);

        // ── Presence ───────────────────────────────────────────
        Route::get   ('presence',            [PresenceController::class, 'index']);   // ?ids=1,4,7 optional
        Route::post  ('presence/background', [PresenceController::class, 'background']);
        Route::post  ('presence/foreground', [PresenceController::class, 'foreground']);

        // ── (optional) device registration ─────────────────────
        Route::post  ('devices/voip',        [DeviceController::class, 'registerVoip']);
    });
});
```

> Base URL becomes `http://YOUR_HOST:8080/api/v1`. Update
> `lib/core/config/environments.dart` in the Flutter app to point at it.

---

## 4. Endpoints — exact contracts

### 4.1 `GET /chats/calls/stream-token`

The app reads **`apiKey`, `token`, `userId`** (all strings) and uses them to
build the Stream client + register the device.

```php
public function streamToken(StreamTokenService $tokens)
{
    $user = auth()->user();
    return ApiEnvelope::ok([
        'apiKey' => config('services.stream.key'),
        'token'  => $tokens->userToken((string) $user->id),
        'userId' => (string) $user->id,
    ]);
}
```

Response:
```json
{ "success": true, "data": { "apiKey": "xxx", "token": "<jwt>", "userId": "1001" } }
```

### 4.2 `POST /chats/conversations/{id}/calls` — start a call

**Request body:** `{ "type": "VOICE" | "VIDEO" }`

This is the heart of the killed/locked flow: persist the call, then ring via
Stream (which pushes offline callees), then broadcast `call.invite` to
online callees.

```php
public function start(Conversation $conversation, Request $req, StreamVideoClient $stream)
{
    $type = strtoupper($req->input('type', 'VOICE')); // VOICE | VIDEO
    $caller = auth()->user();

    $cid = 'default:' . \Str::uuid()->toString();      // Stream call cid

    $call = Call::create([
        'conversation_id'  => $conversation->id,
        'caller_id'        => $caller->id,
        'type'             => $type,
        'status'           => 'RINGING',
        'stream_call_cid'  => $cid,
        'started_at'       => now(),
    ]);

    // participants (caller + everyone else in the conversation)
    $memberIds = $conversation->participantUserIds();   // [1001,1002,...]
    foreach ($memberIds as $uid) {
        CallParticipant::create([
            'call_id' => $call->id,
            'user_id' => $uid,
            'status'  => $uid === $caller->id ? 'ANSWERED' : 'RINGING',
        ]);
    }

    // 1) Ring via Stream — offline callees get the APNs VoIP push (killed/locked ring)
    $stream->ring($cid, (string) $caller->id, array_map('strval', $memberIds));

    // 2) Broadcast to ONLINE callees so they get the in-app overlay too
    $dto = (new CallResource($call->load('participants')))->resolve();
    foreach ($memberIds as $uid) {
        if ($uid === $caller->id) continue;
        broadcast(new CallInvite($uid, $dto));          // → user.{id} private channel
    }

    return ApiEnvelope::ok($dto);
}
```

**Response `data` (CallResource) — the app reads these fields:**

```json
{
  "id": 12345,
  "conversationId": 999,
  "callerId": "1001",
  "type": "VOICE",
  "status": "RINGING",
  "streamCallCid": "default:abc-123",
  "startedAt": "2026-06-25T14:30:00Z",
  "answeredAt": null,
  "endedAt": null,
  "durationSeconds": null,
  "participants": [
    { "userId": "1001", "status": "ANSWERED", "joinedAt": "2026-06-25T14:30:00Z" },
    { "userId": "1002", "status": "RINGING",  "joinedAt": null }
  ]
}
```

> `participants[].userId` and `status` are required — the app derives call
> routing and accept/reject from this array. `streamCallCid` must be the same
> cid you rang Stream with, or the client joins the wrong Stream call.

### 4.3 `POST /chats/calls/{id}/accept`

```php
public function accept(Call $call)
{
    $uid = auth()->id();
    $call->participants()->where('user_id', $uid)
         ->update(['status' => 'ANSWERED', 'joined_at' => now()]);

    if ($call->status === 'RINGING') {
        $call->update(['status' => 'ANSWERED', 'answered_at' => now()]);
    }

    broadcast(new CallAccept($call->conversation_id, [
        'callId'     => (string) $call->id,
        'accepterId' => (string) $uid,
    ]));

    return ApiEnvelope::ok((new CallResource($call->fresh('participants')))->resolve());
}
```

### 4.4 `POST /chats/calls/{id}/reject?reason=busy`

`reason` is an optional **query** param (the app sends `?reason=busy` etc.).

```php
public function reject(Call $call, Request $req)
{
    $uid    = auth()->id();
    $reason = $req->query('reason');                    // busy | declined | null

    $call->participants()->where('user_id', $uid)->update(['status' => 'REJECTED']);

    // if no one is left ringing/answered, the call is over
    if (! $call->participants()->whereIn('status', ['RINGING','ANSWERED'])->exists()) {
        $call->update(['status' => 'REJECTED', 'ended_at' => now()]);
    }

    broadcast(new CallReject($call->conversation_id, [
        'callId' => (string) $call->id,
        'reason' => $reason,
    ]));

    return ApiEnvelope::ok((new CallResource($call->fresh('participants')))->resolve());
}
```

### 4.5 `POST /chats/calls/{id}/end`

```php
public function end(Call $call)
{
    $duration = $call->answered_at
        ? now()->diffInSeconds($call->answered_at)
        : null;

    $call->update([
        'status'           => $call->answered_at ? 'ANSWERED' : 'MISSED',
        'ended_at'         => now(),
        'duration_seconds' => $duration,
    ]);

    broadcast(new CallHangup($call->conversation_id, [
        'callId'         => (string) $call->id,
        'hangerUpperId'  => (string) auth()->id(),
    ]));

    return ApiEnvelope::ok((new CallResource($call->fresh('participants')))->resolve());
}
```

### 4.6 `GET /chats/calls/{id}` — reconcile after a socket dropout

Just return the `CallResource`. The app calls this when it missed a realtime
event (cold start mid-call, network blip).

### 4.7 `GET /chats/calls` and `GET /chats/conversations/{id}/calls`

Paginated history. Query: `?page=1&pageSize=50` (or `pageSize=6` per
conversation). Return a **PageResponse** (§6) of `CallResource` items.

---

## 5. Presence — the push-vs-socket lever

This is what makes killed/locked routing work. When the app backgrounds it
calls `/presence/background`; on resume, `/presence/foreground`. An OFFLINE
callee gets the **VoIP push**; an ONLINE one gets the socket overlay.

### 5.1 `Presence.fromJson` contract

The app reads `userId` (string), `status`
(`ONLINE`|`BUSY`|`AWAY`|`OFFLINE`, uppercase), `lastSeenAt` (ISO-8601 or
null).

```php
class PresenceResource extends JsonResource
{
    public function toArray($req): array
    {
        return [
            'userId'     => (string) $this->user_id,
            'status'     => $this->status,                       // ONLINE|BUSY|AWAY|OFFLINE
            'lastSeenAt' => optional($this->last_seen_at)?->toIso8601String(),
        ];
    }
}
```

### 5.2 Controller

```php
public function background()   // app went to background → OFFLINE NOW
{
    $this->setStatus(auth()->id(), 'OFFLINE');
    return ApiEnvelope::ok();
}

public function foreground()   // app resumed → ONLINE
{
    $this->setStatus(auth()->id(), 'ONLINE');
    return ApiEnvelope::ok();
}

public function index(Request $req)   // GET /chats/presence  (?ids=1,4,7)
{
    $q = Presence::query();
    if ($ids = $req->query('ids')) {
        $q->whereIn('user_id', explode(',', $ids));
    }
    return ApiEnvelope::ok(PresenceResource::collection($q->get())->resolve());
}

private function setStatus(int $userId, string $status): void
{
    $p = Presence::updateOrCreate(
        ['user_id' => $userId],
        ['status' => $status, 'last_seen_at' => now()],
    );
    broadcast(new PresenceUpdated($p));   // → /topic equivalent: presence channel
}
```

> **Critical:** report OFFLINE **immediately** on `/presence/background`
> (don't wait for a heartbeat to lapse). The app relies on this so the
> *next* call to a backgrounded/locked device is routed to the VoIP push,
> not a stale "online" socket the user can't see.

---

## 6. PageResponse (paginated lists)

The app's `PageResponse.fromJson` accepts either naming:

```json
{ "items": [ ...CallResource... ], "page": 1, "pageSize": 50, "total": 237 }
```
(`items`/`content`, `page`/`number`, `pageSize`/`size`, `total`/`totalElements` all work.)

```php
public function index(Request $req)
{
    $page = (int) $req->query('page', 1);
    $size = (int) $req->query('pageSize', 50);

    $p = Call::query()
        ->whereHas('participants', fn ($q) => $q->where('user_id', auth()->id()))
        ->orderByDesc('started_at')
        ->paginate($size, ['*'], 'page', $page);

    return ApiEnvelope::ok([
        'items'    => CallResource::collection($p->items())->resolve(),
        'page'     => $p->currentPage(),
        'pageSize' => $p->perPage(),
        'total'    => $p->total(),
    ]);
}
```

---

## 7. Realtime layer — STOMP → Laravel broadcasting

The Flutter app subscribes over **STOMP** to these destinations:

| STOMP destination (Spring)              | Carries                                   |
|-----------------------------------------|-------------------------------------------|
| `/user/queue/inbox`                     | inbox previews, conversation create/remove |
| `/user/queue/calls`                     | `call.invite`                              |
| `/topic/presence`                       | `presence.update`                          |
| `/topic/conversations/{id}`             | `message.*`, read receipts                 |
| `/topic/conversations/{id}/call`        | `call.accept` / `call.reject` / `call.hangup` |

Every frame body is:

```json
{ "event": "call.invite", "payload": { ... } }
```

You have two options on Laravel:

### Option A — Keep STOMP (drop-in, no app change)
Run a STOMP-capable broker (e.g. **RabbitMQ Web-STOMP** plugin, or a small
Spring-less STOMP relay) and have Laravel publish frames to those exact
destinations. The Flutter app needs **zero** changes. Choose this if you want
to swap only the REST backend and leave the realtime contract untouched.

### Option B — Laravel Reverb / Pusher (requires a thin app-side change)
Use **Laravel Reverb** (`php artisan install:broadcasting`). Map the STOMP
destinations to channels:

| STOMP                              | Laravel channel            |
|------------------------------------|----------------------------|
| `/user/queue/calls`                | `private-user.{id}`        |
| `/user/queue/inbox`                | `private-user.{id}`        |
| `/topic/presence`                  | `presence-chat`            |
| `/topic/conversations/{id}`        | `private-conversation.{id}`|
| `/topic/conversations/{id}/call`   | `private-conversation.{id}`|

Keep the **same `{event, payload}` body** so the parsing stays identical.
This needs the Flutter `ChatTransport` to swap its STOMP client for
`laravel_echo` + `pusher_client` — a transport-layer change only; all the
event handlers stay.

> **Recommendation:** if you want the iOS killed/locked behaviour working with
> the **least** risk, use **Option A** (STOMP broker) — the entire Flutter
> client, including the CallKit/PushKit logic, keeps working byte-for-byte.

### Broadcast event examples (Option B)

```php
class CallInvite implements ShouldBroadcast
{
    public function __construct(public int $userId, public array $payload) {}

    public function broadcastOn(): Channel
    { return new PrivateChannel("user.{$this->userId}"); }

    public function broadcastAs(): string { return 'call.invite'; }

    public function broadcastWith(): array
    { return ['event' => 'call.invite', 'payload' => $this->payload]; }
}
```

**`call.invite` payload** (what the app's `_callInviteFromDto` reads):
```json
{
  "id": "12345", "conversationId": "999", "callerId": "1001",
  "type": "VOICE", "startedAt": "2026-06-25T14:30:00Z",
  "streamCallCid": "default:abc-123",
  "participants": [ { "userId": "1001" }, { "userId": "1002" } ]
}
```

**`call.accept`** → `{ "callId": "12345", "accepterId": "1002" }`
**`call.reject`** → `{ "callId": "12345", "reason": "busy" }`
**`call.hangup`** → `{ "callId": "12345", "hangerUpperId": "1001" }`
**`presence.update`** → `{ "userId":"1001", "status":"OFFLINE", "lastSeenAt":null }`

---

## 8. Database schema (migrations)

```php
// calls
Schema::create('calls', function (Blueprint $t) {
    $t->id();
    $t->foreignId('conversation_id')->constrained()->cascadeOnDelete();
    $t->foreignId('caller_id')->constrained('users');
    $t->enum('type', ['VOICE', 'VIDEO']);
    $t->enum('status', ['RINGING','ANSWERED','REJECTED','MISSED','NO_ANSWER'])
      ->default('RINGING');
    $t->string('stream_call_cid')->unique();     // e.g. "default:uuid"
    $t->timestamp('started_at')->nullable();
    $t->timestamp('answered_at')->nullable();
    $t->timestamp('ended_at')->nullable();
    $t->unsignedInteger('duration_seconds')->nullable();
    $t->timestamps();
});

// call_participants
Schema::create('call_participants', function (Blueprint $t) {
    $t->id();
    $t->foreignId('call_id')->constrained()->cascadeOnDelete();
    $t->foreignId('user_id')->constrained('users');
    $t->enum('status', ['RINGING','ANSWERED','REJECTED','MISSED','NO_ANSWER'])
      ->default('RINGING');
    $t->timestamp('joined_at')->nullable();
    $t->timestamps();
    $t->unique(['call_id', 'user_id']);
});

// presence
Schema::create('presences', function (Blueprint $t) {
    $t->foreignId('user_id')->primary()->constrained()->cascadeOnDelete();
    $t->enum('status', ['ONLINE','BUSY','AWAY','OFFLINE'])->default('OFFLINE');
    $t->timestamp('last_seen_at')->nullable();
    $t->timestamps();
});

// (optional) voip devices, if you let the backend register them with Stream
Schema::create('voip_devices', function (Blueprint $t) {
    $t->id();
    $t->foreignId('user_id')->constrained()->cascadeOnDelete();
    $t->string('voip_token');
    $t->string('platform')->default('ios');   // ios = apn
    $t->timestamps();
    $t->unique(['user_id', 'voip_token']);
});
```

### CallResource (one source of truth for the call JSON)

```php
class CallResource extends JsonResource
{
    public function toArray($req): array
    {
        return [
            'id'              => $this->id,
            'conversationId'  => $this->conversation_id,
            'callerId'        => (string) $this->caller_id,
            'type'            => $this->type,                 // VOICE | VIDEO
            'status'          => $this->status,
            'streamCallCid'   => $this->stream_call_cid,
            'startedAt'       => optional($this->started_at)?->toIso8601String(),
            'answeredAt'      => optional($this->answered_at)?->toIso8601String(),
            'endedAt'         => optional($this->ended_at)?->toIso8601String(),
            'durationSeconds' => $this->duration_seconds,
            'participants'    => $this->participants->map(fn ($p) => [
                'userId'   => (string) $p->user_id,
                'status'   => $p->status,
                'joinedAt' => optional($p->joined_at)?->toIso8601String(),
            ])->values(),
        ];
    }
}
```

---

## 9. The killed/locked sequence — backend timeline

1. **Caller** → `POST /chats/conversations/{id}/calls {type:VOICE}`.
2. Laravel persists the `Call` (status `RINGING`) + participants.
3. Laravel → **Stream `ring`** with the cid + member ids. Stream sees the
   callee is **OFFLINE** (you reported it on their `/presence/background`)
   → Stream sends an **APNs VoIP push**.
4. iOS (killed/locked) wakes via **PushKit → CallKit**, shows the native
   ring with the caller's name. *(All client-side — see the other doc.)*
5. Laravel also broadcasts `call.invite` to any **online** participants for
   the in-app overlay.
6. **Callee accepts** → app `POST /chats/calls/{id}/accept` → Laravel sets
   `ANSWERED` + broadcasts `call.accept`. The app joins the Stream call
   (audio flows through Stream, not your backend).
7. **End** → `POST /chats/calls/{id}/end` → Laravel computes
   `duration_seconds`, sets `ended_at`, broadcasts `call.hangup`.
8. App re-locks → `POST /presence/background` → callee OFFLINE again → the
   **next** call rings via VoIP push. (The app-side re-register of the
   Stream device after disconnect is what keeps the push route alive.)

---

## 10. Backend porting checklist

- [ ] Create a Stream app; add an **APN provider** (.p8 key, bundle id,
      sandbox env to match `aps-environment`).
- [ ] `.env` + `config/services.php` with Stream key/secret.
- [ ] `firebase/php-jwt` → `StreamTokenService` (user + server tokens).
- [ ] `StreamVideoClient::ring()` with `ring:true` (the push trigger).
- [ ] All `/chats/calls/*` + `/chats/conversations/{id}/calls` endpoints,
      returning the **exact** `CallResource` JSON.
- [ ] `/chats/presence` + `/presence/background` + `/presence/foreground`
      (report OFFLINE immediately on background).
- [ ] `ApiEnvelope` wrapper on every response; `PageResponse` shape on lists.
- [ ] Realtime: **Option A** (STOMP broker, zero client change) or
      **Option B** (Reverb/Pusher + `{event,payload}` bodies + a client
      transport swap).
- [ ] Point the Flutter `environments.dart` base URLs at the Laravel host.

---

## 11. Field/contract cheat-sheet (copy/paste safety)

| Thing | Must be | Notes |
|---|---|---|
| All ids in JSON | string-safe | app does `.toString()`; numbers OK but be consistent |
| Timestamps | ISO-8601 string | parsed by `DateTime.tryParse` |
| `type` | `"VOICE"` / `"VIDEO"` | uppercase |
| call `status` | `RINGING/ANSWERED/REJECTED/MISSED/NO_ANSWER` | uppercase |
| presence `status` | `ONLINE/BUSY/AWAY/OFFLINE` | uppercase |
| `streamCallCid` | `"type:id"` | must equal the cid you rang Stream with |
| `reject` reason | **query** param `?reason=` | not a body field |
| every REST body | `{success,message,data,...}` envelope | `success:false` → app errors |
| realtime frame | `{ "event": "...", "payload": {...} }` | same on STOMP or Reverb |

---

### See also
- `IOS_KILLED_LOCKED_CALL_FLOW.md` — the **client-side** (Flutter + iOS
  native PushKit/CallKit) half of this flow. The backend here is only useful
  paired with that client work.
