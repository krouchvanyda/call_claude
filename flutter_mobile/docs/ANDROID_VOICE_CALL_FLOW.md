# Android Voice Call — Step-by-Step Learning Guide

> A teaching walkthrough of how a **voice call** works in this app on **Android**,
> from the moment a screen is shown to the moment the call ends.
> The companion to [`IOS_VOICE_CALL_FLOW.md`](./IOS_VOICE_CALL_FLOW.md) — read
> that one too, because **the signaling, the state machine, the REST/STOMP wire,
> the media engine and the in-call UI are 100% shared**. This doc explains the
> Android-specific layer: the **wake-up path** (FCM + a custom native package
> instead of PushKit/CallKit) and the handful of behavioural differences.

---

## 0. The mental model (same three legs, one different leg)

A call is still **three concerns**:

| Leg | Job | Android tech | (iOS was…) |
|-----|-----|------|------------|
| **Signal** | "ring / accept / hang up" | Laravel **STOMP + REST** | *same* |
| **Media** | the actual audio | **Stream Video** / WebRTC | *same* |
| **Wake-up** | make a backgrounded/killed phone ring | **FCM data push → custom `erp_callkit` native notification** | *PushKit → CallKit* |

> 🔑 **The one big idea for Android:** the wake-up leg is **ours**. On iOS,
> Apple's CallKit/PushKit shows the lock-screen ring. Android has no such
> system call UI you can trigger from a server, so this project ships its own
> tiny native package — **`erp_callkit`** — that renders a full-screen
> "CallStyle" notification with Accept / Reject, and can even **reject a call
> in pure Kotlin while the app is dead**. That package is the heart of this doc.

Everything in legs 1 and 2 is identical to iOS, so this guide spends its time
on leg 3.

---

## 1. The cast of characters (Android files you'll touch)

```
lib/
├── features/chat/
│   ├── presentation/pages/voice_call_page.dart      ← SCREEN (shared, no Platform checks)
│   ├── presentation/widgets/incoming_call_overlay.dart ← in-app ring sheet (shared)
│   └── data/
│       ├── call_signaling_service.dart              ← STATE MACHINE (shared brain)
│       ├── chat_transport.dart                      ← STOMP wire (shared)
│       ├── chats_remote_data_source.dart            ← REST endpoints (shared)
│       ├── stream_call_engine.dart                  ← WebRTC media (shared, fewer iOS hacks)
│       ├── callkit_event_handler.dart               ← Android: up-front permissions
│       └── chat_lifecycle_bridge.dart               ← Android: eager hang-up on detached
├── shared/firebase_services/
│   └── firebase_notification_provider.dart          ← FCM background handler (the entry point)
└── app.dart                                          ← _consumeNativeCallLaunch() (Accept routing)

packages/erp_callkit/                                 ← ★ THE ANDROID WAKE-UP PACKAGE ★
├── lib/erp_callkit.dart                              ← Dart facade (MethodChannel 'erp_callkit')
└── android/src/main/kotlin/.../erp_callkit/
    ├── ErpCallkitPlugin.kt                           ← method channel + intent capture
    ├── IncomingCallNotifier.kt                       ← builds the CallStyle notification
    ├── CallActionReceiver.kt                         ← ★ killed-app Reject (BroadcastReceiver)
    ├── BackendCallClient.kt                          ← POSTs /reject with raw HttpURLConnection
    ├── SecureTokenReader.kt                          ← reads flutter_secure_storage JWT in Kotlin
    └── LaunchActionStore.kt                          ← stashes the Accept bundle for Dart

android/app/src/main/
├── AndroidManifest.xml                               ← call permissions, cleartext, FCM service
└── kotlin/.../MainActivity.kt                        ← show-over-lockscreen + drop-back-when-done
```

---

## 2. Layer diagram — Android wake-up path highlighted

