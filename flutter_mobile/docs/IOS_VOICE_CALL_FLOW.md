# iOS Voice Call — Step-by-Step Learning Guide

> A teaching walkthrough of how a **voice call** works in this app on iOS,
> from the moment a screen is shown to the moment the call ends.
> Read top-to-bottom the first time. Use the diagrams as a map, then the
> step lists as the detail. The final section is a **reusable recipe** so
> you can lift this design into another project.

---

## 0. The mental model (read this first)

A call in this app is **two independent legs** that run side-by-side:

| Leg | Job | Tech | Analogy |
|-----|-----|------|---------|
| **Signaling leg** | "Ring", "I accept", "I hung up" — *control* messages | Your Laravel backend over **STOMP (WebSocket)** + **REST** | The phone *ringing* and the *call buttons* |
| **Media leg** | The actual audio (and video) stream | **Stream Video** (`stream_video_flutter`) over **WebRTC** | The *voice* you hear |

> 🔑 **Key idea:** signaling and media are separate. The ring can reach you
> even with no audio. The audio only starts once both sides *accept*. This
> separation is why the code has two services: `CallSignalingService`
> (control) and `StreamCallEngine` (media).

There's also a third concern that only matters when the app is **not on
screen**:

| Leg | Job | Tech |
|-----|-----|------|
| **Wake-up leg** | Make a backgrounded/killed phone *ring* | **VoIP Push (PushKit) → CallKit** on iOS, **FCM → custom notification** on Android |

So three things to keep straight: **signal**, **media**, **wake-up**.

---

## 1. The cast of characters (files you'll touch)

```
lib/
├── features/chat/
│   ├── presentation/
│   │   ├── pages/voice_call_page.dart         ← THE SCREEN (in-call UI)
│   │   └── widgets/incoming_call_overlay.dart ← the Accept/Reject sheet
│   └── data/
│       ├── call_signaling_service.dart        ← STATE MACHINE (the brain)
│       ├── chat_transport.dart                ← STOMP/WebSocket wire
│       ├── chats_remote_data_source.dart      ← REST endpoints
│       ├── stream_call_engine.dart            ← WebRTC media (Stream Video)
│       ├── callkit_event_handler.dart         ← bridges native taps → Dart
│       ├── chat_lifecycle_bridge.dart         ← background/foreground rules
│       └── chat_di.dart                        ← bootChatTransport() wiring
├── core/router/
│   ├── config_router.dart                     ← pushPageAnimation() helper
│   └── app_router.dart                        ← rootNavigatorKey
├── app.dart                                    ← mounts IncomingCallOverlay
└── main.dart                                   ← boot order

ios/Runner/AppDelegate.swift                    ← PushKit + CallKit native glue
packages/erp_callkit/                           ← (Android) custom ring notification
```

There is **no go_router route** for the call screen. The page is pushed
**programmatically** (see §4). Remember that — it surprises people.

---

## 2. Layer diagram — how the pieces stack

```
┌─────────────────────────────────────────────────────────────┐
│  UI LAYER                                                     │
│  VoiceCallPage  ◄── listens ──┐   IncomingCallOverlay         │
│  (in-call screen)             │   (ringing sheet)             │
└───────────────────────────────┼───────────────────────────────┘
                                 │ activeCallListenable (ValueNotifier<ActiveCall?>)
┌───────────────────────────────▼───────────────────────────────┐
│  BRAIN  —  CallSignalingService                               │
│  • holds the ActiveCall state machine                         │
│  • startOutgoing / acceptIncoming / rejectIncoming / hangup   │
│  • turns wire events into state transitions                   │
└───┬──────────────────────────┬────────────────────────────┬──┘
    │ control                  │ media                       │ native
┌───▼──────────┐   ┌───────────▼──────────┐   ┌──────────────▼─────────┐
│ ChatTransport │   │  StreamCallEngine    │   │ CallkitEventHandler    │
│ (STOMP)       │   │  (WebRTC / Stream)   │   │ + AppDelegate.swift    │
│ + REST DS     │   │                      │   │ (PushKit / CallKit)    │
└───┬──────────┘   └───────────┬──────────┘   └──────────────┬─────────┘
    │                          │                             │
    ▼                          ▼                             ▼
 Laravel backend        Stream Video SFU            iOS system (APNs VoIP)
 (signaling + auth)      (audio media)               (lock-screen ring)
```

