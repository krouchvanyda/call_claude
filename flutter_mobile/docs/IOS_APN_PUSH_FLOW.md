# iOS APN / VoIP Push Flow — Config → Connected → Smooth Calls

> How an incoming call reaches a backgrounded/killed iPhone, the exact chain
> from **configuration** to a **connected, registered** device, and the tricks
> that make the call ceremony feel smooth. iOS-specific. Android uses FCM and
> is intentionally untouched by everything here.
>
> Related: [`IOS_CALL_FLOW.md`](./IOS_CALL_FLOW.md),
> [`STREAM_VIDEO_CALL_SETUP.md`](./STREAM_VIDEO_CALL_SETUP.md),
> [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md).

---

## 0. TL;DR

On iOS the incoming-call **ring is delivered by Stream's `apn` (PushKit VoIP)
provider**, *not* Firebase. For that to work, three layers must all be correct:

1. **App config** — entitlements (`aps-environment`), background modes
   (`voip`, `audio`, `remote-notification`), PushKit registration.
2. **Device registration** — the app must obtain a **PushKit VoIP token** and
   register it with Stream as an `apn` device (env-matched cert in the Stream
   dashboard).
3. **Server ring** — the backend calls Stream `ring: true` for **offline**
   callees, which makes Stream emit the VoIP push → native CallKit screen.

If the `apn` device never registers (Simulator, missing token, cert env
mismatch), a minimized/killed callee will never ring — no client code can fix
that.

```
Config (entitlements + plist + PushKit)
        │
        ▼
Launch → StreamVideoPKDelegateManager.registerForPushNotifications()   (AppDelegate.swift)
        │  iOS issues a PushKit VoIP token (async)
        ▼
Build StreamVideo(pushNotificationManagerProvider: apn+firebase)        (stream_call_engine.dart)
        │  connect() → SDK registers devices with Stream
        ▼
_ensureApnDeviceRegistered() retries registerDevice() until `apn` appears
        │
        ▼
PushDiag confirms: "Stream devices: N · apn provider present: ✅ YES"  ← CONNECTED & READY
```

---

## 0.1 Visual flow — boxes

### A. Config → Connected (device registers with Stream)

```
 ┌──────────────────────────┐      ┌──────────────────────────┐
 │ Xcode capabilities        │      │ Stream Dashboard          │
 │ • Push Notifications       │      │ • APN provider "apn"      │
 │ • Background: VoIP/Audio   │      │   + cert (sandbox/prod)   │
 └────────────┬─────────────┘      │ • Firebase provider       │
              │ entitlements +      └────────────┬─────────────┘
              │ Info.plist                        │ must match
              ▼                                   │ aps-environment
 ┌─────────────────────────────────────────────────────────────┐
 │ iPhone (D)                                                   │
 │ ┌─────────────────────────────────────────────────────────┐ │
 │ │ AppDelegate.swift                                        │ │
 │ │  registerForPushNotifications()  ──► iOS issues          │ │
 │ │                                     VoIP (PushKit) token │ │
 │ │                                     + APNs token (async) │ │
 │ └───────────────────────────┬─────────────────────────────┘ │
 │                            ▼                                  │
 │ ┌─────────────────────────────────────────────────────────┐ │
 │ │ StreamCallEngine._ensureClient()                         │ │
 │ │  GET /chats/calls/stream-token                           │ │
 │ │  StreamVideo(pushNotificationManagerProvider:            │ │
 │ │              apn='apn' + firebase='firebase')            │ │
 │ │  connect() ──► SDK registers device(s) with Stream       │ │
 │ └───────────────────────────┬─────────────────────────────┘ │
 │                            ▼                                  │
 │ ┌─────────────────────────────────────────────────────────┐ │
 │ │ _ensureApnDeviceRegistered()  (retry ~15s)               │ │
 │ │  while no `apn` device → registerDevice()                │ │
 │ │  ✅ "apn provider present: ✅ YES"  ← READY for call push │ │
 │ └─────────────────────────────────────────────────────────┘ │
 └─────────────────────────────────────────────────────────────┘
```

### B. Incoming call: Caller → Backend → Stream → APNs → CallKit

