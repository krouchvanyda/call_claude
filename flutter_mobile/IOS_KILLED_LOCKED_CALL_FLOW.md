# iOS Incoming Call — Killed App + Locked Screen Flow

> How an incoming call rings on iOS when the app is **fully killed** (or
> backgrounded) and the device is **locked**. This is the reference for
> porting the same behaviour to another project.
>
> Stack: **Stream Video (GetStream.io)** for the call media/signalling +
> native **iOS PushKit (VoIP push) → CallKit** + a Spring backend that
> mints Stream tokens and triggers the call.

---

## 1. The Core Idea (read this first)

A killed/locked iOS app **cannot** ring over a WebSocket — the socket is
dead with the process. The ONLY thing iOS will wake a dead app for is a
**VoIP push (PushKit)**, which iOS hands straight to **CallKit** (the
native full-screen call UI on the lock screen).

So the rule is:

```
App ON SCREEN + UNLOCKED   → ring over the WebSocket (in-app overlay)
App KILLED / BACKGROUNDED / LOCKED → ring over the VoIP push → CallKit
```

The whole design is about making sure that **when the callee is not
genuinely looking at the app, their device is registered with Stream for a
VoIP push and its WebSocket is DOWN** — otherwise Stream rings the warm
(invisible) socket and the user never sees the call.

```
┌─────────┐   1. POST start call    ┌──────────────┐
│ Caller  │ ──────────────────────► │ Spring API   │
│ device  │                         │ 172.26.17.x  │
└─────────┘                         └──────┬───────┘
                                           │ 2. tells Stream to ring callee
                                           ▼
                                    ┌──────────────┐
                                    │ Stream Video │
                                    │ coordinator  │
                                    └──────┬───────┘
                  3. callee is OFFLINE →   │  sends APNs VoIP push
                     so Stream pushes      ▼
                                    ┌──────────────┐
                                    │ Apple APNs   │
                                    └──────┬───────┘
                                           │ 4. VoIP push wakes dead app
                                           ▼
                                    ┌──────────────────────────┐
                                    │ Callee iOS (locked)      │
                                    │ PushKit → CallKit screen │
                                    │ shows "Mr A is calling…" │
                                    └──────────────────────────┘
```

---

## 2. Required iOS Native Setup

### 2.1 Entitlements — `ios/Runner/Runner.entitlements`

```xml
<key>aps-environment</key>
<string>development</string>   <!-- "production" for TestFlight / App Store -->
```

Without this key iOS **never issues a push token**, so Stream's VoIP push
can't reach the app and backgrounded calls never ring. The value
(`development` = APNs sandbox / `production`) MUST match the environment
configured in the **Stream Dashboard's APN provider**.

### 2.2 Background Modes — `ios/Runner/Info.plist`

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
    <string>remote-notification</string>
    <string>fetch</string>
    <string>processing</string>
</array>
```

`voip` is mandatory for PushKit. `audio` keeps the mic alive during a call.

### 2.3 Register PushKit — `ios/Runner/AppDelegate.swift`

```swift
// Register the VoIP PushKit registry so iOS issues a VoIP token and routes
// incoming-call pushes to CallKit. Without this, PushKit never initializes →
// getDevicePushTokenVoIP() stays empty → the device never registers with
// Stream → backgrounded incoming calls never ring.
StreamVideoPKDelegateManager.shared.registerForPushNotifications()
```

### 2.4 Two native probes the Dart side needs

The Dart logic must know **(a)** is the app genuinely foreground and
**(b)** is the device unlocked. Expose both over a `MethodChannel`:

```swift
case "isDeviceUnlocked":
    // true when unlocked, false once the device locks (passcode devices)
    result(UIApplication.shared.isProtectedDataAvailable)

case "isAppForeground":
    // real lifecycle state — NOT the brief ".inactive" blip CallKit causes
    result(isAppForeground)   // tracked via applicationDidBecomeActive / willResignActive
```

> **Why both?** When the user taps **Accept** on the lock-screen CallKit
> sheet, iOS activates the app process, so `isAppForeground` reads `true`
> even though the user **never unlocked**. You can only tell "genuinely on
> screen" from "lock-screen accept" by ALSO checking `isDeviceUnlocked`.
> This single distinction is the root of the killed+locked call bug.

### 2.5 Bridge native CallKit Accept/End → Dart

iOS hooks `CXCallObserver` to watch the native call state and bridges to
Dart over the same `MethodChannel`:

```swift
// Accept on lock screen (app was backgrounded)
if !call.isOutgoing, call.hasConnected, !call.hasEnded, !isAppForeground {
    callkitChannel?.invokeMethod("incomingCallAnswered", arguments: payload) // payload.extra.callCid = Stream call id
}

