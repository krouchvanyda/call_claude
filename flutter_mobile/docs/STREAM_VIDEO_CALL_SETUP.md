# Stream Video — Call Setup Guide

> Wires real audio/video onto the chat module's call ceremony.
> The signalling layer (invite → accept/reject → hangup, busy
> handling, group calls, missed-call logs) lives in
> `CallSignalingService`. Stream Video is just the media pipe
> that opens once both sides have accepted.
>
> Companion docs:
> - [`CHAT_MODULE_GUIDE.md`](./CHAT_MODULE_GUIDE.md) — call ceremony test cases
> - [`CHAT_MODULE_BACKEND_INTEGRATIONGUIDE.md`](./CHAT_MODULE_BACKEND_INTEGRATIONGUIDE.md) — REST + STOMP wiring this layers on top of

---

## 1. What we're building

```
┌─────────────── chat ceremony (signalling) ───────────────┐
│                                                          │
│  POST /chats/conversations/{id}/calls  ── create call    │
│  POST /chats/calls/{id}/accept         ── B accepts      │
│  POST /chats/calls/{id}/reject?reason= ── B declines     │
│  POST /chats/calls/{id}/end            ── either ends    │
│  STOMP /user/queue/calls               ── incoming invite│
│  STOMP /topic/conversations/{id}/call  ── state changes  │
│                                                          │
└─────────────────────────┬────────────────────────────────┘
                          │
                 streamCallCid                       ← from ChatCallDto
                          │
                          ▼
┌─────────────── media leg (Stream Video) ─────────────────┐
│                                                          │
│  GET /chats/calls/stream-token                           │
│     → { token, apiKey, userId }                          │
│                                                          │
│  StreamVideo(apiKey, user: User.regular(userId)) ── once │
│     .connect()                                           │
│  client.makeCall(callType, id).getOrCreate().join(...)   │
│                                                          │
│  Audio + video flow through Stream's SFU                 │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

The mobile signalling state machine (in `CallSignalingService`) decides
*when* to join/leave. The media engine (`StreamCallEngine`) is a thin
wrapper around `stream_video_flutter` that knows how to actually
connect and tear down the audio/video session.

---

## 2. Account + dashboard setup (Stream)

1. Go to [dashboard.getstream.io](https://dashboard.getstream.io) and
   create a free Stream account if you don't have one.
2. Create a new **Stream Video** app (separate from Chat — even though
   it's the same console).
3. From the app page grab two values:
   - **API Key** — public, shipped in the token response (also visible
     to the mobile client).
   - **API Secret** — **server-only**, never bundled with mobile. The
     backend uses it to mint JWT user tokens.
4. (Optional) configure call permissions — defaults are fine for
   1:1 + small groups. Bump max participants if you need rooms > 25.
5. (Recommended) enable **call recordings** if you want call playback
   later. Costs apply.

---

## 3. Backend setup

Two pieces the Spring side already ships (per the integration prompts
in `CHAT_MODULE_BACKEND_INTEGRATIONGUIDE.md`):

### 3.1 Provision tokens

A short-lived JWT signed with the Stream API secret, scoped to one
user. Endpoint:

```
GET /api/v1/chats/calls/stream-token
Authorization: Bearer <our app JWT>

→ 200 OK
{
  "success": true,
  "data": {
    "token":  "<JWT for Stream Video>",
    "apiKey": "<Stream API Key>",
    "userId": "<our backend user id, e.g. \"2\">"
  }
}
```

The backend's `StreamTokenService` does:

```java
TokenAuth auth = TokenAuth.builder()
    .apiSecret(streamApiSecret)
    .build();