```
┌─────────────────────────────────────────────────────────────┐
│  UI LAYER  (shared with iOS)                                  │
│  VoiceCallPage  ◄── listens ──┐   IncomingCallOverlay         │
└───────────────────────────────┼───────────────────────────────┘
                                 │ activeCallListenable (ValueNotifier<ActiveCall?>)
┌───────────────────────────────▼───────────────────────────────┐
│  BRAIN — CallSignalingService   (shared)                      │
└───┬──────────────────────────┬────────────────────────────┬──┘
    │ control                  │ media                       │ wake-up (ANDROID)
┌───▼──────────┐   ┌───────────▼──────────┐   ┌──────────────▼─────────────┐
│ ChatTransport │   │  StreamCallEngine    │   │ FCM bg handler             │
│ (STOMP)+REST  │   │  (WebRTC / Stream)   │   │   → ErpCallKit (Dart)      │
└───┬──────────┘   └───────────┬──────────┘   │   → erp_callkit (Kotlin):  │
    │                          │               │     IncomingCallNotifier   │
    ▼                          ▼               │     CallActionReceiver     │
 Laravel backend        Stream Video SFU       │     BackendCallClient      │
 (signaling + auth)      (audio media)          └──────────────┬─────────────┘
                                                               ▼
                                                   Android system (FCM, notifications,
                                                   full-screen intent, lock screen)
```

---

## 3. The state machine — IDENTICAL to iOS

`CallSignalState` (`idle → outgoingRinging / incomingRinging → connected → ended`)
is the same file, the same five states, the same transitions. The `VoiceCallPage`
maps them to `_CallStage` (`calling / ringing / connected / ended`) exactly as on
iOS. **Nothing platform-specific lives here.** See
[`IOS_VOICE_CALL_FLOW.md §3`](./IOS_VOICE_CALL_FLOW.md) for the diagram — it
applies verbatim.

---

## 4. How the screen gets shown — same as iOS

No go_router route; the page is pushed onto the **root navigator**:

- **Tap the phone icon** → `_startCall(isVideo:false)` → `ConfigRouter.pushPageAnimation(VoiceCallPage(...))`.
- **Accept an incoming call** → `AppRouter.rootNavigatorKey.currentState.push(...)` from the overlay, **or** auto-pushed by `IncomingCallOverlay` when the state reaches `connected` (the cold-start route — see §7).
- **Re-dial from history** → same `pushPageAnimation`.

`voice_call_page.dart` and `incoming_call_overlay.dart` contain **no
`Platform.isAndroid` branches** — the UI is genuinely shared.

---

## 5. OUTGOING CALL — step by step (you are the caller)

Almost identical to iOS, with two small differences flagged `← Δ`.

```
 YOU (caller, Android)           BACKEND (Laravel)            PEER (callee)
 ────────────────────           ─────────────────            ─────────────
 tap 📞
   │ push VoiceCallPage → startOutgoing()
   │── POST /chats/conversations/{id}/calls?type=VOICE ──►
   │◄──────── 200 {id:42, streamCallCid} ──────│
   │  state = outgoingRinging                   │
   │  (NO warmUp() pre-connect)        ← Δ      │── server-side Stream ring ──► 📳
   │                                            │   + STOMP call.invite ──────► (FCM/overlay)
   │  join(cid, shouldRing:false)      ← Δ      │
   │  (NO ring heartbeat polling)      ← Δ      │◄── POST /accept ──────────  taps ✅
   │◄──── STOMP call.accept ────────────────────│
   │  state = connected                         │
   │  🔊 audio (WebRTC via Stream SFU) ◄═══════════════════════════════════►
   │  timer 00:01, 00:02…
```

**Steps:**

1. **Tap** → `_startCall` pushes `VoiceCallPage`. `initState` grabs the
   signaling + engine singletons and subscribes to `activeCallListenable`.
2. `_placeOutgoingWithPermission()` runs. On Android `ensureCallPermissions()`
   **returns `true` immediately** — mic/camera were already granted up-front at
   launch (see §9), so there's no per-call prompt. Then `startOutgoing` fires.
3. **`startOutgoing`** POSTs `/chats/conversations/{id}/calls?type=VOICE`,
   gets back the call `id` + `streamCallCid`. State → **outgoingRinging**.
   - `← Δ` **No `warmUp()`**: iOS pre-connects the Stream client to shave
     latency; Android skips it and joins after the POST returns.
   - `← Δ` **Caller joins with `shouldRing: false`**: the *backend* triggers
     Stream's server-side ring to every participant, so the Android client
     never asks Stream to ring.
4. Backend broadcasts **`call.invite`** over STOMP (for online callees) and
   fires the Stream/FCM ring (for offline callees).