---

## 3. The state machine (the single most important diagram)

`CallSignalState` in `call_signaling_service.dart` has 5 states. Everything
the UI shows is just a reaction to which state we're in.

```
                 startOutgoing()
   ┌────────┐  ───────────────────►  ┌──────────────────┐
   │  idle  │                         │ outgoingRinging  │  (I called, waiting)
   └────────┘  ◄───────────────────  └────────┬─────────┘
        ▲       inbound call.invite           │ peer accepts (call.accept
        │                                      │ OR Stream peer-joined
        │                                      │ OR heartbeat sees ANSWERED)
        │                                      ▼
        │                              ┌──────────────┐
        │                              │  connected   │  ──► audio flows
        │                              └──────┬───────┘      (Stream join)
        │                                     │ hangup() / peer call.hangup
        │   inbound call.invite               ▼
   ┌────┴─────────────┐  accept   ┌──────────────┐
   │ incomingRinging  │ ────────► │    ended     │ ──► page pops, cleanup
   └──────────────────┘           └──────────────┘
        │ reject() / 30s timeout         ▲
        └────────────────────────────────┘
```

- **outgoingRinging** → you tapped Call. The page shows "Calling…".
- **incomingRinging** → someone called you. The overlay sheet appears.
- **connected** → both accepted. Timer starts, `StreamCallEngine.join()` runs, audio flows.
- **ended** → anyone hung up / rejected / timed out. Cleanup.

The `VoiceCallPage` maps these straight to its own `_CallStage` enum
(`calling / ringing / connected / ended`) in `_onActiveCallChanged`.

---

## 4. How the screen gets shown (the URL/route question)

> ❓ You asked "what URL / screen do I start from?" — here's the honest answer
> for *this* codebase: **there is no URL.** Calls don't use go_router named
> routes. They're pushed as a widget onto the **root navigator**.

Three ways the `VoiceCallPage` gets mounted:

**(A) User taps the phone icon in a chat** — `chat_conversation_page.dart`:
```dart
// AppBar action
IconButton(
  icon: const Icon(Icons.call_rounded),
  onPressed: () => _startCall(isVideo: false),
);

void _startCall({required bool isVideo}) {
  ConfigRouter.pushPageAnimation(
    context,
    VoiceCallPage(conversationId: widget.conversationId),
  );
}
```

**(B) Accepting an incoming call** — `incoming_call_overlay.dart` uses the
**root navigator key** (not `Navigator.of(context)` — the overlay is a
*sibling* of the router, so a normal lookup silently fails):
```dart
final navigator = AppRouter.rootNavigatorKey.currentState;
navigator.push(MaterialPageRoute(
  builder: (_) => VoiceCallPage(conversationId: call.conversationId),
  fullscreenDialog: true,
));
signaling.acceptIncoming(); // fire-and-forget
```

**(C) Re-dial from call history** — same `ConfigRouter.pushPageAnimation`.

`ConfigRouter.pushPageAnimation` (in `config_router.dart`) wraps
`Navigator.of(context, rootNavigator: true).push(...)` with a
right-to-left `PageTransition` on iOS. Using the **root** navigator is what
makes the call screen cover the bottom-nav shell.

---

## 5. OUTGOING CALL — step by step (you are the caller)

