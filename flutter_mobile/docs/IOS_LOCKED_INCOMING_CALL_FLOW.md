# Current iOS Locked-Screen Incoming-Call Flow Architecture

> A step-by-step trace of what happens when **Caller A** calls **Caller B**
> while B's app is **minimized + the screen is locked**, from VoIP push arrival
> through media connection and audio.
>
> Companion to [`CALL_ARCHITECTURE.md`](./CALL_ARCHITECTURE.md) (the broader
> reference). This file zooms in on the single hardest path.
>
> Stack: `stream_video 1.4.1`, `stream_video_push_notification 1.4.1`,
> `stream_webrtc_flutter 3.0.0` (framework `StreamWebRTC`),
> `flutter_callkit_incoming 2.5.7`. Separate app **chat backend** (LAN) for
> signaling; **Stream cloud** for WebRTC media.

---

## 0. TL;DR

On a locked accept, **two planes must both succeed**:

- **Signaling** (LAN chat backend) — succeeds: caller stops ringing, timer
  starts, UI shows "Connected".
- **Media** (Stream cloud coordinator + WebRTC SFU) — the hard part: a cloud
  `getOrCreate` at accept-time is throttled by iOS in the locked background, so
  the media leg often never forms → both sides silent even though the UI says
  connected.

The current fix warms the media leg **during the VoIP-push window** (when the
STOMP invite reaches Dart), so accept can reuse it instead of doing a cold
cloud call. Manual WebRTC audio then routes the sound once media is up.

---

## 1. VoIP push handling — who shows the ring?

```
Caller A: POST /chats/conversations/{id}/calls   (ring:true)
   └─ backend → Stream getOrCreate(ring:true, members:[B])
        └─ Stream server → VoIP (PushKit) push to B's device
```

On **B's device**:

- `AppDelegate.didFinishLaunchingWithOptions` has already called
  `StreamVideoPKDelegateManager.shared.registerForPushNotifications()`
  (`ios/Runner/AppDelegate.swift`).
- Stream's **native** `StreamVideoCallkitManager` (a `CXProviderDelegate` with
  its **own** `CXProvider`) receives the PushKit push and calls
  `reportNewIncomingCall(...)` → **CallKit shows the full-screen ringer** on the
  lock screen.

> **No Dart code runs to display the ring.** `flutter_callkit_incoming` does
> **not** own this call's provider — Stream does. This is why the CallKit call
> and its audio session belong to Stream's provider (matters in §6).

In parallel, the app's own STOMP `CallInviteEvent` may *also* reach the Dart
isolate (the app is minimized but alive) — see §3, which is where the current
fix hooks.

---

## 2. User taps Accept → native → Dart bridge

```
CallKit "Accept" tapped
   │
AppDelegate CXCallObserver.callObserver(_, callChanged:)
   ├─ guard: !call.isOutgoing && call.hasConnected && !call.hasEnded
   ├─ guard: !isAppForeground   (locked/minimized ⇒ true)
   └─ callkitChannel.invokeMethod("incomingCallAnswered", {uuid, call})
                                             │  method channel: erp/ios_callkit
                                             ▼
callkit_event_handler._onIosNativeCallkit("incomingCallAnswered", body)
   └─ _handleAccept(body)
```