```
 ┌──────────────────────┐  POST   ┌──────────────────────────┐
 │  Caller C (Flutter)  ├────────►│  ERP Backend (Spring)    │
 │  startOutgoing()     │ /calls  │  ChatCallService.start   │
 └──────────────────────┘         └────────────┬─────────────┘
                                                │ PRESENCE GATE
                                                │ ring OFFLINE callees only
                                                ▼
                                  ┌──────────────────────────┐
                                  │ StreamVideoService.ring   │
                                  │   → Stream REST ring:true  │
                                  └────────────┬─────────────┘
                                                ▼
                                  ┌──────────────────────────┐
                                  │  Stream Coordinator       │
                                  └────────────┬─────────────┘
                                APNS VoIP (iOS)  │  FCM (Android)
                                                ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ Callee D — iPhone (killed / minimized)                       │
 │ ┌─────────────────────────────────────────────────────────┐ │
 │ │ PushKit → stream_video_push_notification                 │ │
 │ │         → flutter_callkit_incoming                       │ │
 │ │         → NATIVE CallKit screen  (Decline / Accept)      │ │
 │ └───────────────────────────┬─────────────────────────────┘ │
 │                            ▼                                  │
 │ ┌─────────────────────────────────────────────────────────┐ │
 │ │ Dart engine (cold-started by the push)                   │ │
 │ │   CallkitEventHandler ◄── Event.actionCallIncoming       │ │
 │ │   → keep native ring + warmUp() + watchBackgroundRing…   │ │
 │ └─────────────────────────────────────────────────────────┘ │
 └─────────────────────────────────────────────────────────────┘
```

### C. Device-internal routing: Accept / Decline / End / Caller-cancel

```
 ┌─────────────────────────────────────────────────────────────────┐
 │ Callee D — Flutter app (CallkitEventHandler)                     │
 │                                                                 │
 │  ACCEPT (foreground)     Event.actionCallAccept                 │
 │  ───────────►            → _handleAccept → POST /accept + join  │
 │                                                                 │
 │  ACCEPT (lock/killed)    native CXCallObserver hasConnected     │
 │  ───────────►            → incomingCallAnswered → _handleAccept │
 │                                                                 │
 │  DECLINE (event)         Event.actionCallDecline                │
 │  ───────────►            → _handleDecline → POST /reject        │
 │                           (no DI? → _directRejectNoDi)          │
 │                                                                 │
 │  DECLINE (lock/killed)   native CXCallObserver hasEnded         │
 │  ───────────►            → incomingCallEnded                    │
 │                           → _handleNativeCallEnded              │
 │                           (no active? → _directRejectNoDi POST) │
 │                                                                 │
 │  END ongoing call        Event.actionCallEnded                  │
 │  ───────────►            → _handleHangup → POST /end (or reject)│
 │                                                                 │
 │  CALLER CANCELLED        (no event reaches a minimized D)       │
 │  ───────────►            watchBackgroundRingForCancel() poll    │
 │                           + warmUp() → Stream call.ended        │
 │                           → _clearNativeIncoming                │
 │                             (reportCall(endedAt:) dismiss)      │
 └─────────────────────────────────────────────────────────────────┘
```

> The native `CXCallObserver` bridge exists because a backgrounded/killed Dart
> isolate often can't receive the `flutter_callkit_incoming` events directly —
> so iOS's own call observer is the reliable backstop for accept/end.

---

## 1. Configuration layer (one-time, must be right)

### 1.1 Xcode capabilities
- **Push Notifications** capability → creates the APNs entitlement.
- **Background Modes** → check **Voice over IP**, **Audio, AirPlay…**, and
  **Remote notifications**.

### 1.2 `ios/Runner/Runner.entitlements`
```xml
<key>aps-environment</key>
<string>development</string>   <!-- sandbox for Xcode/dev builds -->
```
- `development` = APNs **sandbox** → for builds run from Xcode onto a device.
- `production` = for TestFlight / App Store.
- **The Stream Dashboard APN provider environment MUST match this** (sandbox
  cert for dev builds, production cert for TestFlight). A mismatch is the #1
  cause of "registered but never rings."
- Without this key iOS never issues a push token at all.

### 1.3 `ios/Runner/Info.plist` → `UIBackgroundModes`
```
audio                 ← keep the mic/audio leg alive when backgrounded mid-call
voip                  ← let PushKit wake a killed app for an incoming call
remote-notification   ← data pushes (FCM fallbacks)
fetch / processing    ← misc background work
```