```
 YOU (caller)                    BACKEND (Laravel)            PEER (callee)
 ────────────                    ─────────────────            ─────────────
 tap 📞
   │
   │ push VoiceCallPage
   │ initState → permission → startOutgoing()
   │
   │── POST /chats/conversations/{id}/calls?type=VOICE ──►
   │                                  creates call row,
   │                                  returns {id, streamCallCid}
   │◄──────── 200 {id:42, cid} ───────│
   │                                   │── STOMP call.invite ──►  📳 rings
   │  state = outgoingRinging          │   (/topic/.../call)       (overlay
   │  UI: "Calling…"                   │                            or CallKit)
   │                                   │
   │  ⟳ iOS heartbeat: GET /chats/calls/42 every few sec
   │     (detects ANSWERED even if STOMP frame is lost)
   │                                   │◄── POST /accept ──────────  taps ✅
   │◄──── STOMP call.accept ───────────│
   │  state = connected                │
   │  StreamCallEngine.join(cid) ──────────────────────────► 🔊 audio (WebRTC)
   │  timer starts 00:01, 00:02…       │
```

**Detailed steps:**

1. **Tap** the phone icon → `_startCall` pushes `VoiceCallPage`.
2. **`initState`** sets `VoiceCallPage.isMounted = true`, grabs
   `CallSignalingService` + `StreamCallEngine` from GetIt, and subscribes to
   `activeCallListenable`.
3. Because no call exists yet, it runs `_placeOutgoingWithPermission()`:
   asks for **mic permission** (iOS), then **always** calls `startOutgoing`
   regardless of the result (the *ring* is a REST call that needs no mic;
   if you denied mic you just transmit silence — the peer still rings).
4. **`startOutgoing`** POSTs `/chats/conversations/{id}/calls?type=VOICE`.
   Backend creates the call, returns the numeric `id` and the Stream
   `streamCallCid`. The service swaps its local placeholder id for the real
   one and stamps the cid.
5. State becomes **outgoingRinging**. The page shows "Calling…" with a
   pulsing avatar. In parallel iOS calls `StreamCallEngine.warmUp()` to fetch
   the Stream token and connect the Stream WebSocket *early* (saves seconds
   later).
6. Backend broadcasts **`call.invite`** over STOMP to the conversation topic;
   every callee's `CallSignalingService` flips to **incomingRinging**.
7. **iOS-only ring heartbeat:** the caller polls `GET /chats/calls/{id}`
   (`reconcileActive()`) on a timer. If the STOMP `call.accept` frame is ever
   lost, the poll still sees the backend status is `ANSWERED` and flips the
   caller to **connected**. (This is the fix from the
   *"caller stuck Calling…"* memory.)
8. When the callee accepts, **`call.accept`** arrives (or Stream fires
   *peer-joined*, or the heartbeat catches it). The caller transitions to
   **connected**.
9. **`StreamCallEngine.join(cid)`** runs on both sides → WebRTC media
   negotiation → 🔊 audio. The page's ticker starts counting `00:01, 00:02…`.

---

## 6. INCOMING CALL — foreground (app open on screen)

This is the simple case: the app is alive, STOMP is connected.

1. Caller does step 4–6 above. Backend broadcasts **`call.invite`** over STOMP.
2. Your `ChatTransport` receives it → emits a `CallInviteEvent`.
3. `CallSignalingService._onEvent` builds an `ActiveCall` and sets state to
   **incomingRinging**.
4. `IncomingCallOverlay` (mounted globally via `MaterialApp.builder` in
   `app.dart`) has a `ValueListenableBuilder` watching
   `activeCallListenable`. It sees `state == incomingRinging` and paints the
   full-screen **Accept / Reject** sheet over whatever screen you're on.
5. **Reject** → `signaling.rejectIncoming()` → POST `/chats/calls/{id}/reject`.
   State → ended.
6. **Accept** →
   - capture `AppRouter.rootNavigatorKey.currentState` **first**,
   - `await ensureCallPermissions()`,
   - **push the `VoiceCallPage` immediately**,
   - then fire `signaling.acceptIncoming()` (fire-and-forget).

   > ⚠️ Order matters. Accepting flips state to `connected`, which unmounts
   > the overlay. If you pushed *after* awaiting accept, the unmount would
   > swallow the navigation and the call page would never open. (This is the
   > *Slice 10.2.8 / 10.2.9* fix — push first, accept second.)
