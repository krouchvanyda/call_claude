# Voice / Video Call Architecture (Module 10)

> iOS-focused reference for the Stream-Video-based calling stack: VoIP push →
> CallKit ring → accept → media leg → audio. Traces every critical path,
> documents the long-running "locked-screen accept is silent" bug, its proven
> root causes, and the fixes applied.
>
> Stack: `stream_video 1.4.1` + `stream_video_push_notification 1.4.1` +
> `stream_webrtc_flutter 3.0.0` (framework `StreamWebRTC`) +
> `flutter_callkit_incoming 2.5.7`. A separate **app chat backend** (Spring, on
> the LAN) owns call *signaling* (who's ringing / accepted / hung up); Stream
> owns the *media* (WebRTC SFU).

---

## 1. The two independent planes

A call has **two parallel systems** that must both succeed:

| Plane | Owner | Transport | Purpose |
|---|---|---|---|
| **Signaling** | App chat backend (`/chats/calls/...`) | STOMP + REST over LAN | Ring / accept / reject / hangup between caller & callee; drives call-page UI state |
| **Media** | Stream Video (WebRTC) | Stream cloud coordinator + SFU | The actual audio/video |

They run on **different networks**: the chat backend is on the **LAN**
(`172.26.17.118:8080`); Stream's coordinator is on the **cloud**
(`video.stream-io-api.com`). This distinction is central to the locked-screen
bug (§7): iOS throttles cloud access in the background but the LAN keeps
working, so the signaling plane succeeds while the media plane hangs.

Key files:

- `lib/features/chat/data/stream_call_engine.dart` — Stream client + media
  (join / accept / getOrCreate / audio session). "The engine."
- `lib/features/chat/data/call_signaling_service.dart` — chat-backend signaling,
  call state machine, STOMP event handling. "The signaling service."
- `lib/features/chat/data/callkit_event_handler.dart` — bridges native
  CallKit events → the signaling service. "The handler."
- `ios/Runner/AppDelegate.swift` — VoIP registration, CXCallObserver bridge,
  WebRTC manual-audio handshake.
- `lib/shared/firebase_services/firebase_notification_provider.dart` — Android
  FCM push handling (iOS uses Stream's native PushKit instead).

---

## 2. Who shows the incoming-call ring?

### iOS (VoIP / PushKit)
- `AppDelegate.didFinishLaunching` calls
  `StreamVideoPKDelegateManager.shared.registerForPushNotifications()`.
- When a caller creates a Stream call with `ringing: true`, Stream's server
  fires a **VoIP push** to the callee.
- **Stream's own native code** (`StreamVideoCallkitManager`, a
  `CXProviderDelegate` with its **own** `CXProvider`) receives the PushKit push
  and reports the incoming call to **CallKit**. This shows the full-screen
  ringer even on the lock screen / when the app is killed.
- **No Dart code runs to show the ring.** `flutter_callkit_incoming` is only a
  bridge for events; it does **not** own this call's CXProvider.

### Android (FCM)
- `firebaseMessagingBackgroundHandler` runs in a background isolate and calls
  `ErpCallKit.showIncomingCall()` to render the ringer.

> **Consequence:** on iOS, the CallKit call (and its audio session) is owned by
> **Stream's** `CXProvider`, *not* the app's `flutter_callkit_incoming`
> provider. This is why the app's own `CallkitIncomingAppDelegate.didActivate`
> historically never fired for locked calls, and why manual-audio has to enable
> WebRTC audio regardless of which provider activates the session (§7.4).

---

## 3. Stream client lifecycle

The Stream client (`_client` in the engine) is **not always connected** — by
design it goes offline in the background so incoming calls arrive via VoIP push
rather than an invisible WebSocket event.

| Method | When | Effect |
|---|---|---|
| `warmUp()` | auth transition, app resume | Connects the client — **SKIPPED when app is backgrounded OR device locked** (so the next call rings via push, not WS) |
| `_ensureClient()` | inside `join()` / `acceptByCid()` / `acceptPendingIncoming()` / `prepareIncoming()` | Lazily builds + connects the client on demand; retries `connect()` up to 4× (coordinator WS handshake has a hard 5s SDK timeout) |
| `disconnectForBackground()` | app → background, no active call | Drops the WS so Stream marks the device offline → next call rings via APNs VoIP push |
| `goOfflineForPushIfBackground()` | after a background ring resolves | Drops STOMP + Stream WS + reports OFFLINE so the next call rings via push |

**Critical timing:** on the locked path the client is **not alive at
push-arrival** — historically it was first built inside `join()`, *after* the
user taps Accept. Moving coordinator work earlier (into the push window) is the
current fix direction (§7.5).

---

## 4. Outgoing (caller) flow

`call_signaling_service.startOutgoing(conversationId, callType)`:

1. **iOS:** `warmUp()` in parallel (pre-connect while the POST round-trips).
2. `POST /chats/conversations/{id}/calls` → backend creates the call row,
   returns numeric `id` + `streamCallCid`.
3. Swap the placeholder callId for the numeric id.
4. `streamEngine.join(streamCallCid, shouldRing: true, isOutgoing: true)`:
   - `getOrCreate(ringing: true, members: [callee ids])` → fires the VoIP push
     to callees, extends ring timeouts to 60s.
   - **iOS only:** `client.state.setOutgoingCall(null)` after the ring so the
     SDK's outgoing-call state machine can't cancel our in-flight `call.join()`
     when the callee accepts.
   - `call.join()` → joins the SFU; `_attachPeerJoinedListener(call)`.
5. Caller flips to **Connected** when EITHER:
   - **(primary)** STOMP `call.accept` arrives (callee POSTed `/accept`), or
   - **(fallback)** Stream `onStreamPeerJoined` fires (callee's media leg came
     up even though the backend never broadcast `call.accept`).

---

## 5. Incoming (callee) accept flow — locked / background

The full chain when B is minimized + locked and taps Accept on the native
CallKit screen:

```
VoIP push ──► Stream native PushKit ──► CallKit shows ring (no Dart)
                                             │
                              user taps Accept
                                             │
AppDelegate CXCallObserver.callChanged(hasConnected, !isAppForeground)
   └─ invokeMethod("incomingCallAnswered", {uuid, call})  → Dart
                                             │
callkit_event_handler._handleAccept(body):
   ├─ UUID-only? → signaling.recoverRingingInviteFromBackend()
   │     (list backend calls → newest RINGING → real callCid + numeric id)
   ├─ notifyBackendAcceptEarly(id) → POST /chats/calls/{id}/accept  (FIRE-AND-FORGET)
   │     └─ backend broadcasts call.accept → CALLER STOPS RINGING immediately
   ├─ step 1: signaling.handleIncomingFromPush(payload)  → seed _active = incomingRinging
   ├─ step 2: push VoiceCallPage / VideoCallPage (with retries)
   └─ step 3: signaling.acceptIncoming()
                                             │
call_signaling_service.acceptIncoming():
   ├─ POST /chats/calls/{id}/accept   (chat plane → response carries streamCallCid)
   ├─ configureIosCallAudio()         (AVAudioSession → playAndRecord/voiceChat)
   ├─ _setActive(state: connected)    (call page mounts, timer starts)
   └─ unawaited media bring-up:
        ├─ hasPendingIncoming (foreground WS ring) → acceptPendingIncoming(cid)
        ├─ iOS + no pending (LOCKED)              → join(shouldRing: false)   ◄── the locked path
        └─ Android + no pending                   → acceptByCid(cid)
                                             │
stream_call_engine.join(streamCallCid, shouldRing: false):
   ├─ _ensureClient()                 (build + connect client; retries connect 4×)
   ├─ reuse _preparedCall if present  (skipGetOrCreate — see §7.5)
   ├─ else call.getOrCreate(ringing:false, watch:false)   ◄── HANGS in locked bg (§7)
   ├─ call.join()                     (WebRTC media leg → SFU)
   ├─ _setWebRtcAudioEnabled(true)    (manual audio — §7.4)
   ├─ _ensureMicPublishing(call)
   └─ _reassertIosAudioRoute()
```

### The three media-bring-up paths

| Path | When | Mechanism |
|---|---|---|
| `acceptPendingIncoming(cid)` | Foreground, Stream WS delivered the ring | `call.accept()` + `call.join()` on the **same** Call ref Stream pushed (`state.incomingCall`) |
| `join(shouldRing: false)` | **iOS locked/background**, no pending ref | fresh `makeCall` → `getOrCreate` (or reuse prepared) → `call.join()` |
| `acceptByCid(cid)` | Android / fallback | `consumeIncomingCall(uuid, cid)` → SDK fetches call in Incoming state → `accept()` + `join()` |

### Why the early backend POST matters
`notifyBackendAcceptEarly()` POSTs `/accept` **before** any media setup, so the
caller's STOMP socket gets `call.accept` and stops ringing even if the callee's
media join is slow or suspended. Removing it strands the caller on "Calling…".

---

## 6. Teardown / end signals

A call can end via several independent signals; the code must treat each
correctly (a mis-handled one either strands a call or kills it early):

- **Local End button** → `endActiveCall()` (bumps `_callSeq`, tears down media)
  + `POST /end`.
- **Native End on the CallKit screen** (locked) → `AppDelegate` CXCallObserver
  `hasEnded` → `incomingCallEnded` → `_handleNativeCallEnded` → hangup POST.
- **Peer hangup (STOMP `call.hangup`)** → signaling tears down.
- **Stream media end** (`onStreamCallEnded`) → the engine detects the peer left
  / disconnect via `_attachEndListener`. Debounced 6s for the 1.4.x
  roster-empty-while-connected blip; suppressed entirely during call setup
  (see §7.1).

---

## 7. The "locked accept connects but is silent" bug

Long-standing: A calls B; B is minimized + locked; B accepts; the timer runs on
both sides but **neither can hear the other**. This took a long series of fixes,
each uncovering the next layer. Documented here so the history isn't lost.

### 7.1 Spurious call-end superseded the join
`join()` claims `mySeq = ++_callSeq` then awaits `_ensureClient()`. Building a
fresh client subscribes to `incomingCall.valueStream`, which **replays `null`**
(the ring slot is already cleared on a locked cold-accept) → fired
`onStreamCallEnded(incomingCleared)` → `endActiveCall()` → `++_callSeq` → the
in-flight `join()` saw `mySeq != _callSeq` and bailed **before** `call.join()`.

**Fix:** route every `onStreamCallEnded` emission through `_emitCallEnded()`,
which **drops** the event while `_callSetupInProgress && _activeCall == null` —
before the media leg exists, any Stream-media "ended" signal is churn; a real
caller hangup arrives over STOMP.

### 7.2 A debug diagnostic blocked the join
`_ensureClient()` did `await _logPushDiagnostics()`, which internally awaited
`_checkStreamDevices()` → `_client.getDevices()` — a coordinator call that
hangs in the locked background. It never returned, so `join()` never reached
`getOrCreate`.

**Fix:** fire-and-forget the diagnostic (`unawaited(...)`). Diagnostic-only
code must never gate the accept path.

### 7.3 `getOrCreate` times out — coordinator WS gated
In `stream_video 1.4.1`, **every** coordinator op
(`CoordinatorClientOpenApi.getOrCreateCall`) first does
`await _waitUntilConnected()`, which blocks on the coordinator **WebSocket**
reaching Connected (hard 5s SDK timeout). Also, `getOrCreate` defaults to
`watch: true`, which opens a WS event-watch subscription as part of the op.

**Fixes:**
- Retry `_client.connect()` up to 4× so the WS handshake actually completes.
- Pass `watch: false` on the callee `getOrCreate` (the callee only joins an
  existing call; it doesn't need the coordinator watch).
- Timeout + retry the `getOrCreate` itself, reconnecting the WS between tries.

### 7.4 Audio session won't activate (manual audio)
Even once the media leg forms (`call.join OK`), audio was silent with native
`AVAudioSession … "Session activation failed"`. WebRTC ran in **automatic**
audio mode, so its audio device module tried to activate the shared
`AVAudioSession` itself — which iOS **forbids from the lock screen**. And Stream's
CallKit `didActivate` (which would activate it properly) reaches **Stream's**
provider, not the app's.

**Fix (manual audio):**
- `AppDelegate`: `import StreamWebRTC`; `RTCAudioSession.useManualAudio = true`
  at launch; on CallKit `didActivate` → `audioSessionDidActivate` +
  `isAudioEnabled = true` (reverse on deactivate); new `setWebRtcAudioEnabled`
  method-channel case.
- Engine: `_setWebRtcAudioEnabled(true)` after **every** successful join (so the
  foreground/outgoing/in-app paths — which CallKit never activates — still start
  audio); `false` on `leave()`.
- Also bridge Stream's own `ActionCallToggleAudioSession(isActive:true)` (from
  `pushNotificationManager.onCallEvent`) to the existing route-reassert +
  mic-bounce, since on the locked path that event — not
  `flutter_callkit_incoming`'s — is what fires.

### 7.5 The real wall: cloud coordinator throttled post-accept
**Decisive finding (release build, logs 2704–2710):** the coordinator WS
reconnects successfully every retry, yet `getOrCreate` **still** times out. The
LAN `/chats` polling works throughout, but the **cloud** coordinator call hangs.
**iOS throttles the freshly-woken app's internet access in the locked
background** (LAN stays reachable). Because the manual accept path does the
cloud round-trip at **Accept** time — 5–15s after the push, once iOS has
throttled the app — it can't complete. No media leg → silence.

> A `debug` build makes this worse: the Dart VM runs on a throttled
> `UIApplication` background task (`"Flutter debug task" … risk of
> termination`). A **release** build with the active CallKit call lets the media
> leg form (`call.join OK` seen), but the cloud call is still flaky.

**Fix direction (chosen): do the coordinator work in the guaranteed VoIP-push
window, not at Accept.** The off-screen STOMP `CallInviteEvent` reaches Dart
right after the push wakes the app. That handler now fires
`_prepareIncomingStream()` (→ `prepareIncoming()` → `getOrCreate(watch:false)`)
**then**, warming the media leg while iOS still permits cloud access.
`join()`'s prepared-call fast-path (`skipGetOrCreate`) reuses that ref at
Accept, so Accept only runs the SFU join. A 45s `_bgRingRearmTimer` re-arms
"offline for push" if the ring is never accepted (so the next call still rings),
cancelled the instant the user accepts.

**Scope / limitation:** this covers *app minimized + locked but alive* (the
STOMP invite reaches Dart). It does **not** cover a *killed* app or a
STOMP-down state — those still hit the throttled Accept-time `getOrCreate`. If
prepare's `getOrCreate` also times out in the push window, the remaining option
is *fully* native: let Stream's PushKit callback consume the call before any
Dart runs, or keep the connection warm across background.

---

## 8. Dual-provider notes (iOS)

- **Only** `StreamVideoPKDelegateManager` registers for VoIP push. Stream's
  `CXProvider` shows and owns the locked call + its audio session.
- `flutter_callkit_incoming` is a **bridge** for CallKit events; it does not
  register VoIP or show this call's ring. Its `activeCalls()` may still list the
  call, but calling `setCallConnected` on it **crashes** the Stream PushKit path
  (force-unwraps nil) — so we never do.
- The app detects the native accept via its own `CXCallObserver` (in
  `AppDelegate`), not via Stream's answer action — which is why our flow runs a
  manual accept rather than Stream's built-in one.

---

## 9. Guardrails when touching this code

- **Never** block the accept path on a diagnostic or a coordinator read (§7.2).
- Media-plane end signals (`onStreamCallEnded`) must be **suppressed during
  setup** and **debounced** for the 1.4.x roster blip (§7.1, §6).
- Keep the **early backend POST** (`notifyBackendAcceptEarly`) — it's what stops
  the caller ringing on a slow/suspended accept (§5).
- Manual audio changes the audio path for **all** call types — re-test
  **foreground + outgoing** after any audio change, not just the locked case
  (§7.4).
- `warmUp()` stays SKIPPED when backgrounded/locked; connect on demand via
  `_ensureClient()` (§3). Don't keep the WS warm globally — it reintroduces the
  "next call rings silently over WS / missed call" bug.
- The caller learns of accept via STOMP `call.accept` **or** Stream
  `onStreamPeerJoined` — keep both (§4).

---

## 10. Key log breadcrumbs

Grep these in a device log to locate yourself in the flow:

| Log line | Meaning |
|---|---|
| `CallInviteEvent N arrived while off-screen` | STOMP ring reached Dart (push window) |
| `WARMING the Stream media leg NOW (VoIP-push window)` | prepare-during-ring started (§7.5) |
| `prepared incoming call default:erp-call-N (getOrCreate done during ring)` | **coordinator succeeded in the push window** ✅ |
| `_handleAccept ENTER` / `✅ CALL CONNECTED` | native accept bridged to Dart |
| `connect() attempt N/4 → coordinator WS CONNECTED` | Stream client connected |
| `reusing prepared call … skipping getOrCreate` | Accept reused the warmed call ✅ |
| `getOrCreate TIMED OUT (attempt N/3)` | cloud coordinator throttled (§7.5) ❌ |
| `call.join OK on outgoing` | media leg formed |
| `setWebRtcAudioEnabled(true) → sent` / `callkitAudioActivated` | manual audio enabled (§7.4) |
| `Session activation failed` | AVAudioSession not activatable from bg (§7.4) |

---

*Last updated: 2026-07-02. See the branch `fix/stream-1.4.1-locked-audio` git
history for the individual fixes referenced in §7.*