### 1.4 `ios/Runner/AppDelegate.swift`
```swift
StreamVideoPKDelegateManager.shared.registerForPushNotifications()
```
Registers the PushKit registry so iOS issues a VoIP token and routes
incoming-call pushes to CallKit. **Without this the VoIP token stays empty →
the device never registers with Stream → backgrounded calls never ring.**

It also installs:
- a **`CXCallObserver`** (native accept/end bridge — see §5), and
- the **`erp/ios_callkit`** method channel (`isDeviceUnlocked`,
  `isAppForeground`, `dismissIncoming`).

### 1.5 Stream Dashboard (server-side, one-time)
- Push Notifications → add an **APN** provider named **exactly `apn`**
  (matches `StreamVideoPushProvider.apn(name: 'apn')` in code).
- Upload the **APNs auth key / cert** for the matching **environment**.
- Add a **Firebase** provider named `firebase` for Android.

### 1.6 Firebase (only for the FCM data-push fallbacks)
- Backend needs `FCM_ENABLED=true` + `FCM_SERVICE_ACCOUNT_JSON_PATH`.
- For iOS FCM delivery, upload the **APNs auth key to Firebase** (Cloud
  Messaging → Apple app config). Note: the *primary* iOS ring is Stream `apn`,
  not FCM — FCM is the dismiss/cancel backstop.

---

## 2. Token acquisition (runtime, async)

Two independent tokens, both needed:

| Token | Source | Proves | Diag line |
|---|---|---|---|
| APNs token | `FirebaseMessaging.getAPNSToken()` | entitlement/provisioning works | `[PushDiag] ✅ APN TOKEN OK` |
| VoIP (PushKit) token | `FlutterCallkitIncoming.getDevicePushTokenVoIP()` | PushKit registered; the token Stream registers for *call* push | `[PushDiag] ✅ VoIP token present` |

The VoIP token arrives **asynchronously** after launch, so it is often *not*
ready the instant the Stream client first connects — hence the retry in §3.

`_logPushDiagnostics()` in `stream_call_engine.dart` logs both on iOS connect.

---

## 3. Device registration with Stream (Config → Connected)

`StreamCallEngine._ensureClient()` (`stream_call_engine.dart`) builds the
client with the push provider wired in:

```dart
_client = StreamVideo(
  apiKey,
  user: User.regular(userId: ..., name: ..., image: ...),
  userToken: token,                                  // GET /chats/calls/stream-token
  pushNotificationManagerProvider:
      StreamVideoPushNotificationManager.create(
    iosPushProvider: const StreamVideoPushProvider.apn(name: 'apn'),
    androidPushProvider: const StreamVideoPushProvider.firebase(name: 'firebase'),
  ),
);
await _client!.connect();        // SDK registers the device(s) on connect
```

Because the VoIP token may be late, the SDK's one-shot registration can miss
the `apn` device. We close that race with **`_ensureApnDeviceRegistered()`**:

```
poll getDevices() up to ~15 s; while no `apn` device:
    pushNotificationManager.registerDevice()   // VoIP token more likely ready now
```

**Healthy "connected & ready" log:**
```
[PushDiag] ✅ APN TOKEN OK — iOS APNs token present (len=64).
[PushDiag] ✅ VoIP token present (len=64).
[PushDiag/at-connect] Stream devices: 2 · apn provider present: ✅ YES
[PushDiag/at-connect]   • provider=apn      voip=true  token=429fcbd5bcf3…
[PushDiag/at-connect]   • provider=firebase voip=true  token=eQ2rMi6xQQyf…
[PushDiag/apn-retry] apn provider registered after 1 check(s) — ring route is ready
```

> **`[PushDiag/+10s] ⓘ skipped — Stream client not connected`** is **normal**,
> not an error: the `+10s` re-check fires after the call ended and
> `disconnectForBackground` dropped the client. The registered devices are
> unchanged on the server. (A real failure logs `❌ getDevices() returned no
> data (API error while connected)`.)

---

## 4. End-to-end incoming-call ring (Connected → Ringing)

```
Caller C: POST /chats/conversations/{id}/calls
        │
Backend (ChatCallService.start):
   • create ChatCall (RINGING) + participants
   • PRESENCE GATE: ring via Stream ONLY for callees whose presence == OFFLINE
     (no live STOMP session). Online callees get the STOMP invite + in-app
     overlay instead — sending them a VoIP push too caused a duplicate native
     header + a contested audio session.
   • StreamVideoService.ring(cid, callerId, members)  → Stream REST ring:true
        │
Stream coordinator → APNs VoIP push → callee D's PushKit
        │
D (killed/minimized): stream_video_push_notification reports the call to CallKit
   via flutter_callkit_incoming → native incoming-call screen ("Erp Mobile
   Audio… / 11", Decline / Accept).
        │
D's Dart engine (cold-started by the push) → CallkitEventHandler receives
   Event.actionCallIncoming.
```