7. `acceptIncoming` POSTs `/chats/calls/{id}/accept` and calls
   `StreamCallEngine.acceptByCid(...)` → join → audio. State → **connected**.

> 🟢 **Foreground design choice (from memory `call-ring-presence-gate`):**
> the *backend* decides who gets a native ring. If you're **online**
> (STOMP session present) you get the in-app overlay only — **no** Stream
> VoIP push. Only **offline** callees get the CallKit ring. This avoids
> double-ringing.

---

## 7. INCOMING CALL — backgrounded or killed (the hard iOS case)

When your app isn't on screen, STOMP is dropped (the lifecycle bridge closes
it to save battery). So the ring **cannot** arrive over WebSocket. Instead it
comes via **VoIP push → CallKit**.

```
 CALLER          BACKEND          Stream/APNs            YOUR iPHONE (locked)
 ──────          ───────          ───────────            ────────────────────
 startOutgoing ─► creates call ─► rings via VoIP push ─► 📳 CallKit full-screen
                  (callee offline)                        ring on LOCK SCREEN
                                                            │
                                                   user taps ✅ Accept
                                                            │
                            ┌───────────────────────────────┘
                            ▼
        iOS CXCallObserver (AppDelegate.swift) sees "hasConnected"
                            │ notifyIncomingCallAnswered(uuid)
                            ▼  via MethodChannel 'erp/ios_callkit'
        CallkitEventHandler (Dart) — _handleAccept:
          1. seed signaling state from the CallKit entry (callCid)
          2. EARLY POST /accept  ◄── so caller stops ringing ASAP
          3. push VoiceCallPage (with retry — cold start may wipe it)
          4. full acceptIncoming() → StreamCallEngine.join → 🔊 audio
```