// End tapped on the native screen
if call.hasEnded, !isAppForeground {
    callkitChannel?.invokeMethod("incomingCallEnded", arguments: payload)
}
```

---

## 3. Backend API — URLs & Endpoints

> **Base URL** (all environments in this project point to the same host):
>
> | Layer | URL |
> |---|---|
> | REST API | `http://172.26.17.118:8080/api/v1` |
> | Realtime (STOMP/WS) | `ws://172.26.17.118:8080/realtime` (and `/ws`) |
>
> Defined in `lib/core/config/environments.dart`. Swap these for your own
> backend host when porting.

### 3.1 Call endpoints — prefix `/chats/calls`

| Method | Endpoint | Purpose |
|---|---|---|
| `GET`  | `/chats/calls/stream-token` | **Mint the Stream JWT** → returns `{ apiKey, token, userId }`. Call this first; needed to build the Stream client and register the device. |
| `POST` | `/chats/conversations/{id}/calls` | **Start a call.** Body: `{ "type": "VOICE" \| "VIDEO" }`. The backend tells Stream to ring the other participants. |
| `POST` | `/chats/calls/{id}/accept` | Accept an incoming call. |
| `POST` | `/chats/calls/{id}/reject?reason=...` | Reject (optional `reason` query param, e.g. `busy`). |
| `POST` | `/chats/calls/{id}/end` | End an active call. |
| `GET`  | `/chats/calls/{id}` | Reconcile call state after a socket dropout. |
| `GET`  | `/chats/calls` | List all calls (paginated history). |
| `GET`  | `/chats/conversations/{id}/calls` | List calls in one conversation. |

### 3.2 Presence endpoints — prefix `/chats/presence`

These are what make the killed/locked routing work: the callee must be
reported **OFFLINE** so Stream chooses the **VoIP push** route instead of
the (dead) WebSocket.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET`  | `/chats/presence` | Full online-status snapshot of all users. |
| `GET`  | `/chats/presence?ids=1,4,7` | Batch-hydrate specific users. |
| `POST` | `/chats/presence/background` | **App backgrounded → mark me OFFLINE now** (so my next call rings via push). |
| `POST` | `/chats/presence/foreground` | App resumed → mark me ONLINE. |

### 3.3 Stream Video direct REST (the killed+locked fix)

When the app drops its Stream WebSocket on background, Stream's SDK
internally calls `unregisterDevice()` which **deletes** the APNs device
server-side — so the next call has no push route. You must **re-register
the device directly** against Stream's coordinator:

```
POST https://video.stream-io-api.com/video/devices?api_key=<STREAM_API_KEY>

Headers:
  Authorization: <STREAM_USER_JWT>
  stream-auth-type: jwt
  Content-Type: application/json

Body:
  {
    "id": "<VoIP push token from FlutterCallkitIncoming.getDevicePushTokenVoIP()>",
    "push_provider": "apn",
    "push_provider_name": "apn",
    "voip_token": true
  }
