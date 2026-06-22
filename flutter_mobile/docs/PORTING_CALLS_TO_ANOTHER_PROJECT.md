# Porting Voice & Video Calls to Another Project

> You understand how calls work here. This doc is the **practical checklist** for
> lifting that system into a *new* Flutter app. Read
> [`CALL_SETUP_FOR_BEGINNERS.md`](./CALL_SETUP_FOR_BEGINNERS.md) first if the
> pieces aren't clear yet.
>
> The honest summary up front: **a call system is ~30% Flutter code you can copy
> and ~70% backend + cloud configuration you must provide.** Copying the Dart
> files is the easy part. The work is the backend endpoints, the Stream account,
> and the push setup. Plan for that.

---

## 0. First, decide which path you're on

The amount of work depends on what you're keeping:

| Path | When | Effort |
|---|---|---|
| **A. Same stack** (Laravel-style backend + Stream + FCM) | You control the backend and can add the call endpoints | Medium — copy Flutter, build the backend mirror |
| **B. Different backend** (Node, Firebase-only, Supabase…) | New project uses a different server | Medium-high — keep the Flutter *shape*, rewrite the transport + token endpoint |
| **C. No backend / pure P2P demo** | Just learning, no server | Different — you'd let Stream handle ringing directly; skip STOMP. Not what this app does. |

This guide assumes **Path A or B** (a real backend), because that's the design
here. The Flutter side is nearly identical for both; only the *transport* and
*token endpoint* differ.

---

## 1. The mental checklist (what a working call needs)

Before touching files, confirm you can provide all three legs (from the beginner
guide):

1. **Signal** — a backend that can broadcast "ring / accept / reject / hangup."
2. **Media** — a **Stream Video** account (apiKey + a token endpoint).
3. **Wake-up** — a **Firebase** project (FCM) and, for iOS, an **Apple paid
   account** with VoIP push.

If any of the three is missing, calls will partially work at best (e.g. ringing
only when the app is already open). Get all three lined up first.

---

## 2. Step-by-step port

### Step 1 — Stand up the cloud services
1. Create a **Stream Video** app at getstream.io. Note the **API key** and
   **secret**.
2. Create a **Firebase** project. Download `google-services.json` (Android) and
   `GoogleService-Info.plist` (iOS).
3. In the **Stream Dashboard → Push Notifications**, add:
   - a provider named **`firebase`** (upload Firebase Admin SDK JSON),
   - a provider named **`apn`** (upload your Apple push key).
   > These names are referenced verbatim in the Flutter code (§4) — keep them.

### Step 2 — Build the backend contract
Your server must expose (mirror of [`IOS_VOICE_CALL_FLOW.md §10`](./IOS_VOICE_CALL_FLOW.md)):

- **Stream token endpoint** → returns `{ apiKey, token, userId }`. The server
  signs the token with the Stream **secret** (never ship the secret in the app).
- **Call REST endpoints:**
  `POST /…/calls` (start, returns `{id, streamCallCid}`), `/accept`, `/reject`,
  `/end`, `GET /…/calls/{id}` (status).
- **Realtime broadcast** of `call.invite / call.accept / call.reject /
  call.hangup` (STOMP here; could be any socket).
- On **start**, the server tells Stream to create the call and (for offline
  callees) **ring** them via push.
- A **presence** signal so the server only push-rings users who are *offline*
  (online users get the socket invite + in-app sheet). This one rule prevents
  the worst double-ring bugs.

> This is the part you cannot copy from the Flutter repo — it lives on the
> server. Budget real time for it.

### Step 3 — Add the Flutter packages
Copy these into the new app's `pubspec.yaml`, then `flutter pub get`:

```yaml
stream_video_flutter: ^0.10.0
stream_video_push_notification: ^0.10.4
stomp_dart_client: ^2.1.0          # (or your socket client of choice)
firebase_core: ^3.13.0
firebase_messaging: ^15.2.5
flutter_local_notifications: ^19.1.0
permission_handler: ^12.0.1
connectivity_plus: ^6.1.0
get_it: ^8.0.3
```

### Step 4 — Copy the call feature code
From this repo, the call system is mostly self-contained. Copy:

**Copy nearly verbatim (the reusable engine):**
```
lib/features/chat/data/call_signaling_service.dart   ← the state machine (the brain)
lib/features/chat/data/stream_call_engine.dart        ← Stream/WebRTC wrapper
lib/features/chat/presentation/pages/voice_call_page.dart
lib/features/chat/presentation/pages/video_call_page.dart
lib/features/chat/presentation/widgets/incoming_call_overlay.dart
lib/features/chat/presentation/widgets/call_permission_gate.dart
lib/features/chat/data/callkit_event_handler.dart     ← native Accept/Reject bridge
lib/features/chat/data/chat_lifecycle_bridge.dart     ← background/foreground rules
packages/erp_callkit/                                 ← the whole Android native package
```

**Adapt to your project (the seams):**
```
lib/features/chat/data/chat_transport.dart            ← your socket protocol (STOMP or other)
lib/features/chat/data/chats_remote_data_source.dart  ← your REST endpoint paths
lib/features/chat/data/chat_settings.dart             ← userId / base URL storage
lib/core/config/environments.dart                     ← your API base URL
lib/shared/firebase_services/firebase_notification_provider.dart ← FCM payload shape
lib/features/chat/chat_di.dart                        ← DI registration + bootChatTransport
```

> 💡 Tip: keep the **class names and method signatures** (`startOutgoing`,
> `acceptIncoming`, `rejectIncoming`, `hangup`, the `ActiveCall` state machine).
> They're the stable contract the UI depends on. Change only what's *inside* the
> transport and data-source files.