String streamToken = auth.createToken(
    UserId.of(String.valueOf(principal.userId())),
    Optional.of(Date.from(Instant.now().plus(Duration.ofHours(1)))),  // exp
    Optional.empty()                                                  // iat
);
```

Token TTL is 1 hour — the mobile fetches a fresh one each call.

### 3.2 Provision call CIDs

When a user calls `POST /chats/conversations/{id}/calls`, the backend:

1. Creates a `ChatCall` row in Postgres (status=RINGING)
2. Calls Stream's REST API to create a call object (`type:id`, e.g.
   `default:550e8400-e29b-41d4-a716-446655440000`)
3. Stores the `streamCallCid` on the row
4. Returns the full `ChatCallDto` (now including `streamCallCid`)
5. Fans `call.invite` on `/user/queue/calls` to each callee — payload
   is the same DTO, so callees also receive `streamCallCid`

The `accept` endpoint returns the same DTO so the callee can read
the cid even if the invite landed via STOMP without it.

### 3.3 Verify

```bash
# A logged-in user fetches a token
curl -H "Authorization: Bearer $JWT" \
     http://localhost:8080/api/v1/chats/calls/stream-token

# Expected:
# {"success":true,"data":{"token":"eyJ…","apiKey":"abc123","userId":"2"}}
```

If `apiKey` is empty or `token` is missing, the Spring app's
`stream.api-secret` / `stream.api-key` env vars aren't set.

---

## 4. Mobile setup (Flutter)

### 4.1 Dependency

Already added to `pubspec.yaml`:

```yaml
dependencies:
  stream_video_flutter: ^0.10.0
```

Run:

```bash
flutter pub get
cd ios && pod install && cd ..   # iOS only
```

### 4.2 Platform permissions

The SDK needs **microphone** for voice calls and **microphone +
camera** for video.

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<!-- Required for Android 14+ -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA"/>
```

`minSdkVersion 24` in `android/app/build.gradle`.

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera for video calls.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone for voice and video calls.</string>
```

Background audio (so calls keep going when the user switches apps):

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
</array>
```

### 4.3 Engine + DI

Already registered in
[`lib/features/chat/chat_di.dart`](../lib/features/chat/chat_di.dart):

```dart
getIt.registerLazySingleton<StreamCallEngine>(
  () => StreamCallEngine(remote: getIt<ChatsRemoteDataSource>()),
);

getIt.registerLazySingleton<CallSignalingService>(
  () => CallSignalingService(
    transport: getIt<ChatTransport>(),
    settings: getIt<ChatSettings>(),
    conversations: getIt<ConversationsRepository>(),
    callLog: getIt<CallLogRepository>(),
    remote: getIt<ChatsRemoteDataSource>(),
    streamEngine: getIt<StreamCallEngine>(),   // ← here
  ),
);
```

Nothing extra to wire — `CallSignalingService` calls
`streamEngine.join(...)` after the chat ceremony reaches `connected`
and `streamEngine.leave()` on every termination path.

### 4.4 The data flow at runtime