5. Callee accepts → **`call.accept`** over STOMP → caller transitions to
   **connected**.
   - `← Δ` **No ring heartbeat**: iOS polls `GET /chats/calls/{id}` while
     ringing to catch a lost accept frame. Android relies on the STOMP
     `call.accept` (and the Stream *peer-joined* signal) only.
6. `StreamCallEngine.join(cid)` → WebRTC audio. Ticker starts.

---

## 6. INCOMING CALL — foreground (app open) — same as iOS

When the app is on screen STOMP is live, so the ring arrives over WebSocket and
the flow is identical to iOS:

1. `ChatTransport` receives **`call.invite`** → emits `CallInviteEvent`.
2. `CallSignalingService` builds the `ActiveCall`, state → **incomingRinging**.
3. `IncomingCallOverlay` (mounted in `MaterialApp.builder`) sees the state and
   paints the **Accept / Reject** sheet.
4. **Reject** → `rejectIncoming()` → POST `/reject`.
5. **Accept** → capture the root navigator, push `VoiceCallPage` **first**, then
   fire `acceptIncoming()` (push-first-accept-second — same ordering rule as iOS).

> 🟢 Same backend presence gate: **online** callees get the STOMP invite + the
> in-app overlay only; **offline** callees get the native ring (§7). One person
> never gets both.

---

## 7. INCOMING CALL — backgrounded or killed (the Android wake-up path) ★

This is where Android diverges hard from iOS. There's no PushKit/CallKit; the
ring is a **custom native notification** driven by an **FCM data message**.

```
 CALLER       BACKEND        FCM (Google)      ANDROID SYSTEM        Kotlin (erp_callkit)
 ──────       ───────        ────────────      ──────────────        ───────────────────
 startOutgoing─►creates call─►data push────────►wakes a BACKGROUND
              (callee         {sender:           ISOLATE (no app UI,
               offline)        stream.video,     no GetIt, no BLoC)
                               type:call.ring}        │
                                                       │ firebaseMessagingBackgroundHandler()
                                                       │   (firebase_notification_provider.dart)
                                                       ▼
                                            ErpCallKit.showIncomingCall(
                                              callId, callCid, callerName,
                                              isVideo, baseUrl, …)  ← baseUrl baked in
                                                       │ MethodChannel 'erp_callkit'
                                                       ▼
                                            IncomingCallNotifier.show():
                                              • CallStyle.forIncomingCall(...)
                                              • REJECT  → PendingIntent → CallActionReceiver
                                              • ACCEPT  → PendingIntent → MainActivity (accept=true)
                                              • body    → PendingIntent → MainActivity (accept=false)
                                              • channel "erp_incoming_calls" IMPORTANCE_HIGH
                                              • 65s AlarmManager timeout backstop
                                                       ▼
                                            📳 Full-screen heads-up ring on lock screen
```

Then it forks on what the user taps:

### 7a. REJECT — runs even if the app is **dead** (the clever bit)

```
tap Reject
  → CallActionReceiver.onReceive()        (a BroadcastReceiver — no Flutter engine needed)
      1. IncomingCallNotifier.dismissById(...)        ← ring disappears instantly
      2. goAsync()                                    ← keep the short-lived process alive
      3. Thread { BackendCallClient.rejectCall(...) }:
           • SecureTokenReader.read(context)          ← decrypt flutter_secure_storage JWT in Kotlin
           • POST /chats/calls/{id}/reject?reason=declined  (raw HttpURLConnection)
           • on 401 → POST /auth/refresh → retry, write rotated tokens back
      4. caller's phone stops ringing
```

> 🔑 **Why this is the headline Android feature:** declining a call must stop
> the caller's ring, but on a killed phone there's no Dart, no DI, no Dio. So
> the reject is done **entirely in Kotlin**: a `BroadcastReceiver` reads the JWT
> straight out of `flutter_secure_storage`'s `EncryptedSharedPreferences` and
> POSTs with `HttpURLConnection`. The `baseUrl` was baked into the notification
> bundle at show-time precisely because there's no config service to ask later.
> (This is the *`android-decline-token-read-fail`* memory: the original bug was
> `SecureTokenReader` throwing `AEADBadTagException`; the fix was to pass the JWT
> through and open the prefs with the correct master key.)

### 7b. ACCEPT — bring the app up and join

