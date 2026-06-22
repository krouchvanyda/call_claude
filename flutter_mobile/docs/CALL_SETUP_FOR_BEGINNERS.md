# Voice & Video Calls — Beginner's Setup Guide (start here)

> 👋 **New to calls?** Read this **before** the flow docs. It explains, in plain
> language, **what a call needs to even exist** — the accounts, the packages, the
> keys, the native settings — and *why* each one is there. We start from
> **configuration** and end at "you can place a call." Once this makes sense,
> read the flow docs:
> [`IOS_VOICE_CALL_FLOW.md`](./IOS_VOICE_CALL_FLOW.md) ·
> [`ANDROID_VOICE_CALL_FLOW.md`](./ANDROID_VOICE_CALL_FLOW.md) (and the two
> `*_VIDEO_*` companions).

---

## 1. The big picture in plain words

Think of a phone call as needing **three things working together**. If you only
remember one thing from this guide, remember these three:

1. **A way to say "ring!"** — a tiny control message: *"User A wants to call User B."*
   In this app that travels over your **backend** (a WebSocket protocol called
   **STOMP**, plus normal REST API calls).

2. **A way to carry the actual voice/video** — the real audio and camera. Sending
   live media between two phones is *hard* (firewalls, NAT, codecs), so we don't
   build it ourselves. We rent it from a company called **Stream**
   (getstream.io). Their SDK `stream_video_flutter` does the WebRTC media.

3. **A way to wake a sleeping phone** — if the app is closed, it can't hear the
   "ring!" message. So the phone's OS push system wakes it:
   - **iOS** → Apple's **VoIP Push + CallKit** (the native call screen).
   - **Android** → **Firebase Cloud Messaging (FCM)** + a small custom
     notification package in this repo called **`erp_callkit`**.

> 🧠 **Analogy:** Stream is the *phone line* (carries your voice). Your backend
> is the *operator* (connects the call, says who's calling). Push (CallKit/FCM)
> is the *phone bell* that rings even when you're asleep.

You configure all three. Let's go.

---

## 2. Accounts & services you need (the "cloud" side)

Before any code runs, three external things must exist:

| Service | What it's for | Where you set it up |
|---|---|---|
| **Your backend** (Laravel here) | Issues call invites, accept/reject, and the Stream login token | Your server |
| **Stream Video** account | Carries the audio/video media | https://getstream.io → Dashboard |
| **Firebase** project | Sends the wake-up push (FCM on Android, and routes Apple VoIP) | https://console.firebase.google.com |

### 2.1 Stream Dashboard (one-time, ~5 min)
From the comment in `stream_call_engine.dart`, the exact steps this project relies on:

1. Stream Console → your app → **Push Notifications**.
2. Add a **Firebase** provider, named **exactly `firebase`** (Android). Upload
   your Firebase **Admin SDK service-account JSON**.
3. Add an **APNs** provider, named **exactly `apn`** (iOS). Upload your Apple
   push key.

> ⚠️ The provider **names must match the code** (`'firebase'` and `'apn'`) — the
> app registers them by that exact string (see §6). A typo here = the ring push
> silently never arrives.

### 2.2 What your backend must expose
Calls won't work unless the server provides these. (Full detail in
[`IOS_VOICE_CALL_FLOW.md §10`](./IOS_VOICE_CALL_FLOW.md).)

- A **Stream token endpoint** — returns `{ apiKey, token, userId }`. This is how
  the app logs into Stream *as the current user*. The app calls
  `remote.getStreamToken()`.
- **Call REST endpoints:** `POST /chats/conversations/{id}/calls` (start),
  `/accept`, `/reject`, `/end`, `GET /chats/calls/{id}` (status).
- A **STOMP/WebSocket** broker that broadcasts `call.invite` / `call.accept` /
  `call.reject` / `call.hangup`.
- For **offline** callees: trigger Stream's server-side **ring push**.

---

## 3. Flutter packages (the `pubspec.yaml` side)

These are already in [pubspec.yaml](../pubspec.yaml). Here's what each one is
*for*, so the list isn't a mystery:

```yaml
# ── Carry the media (the phone line) ──────────────────────────
stream_video_flutter: ^0.10.0          # WebRTC audio/video via Stream
stream_video_push_notification: ^0.10.4 # bridges Stream's ring push → native call UI

# ── Say "ring!" (the operator) ────────────────────────────────
stomp_dart_client: ^2.1.0              # WebSocket signalling (call.invite, etc.)
dio: ^5.7.0                            # REST calls (start/accept/reject/end)

# ── Wake a sleeping phone (the bell) ──────────────────────────
firebase_core: ^3.13.0
firebase_messaging: ^15.2.5            # receives the FCM wake-up push
flutter_local_notifications: ^19.1.0   # shows notifications
erp_callkit:                           # ← OUR custom package (Android call UI + killed-app reject)
  path: packages/erp_callkit

# ── Supporting cast ───────────────────────────────────────────
permission_handler: ^12.0.1            # ask for mic + camera
connectivity_plus: ^6.1.0              # know when network returns
get_it: ^8.0.3                         # dependency injection (wiring services)
injectable: ^2.5.0
```