| Step | Code | Effect |
|---|---|---|
| Caller taps Voice/Video | `startOutgoing(conversationId, callType)` | Optimistic UI shows "Calling…" |
| Behind the scenes | `transport.sendCallInvite(...)` → POST `/calls` | Backend creates ChatCall + Stream call CID |
| Response arrives | `{id: 42, streamCallCid: "default:abc"}` | `_setActive(callId: "42", streamCallCid: "default:abc")` |
| | `streamEngine.join(cid, isVideo: false)` | First call fetches the token, then `StreamVideo.connect()`, then `Call.join()` |
| Callee sees incoming sheet | `_IncomingCallSheet` (root navigator overlay) | Buttons: Accept / Reject |
| Callee taps Accept | `acceptIncoming()` → awaits POST `/accept` | Response includes `streamCallCid` (in case the invite didn't) |
| | `streamEngine.join(cid, isVideo)` | Audio + video flow |
| Either taps End | `hangup()` → POST `/end` → `_setActive(state: ended)` | `_setActive` detects the `connected → ended` transition → `streamEngine.leave()` automatically |
| Call lost / timeout | `_setActive(null)` | Same `_setActive` guard — leave is auto-called |

---

## 5. Testing

### 5.1 Two-device test

1. Sign in as two different users on two phones (or one phone + an
   emulator).
2. Both phones show the green connection pill in the inbox AppBar.
3. From phone A, open the direct conv with user B and tap 📞 (voice).
4. **Expected on phone A:**
   - "Calling…" subtitle, pulsing avatar, End button.
   - Dio log: `POST /api/v1/chats/conversations/{id}/calls` returns
     200 with `streamCallCid` in the response body.
   - Dio log: `GET /api/v1/chats/calls/stream-token` immediately after.
5. **Expected on phone B:**
   - Full-screen incoming sheet within ~500 ms, caller's name + avatar.
   - Accept and Reject buttons.
6. B taps **Accept**.
7. **Expected:**
   - B's Dio log: `POST /api/v1/chats/calls/{id}/accept` returns 200.
   - B's Dio log: `GET /chats/calls/stream-token` follows.
   - Both call pages show the connected state with a ticking timer.
   - **Audio flows both ways** — both users can hear each other.
8. Either taps **End**.
9. **Expected:**
   - Both pages pop within ~600 ms.
   - Inbox tile on both shows `📞 Voice call · 0:23` (caller sees `You: …`).
   - The Stream call session ends — audio stops.

### 5.2 Video call

Same path with the 🎥 icon. Permissions prompt the first time
(camera + microphone). The connected page shows the camera preview
overlaid on the call hero.

### 5.3 Group call (3+ devices)

1. Create or open a group with at least three members.
2. From phone A tap 📞 — backend creates a call with `streamCallCid`.
3. Both other phones' incoming sheets appear independently.
4. Each tapping Accept joins the same Stream call — three-way audio.
5. Last callee tapping End triggers the caller's auto-end
   (Slice 10.2.11 — `_activeCallees` drains to empty).

### 5.4 Verify Stream session

In the **Stream dashboard → Live Calls** tab you should see the
active call with the participants and their connection states.
Useful for debugging "the timer ticks but I can't hear audio":
if the participant isn't listed at all in Stream, the join failed
(check Flutter console for `StreamCallEngine.join failed`).

---

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| **Call connects but no audio** | `streamCallCid` missing in response | Backend didn't create a Stream call when persisting `ChatCall`. Check `StreamCallService.createCall(...)` was invoked. |
| | `StreamCallEngine.join failed: …` in Flutter console | Token expired / API key mismatch. Re-check the `apiKey` returned matches the dashboard. |
| | Permission denied (microphone) | Android: app settings → Permissions → Microphone. iOS: Settings → app → Microphone. |
| **Token endpoint returns 401** | Our app's `AuthInterceptor` didn't attach the access token | Check the user's signed-in state. |
| **Token endpoint returns 500** | Backend's `STREAM_API_SECRET` env var missing | Check Spring app's `application.yml` / env. |
| **Caller's accept button doesn't react** | Local callId is still the placeholder `call-<me>-<ts>` | Restart the app — `transport.sendCallInvite` may have lost the swap during a hot-reload. |
| **Callee never sees the incoming sheet** | Backend doesn't fan to `/user/queue/calls` | Verify `ChatBroadcaster.broadcastCallInvite(...)` uses `convertAndSendToUser(callee.userId, "/queue/calls", event)` — see Section 7 of the backend integration guide. |
| | Phone's STOMP connection isn't live | Check connection pill in inbox AppBar. |
| **Sheet appears but Accept does nothing** | Self-echo filter dropping it | We've already disabled the `targetIds` filter — restart to pick up the latest build. |
| **Audio stops the moment the app backgrounds** | Missing iOS `UIBackgroundModes: voip+audio` | Add to `Info.plist` (Section 4.2). Android needs the foreground-service permissions. |
| **App crashes on `connect()` with "AndroidManifest missing CHANGE_NETWORK_STATE"** | Stream WebRTC dep needs network-change perm | Add `<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>` to the manifest. |
| **Group call only joins 2 of 3 devices** | One device's accept POST never returned | Check that device's Dio log for the accept response. If 4xx, the call expired server-side. |
| **"Call ended" appears immediately after Accept** | Backend returns 404 on accept — call row already torn down | Caller may have hung up before the callee tapped. The mobile correctly drops to `ended` state with `endReason: 'hangup'`. |
| **Audio works but timer doesn't tick** | Page is using its local Timer that depends on state change | Open the page after `_setActive(connected)` has already fired — happens during a stale push. Restart should fix. |

---

## 7. Known limitations + future work

| Limit | Status | Path forward |
|---|---|---|
| No background ring (app killed) | The OS kills the STOMP socket before the invite arrives | FCM push wakes the device → see [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md). Stream's Flutter SDK has a CallKit / ConnectionService integration that pairs with FCM data messages — not yet wired here. |
| Call recordings | Not enabled | Toggle in Stream dashboard + add `record_session: true` to the join payload (`CallConnectOptions.recordOnJoin`). |
| Screen sharing | Not wired | `CallConnectOptions.screenShare = TrackOption.enabled()` + Android foreground service for media projection. |
| Multi-device same user | Stream supports it; chat ceremony's busy guard will auto-reject the second device | Drop the guard if you want simul-ring (rare for ERP). |
| Token rotation mid-call | The 1-hour TTL outlives most calls; if a 4+ hour call somehow happens the SDK will silently drop | Add a `Timer.periodic(50min)` calling `streamEngine._ensureClient()` to refresh — currently not wired. |
| Network change handling | SDK handles WiFi ↔ cellular transitions automatically | None |
| End-to-end encryption | Stream supports it; not enabled here | Backend toggle: pass `e2ee: true` when creating the call. Adds minor latency. |

---

## 8. File map (what owns what)

| File | Responsibility |
|---|---|
| [`lib/features/chat/data/stream_call_engine.dart`](../lib/features/chat/data/stream_call_engine.dart) | Thin wrapper around `stream_video_flutter`. Lazily builds the `StreamVideo` client, joins/leaves calls, swallows SDK failures. |
| [`lib/features/chat/data/chats_remote_data_source.dart`](../lib/features/chat/data/chats_remote_data_source.dart) | REST endpoints including `getStreamToken()`. |
| [`lib/features/chat/data/call_signaling_service.dart`](../lib/features/chat/data/call_signaling_service.dart) | The state machine. Decides *when* to join (after caller POST returns, after callee accept POST returns) and *when* to leave (every `connected → ended/null` transition). |
| [`lib/features/chat/data/chat_transport.dart`](../lib/features/chat/data/chat_transport.dart) | `sendCallInvite()` and `sendCallAccept()` return the full ChatCallDto (with `streamCallCid`) instead of just the id. |
| [`lib/features/chat/presentation/pages/voice_call_page.dart`](../lib/features/chat/presentation/pages/voice_call_page.dart) | UI for voice calls — connects to `CallSignalingService.activeCallListenable`. Doesn't touch `StreamCallEngine` directly. |
| [`lib/features/chat/presentation/pages/video_call_page.dart`](../lib/features/chat/presentation/pages/video_call_page.dart) | Same for video. To render Stream's `StreamCallContainer` widget instead of the current placeholder, see Section 9. |

---

## 9. (Optional) Render Stream's call UI

The current `VideoCallPage` shows placeholder avatars + a timer. To
render Stream's pre-built call UI (with remote video tiles, mute
controls, camera flip, etc.), replace the page body with:

```dart
import 'package:stream_video_flutter/stream_video_flutter.dart';

// In VideoCallPage.build, when state == connected:
final activeStreamCall = StreamVideo.instance.activeCall;
if (activeStreamCall != null) {
  return StreamCallContainer(
    call: activeStreamCall,
    callContentBuilder: (context, call, callState) {
      return StreamCallContent(
        call: call,
        callState: callState,
      );
    },
  );
}
```

`StreamCallContent` ships floor controls (mute, camera, end), the
remote-video grid, the local PiP, and a callee-list strip. You can
replace any of those via `callControlsBuilder` /
`callParticipantsBuilder` callbacks while keeping the rest.

For voice calls just use `StreamCallContainer` with no video tiles —
the SDK auto-detects audio-only sessions.

---

## 10. Cost notes (Stream pricing)

Quick reference — see [getstream.io/video/pricing](https://getstream.io/video/pricing) for current numbers.

| Tier | What you get | Roughly |
|---|---|---|
| Free | 25 MAU, 50 GB bandwidth/mo | Demo + small teams |
| Maker | $99/mo | Small startups |
| Growth | $499/mo | Production small/mid |
| Enterprise | custom | Volume discounts, SLA, on-prem |

Bandwidth is the biggest variable — video calls eat ~1 Mbps per
participant. Audio-only calls are ~50 Kbps.