`AppDelegate` uses a `CXCallObserver` (not Stream's answer action) because on a
killed/locked cold-start the plugin's `actionCallAccept` event is unreliable —
`hasConnected` on the observed call is the one timing-independent signal.

---

## 3. Prepare the media leg during the VoIP-push window ◄── the current fix

**Before** the user even accepts, if the app is minimized+alive the STOMP
invite reaches Dart:

```
call_signaling_service._onTransportEvent → CallInviteEvent
   └─ iOS && !(appForeground && deviceUnlocked):
        print "CallInviteEvent N arrived while off-screen … WARMING the Stream
               media leg NOW (VoIP-push window)"
        ├─ _prepareIncomingStream(callId, callType)
        │     ├─ remote.getCall(callId)         → learn streamCallCid   (LAN — works in bg)
        │     └─ streamEngine.prepareIncoming(cid)
        │           ├─ _ensureClient()          → build + connect Stream client
        │           └─ call.getOrCreate(ringing:false, watch:false, 8s)  (CLOUD)
        │                 └─ _preparedCall = call ; _preparedCid = cid
        │                    print "prepared incoming call … (getOrCreate done during ring)"
        └─ _armBackgroundRingRearm(callId)       → 45s safety timer
```

- **Why here:** iOS throttles cloud access *later* (at accept time), but grants
  execution right after the push wakes the app. Doing `getOrCreate` **now**,
  while cloud is still reachable, is the whole point.
- **`watch:false`** — the callee only joins an existing call; it doesn't need the
  coordinator WS event-watch (which stalls when iOS suspends the socket).
- **We do NOT `goOfflineForPushIfBackground()` here** — that would drop the
  client we're warming. The 45s `_bgRingRearmTimer` re-arms "offline for push"
  (and `discardPrepared()`) if the ring is never accepted, so the next call
  still rings via push. It's cancelled the instant `acceptIncoming()` runs.

> **Scope:** this path only fires when the STOMP invite reaches Dart — i.e.
> **minimized + locked but alive**. A *killed* app, or a state where STOMP is
> down, skips this and falls back to the throttled accept-time `getOrCreate`
> (§5, "no prepared call" branch).

---

## 4. `_handleAccept` — recover the call + tell the backend early

`callkit_event_handler._handleAccept(body)`:

```
1. cid resolution:
     UUID-only accept?  → signaling.recoverRingingInviteFromBackend()
                          (GET /chats/calls → newest RINGING where caller≠me →
                           { callId, streamCallCid })
2. notifyBackendAcceptEarly(numericId)
     → POST /chats/calls/{id}/accept   (FIRE-AND-FORGET)
     → backend broadcasts call.accept → CALLER STOPS RINGING immediately,
       even if the rest of the flow is slow/suspended
3. step 1 → signaling.handleIncomingFromPush(payload)   → _active = incomingRinging
4. step 2 → push VoiceCallPage / VideoCallPage           (retry for cold-start)
5. step 3 → signaling.acceptIncoming()                   → §5
```

The **early POST (step 2)** is load-bearing: it's what reliably stops the
caller's ring on a slow locked accept. Do not remove it.

---

## 5. `acceptIncoming` — chat accept + media bring-up

`call_signaling_service.acceptIncoming()`:

```
_bgRingRearmTimer.cancel()                 // user is accepting — don't re-arm
POST /chats/calls/{id}/accept              // chat plane; response carries streamCallCid
configureIosCallAudio()                    // AVAudioSession → playAndRecord/voiceChat
_setActive(state: connected)               // call page mounts, TIMER STARTS
unawaited media bring-up:
   ├─ streamEngine.hasPendingIncoming?     → acceptPendingIncoming(cid)   // foreground WS ring
   ├─ iOS && no pending                    → join(shouldRing: false)       // ◄── LOCKED PATH
   └─ Android && no pending                → acceptByCid(cid)
```

The locked path takes `join(shouldRing: false)` because the Stream WS was down
when the ring arrived, so `state.incomingCall` was never populated
(`hasPendingIncoming == false`).

### `stream_call_engine.join(streamCallCid, shouldRing: false)`

```
mySeq = ++_callSeq
_callSetupInProgress = true
_ensureClient():
   ├─ fetch /chats/calls/stream-token
   ├─ build StreamVideo(userId, token, apiKey)
   ├─ subscribe state.incomingCall  (guarded by _emitCallEnded so a null-replay
   │                                  can't supersede this join — §7.1 of the
   │                                  companion doc)
   ├─ subscribe pushNotificationManager.onCallEvent  (ActionCallToggleAudioSession → audio)
   ├─ connect() retried up to 4×  → "coordinator WS CONNECTED"
   └─ (fire-and-forget push diagnostics — must NOT block)
supersede check (mySeq == _callSeq)  → "past post-_ensureClient supersede check"
resolve Call ref:
   ├─ IF _preparedCall && _preparedCid == cid   → REUSE  → "reusing prepared call … skipping getOrCreate"   ✅ (§3)
   └─ ELSE  makeCall() → getOrCreate(ringing:false, watch:false)   // cold path — throttled in locked bg (§7)
call.join()                          → "call.join OK on outgoing" — WebRTC media leg up
_activeCall = call
_setWebRtcAudioEnabled(true)         → manual audio (§6)
_ensureMicPublishing(call)           → "setMicrophoneEnabled(true) → OK"
_reassertIosAudioRoute()             → ensureiOSAudioSession + speaker
```

**If §3 warmed the call**, `join` hits the `reusing prepared call` fast-path and
only runs `call.join()` — no cold cloud round-trip. **If not**, it falls to the
cold `getOrCreate`, which is the step that times out in the locked background.

---

## 6. Audio — WebRTC manual audio

Even after `call.join OK`, audio was silent because WebRTC (automatic mode)
tried to activate the `AVAudioSession` itself, which iOS forbids from the lock
screen (`"Session activation failed"`), and CallKit's `didActivate` fires on
**Stream's** provider, not the app's.

Current handshake:

```
AppDelegate.didFinishLaunching:
   RTCAudioSession.sharedInstance().useManualAudio = true      // WebRTC won't self-activate
   RTCAudioSession.sharedInstance().isAudioEnabled  = false

AppDelegate.didActivateAudioSession(session):                  // CallKit activated the session
   RTCAudioSession.audioSessionDidActivate(session)
   RTCAudioSession.isAudioEnabled = true                       // start the audio unit
   callkitChannel.invokeMethod("callkitAudioActivated")

erp/ios_callkit "setWebRtcAudioEnabled" { enabled } :
   RTCAudioSession.isAudioEnabled = enabled

engine after every successful join:  _setWebRtcAudioEnabled(true)   // covers non-CallKit paths
engine on leave():                    _setWebRtcAudioEnabled(false)
engine onCallEvent ActionCallToggleAudioSession(isActive:true):
   → onCallKitAudioSessionActivated()  (route re-assert + mic bounce)
```

Manual audio changes the audio path for **all** call types, so foreground +
outgoing must be re-tested alongside the locked case.

---

## 7. Why the cold accept-time path fails (the wall)

Proven from release-build device logs (calls 2704–2710):

1. `connect() attempt 1/4 → coordinator WS CONNECTED` — the WS **does** connect.
2. `getOrCreate(...)` → `TIMED OUT (attempt 1/3)` … even after
   `reconnect() → WS reconnected` on every retry.
3. Meanwhile the **LAN** `/chats/calls/{id}` polling returns `200 OK` throughout.

Conclusion: it's **not** the WebSocket — it's the `getOrCreate` **REST call to
Stream's cloud** that hangs. iOS **throttles the freshly-woken app's internet
access** in the locked background (LAN stays reachable). Because the manual
accept does that cloud round-trip 5–15s after the push (once throttled), it
times out → no media leg → silence.

That is why §3 moves the coordinator work into the push window. Remaining gap:
*killed app* / *STOMP-down* still hit this cold path; the fully-native
alternative (Stream's PushKit callback consumes the call before any Dart runs)
is the next escalation if the push-window warm also proves throttled.

---

## 8. End-to-end summary table

| # | Stage | File | Component / Action |
|---|---|---|---|
| 1 | VoIP push arrives | `AppDelegate.swift` | Stream PushKit → CallKit shows ring (no Dart) |
| 2 | STOMP invite reaches Dart (bg+alive) | `call_signaling_service.dart` | **warm media leg** via `_prepareIncomingStream` (§3) |
| 3 | User taps Accept | `AppDelegate.swift` | `CXCallObserver.hasConnected` → `incomingCallAnswered` |
| 4 | Dart receives accept | `callkit_event_handler.dart` | `_handleAccept` — recover cid |
| 5 | Early backend POST | `callkit_event_handler.dart` | `notifyBackendAcceptEarly` → caller stops ringing |
| 6 | Seed state | `call_signaling_service.dart` | `handleIncomingFromPush` → `incomingRinging` |
| 7 | Push call page | `callkit_event_handler.dart` | `VoiceCallPage` / `VideoCallPage` |
| 8 | Accept orchestration | `call_signaling_service.dart` | `acceptIncoming`: POST `/accept` + configure audio + `_setActive(connected)` |
| 9 | Media bring-up (locked) | `stream_call_engine.dart` | `join(shouldRing:false)` |
| 10 | Client connect | `stream_call_engine.dart` | `_ensureClient` + retry `connect()` 4× |
| 11 | Resolve call | `stream_call_engine.dart` | **reuse prepared** (fast) or cold `getOrCreate` (throttled) |
| 12 | Media leg | `stream_call_engine.dart` | `call.join()` → SFU |
| 13 | Audio | `stream_call_engine.dart` + `AppDelegate.swift` | manual audio: `setWebRtcAudioEnabled(true)` / `didActivate` |

---

## 9. Log breadcrumbs (locate yourself in a device log)

| Log line | Meaning |
|---|---|
| `CallInviteEvent N arrived while off-screen … WARMING the Stream media leg NOW` | §3 started |
| `prepared incoming call default:erp-call-N (getOrCreate done during ring)` | **cloud succeeded in the push window** ✅ |
| `native CXCallObserver → incomingCallAnswered` | §2 accept bridged |
| `_handleAccept · recovered real cid …` | §4 cid recovery |
| `notifyBackendAcceptEarly → POST …/accept` | §4 early POST (caller stops ringing) |
| `STATE TRANSITION · … → connected` | §5 timer starts (UI only — media may not be up yet) |
| `connect() attempt N/4 → coordinator WS CONNECTED` | §5 client connected |
| `reusing prepared call … skipping getOrCreate` | §5 fast-path reused the warmed call ✅ |
| `getOrCreate TIMED OUT (attempt N/3)` | §7 cold cloud call throttled ❌ |
| `call.join OK on outgoing` | §5 media leg formed |
| `setWebRtcAudioEnabled(true) → sent` / `callkitAudioActivated` | §6 audio enabled |
| `Session activation failed` | §6 AVAudioSession not activatable from bg |

**Success looks like:** breadcrumb 1 → 2 (`prepared incoming call`) → accept →
`reusing prepared call … skipping getOrCreate` → `call.join OK` →
`setWebRtcAudioEnabled(true)` → audio.

**Failure (current) looks like:** accept → cold `getOrCreate TIMED OUT` ×3 →
`getOrCreate never resolved … aborting join` → no media → silence.

---

*Last updated: 2026-07-02 · branch `fix/stream-1.4.1-locked-audio`.*