> `stream_video_push_notification` is the glue that turns Stream's "ring" push
> into the **native incoming-call screen** (`flutter_callkit_incoming` under the
> hood). Without it, an incoming call would just be a silent notification.

After editing pubspec: `flutter pub get`.

---

## 4. The API address (where the app talks to your backend)

Set in [lib/core/config/environments.dart](../lib/core/config/environments.dart):

```dart
class Environments {
  static const String prodApiBaseUrl = 'http://172.26.17.118:8080/api/v1';
  // staging / local also point here in this demo
}
```

> 📝 **Beginner note:** `172.26.17.118:8080` is a **LAN IP** — a computer on the
> same Wi-Fi running the backend. For your own project change this to your
> server's address. Because it's `http://` (not `https://`), Android needs a
> special "allow cleartext" flag (see §5.2). The **killed-app reject** on
> Android also reuses this URL, baked in as `_callRejectBaseUrl` in
> `firebase_notification_provider.dart` (the background isolate has no access to
> normal config, so the URL is hard-wired there).

---

## 5. Native configuration (the part beginners always miss)

This is the step that makes calls *actually ring*. The OS won't let an app use
the mic, camera, or wake the screen unless you declare it.

### 5.1 iOS — `ios/Runner/Info.plist`
Already set in this project:

```xml
<key>NSMicrophoneUsageDescription</key><string>…needed for calls…</string>
<key>NSCameraUsageDescription</key><string>…needed for video calls…</string>
<key>NSBluetoothAlwaysUsageDescription</key><string>…headset audio…</string>
<key>NSLocalNetworkUsageDescription</key><string>…LAN backend…</string>

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>              <!-- keep audio alive in background -->
  <string>voip</string>               <!-- receive VoIP wake-up pushes -->
  <string>remote-notification</string><!-- background push -->
</array>
```

### iOS — `ios/Runner/Runner.entitlements`
```xml
<key>aps-environment</key><string>development</string>
```
> Without `aps-environment`, **iOS never issues a push token**, so Stream's VoIP
> call push can't ring the phone. (Switch to `production` for App Store builds.)
> iOS VoIP push also needs a **paid Apple Developer account** + the push
> capability — see the project memory note on iOS call testing constraints.

### 5.2 Android — `android/app/src/main/AndroidManifest.xml`
Already set:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/> <!-- ring over lock screen -->
<uses-permission android:name="android.permission.TURN_SCREEN_ON"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>     <!-- Android 13+ -->

<application android:usesCleartextTraffic="true">   <!-- allow http:// to the LAN backend -->
```

### 5.3 Firebase config files (both platforms)
- Android: `android/app/google-services.json` ✅ present
- iOS: `ios/Runner/GoogleService-Info.plist` ✅ present

These come from your Firebase project. They tell the app which Firebase project
to use for push. **They are required** — no file, no push, no ringing when closed.

---

## 6. How the app logs into Stream (the key moment in code)

When you sign in, the app fetches your Stream credentials from the backend and
builds the Stream client. This is in `stream_call_engine.dart`:

```dart
// 1. Ask OUR backend for Stream credentials for the logged-in user
final tokenJson = await remote.getStreamToken();   // → { apiKey, token, userId }
final apiKey = tokenJson['apiKey'];
final token  = tokenJson['token'];
final userId = tokenJson['userId'];

// 2. Build the Stream client AS that user
_client = StreamVideo(
  apiKey,
  user: User.regular(userId: userId, name: displayName, image: avatarUrl),
  userToken: token,
  // 3. Wire the native ring screen + register push providers by name
  pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
    iosPushProvider:     const StreamVideoPushProvider.apn(name: 'apn'),        // ← matches Stream Dashboard
    androidPushProvider: const StreamVideoPushProvider.firebase(name: 'firebase'), // ← matches Stream Dashboard
  ),
);