**Why the presence gate matters:** it is the backend's job, and it's what keeps
a *foreground* call from showing a native header AND fighting WebRTC for the
audio session. See memory note "Call ring presence gate".

---

## 5. Accept / Decline / Cancel (Ringing → terminal)

Because a backgrounded/killed Dart isolate can't always receive the
flutter_callkit_incoming events, the **native `CXCallObserver`** in
`AppDelegate.swift` is the backstop and bridges to Dart:

| User action (native screen) | Native signal | Dart handler |
|---|---|---|
| Accept (lock/minimized/killed) | `CXCall.hasConnected` → `incomingCallAnswered` | `_handleAccept` → POST `/accept` + Stream join |
| End/Decline while not foreground | `CXCall.hasEnded` → `incomingCallEnded` | `_handleNativeCallEnded` → POST `/reject` or `/end` |
| Decline (event path) | `actionCallDecline` | `_handleDecline` |
| End (event path) | `actionCallEnded` | `_handleHangup` |

All three end paths (`_handleDecline`, `_handleNativeCallEnded`,
`_handleHangup`) relay the reject to the backend so the **caller stops
ringing** — including a **DI-less direct POST** (`_directRejectNoDi`) for the
killed-app cold-start where dependency injection isn't ready yet.

**Caller cancels** → `POST /chats/calls/{id}/end` →
`ChatCallService.endCallInternal` → `StreamVideoService.endCall` (Stream
`mark_ended`) + broadcast `call.hangup` + FCM `call.cancel`. On the callee that
dismisses the native ring (see §6).

---

## 6. What makes the call "smooth" (the optimizations)

These are the pieces that turn a working-but-janky ceremony into a fast, clean
one. Each is iOS-gated and additive.

### 6.1 Pre-warm the media path while ringing
`startOutgoing` and the incoming path call **`streamEngine.warmUp()`** and
**`_prepareIncomingStream()`** *during* the ring, so the Stream client connect
+ coordinator `getOrCreate` are already done before Accept. On accept only the
final SFU media connect remains → audio starts fast instead of cold-starting
the whole stack after the tap.

### 6.2 Caller joins with `shouldRing: false` (iOS)
The **backend** does the ring (server-side, presence-gated). The caller's
client joins `ring:false` and then clears the SDK's outgoing-call slot, so a
callee's accept can't cancel the caller's own join ("connect cancelled").

### 6.3 Foreground CallKit suppression
When the app is genuinely on screen, the in-app overlay should own the ring —
not a native header. `_suppressForegroundCallkit` + the native `CXCallObserver`
dismiss the native screen **only when `isAppForeground == true`**; a
killed/locked/minimized launch keeps the native screen (the only UI there).
The dismiss uses `reportCall(endedAt:)` — a `CXEndCallAction` does **not**
tear down a PushKit-reported incoming call.

### 6.4 Audio session handoff
On `actionCallToggleAudioSession {isActivate:true}` the engine restarts
WebRTC's audio unit on CallKit's now-live `AVAudioSession`
(`onCallKitAudioSessionActivated`). Without this a minimized/killed accept
connects but is **silent**. A back-to-back call's late `didDeactivate` is
detected and re-asserted so call #2 isn't muted.

### 6.5 Drop the WS on background → ring via push
`disconnectForBackground` drops the Stream WebSocket when the app backgrounds
(no active call), forcing Stream to use the APNs VoIP route — the only thing
that can raise a native screen on a backgrounded app.

### 6.6 Re-drop the WS at terminal teardown (2nd-call fix)
When a call ends **while still backgrounded**, there's no fresh `paused` event
to drop the WS again, so the next call would ring over the warm WS (invisible).
`_setActive` re-drops the WS (`disconnectForBackground(force:true)`) on the
terminal transition so call #2 rings via APNs.

### 6.7 Caller-stuck-"Calling…" heartbeat
If the caller never receives the `call.accept` signal, a ring heartbeat polls
`reconcileActive()` (backend `ANSWERED` → local `connected`) so the caller
connects instead of hanging on "Calling…".