```
tap Accept
  → MainActivity launches with the call bundle (accept=true)
      • maybeShowOverLockscreen(): setShowWhenLocked(true) + setTurnScreenOn(true)
        (screen lights up, sheet is tappable WITHOUT unlocking; keyguard stays up)
      • ErpCallkitPlugin captures the intent → LaunchActionStore.put(bundle)
  → Flutter engine starts → app.dart._consumeNativeCallLaunch():
      • ErpCallKit.consumeLaunchAction()  → reads the bundle (accept=true)
      • build a synthetic call.invite payload (resolve conversation via findDirectWith)
      • signaling.handleIncomingFromPush(payload)   → state = incomingRinging
      • because accept==true → signaling.acceptIncoming()  → POST /accept → Stream join
  → IncomingCallOverlay sees state == connected → auto-pushes VoiceCallPage → 🔊 audio
```

### 7c. BODY tap (not a button) — show the in-app sheet

Same as Accept up to `_consumeNativeCallLaunch`, but `accept==false`, so it
stops at **incomingRinging** and the user chooses Accept/Reject inside the app.

**Android wake-up pieces and why each exists:**

- **`firebase_notification_provider.dart`** — the `@pragma('vm:entry-point')`
  background handler. Runs in a bare isolate, so it can't use GetIt; it branches
  on the FCM payload: `stream.video/call.ring` → `ErpCallKit.showIncomingCall`;
  `call.ended/call.missed/call.cancel` → `ErpCallKit.dismiss`. iOS takes the
  CallKit branch instead.
- **`IncomingCallNotifier.kt`** — builds `NotificationCompat.CallStyle`
  with three PendingIntents (Reject→receiver, Accept→activity, body→activity).
  Uses an `IMPORTANCE_HIGH` channel + a 65s `AlarmManager` backstop because
  Samsung One UI ignores `setTimeoutAfter`.
- **`CallActionReceiver.kt`** — the killed-app reject (§7a).
- **`BackendCallClient.kt` + `SecureTokenReader.kt`** — DI-free HTTP + JWT.
- **`LaunchActionStore.kt`** — process-wide bundle stash so Dart can pick up the
  Accept after the engine boots.
- **`MainActivity.kt`** — `setShowWhenLocked`/`setTurnScreenOn` to ring over the
  keyguard, and `moveTaskToBack` to drop back behind the lock screen when the
  call ends.
- **`dismissAllCallNotifications`** — nukes lingering "ongoing" CallStyle
  notifications (Samsung pins them even after `cancel(id)`).

---

## 8. ENDING THE CALL — same core, one Android difference

The hangup path is shared: `CallSignalingService.hangup()` POSTs
`/chats/calls/{id}/end`, broadcasts **`call.hangup`** over STOMP, calls
`StreamCallEngine.leave()`, dismisses notifications, sets state → **ended**, and
writes a `📞 Voice call · 1:23` history row. The group-call "only the original
caller's hangup ends it for everyone" rule is identical too.

> `← Δ` **Eager hang-up on `detached`** (`chat_lifecycle_bridge.dart`): on
> Android, `AppLifecycleState.detached` is a reliable "process is dying" signal
> (user swiped from recents / OS kill), so the bridge **hangs up immediately**
> to free the peer. On iOS it must *not* (the CallKit audio session keeps the
> process alive mid-call). This is the single most important lifecycle
> difference between the platforms.

---

## 9. Permissions — Android asks UP FRONT (the opposite of iOS)

| | iOS | Android |
|---|---|---|
| **When** | per-call, lazily, inside `ensureCallPermissions()` | once, **up front at launch** in `callkit_event_handler._requestCallkitPermissions()` |
| **What** | mic (voice) / mic+camera (video) | `POST_NOTIFICATIONS`, `RECORD_AUDIO`, and `USE_FULL_SCREEN_INTENT` (Android 14+ → Settings page) |
| **Track gating** | `_connectOptions` disables a track whose permission was denied so `join()` still succeeds | **no per-track gating** — mic/camera assumed granted, tracks stay enabled |
| **`ensureCallPermissions`** | does the real work | **returns `true` immediately** (`if (!Platform.isIOS) return true;`) |

Because Android requests everything up front, the call pages don't need the
"disabled track" dance — and `StreamCallEngine` skips `configureIosCallAudio`,
`_reassertIosAudioRoute`, the CallKit audio re-assert, and the WebRTC audio-sink
prime entirely (those are all iOS workarounds).

