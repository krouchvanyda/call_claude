# Android Video Call — Companion Guide (what changes vs Voice)

> Read [`ANDROID_VOICE_CALL_FLOW.md`](./ANDROID_VOICE_CALL_FLOW.md) **first**.
> Video on Android reuses **the exact same skeleton** as voice: the same
> `CallSignalingService` state machine, the same STOMP signaling, the same REST
> endpoints, the same **FCM → `erp_callkit`** wake-up path, the same
> root-navigator push, the same `IncomingCallOverlay`. This doc only covers the
> **deltas**.
>
> The video *UI* deltas (remote video, PiP, camera controls, auto-hide chrome)
> are **identical to iOS** — that screen has no `Platform` branches — so this
> guide leans on [`IOS_VIDEO_CALL_FLOW.md`](./IOS_VIDEO_CALL_FLOW.md) for those
> and focuses on the one place Android genuinely differs: **permissions**.

---

## 0. TL;DR — the whole difference in one table

| Concern | Voice | Video | Android note |
|---|---|---|---|
| Page | `VoiceCallPage` | `VideoCallPage` | shared with iOS, no Platform checks |
| `ChatCallType` sent | `voice` | `video` | backend `type=VIDEO` |
| Permissions | mic (up front) | mic **+ camera** (up front) | **both requested at launch**, not per-call |
| Track gating | n/a | **none** | Android leaves tracks enabled (iOS disables a denied track) |
| iOS audio session | — | — | **skipped entirely** on Android |
| Media widgets | none | `StreamCallParticipants` (remote) + `StreamCallParticipant` (PiP) | same widgets as iOS |
| Extra controls | mute, speaker | mute, **camera on/off**, **flip**, speaker | same as iOS |
| Chrome | static | **auto-hide after 3s** | same as iOS |
| FCM ring hint | `call_type: voice` | `call_type: video` | drives the notification icon |
| History label | `📞 Voice call · 1:23` | `📹 Video call · 1:23` | shared |

Everything else — the wake-up path, the killed-app Kotlin reject, the
`MainActivity` lock-screen handling, the eager-hangup-on-`detached` — is
**identical to the Android voice flow**.

---

## 1. Starting a video call — same as iOS

The single `_startCall` helper picks the page by flag; `VideoCallPage.initState`
tags the call as video:

```dart
IconButton(
  icon: const Icon(Icons.videocam_rounded),
  onPressed: () => _startCall(isVideo: true),
);

Future<void> _placeOutgoingWithPermission() async {
  await ensureCallPermissions(needCamera: true);   // ← see §2 (Android no-op)
  if (!mounted) return;
  _signaling.startOutgoing(
    conversationId: widget.conversationId,
    callType: ChatCallType.video,                  // ← video
  );
}
```

On Android `startOutgoing` then behaves exactly as in the voice flow: **no
`warmUp()`, joins with `shouldRing: false`, no ring heartbeat** (see
[`ANDROID_VOICE_CALL_FLOW.md §5`](./ANDROID_VOICE_CALL_FLOW.md)). The only
payload change is `type=VIDEO`.

---

## 2. Permissions — the real Android delta

This is where Android video differs from **both** iOS video and Android voice
needs nothing extra at call time.

- **iOS** requests camera lazily, per-call, inside `ensureCallPermissions(needCamera:true)`,
  and then **gates tracks** in `_connectOptions` (a denied camera → a *disabled*
  camera track so `join()` still succeeds).
- **Android** requests **mic + camera + notifications up front at launch**
  (`callkit_event_handler._requestCallkitPermissions()`), so:
  - `ensureCallPermissions(...)` **returns `true` immediately**
    (`if (!Platform.isIOS) return true;`) — no per-call prompt for video either.
  - `_connectOptions` does **no per-track gating** — the camera/mic tracks are
    left enabled because permission was already granted at launch.

```dart
// stream_call_engine.dart — Android takes the ungated branch
Future<CallConnectOptions> _connectOptions({required bool isVideo}) async {
  var micEnabled = true;
  var camEnabled = isVideo;          // ← Android stops here: both stay enabled
  if (Platform.isIOS) {
    micEnabled = await Permission.microphone.isGranted;
    camEnabled = isVideo && await Permission.camera.isGranted;
    await configureIosCallAudio(isVideo: isVideo);   // ← skipped on Android
  }
  return CallConnectOptions(
    camera: camEnabled ? TrackOption.enabled() : TrackOption.disabled(),
    microphone: micEnabled ? TrackOption.enabled() : TrackOption.disabled(),
  );
}
```

> 🔑 **Consequence:** Android never hits the iOS "camera denied → connected with
> camera off" path, because by the time a call starts the camera grant is
> already settled. If the user *did* deny camera at launch, the Stream camera
> track simply has nothing to publish. There's also **no `configureIosCallAudio`
> / `videoChat` audio-mode step** — that whole iOS audio-session dance is
> skipped; Android uses Stream's default routing.