```

> `push_provider_name` ("apn") must match the **push provider name you
> configured in the Stream Dashboard**.

---

## 4. End-to-End Flow — Killed App + Locked Screen

### 4.1 First incoming call (cold, killed app)

1. **Caller** → `POST /chats/conversations/{id}/calls` `{type: VOICE}`.
2. Backend asks **Stream** to ring the callee.
3. Callee is **OFFLINE** (no live socket — app is dead) → Stream sends an
   **APNs VoIP push**.
4. **Apple APNs** delivers the VoIP push → iOS **wakes the dead app into a
   background process** and hands the push to **PushKit**.
5. PushKit → **CallKit** renders the native incoming-call screen **on the
   lock screen** showing the caller's name.
6. User taps **Accept** on the lock screen:
   - `CXCallObserver` sees `hasConnected` → bridges `incomingCallAnswered`
     to Dart with the Stream `callCid`.
   - Dart `_handleAccept` runs `_ensureClient()` → connects the Stream WS
     **on demand, just for this call**, and joins the Stream call → audio
     flows.
7. User taps **End** → `CXCallObserver` `hasEnded` → `incomingCallEnded` →
   Dart ends the Stream call → media leg closes.

### 4.2 The hard part — the **second** call after the first ends

After step 7 the device is **still locked/backgrounded**, but the accept in
step 6 left the **Stream WebSocket UP**. If nothing changes, the 2nd call
rings over that warm-but-invisible socket and **the user never sees it**.

Three fixes make the 2nd call ring correctly:

#### Fix A — Lock-aware warmUp gate

Never bring the Stream WS up unless the app is **foreground AND unlocked**:

```dart
Future<void> warmUp() async {
  if (Platform.isIOS && !(await _appForeground() && await _deviceUnlocked())) {
    // backgrounded or locked → STAY offline so the next call rings via VoIP push.
    // (Accept still connects on demand via _ensureClient.)
    return;
  }
  await _ensureClient();
}
```

#### Fix B — Go offline-for-push after every call ends

```dart
Future<void> goOfflineForPushIfBackground() async {
  final fg = await _appForeground();
  final unlocked = await _deviceUnlocked();
  if (fg && unlocked) return; // genuinely on screen → keep WS warm for in-app overlay
  // backgrounded/locked → drop everything so the NEXT call rings via APNs
  unawaited(transport.pause());                                 // drop STOMP
  unawaited(streamEngine.disconnectForBackground(force: true)); // drop Stream WS
  unawaited(remote.reportBackground());                         // POST /chats/presence/background
}
```

Called from every call-end path (end / reject / peer-hangup / ring-timeout).

#### Fix C — Re-register the APNs device after the WS drops

Because `disconnect()` deleted the device server-side, immediately re-create
it via the direct Stream REST call in §3.3 (`POST /video/devices`). The
`apiKey` + `token` are cached at client-build time so this needs no extra
backend round-trip and no live WS.

### 4.3 Caller name on the ring (not the numeric id)

On a cold start the Stream client can be built before the user's display
name is cached → the VoIP push shows the caller's **id** ("9") instead of
**"Mr A"**. Fix: track the name the client was built with, and **rebuild
the client** once the real name is available:

```dart
final haveRealName = displayName.isNotEmpty && displayName != userId;
final builtWithRealName = _clientUserName != null && _clientUserName != userId;
// reuse the client UNLESS it was built name-less and we now have a real name
if (builtWithRealName || !haveRealName) return;
// else: disconnect + rebuild StreamVideo(user: User.regular(name: displayName))
```

---

## 5. Gotchas / Edge Cases Already Solved Here

- **Minimize ≠ decline.** On a minimize the call can arrive over BOTH the
  STOMP invite (in-app `incomingRinging`) AND the native CallKit push.
  Dismissing the native screen fires `actionCallEnded`; turning that into a
  reject would auto-decline a call the user never touched. Guard with a
  "did *we* just dismiss the native CallKit in the last ~4s?" flag
  (`recentlyDismissedNativeCallkit()`).
- **Busy / 2nd caller.** A reject can carry `reason: 'busy'`; surface it on
  the caller side ("X is on another call").
- **`isAppForeground` lies on a lock-screen accept.** Always pair it with
  `isDeviceUnlocked` — this is the single most important detail.
- **Default both native probes to the *safe* value on channel error:**
  `isDeviceUnlocked` → `false` ("treat as locked → stay offline → next call
  rings via push"). Failing safe means the worst case is "rings via push"
  not "never rings".
- **`aps-environment` must match the Stream Dashboard APN provider env**
  (sandbox vs production) or no push is ever delivered.

---

## 6. Porting Checklist (for the other project)

- [ ] Add `aps-environment` to `Runner.entitlements` (sandbox for dev).
- [ ] Add `voip` + `audio` + `remote-notification` to `UIBackgroundModes`.
- [ ] Enable **Push Notifications** + **Background Modes (Voice over IP)**
      capabilities in Xcode; upload the **APNs key** to the Stream Dashboard.
- [ ] Register PushKit in `AppDelegate` and expose `isDeviceUnlocked` +
      `isAppForeground` over a `MethodChannel`.
- [ ] Bridge native CallKit Accept/End → Dart.
- [ ] Backend: implement `GET /…/stream-token`, the call endpoints, and the
      `/presence/background` + `/presence/foreground` reports.
- [ ] Dart: gate `warmUp` on foreground+unlocked; call
      `goOfflineForPushIfBackground()` after every call end; re-register the
      APNs device via `POST https://video.stream-io-api.com/video/devices`
      after each background disconnect.
- [ ] Rebuild the Stream client when the caller's real display name becomes
      available (so the ring shows the name, not the id).

---

## 7. Key Source Files (this project, for reference)

| File | What's in it |
|---|---|
| `ios/Runner/Runner.entitlements` | `aps-environment` |
| `ios/Runner/Info.plist` | `UIBackgroundModes` |
| `ios/Runner/AppDelegate.swift` | PushKit register, `isDeviceUnlocked` / `isAppForeground`, CXCallObserver bridge |
| `lib/core/config/environments.dart` | Base URLs |
| `lib/features/chat/data/chats_remote_data_source.dart` | All `/chats/calls/*` + `/chats/presence/*` endpoints |
| `lib/features/chat/data/stream_call_engine.dart` | `warmUp` gate, `_deviceUnlocked`, APNs re-register, client name rebuild |
| `lib/features/chat/data/call_signaling_service.dart` | `goOfflineForPushIfBackground`, dismiss tracker |
| `lib/features/chat/data/callkit_event_handler.dart` | native Accept/End → `_handleAccept` / `_handleNativeCallEnded` |
