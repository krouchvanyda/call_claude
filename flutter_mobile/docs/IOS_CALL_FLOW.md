# iOS Call Flow (CallKit + Stream VoIP Push)

How voice/video calls work on **iOS**, end to end — registration, incoming
push, and the Accept / Reject / Hang-up handling. Companion docs:
[`STREAM_VIDEO_CALL_SETUP.md`](./STREAM_VIDEO_CALL_SETUP.md),
[`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md).

> ## 🔒 Golden rule
> **Android calls already work. Every iOS call fix must be iOS-only and must
> not change Android behaviour.** In shared Dart call code:
> - Guard iOS-specific logic with `Platform.isIOS`.
> - Make key/field lookups **additive** — Android's keys keep priority; add
>   the iOS (CallKit-native) keys only as fallbacks.
> - Prefer iOS-only files (`AppDelegate.swift`, entitlements, `Info.plist`).

---

## 1. The two transports

A call has **two** independent channels. Understanding which one is live is
the key to the whole flow:

| Channel | Used when | Carries |
|---|---|---|
| **Stream WebSocket** (in `StreamCallEngine`) | app is **foreground** | live ring/accept/end events → in-app overlay |
| **VoIP push (PushKit → CallKit)** | app is **backgrounded / killed** | wakes the app, shows the native CallKit ring |

When the app backgrounds, `StreamCallEngine.disconnectForBackground()`
**drops the WebSocket on purpose** so Stream falls back to sending a VoIP
push. So a backgrounded incoming call arrives via CallKit, **not** the WS.

---

## 2. Key files

| File | Role |
|---|---|
| [`ios/Runner/AppDelegate.swift`](../ios/Runner/AppDelegate.swift) | Registers the VoIP `PKPushRegistry` (`registerForPushNotifications()`) |
| [`ios/Runner/Runner.entitlements`](../ios/Runner/Runner.entitlements) | `aps-environment` — required for any push token |
| [`stream_call_engine.dart`](../lib/features/chat/data/stream_call_engine.dart) | Stream client, device registration, `[PushDiag]` logs |
| [`call_signaling_service.dart`](../lib/features/chat/data/call_signaling_service.dart) | App-level call state machine (`ActiveCall`, accept/reject/hangup) |
| [`callkit_event_handler.dart`](../lib/features/chat/data/callkit_event_handler.dart) | Bridges CallKit button taps → signaling/engine |
| [`callkit_call_id.dart`](../lib/features/chat/data/callkit_call_id.dart) | Maps Stream cid → deterministic UUID for CallKit (iOS) |
| [`firebase_notification_provider.dart`](../lib/shared/firebase_services/firebase_notification_provider.dart) | FCM background handler (chat + Android call push) |

---

## 3. Setup / registration flow (app start → ready to receive calls)

```
AppDelegate.didFinishLaunching
  └─ StreamVideoPKDelegateManager.shared.registerForPushNotifications()   ← MUST be called
        └─ PKPushRegistry(desiredPushTypes: [.voIP])

User logs in → StreamCallEngine builds client with
  pushNotificationManagerProvider = StreamVideoPushNotificationManager.create(
      iosPushProvider: apn(name: 'apn'))          ← iOS
      androidPushProvider: firebase(name:'firebase')) ← Android
  └─ client.connect()  (registerPushDevice: true)
        └─ registerDevice():
             • PushKit delivers VoIP token → didUpdatePushCredentials
                 → setDevicePushTokenVoIP() (stored in flutter_callkit_incoming)
             • Dart reads it via FlutterCallkitIncoming.getDevicePushTokenVoIP()
             • client.createDevice(token, voipToken:true, provider:'apn')
        └─ Stream now knows this device → can send it call pushes
```

**Critical dependency chain (each link is required):**
`aps-environment` entitlement → iOS issues APNs/VoIP token →
`registerForPushNotifications()` sets up PushKit → VoIP token delivered →
`createDevice` registers it with Stream → Stream can push a call.

> If `registerForPushNotifications()` is never called, PushKit never
> initializes, the VoIP token stays empty, no device registers, and
> **backgrounded calls never ring.** (This was the main bug — fixed in
> `AppDelegate.swift`.)

---

## 4. Incoming call — foreground

```
Stream backend rings → WebSocket event → StreamCallEngine.incomingCall
  → CallSignalingService: state = incomingRinging
  → IncomingCallOverlay shows in-app accept/reject
  → accept → join Stream call → state = connected