Make sure `CAMERA` and the foreground-service permissions are declared (they are
in this project's manifest — see §11 of the voice doc):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA"/>
```

---

## 3. The screen — identical to iOS video

`video_call_page.dart` has **no `Platform` branches**, so the remote-video +
PiP UI is exactly what [`IOS_VIDEO_CALL_FLOW.md §5–§6`](./IOS_VIDEO_CALL_FLOW.md)
describes. In brief:

- **Remote (full screen):** `StreamCallParticipants` in spotlight layout, gated
  on `remotes.isNotEmpty` (the SDK does `participants.first` and **throws on an
  empty list** — same crash on Android). Placeholder avatar until the peer joins.
- **Local PiP:** draggable 120×160 preview, front camera **mirrored**
  (`Matrix4.diagonal3Values(-1,1,1)`).
- **Controls:** Mute / **Camera toggle** / **Flip** / Speaker / End, wired to
  `call.setMicrophoneEnabled`, `setCameraEnabled`, `flipCamera`.
- **Chrome:** auto-hides after 3s (`Timer` + `AnimatedOpacity` + `IgnorePointer`).

All of that runs the same on both platforms.

---

## 4. Wake-up, signaling, lifecycle — same as Android voice

To be explicit about what you do **not** relearn for Android video:

- **Wake-up:** offline callees get the same FCM `call.ring` → `erp_callkit`
  native CallStyle notification. The only difference is the FCM `call_type` hint
  is `video`, which the notification can use for its icon. Accept/Reject paths
  (incl. the **pure-Kotlin killed-app reject**) are identical.
- **State machine / STOMP / REST:** identical — only the start payload says
  `VIDEO`.
- **Lifecycle:** same Android **eager hang-up on `detached`**.
- **Permissions up front, no track gating, no iOS audio hacks:** as in §2.

---

## 5. Sequence diagram (Android video, deltas marked `← Δ`)

```
Caller (VideoCallPage, Android)   Backend            Callee
  tap 🎥
   │ ensureCallPermissions(needCamera:true) → true (granted at launch) ← Δ vs iOS
   │ startOutgoing(type: video)
   │── POST /calls?type=VIDEO ──►                       ← Δ VIDEO
   │◄── {id, streamCallCid} ─────┤
   │  (no warmUp, no heartbeat)   │── server ring + STOMP/FCM ──►  ring
   │  join(cid, shouldRing:false) │   (FCM call_type:video → 📹 icon) ← Δ
   │   • camera+mic tracks ENABLED, no per-track gating ← Δ vs iOS
   │   • NO configureIosCallAudio/videoChat            ← Δ vs iOS
   │◄── STOMP accept ─────────────┤◄── POST /accept ────┤
   │  connected
   │◄═══ WebRTC audio + VIDEO (Stream SFU) ═══►│
   │  StreamCallParticipants (remote, spotlight)   ← same as iOS
   │  _LiveLocalPip (mirrored, draggable)          ← same as iOS
   │  controls auto-hide after 3s                  ← same as iOS
   │  tap End → hangup() → 📹 Video call · m:ss in history
```

---

## 6. Reuse recipe — Android video deltas

On top of the shared video recipe ([`IOS_VIDEO_CALL_FLOW.md §9`](./IOS_VIDEO_CALL_FLOW.md))
and the Android wake-up recipe ([`ANDROID_VOICE_CALL_FLOW.md §13`](./ANDROID_VOICE_CALL_FLOW.md)):

1. **Declare `CAMERA` + `FOREGROUND_SERVICE_CAMERA`** in the manifest and
   request camera **up front at launch** alongside mic/notifications.
2. **Skip per-track gating** — leave camera/mic enabled in `_connectOptions`
   (permission already settled), and **skip the iOS audio-session config**.
3. **Send `type=VIDEO`** and set the FCM `call_type: video` hint so the native
   notification shows a video icon.
4. **Reuse the rest verbatim** — the video page UI, the spotlight empty-list
   guard, the mirrored PiP, the camera/flip controls, the auto-hide chrome, and
   the entire Android wake-up + killed-app-reject machinery.

---

## 7. Gotchas (Android video)

- **Spotlight throws on an empty participant list** — same crash as iOS; keep
  the `remotes.isEmpty` guard and pre-filtered `participants:` list.
- **Front camera must be mirrored** — same FaceTime convention.
- **Camera grant is decided at launch, not at call time** — if you ever move to
  lazy/per-call camera prompts on Android, you'd need the iOS-style track gating
  to stop `join()` from failing on a denied camera.
- **No `videoChat` audio mode on Android** — don't port the iOS audio-session
  code; Stream's default routing handles it.
- Everything else: see the Android voice doc's gotcha list (FCM isolate has no
  DI, native killed-app reject, `goAsync()`, Samsung sticky notifications,
  Android 14 full-screen-intent gate) — it all still applies.
```