### Step 5 — Wire the boot sequence
Replicate the order from [`CALL_SETUP_FOR_BEGINNERS.md §7`](./CALL_SETUP_FOR_BEGINNERS.md)
in your `main.dart`:
1. `primeWebRtcAudioEventSinkEarly()` (iOS, first)
2. `Firebase.initializeApp`
3. `FirebaseMessaging.onBackgroundMessage(handler)` — **before `runApp`**
4. DI / register services
5. `bootChatTransport` — **eagerly create `CallSignalingService`**
6. `CallkitEventHandler.instance.attach()`
7. mount `IncomingCallOverlay` in `MaterialApp.builder`, add `rootNavigatorKey`

### Step 6 — Native configuration
Copy the platform settings (from the beginner guide §5):
- **iOS** `Info.plist`: mic/camera usage strings + `UIBackgroundModes`
  (`audio`, `voip`, `remote-notification`); `Runner.entitlements`:
  `aps-environment`. Drop in `GoogleService-Info.plist`.
- **Android** `AndroidManifest.xml`: `RECORD_AUDIO`, `CAMERA`,
  `FOREGROUND_SERVICE*`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`,
  `TURN_SCREEN_ON`, and `usesCleartextTraffic` if your API is `http://`. Drop in
  `google-services.json`. Make sure the `erp_callkit` receiver/activity is
  declared (it ships its own manifest).

### Step 7 — Set your addresses & login
- Point `environments.dart` at your backend.
- Make sure your login flow calls `setIdentity(userId, userName)` and that the
  Stream warm-up runs after login (`_wireStreamWarmUpToAuth`).

### Step 8 — Test in the right order
Test from easiest to hardest — each builds on the last:
1. **Both apps open, same Wi-Fi** → tap call → in-app sheet rings → accept →
   audio. (Tests signal + media; no push yet.)
2. **Callee app backgrounded** → does the push wake it? (Tests FCM/CallKit.)
3. **Callee app killed** → does it still ring? Does **Reject** stop the caller?
   (Tests the hardest path — the native wake-up + killed-app reject.)
4. **Video** → camera + PiP.

---

## 3. What's truly reusable vs what you must rebuild

| Piece | Reusable? | Notes |
|---|---|---|
| `CallSignalingService` state machine | ✅ copy | The crown jewel — platform-agnostic logic |
| `voice_call_page` / `video_call_page` / overlay | ✅ copy | No `Platform` branches in the pages |
| `StreamCallEngine` | ✅ mostly | Works as-is if you use Stream |
| `erp_callkit` Android package | ✅ copy | Self-contained; just keep the package name consistent |
| `callkit_event_handler` / `chat_lifecycle_bridge` | ✅ copy | Platform glue, stable |
| `chat_transport` (STOMP) | 🔧 adapt | Swap for your socket; keep the event types |
| `chats_remote_data_source` | 🔧 adapt | Change endpoint paths to match your API |
| **The backend** | ❌ rebuild | Endpoints + socket + Stream server integration |
| **Stream / Firebase / Apple accounts** | ❌ provision | Your own credentials |

---

## 4. The traps that will cost you days (learn them now)

These are the hard-won lessons baked into this codebase — re-introduce the
*fixes*, not the bugs:

- **Eagerly build the signaling service** at boot, or it misses the first invite.
- **Push the call page BEFORE awaiting accept** (the overlay unmounts on
  `connected` and eats a later navigation).
- **Use a root navigator key** from the overlay — it's a sibling of the router,
  not an ancestor; `Navigator.of(context)` silently fails.
- **Backend decides online-vs-offline ringing**, not the client → no double-ring.
- **Stream token comes from your backend**, never hard-code the Stream secret.
- **Provider names `'firebase'` / `'apn'`** must match the Stream Dashboard.
- **iOS: don't self-hang-up on `detached`** during a call (CallKit keeps the
  process alive); **Android: do** hang up eagerly.
- **Android killed-app reject must be native** (a BroadcastReceiver + HTTP), and
  the FCM background isolate has **no DI** — bake the base URL + pass the token
  through the notification bundle.
- **iOS VoIP push needs a paid Apple account** + `aps-environment` or it never
  gets a push token. (See the project memory on iOS testing constraints.)
- **Call type is authoritative on your backend** (`type: VOICE|VIDEO`), not from
  Stream (Stream's call type is always `'default'`).

---

## 5. If you only have a weekend (the minimum viable port)

Cut scope deliberately and add the hard parts later:

1. **MVP:** signal + media only, **app-open-on-both-sides**. Copy the signaling
   service, the call pages, the overlay, the Stream engine; wire your socket +
   token endpoint. Skip FCM/CallKit entirely. You get working calls when both
   apps are foregrounded — enough to validate the whole pipeline.
2. **Then add background ringing:** FCM + the `erp_callkit` package (Android) and
   CallKit/VoIP (iOS). This is the bigger half — do it once the MVP works.
3. **Then add video, group calls, call history.**

Don't try to do killed-app push on day one — get foreground calls solid first,
because every later layer depends on the signal+media core being correct.

---

## 6. One-paragraph summary

To reuse this in a new project: **provision the three services** (Stream,
Firebase, and your backend with the call endpoints + socket), **copy the
self-contained Flutter call code** (`CallSignalingService`, the call pages, the
overlay, `StreamCallEngine`, `erp_callkit`), **adapt the two seams** (the socket
transport and the REST endpoint paths), **replicate the native config**
(Info.plist/entitlements, AndroidManifest, Firebase files) and the **boot order**,
then **test foreground → backgrounded → killed → video** in that order. The
Flutter code ports almost as-is; the real work is the backend and the cloud
setup. Re-introduce the fixes in §4 from the start so you don't rediscover the
same bugs.
```