**Why each piece exists (the iOS gotchas you'll want to remember):**

- **PushKit registration** in `AppDelegate.swift`
  (`StreamVideoPKDelegateManager.shared.registerForPushNotifications()`)
  is what makes a *killed* app able to ring at all.
- **FCM background isolate** (`firebase_notification_provider.dart`) handles
  the `stream.video / call.ring` data message. On **iOS** it lets native
  CallKit/PushKit show the ring; on **Android** it renders a custom
  full-screen notification via the `erp_callkit` package.
- **`CXCallObserver`** in `AppDelegate.swift` watches CallKit. When the user
  taps Accept on the lock screen, the native `hasConnected` transition is
  bridged to Dart (`notifyIncomingCallAnswered`). When they tap End, the
  `hasEnded` transition bridges to `notifyIncomingCallEnded` so a backgrounded
  hangup still reaches the backend.
- **Foreground suppression:** the same `CXCallObserver` *dismisses* a CallKit
  screen if it appears while the app is genuinely on-screen — so you never get
  both the native ring and the in-app overlay. It uses an `isAppForeground`
  flag that ignores the transient `.inactive` state CallKit triggers.
- **Cold-start retry:** when the app launches fresh from a lock-screen accept,
  go_router's splash→dashboard redirect can wipe the freshly-pushed call page.
  `IncomingCallOverlay` polls for up to ~6s and re-pushes if
  `VoiceCallPage.isMounted` went false. That static `isMounted` flag exists
  exactly for this.
- **`chat_lifecycle_bridge.dart` iOS carve-out:** on iOS, when `detached`
  fires *during* a call (which it does a few seconds after a lock-screen
  accept), the bridge **must NOT** hang up — the CallKit audio session keeps
  the process alive. On Android it *does* hang up before death.

---

## 8. ENDING THE CALL

1. User taps the red **End** button on `VoiceCallPage` (or the native CallKit
   End, or the peer hangs up).
2. `CallSignalingService.hangup()`:
   - POSTs `/chats/calls/{id}/end`,
   - broadcasts **`call.hangup`** over STOMP,
   - calls `StreamCallEngine.leave()` to tear down WebRTC media,
   - clears all call notifications / dismisses any CallKit screen,
   - sets state → **ended**.
3. The page reacts to `ended`, cancels its ticker, and pops. `dispose()` sets
   `VoiceCallPage.isMounted = false`. If the call was answered over the lock
   screen, it returns the app *behind the keyguard* instead of revealing the
   dashboard.
4. A summary row (`📞 Voice call · 1:23` / `Missed` / `Declined`) is written
   to the conversation so the inbox tile and timeline show call history.

**Group-call nuance (from memory):** in a group, only the **original
caller's** hangup ends it for everyone (`hangerUpperId == callerId`). A callee
tapping End just leaves their own leg; the rest stay connected. When the *last*
callee leaves, the caller auto-ends (tracked via an `_activeCallees` set).

---

## 9. Full sequence diagram (foreground accept, the clean path)

```
Caller App        Backend          Callee App (foreground)
    │  POST /calls?type=VOICE         │
    ├────────────────►│               │
    │   200 {id,cid}  │               │
    │◄────────────────┤               │
    │ outgoingRinging │ STOMP invite  │
    │                 ├──────────────►│ incomingRinging
    │                 │               │  → IncomingCallOverlay sheet
    │                 │   POST /accept│
    │                 │◄──────────────┤ (tap Accept; push page FIRST)
    │ STOMP accept    │               │
    │◄────────────────┤               │
    │ connected       │               │ connected
    │ Stream.join(cid)│               │ Stream.acceptByCid(cid)
    │◄═══════════ WebRTC audio (Stream SFU) ═══════════►│
    │ 00:01 00:02 …   │               │ 00:01 00:02 …
    │  tap End        │               │
    │ POST /end       │               │
    ├────────────────►│ STOMP hangup  │
    │                 ├──────────────►│ ended → pop
    │ ended → pop     │               │
```

---

## 10. Backend contract (the REST + STOMP surface)

If you reuse this, your backend needs to expose exactly this. From
`chats_remote_data_source.dart`:

| Action | HTTP | Endpoint | Body / Query | Returns |
|--------|------|----------|--------------|---------|
| Start call | POST | `/chats/conversations/{id}/calls` | `type=VOICE\|VIDEO` | `{id, streamCallCid, …}` |
| Accept | POST | `/chats/calls/{id}/accept` | — | call dto |
| Reject | POST | `/chats/calls/{id}/reject` | `?reason=` | call dto |
| End | POST | `/chats/calls/{id}/end` | — | call dto |
| Reconcile | GET | `/chats/calls/{id}` | — | call dto (status) |
| Stream token | GET | (token endpoint) | — | JWT for Stream SDK |

STOMP topics (from `chat_transport.dart`):

| Topic | Carries |
|-------|---------|
| `/user/queue/calls` | incoming `call.invite` to me |
| `/topic/conversations/{id}/call` | `call.accept` / `call.reject` / `call.hangup` |
| `/user/queue/inbox` | global events |

**The backend is the source of truth** — note from memory: the call's
voice-vs-video type lives **only** in your backend's `ChatCallDto.type`; the
Stream call type is always `'default'`. Don't read call type from Stream.

---

## 11. Boot order (where it all gets wired) — `main.dart`

```
1. StreamCallEngine.primeWebRtcAudioEventSinkEarly()  ← iOS crash fix, FIRST
2. Firebase.initializeApp()
3. FirebaseMessaging.onBackgroundMessage(handler)     ← before runApp
4. LocalNotificationProvider().initialize()
5. registerChatModule(getIt)                          ← DI registrations
6. bootChatTransport(getIt)                           ← connect STOMP, wire events,
                                                         eagerly create CallSignalingService
7. _wireStreamWarmUpToAuth(...)                        ← warm Stream on login
8. CallkitEventHandler.instance.attach()              ← before runApp
9. runApp(...)  →  app.dart mounts IncomingCallOverlay via MaterialApp.builder
```

The critical subtlety: `bootChatTransport` **eagerly resolves**
`CallSignalingService` so its STOMP listener is live *before* any peer can
call you. A lazy singleton would miss the first invite.

---

## 12. Reusable recipe — porting this to another project

Here's the checklist to rebuild this pattern cleanly elsewhere:

### Backend
1. A `calls` table + 5 endpoints (start/accept/reject/end/get) — §10.
2. A STOMP/WebSocket broker that, on `start`, broadcasts `call.invite` to the
   other participants, and relays `accept`/`reject`/`hangup`.
3. Integrate **Stream Video** server-side: create the call, return its
   `streamCallCid`, and (for offline callees) trigger the **VoIP push ring**.
4. A "presence" signal so the backend only sends a *push ring* to **offline**
   users (online users get the STOMP invite + in-app sheet). This single rule
   removes the worst double-ring bugs.

### Flutter — control plane
5. A **state machine service** (`CallSignalingService`) holding an
   `ActiveCall` exposed as a `ValueNotifier`. 5 states (§3). Methods:
   `startOutgoing / acceptIncoming / rejectIncoming / hangup`.
6. A **transport** that subscribes to STOMP and emits typed events
   (`CallInviteEvent`, `CallAcceptEvent`, `CallRejectEvent`, `CallHangupEvent`).
7. **Eagerly construct** the signaling service at boot so it doesn't miss the
   first invite.
8. A **ring heartbeat** for the caller (poll `GET /calls/{id}`) so a lost
   accept frame still connects the call.

### Flutter — UI plane
9. An **in-call page** that subscribes to the `ValueNotifier` and maps states
   to UI. Push it via the **root navigator** (not a nested one).
10. A **global incoming overlay** mounted in `MaterialApp.builder`, watching
    the same notifier. On Accept: **push the page first, accept second.**
11. A `rootNavigatorKey` so the overlay (a router sibling) can navigate.

### Flutter — media plane
12. `StreamCallEngine` wrapping `stream_video_flutter`: `warmUp()`, `join(cid)`,
    `acceptByCid(cid)`, `leave()`. Configure the iOS audio session
    (`playAndRecord` / `voiceChat`) and re-assert the route after join.

### iOS native
13. `AppDelegate.swift`: register **PushKit**, add a **`CXCallObserver`** to
    (a) bridge lock-screen Accept/End taps to Dart and (b) dismiss CallKit when
    the app is genuinely foreground.
14. A `MethodChannel` (`erp/ios_callkit`) for `isAppForeground` / `dismissIncoming`.
15. `flutter_callkit_incoming` + a Dart `CallkitEventHandler` that drives the
    accept ceremony on the cold-start / backgrounded paths.
16. **Lifecycle carve-out:** on iOS, never self-hang-up on `detached` during a
    call — the CallKit audio session keeps you alive.

### The traps that cost the most time (learn from the memory log)
- **Push the call page BEFORE awaiting accept** (else the overlay unmount eats the nav).
- **Use a root navigator key from the overlay** (it's a sibling, not an ancestor).
- **Online vs offline ring gate lives on the backend**, not the client.
- **Caller heartbeat** rescues "stuck on Calling…".
- **iOS `detached` ≠ death during a call** — don't hang up.
- **Call type comes from your backend**, never from Stream (`'default'`).
- **Prime the WebRTC audio sink at startup** or `stream_webrtc` crashes on accept.

---

## 13. One-paragraph summary (the elevator version)

You tap a phone icon; the app pushes `VoiceCallPage` and calls
`CallSignalingService.startOutgoing`, which POSTs to your Laravel backend and
gets a Stream call id back. The backend rings the other person — over STOMP if
they're online (in-app overlay) or over a VoIP push → CallKit if they're not
(lock-screen ring). When they accept, an `accept` comes back over STOMP (or a
heartbeat catches it), both sides flip to `connected` and call
`StreamCallEngine.join()` so WebRTC audio flows through Stream's servers. End
hangs up over REST + STOMP, tears down the media, and writes a call-history
row. Signaling, media, and wake-up are three separate concerns — keep them
separate and the whole thing stays understandable.
```