---

## 10. Backend & wire contract — identical to iOS

Same REST surface and same STOMP topics as
[`IOS_VOICE_CALL_FLOW.md §10`](./IOS_VOICE_CALL_FLOW.md):

| Action | HTTP | Endpoint |
|--------|------|----------|
| Start | POST | `/chats/conversations/{id}/calls?type=VOICE\|VIDEO` |
| Accept | POST | `/chats/calls/{id}/accept` |
| Reject | POST | `/chats/calls/{id}/reject?reason=` |
| End | POST | `/chats/calls/{id}/end` |
| Reconcile | GET | `/chats/calls/{id}` |

The **only Android-specific wire detail** is the **FCM data message** the backend
sends to offline callees: `{ sender: "stream.video", type: "call.ring",
call_cid, call_type, created_by_display_name, call_display_name, … }`. The
`call.ended` / `call.missed` / `call.cancel` variants drive `ErpCallKit.dismiss`.

> Same source-of-truth rule: voice-vs-video comes from your **backend's**
> `ChatCallDto.type`, never from Stream (Stream's call type is always
> `'default'`). The FCM `call_type` field is just a hint for the notification icon.

---

## 11. Android Manifest — what makes the ring legal

`android/app/src/main/AndroidManifest.xml` (and the `erp_callkit` manifest):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>  <!-- lock-screen ring -->
<uses-permission android:name="android.permission.TURN_SCREEN_ON"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>      <!-- Android 13+ -->

<application android:usesCleartextTraffic="true">   <!-- killed-app reject POSTs over http:// -->
  <activity android:name=".MainActivity" android:launchMode="singleTask" .../>
  <service android:name="com.google.firebase.messaging.FirebaseMessagingService">
    <intent-filter><action android:name="com.google.firebase.MESSAGING_EVENT"/></intent-filter>
  </service>
</application>

<!-- packages/erp_callkit manifest -->
<receiver android:name=".CallActionReceiver" android:exported="false"/>
```

- **`USE_FULL_SCREEN_INTENT`** is what lets a backgrounded ring take over the
  screen. Android 14+ requires the user to grant it (the handler opens the
  Settings page).
- **`usesCleartextTraffic="true"`** is required so the Kotlin
  `HttpURLConnection` reject can hit `http://host:8080/api/v1` in the LAN demo.
- **`exported="false"`** on the receiver because it's only ever the explicit
  target of our own PendingIntent.

---

## 12. Side-by-side: Android vs iOS at a glance

| Concern | iOS | Android |
|---|---|---|
| Signaling / state machine / REST / STOMP | shared | **shared** |
| In-call UI (`voice_call_page.dart`) | shared | **shared** (no Platform checks) |
| Media engine | Stream Video | Stream Video |
| Wake-up ring | PushKit → **CallKit** (system) | FCM → **`erp_callkit`** (custom native notification) |
| Killed-app **Reject** | Dart `_directRejectNoDi()` after wake | **pure Kotlin** `CallActionReceiver` + `HttpURLConnection` |
| Killed-app **Accept** | CallKit `CXCallObserver` → MethodChannel | notification PendingIntent → `MainActivity` → `LaunchActionStore` → Dart |
| Permissions | per-call, lazy, track-gated | **up front at launch**, no track gating |
| iOS audio session hacks (`configureIosCallAudio`, route re-assert, WebRTC prime) | required | **all skipped** |
| Pre-warm (`warmUp` / `prepareIncoming`) | yes (latency) | **no** |
| Caller ring heartbeat | yes | **no** |
| Caller asks Stream to ring | — | **no — backend rings server-side**, client joins `shouldRing:false` |
| `detached` during call | **do NOT hang up** | **hang up eagerly** |
| Lock-screen ring | CallKit | `setShowWhenLocked` + `USE_FULL_SCREEN_INTENT` |

> Takeaway: iOS has ~2.4× more platform-specific code than Android, almost all
> of it CallKit audio-session and PushKit cold-start workarounds. Android's
> complexity is concentrated in **one place** — the `erp_callkit` native
> package — and is otherwise simpler.

---

## 13. Reusable recipe — the Android wake-up layer

The shared backend + Flutter recipe is in
[`IOS_VOICE_CALL_FLOW.md §12`](./IOS_VOICE_CALL_FLOW.md). To add **Android** on
top of that shared core:

1. **Backend:** when a callee is offline, send an **FCM data message**
   (`type: call.ring`, with `call_cid`, `call_type`, caller name). Send
   `call.ended/call.cancel` variants so the ring can be dismissed.
2. **FCM background handler** (`@pragma('vm:entry-point')`): branch on the
   payload; on `call.ring` call your native "show incoming call". Remember it
   runs in a bare isolate — **bake the API base URL in as a const**, no DI.
3. **A native notification package** (the `erp_callkit` equivalent):
   - `IncomingCallNotifier` → `NotificationCompat.CallStyle.forIncomingCall`
     with three PendingIntents (Reject→receiver, Accept→activity, body→activity),
     an `IMPORTANCE_HIGH` channel, and an `AlarmManager` timeout backstop.
   - `CallActionReceiver` (BroadcastReceiver) → dismiss + `goAsync()` +
     background-thread `HttpURLConnection` POST `/reject`. **This is what lets a
     dead app decline.**
   - `SecureTokenReader` → open `flutter_secure_storage`'s
     `EncryptedSharedPreferences` from Kotlin to get the JWT (handle 401 →
     refresh → write back).
   - `LaunchActionStore` → stash the Accept bundle for Dart to consume after the
     engine boots.
4. **`MainActivity`:** `setShowWhenLocked(true)` + `setTurnScreenOn(true)` to
   ring over the keyguard; `moveTaskToBack(true)` to drop back when done.
5. **`app.dart`:** `consumeLaunchAction()` on start/resume → synthesize a
   `call.invite` → `handleIncomingFromPush` → (if `accept`) `acceptIncoming`.
6. **Permissions up front:** request `RECORD_AUDIO`, `POST_NOTIFICATIONS`, and
   `USE_FULL_SCREEN_INTENT` at launch. Skip the per-track gating.
7. **Lifecycle:** hang up eagerly on `detached` (Android can; iOS can't).
8. **Manifest:** `USE_FULL_SCREEN_INTENT`, `FOREGROUND_SERVICE*`,
   `POST_NOTIFICATIONS`, `TURN_SCREEN_ON`, `usesCleartextTraffic` (if HTTP),
   the FCM service, and the `exported="false"` receiver.

### Android gotchas (add to the shared list)
- **The FCM background isolate has no DI** — bake in the base URL, pass
  everything you need (incl. the JWT path) through the notification bundle.
- **Killed-app Reject must be native** — a Dart-only reject can't run when the
  process is dead. Use a BroadcastReceiver + `HttpURLConnection`.
- **`goAsync()`** in the receiver, or your reject POST gets killed mid-flight.
- **Samsung One UI pins ongoing CallStyle notifications** — sweep them with
  `dismissAllCallNotifications`, and don't rely on `setTimeoutAfter` alone (use
  an `AlarmManager` backstop).
- **Android 14 gates `USE_FULL_SCREEN_INTENT`** — request it (Settings page) or
  the ring won't take over the screen.
- **`AEADBadTagException` reading secure storage** — open
  `EncryptedSharedPreferences` with the exact master-key spec
  `flutter_secure_storage` used, or pass the token in from Dart.

---

## 14. One-paragraph summary (the elevator version)

On Android the **signaling, media, state machine and in-call screen are exactly
the same as iOS** — you tap a phone icon, `startOutgoing` POSTs to Laravel, gets
a Stream call id, and audio flows through Stream once both sides accept. The
*only* real difference is the **wake-up leg**: instead of Apple's PushKit/CallKit,
the backend sends an **FCM data push** that wakes a background isolate, which
calls the project's own **`erp_callkit`** native package to draw a full-screen
CallStyle notification. Tapping **Accept** launches `MainActivity` over the lock
screen and routes the call into the shared signaling path; tapping **Reject**
fires a **pure-Kotlin `BroadcastReceiver`** that reads the JWT from secure
storage and POSTs `/reject` over `HttpURLConnection` — so a call can be declined
even when the app is completely dead. Android also asks for permissions up front
(no per-call prompts, no track gating), skips all the iOS audio-session
workarounds, and hangs up eagerly when the process is killed. Keep the three legs
separate and Android is mostly "iOS minus the CallKit hacks, plus one tidy native
notification package."
```