### 6.8 Caller-cancel reaches a minimized callee
Three layers, because a minimized callee has **no live channel** (STOMP + Stream
WS down):
- **Backend** `mark_ended` → Stream cancels the ring for all members
  (delivered over the same `apn` route, when registered).
- **Callee** `watchBackgroundRingForCancel(callId)` — a deterministic REST
  poll of `GET /chats/calls/{id}` while the ring is up; dismisses the native
  ring on terminal status. Works even without `apn`/FCM, as long as the app is
  alive.
- **Callee** `warmUp()` on the ring so the Stream `call.ended` event can also
  dismiss it event-driven.

### 6.9 Killed-app decline relays to the caller
`_handleNativeCallEnded` / `_handleHangup` / `_handleDecline` fall back to
`_directRejectNoDi` (reads the token straight from secure storage, POSTs
`/reject`) when DI isn't ready on a cold-started engine — so the caller stops
ringing even on a killed-app decline. (Android has its native `erp_callkit`
reject receiver for this.)

---

## 7. How to read the diagnostics

| Log | Meaning |
|---|---|
| `[PushDiag] ✅ APN TOKEN OK` | entitlement/provisioning OK |
| `[PushDiag] ⏳ VoIP token EMPTY` | PushKit not delivered yet (or Simulator) — no `apn` device can register |
| `apn provider present: ✅ YES` | **device is registered & ready** for call push |
| `apn provider present: ❌ NO` | Stream can't push the ring — check Simulator / token / cert env |
| `⚠ apn provider STILL missing after retries` | NOT a timing race → cert/env mismatch in the Stream dashboard |
| `ⓘ skipped — Stream client not connected` | harmless post-call re-check; devices unchanged |
| `watchBackgroundRingForCancel(N) — polling` | callee is polling for a caller-cancel while minimized |
| `_directRejectNoDi · POST /reject OK` | killed-app decline relayed to the caller |

**Capturing killed-app logs:** the app is relaunched by the push *outside* a
`flutter run` session, so use **Console.app** (connect device → select it →
filter `CallkitEventHandler` / `PushDiag`), or
`idevicesyslog | grep -iE "callkit|pushdiag"`.

---

## 8. Failure-mode checklist

| Symptom | Likely cause | Fix |
|---|---|---|
| Minimized/killed callee never rings | no `apn` device | real device (not Simulator) + VoIP token + matching Stream cert env |
| Rings but caller-cancel doesn't dismiss | callee offline + no push route | `mark_ended` + apn, or the REST poll (§6.8) |
| Killed-app decline → caller keeps ringing | reject never POSTed (DI not ready) | `_directRejectNoDi` fallback (§6.9) |
| Connected but silent | audio session not handed off | `onCallKitAudioSessionActivated` (§6.4) |
| 2nd call to minimized callee no ring | warm Stream WS | re-drop WS at terminal teardown (§6.6) |
| `[fcm] skip send — service not ready` | backend FCM disabled | `FCM_ENABLED=true` + `FCM_SERVICE_ACCOUNT_JSON_PATH` |
| Duplicate native header on a foreground call | rang an online callee | backend presence gate (§4) |

---

## 9. Key files

| File | Role |
|---|---|
| `ios/Runner/Runner.entitlements` | `aps-environment` (sandbox/prod) |
| `ios/Runner/Info.plist` | `UIBackgroundModes` (voip/audio/remote-notification) |
| `ios/Runner/AppDelegate.swift` | PushKit registration, `CXCallObserver`, `erp/ios_callkit` channel |
| `lib/features/chat/data/stream_call_engine.dart` | client build + push provider, token diag, apn-retry, warm-up, WS lifecycle |
| `lib/features/chat/data/call_signaling_service.dart` | call ceremony, foreground suppression, ring poll, heartbeats, terminal WS re-drop |
| `lib/features/chat/data/callkit_event_handler.dart` | CallKit event/native-bridge → accept/decline/hangup, DI-less reject |
| `lib/shared/firebase_services/firebase_notification_provider.dart` | FCM fallbacks (`call.invite` / `call.cancel`), `_showStreamCallkitRinger` |
| backend `StreamVideoService` | `ring()` + `endCall()` (mark_ended) |
| backend `ChatCallService` / `ChatCallController` | call state machine, presence gate, FCM cancel |