StreamBackgroundService.init(_client!);   // keeps mic alive when backgrounded mid-call
await _client!.connect();                  // open the media WebSocket
```

> 🔑 **Why the token comes from your backend, not hard-coded:** the `apiKey` is
> public-ish, but the `token` is a *signed login* proving "I am userId 11."
> Only your server (which holds Stream's secret) can mint it. This is the
> standard, secure pattern — never put Stream's secret in the app.

The `name: 'apn'` / `name: 'firebase'` strings **must equal** the provider names
you created in the Stream Dashboard (§2.1).

---

## 7. Boot order — what gets configured at app start

When the app launches, [lib/main.dart](../lib/main.dart) wires everything in a
**specific order** (order matters — comments in the file explain each):

```
1. StreamCallEngine.primeWebRtcAudioEventSinkEarly()  // iOS crash workaround, must be FIRST
2. Firebase.initializeApp(...)                         // turn on Firebase
3. FirebaseMessaging.onBackgroundMessage(handler)      // register the wake-up handler BEFORE runApp
4. LocalNotificationProvider().initialize()            // notification channels
5. configureDependencies(environment: prod)            // DI: build all services
6. registerChatModule(getIt)                           // register chat/call services
7. bootChatTransport(getIt)                             // connect STOMP, eagerly build CallSignalingService
8. _wireStreamWarmUpToAuth(...)                         // log into Stream when the user logs in
9. CallkitEventHandler.instance.attach()               // listen for native Accept/Reject taps
10. runApp(ErpMobileApp())                             // app.dart then mounts IncomingCallOverlay
```

Two beginner-important subtleties:
- **#3 must happen before `runApp`** so a call push can wake the app even when it
  was fully closed.
- **#7 eagerly builds `CallSignalingService`** so it's already listening when the
  first "ring!" arrives — a lazy service would miss it.

---

## 8. Permissions at runtime (mic & camera)

Declaring permissions in the manifest/plist only lets you *ask*. You still
prompt the user at runtime:

- **Android:** asks **up front at launch** (mic, notifications, full-screen
  intent) in `callkit_event_handler.dart`. By call time it's already granted.
- **iOS:** asks **per call**, lazily, via `ensureCallPermissions()` in
  `call_permission_gate.dart` — mic for voice, mic **+ camera** for video.

> 🧠 Rule of thumb you'll see in the code: the *ring* itself needs **no**
> hardware (it's just a message), so the call is always placed even if the user
> denies the mic — they simply transmit silence. Don't block the ring on
> permission.

---

## 9. Quick "did I configure it right?" checklist

Run through this before testing a call:

- [ ] Stream Dashboard has a **`firebase`** provider (with Admin SDK JSON) and an **`apn`** provider (with Apple key).
- [ ] Backend returns `{apiKey, token, userId}` from the Stream token endpoint.
- [ ] Backend has the 5 call REST endpoints + STOMP broadcasting invites.
- [ ] `pubspec.yaml` has `stream_video_flutter`, `stream_video_push_notification`, `firebase_messaging`, `erp_callkit`, `stomp_dart_client`, `permission_handler` → `flutter pub get` done.
- [ ] `environments.dart` `prodApiBaseUrl` points at your reachable backend.
- [ ] **iOS:** Info.plist has mic/camera usage strings + `UIBackgroundModes` (audio/voip/remote-notification); entitlements has `aps-environment`; `GoogleService-Info.plist` present; **paid** Apple account with push.
- [ ] **Android:** manifest has RECORD_AUDIO/CAMERA/FOREGROUND_SERVICE*/USE_FULL_SCREEN_INTENT/POST_NOTIFICATIONS + `usesCleartextTraffic` (if http); `google-services.json` present.
- [ ] Both phones are **logged in as different users** and can reach the backend.

---

## 10. What happens when you press Call (one-paragraph preview)

You tap the phone icon. The app asks your backend to start a call
(`POST /…/calls`); the backend creates a Stream call, returns its id, and rings
the other person — **over STOMP** if they're online (an in-app sheet pops up) or
**over a push** if they're asleep (CallKit on iOS, an `erp_callkit` notification
on Android). When they accept, both phones log into the **Stream** call and the
audio/video flows. Pressing End tells the backend, tears down the Stream
connection, and logs the call to history.

That's the *flow* — and now that you understand the *configuration* behind it,
the detailed flow docs will make sense:

- **iOS:** [`IOS_VOICE_CALL_FLOW.md`](./IOS_VOICE_CALL_FLOW.md) → [`IOS_VIDEO_CALL_FLOW.md`](./IOS_VIDEO_CALL_FLOW.md)
- **Android:** [`ANDROID_VOICE_CALL_FLOW.md`](./ANDROID_VOICE_CALL_FLOW.md) → [`ANDROID_VIDEO_CALL_FLOW.md`](./ANDROID_VIDEO_CALL_FLOW.md)

---

## 11. Glossary (terms you'll keep seeing)

| Term | Plain meaning |
|---|---|
| **Signaling** | The small control messages: ring, accept, reject, hang up. |
| **Media** | The actual audio/video bytes. Handled by Stream/WebRTC. |
| **WebRTC** | The web standard for real-time audio/video between devices. |
| **Stream (getstream.io)** | The paid service that carries the media so you don't build WebRTC yourself. |
| **STOMP** | A simple messaging protocol running over a WebSocket — how the backend pushes "ring" to online users. |
| **FCM** | Firebase Cloud Messaging — Google's push system (wakes Android, routes some iOS). |
| **VoIP Push / PushKit** | Apple's special high-priority push that can ring a closed iOS app. |
| **CallKit** | Apple's native incoming-call screen UI. |
| **`erp_callkit`** | This repo's custom package that draws the Android incoming-call notification (and can reject in pure Kotlin while the app is dead). |
| **CID** (`streamCallCid`) | Stream's id for a specific call, e.g. `default:erp-call-637`. Both phones join the same CID. |
| **Token** | A signed string proving "I am this user" — minted by your backend, used to log into Stream. |
| **DI / GetIt** | "Dependency injection" — how the app builds and shares services like `CallSignalingService`. |
| **ActiveCall / state machine** | The object tracking whether a call is ringing, connected, or ended. |
```