```
No CallKit, no push involved.

## 5. Incoming call — backgrounded / killed

```
Stream backend → VoIP push (APNs) → PushKit wakes app
  → StreamVideoPKDelegateManager.didReceiveIncomingPushWith
  → handleIncomingCall → flutter_callkit_incoming shows native CallKit ring
  → user taps Accept / Decline on the system call screen
  → CallKit fires an Event → callkit_event_handler.dart
```

---

## 6. CallKit event handling

`callkit_event_handler.dart` listens to `FlutterCallkitIncoming.onEvent`:

| CallKit event | Handler | Action |
|---|---|---|
| `actionCallAccept` | `_handleAccept` | join Stream call → connected |
| `actionCallDecline` | `_handleDecline` | `rejectByCid` + backend reject |
| `actionCallEnded` / `actionCallTimeout` | `_handleHangup` | hang up / reject |

### ⚠️ Gotcha A — field names differ by transport
The CallKit entry built by **Stream's native VoIP handler** uses
CallKit-native keys; our **FCM/Android** path uses snake_case. Handlers must
read **both** (Android key first → additive, no Android impact):

| Meaning | Android / FCM key | iOS VoIP-push key |
|---|---|---|
| Stream call id | `call_cid` | `callCid` (in `extra`) |
| caller id | `caller_id` | `handle` |
| caller name | `caller_name` | `nameCaller` |
| (CallKit's own UUID, **not** a Stream cid) | — | `id` / `uuid` |

If you read only the snake_case keys on an iOS VoIP push, the cid becomes the
CallKit UUID and the caller is empty → accept/reject target the wrong call.

### ⚠️ Gotcha B — never call `setCallConnected` for PushKit calls
`flutter_callkit_incoming`'s native `connectedCall` force-unwraps
`self.data!` on the `isFromPushKit` path; it's nil in the synthesized-accept
flow → **EXC_BAD_ACCESS, the app closes on Accept.** Do not call it.

### ⚠️ Gotcha C — spurious `actionCallEnded` after Accept
Because we can't call `setCallConnected`, iOS CallKit fires a stray
`actionCallEnded` ~1s after Accept. Untreated, `_handleHangup` turns it into
`signaling.hangup()` → **closes the caller's call.** Fix: `_handleAccept`
records the accept time per cid (`_acceptedAt`, iOS-only); `_handleHangup`
**ignores** an end that lands within `_acceptHandoffWindow` (6s) of accept.
A real End tap arrives later and hangs up normally.
*Side effect:* the system CallKit screen may auto-dismiss shortly after
accept, but the call continues via Stream + the in-app `VoiceCallPage`.

---

## 7. Config requirements (server / account)

Backgrounded iOS calls need ALL of:
1. **Paid Apple Developer account** (free/Personal teams can't use Push
   Notifications).
2. **`aps-environment` entitlement** present + signed (Push Notifications
   capability on the App ID).
3. **Stream Dashboard → Push Notifications → APN provider named `apn`** with
   the `.p8` key, Key ID, Team ID `664K6U434T`, bundle `com.enterprise.erpMobile`.
4. **Environment match:** a dev build → sandbox APNs token → the Stream `apn`
   provider must be set to **Sandbox**. (Mismatch = silent drop, no ring.)

> The Firebase APNs key powers **FCM only** (chat banners / Android). The iOS
> **call** ring is pushed by the **Stream `apn` provider**, not Firebase.

---

## 8. Diagnostics — `[PushDiag]`

`StreamCallEngine._logPushDiagnostics()` (iOS-only, after connect) prints:

```
[PushDiag] ✅ APN TOKEN OK (len=64)              ← entitlement works
[PushDiag] ✅ VoIP token present (len=64)        ← PushKit registered
[PushDiag/+10s] Stream devices: 1 · apn provider present: ✅ YES   ← Stream can push
```

| Symptom | Meaning |
|---|---|
| `❌ APN NOT WORKING` (null) | entitlement / provisioning / account issue |
| `⏳ VoIP token EMPTY` | `registerForPushNotifications()` not called / no PushKit |
| `0 devices` after +10s with VoIP token present | Stream `apn` provider missing / `createDevice` failing |

---

## 9. Known limitations on the current test setup
- Testing is on **iPads** (CallKit/VoIP do work on iPad).
- Dev builds use **sandbox** APNs — Stream provider must match.
- Without `setCallConnected`, the system CallKit UI may dismiss right after
  accept; the in-app call screen owns the call from then on.
