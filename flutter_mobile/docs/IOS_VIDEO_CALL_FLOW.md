# iOS Video Call — Companion Guide (what changes vs Voice)

> Read [`IOS_VOICE_CALL_FLOW.md`](./IOS_VOICE_CALL_FLOW.md) **first**. Video
> reuses **the exact same skeleton**: the same `CallSignalingService` state
> machine, the same STOMP signaling, the same REST endpoints, the same
> PushKit/CallKit wake-up, the same root-navigator push, the same
> `IncomingCallOverlay`. This document only covers **the deltas** — the
> handful of places where video does something voice does not.

---

## 0. TL;DR — the whole difference in one table

| Concern | Voice | Video | Why |
|---|---|---|---|
| Page | `VoiceCallPage` | `VideoCallPage` | different UI |
| `ChatCallType` sent | `voice` | `video` | backend `type=VIDEO` |
| Permissions | mic | mic **+ camera** | `ensureCallPermissions(needCamera: true)` |
| iOS audio mode | `voiceChat` | `videoChat` | `configureIosCallAudio(isVideo: true)` |
| Stream connect | mic track | mic **+ camera** track | `_connectOptions(isVideo: true)` |
| Media widgets | none (audio only) | `StreamCallParticipants` (remote) + `StreamCallParticipant` (local PiP) | render video tracks |
| Extra controls | mute, speaker | mute, **camera on/off**, **flip camera**, speaker | camera management |
| Chrome | static | **auto-hide after 3s** | FaceTime-style immersion |
| History label | `📞 Voice call · 1:23` | `📹 Video call · 1:23` | the `📹` glyph |

Everything else — signaling, the 5-state machine, the wake-up path, the
caller heartbeat, the lifecycle carve-out — is **identical**. If you
understand the voice flow, you already understand 90% of video.

---

## 1. Starting a video call

Same entry points, the camera icon instead of the phone icon. In
`chat_conversation_page.dart` the single `_startCall` helper switches on a
flag:

```dart
IconButton(
  icon: const Icon(Icons.videocam_rounded),
  onPressed: () => _startCall(isVideo: true),   // ← the only difference
);

void _startCall({required bool isVideo}) {
  ConfigRouter.pushPageAnimation(
    context,
    isVideo
        ? VideoCallPage(conversationId: widget.conversationId)
        : VoiceCallPage(conversationId: widget.conversationId),
  );
}
```

`VideoCallPage.initState` mirrors `VoiceCallPage` exactly — subscribe to
`activeCallListenable`, decide outgoing-vs-connected — but its outgoing path
requests **camera too** and tags the call as video:

```dart
Future<void> _placeOutgoingWithPermission() async {
  await ensureCallPermissions(needCamera: true);   // ← mic + camera
  if (!mounted) return;
  _signaling.startOutgoing(
    conversationId: widget.conversationId,
    callType: ChatCallType.video,                  // ← video
  );
}
```

> 🔑 Same rule as voice: the ring is a REST invite that needs no hardware, so
> we **always** call `startOutgoing` even if permission was denied — the peer
> must ring regardless. A denied camera just means you publish no video track
> (see §4). Popping the page on denial was the old bug.

---

## 2. Permissions — mic AND camera (`call_permission_gate.dart`)

The shared gate takes a `needCamera` flag. Voice passes nothing (mic only);
video passes `true`:

```dart
Future<bool> ensureCallPermissions({bool needCamera = false}) async {
  if (!Platform.isIOS) return true;            // Android unchanged
  final micOk = await ensure(Permission.microphone);
  final camOk = needCamera ? await ensure(Permission.camera) : true;
  return micOk && camOk;                       // both needed for full video
}
```

This is **iOS-only** (returns `true` immediately on Android, which requests
up-front at launch). It uses the native system prompt; once denied, iOS won't
re-show it, so partial grants are normal and must be handled gracefully — which
is exactly what §4 does.

The **incoming overlay** does the same: when Accept is tapped, it gates on
`needCamera: call.callType == ChatCallType.video` before pushing `VideoCallPage`.

---

## 3. iOS audio session — `videoChat` not `voiceChat`

`StreamCallEngine.configureIosCallAudio(isVideo:)` puts the `AVAudioSession`
into `playAndRecord` with a different *mode* for video:

```dart
appleAudioMode: isVideo
    ? rtc.AppleAudioMode.videoChat     // video
    : rtc.AppleAudioMode.voiceChat,    // voice
```

Same critical timing rule as voice: this **must** run *before* the call flips
to `connected`, because the page touches the audio route the instant the
connected state lands. It's also skipped if mic isn't granted (configuring
`playAndRecord` without mic trips iOS's privacy guard). Default route is
speaker (`defaultToSpeaker`) — sensible for video.

---

## 4. Media tracks — graceful partial-permission gating

This is the subtle one. `_connectOptions(isVideo:)` maps each declined
permission to a **disabled track** rather than refusing to join:

```dart
Future<CallConnectOptions> _connectOptions({required bool isVideo}) async {
  var micEnabled = true;
  var camEnabled = isVideo;
  if (Platform.isIOS) {
    micEnabled = await Permission.microphone.isGranted;
    camEnabled = isVideo && await Permission.camera.isGranted;
    await configureIosCallAudio(isVideo: isVideo);
  }
  return CallConnectOptions(
    camera: camEnabled ? TrackOption.enabled() : TrackOption.disabled(),
    microphone: micEnabled ? TrackOption.enabled() : TrackOption.disabled(),
  );
}
```

> ⚠️ **Why this matters:** enabling a track the user declined makes
> `call.join()` **fail**, and the failure path calls `leave()` — which cancels
> the call (kills the callee's ring, or drops a call you just accepted).
> Disabling the declined track lets the join **succeed**; the call connects, you
> just publish nothing on that track. So "camera denied, mic granted" → a
> connected video call with your camera off. Handle partial grants, never abort.

---

## 5. The screen — remote fills, local is a PiP

Voice has no media widgets. Video's `build()` is a `Stack`:

### 5a. Remote video (full screen)
A `ValueListenableBuilder<Call?>` on `_engine.callNotifier`, wrapping a
`StreamBuilder<CallState>`, renders `StreamCallParticipants` in
**spotlight** layout — but only once a remote participant is actually present:

```dart
final remotes = snap.data?.callParticipants
        .where((p) => !p.isLocal).toList() ?? const [];
if (remotes.isEmpty) return placeholder();      // ← critical guard
return StreamCallParticipants(
  call: call,
  layoutMode: ParticipantLayoutMode.spotlight,
  participants: remotes,                          // pre-filtered to remotes
);
```

> ⚠️ **The empty-list trap:** the SDK's spotlight layout does
> `participants.first`, which **throws on an empty list**. If you mount it
> before the peer joins, you hand it exactly that. The `remotes.isEmpty`
> guard + pre-filtered `participants:` list is what prevents the crash. Until
> the peer's video arrives you show `_RemoteVideoPlaceholder` (avatar + name)
> or `_RemoteOffPlaceholder` (when the remote camera is off).

### 5b. Local PiP (draggable, mirrored)
A 120×160 floating preview, also driven by `callNotifier`. When the local
participant track exists it's `_LiveLocalPip` (real `StreamCallParticipant`),
else a placeholder icon. Front camera is **mirrored** (FaceTime convention):

```dart
mirror   // front camera
  ? Transform(
      transform: Matrix4.diagonal3Values(-1, 1, 1),  // horizontal flip
      child: inner,
    )
  : inner;
```

It's wrapped in a `Draggable` whose `onDragEnd` clamps the position inside the
screen so you can park it in any corner.

### 5c. Cold-start identity fallback
Same trick as voice: `watchById` may return null before the local conversation
resolves (lock-screen / killed-app accept), so name + avatar fall back to the
`ActiveCall` push payload:

```dart
final displayName = conv?.name ?? active?.conversationName ?? active?.peerName;
final avatarPath  = conv?.avatarFilePath ?? active?.conversationAvatarFilePath;
```

---

## 6. Controls — four buttons + End (and they auto-hide)

| Button | Action | Stream SDK call |
|---|---|---|
| **Mute** | toggle mic | `call.setMicrophoneEnabled(enabled: !muted)` |
| **Camera** | toggle local video | `call.setCameraEnabled(enabled: cameraOn)` |
| **Flip** | front ⇄ back camera | `call.flipCamera()` |
| **Speaker** | toggle route | (UI toggle; routing helper wired separately) |
| **End** | hang up | `signaling.hangup()` |

`call` here is `_engine.callNotifier.value` — the live Stream `Call`. Voice has
only Mute / Speaker / End; **Camera** and **Flip** are video-only.

**Auto-hide chrome** (the FaceTime feel) is video-only:

```dart
void _resetHideTimer() {
  _hideTimer?.cancel();
  _hideTimer = Timer(const Duration(seconds: 3), () {
    if (mounted) setState(() => _controlsVisible = false);
  });
}
void _toggleControls() {           // tap anywhere on the video
  setState(() => _controlsVisible = !_controlsVisible);
  if (_controlsVisible) _resetHideTimer();
}
```

Top bar and bottom controls are wrapped in `AnimatedOpacity` (200ms) driven by
`_controlsVisible`; every control tap calls `_resetHideTimer()` to keep them up
while you're interacting. Bottom controls also use `IgnorePointer` while hidden
so invisible buttons can't be tapped.

---

## 7. State machine, signaling, wake-up — UNCHANGED

To be explicit about what you do **not** need to relearn:

- **State machine** — identical `CallSignalState` (`idle → outgoingRinging /
  incomingRinging → connected → ended`). `VideoCallPage._onActiveCallChanged`
  reacts the same way `VoiceCallPage` does, including the `endReason` snackbars
  (`busy` / `declined` / `no_answer`).
- **Signaling** — same STOMP topics, same `call.invite/accept/reject/hangup`
  envelopes, same caller **ring heartbeat** rescuing "stuck on Calling…".
- **REST** — same endpoints; the only payload difference is `type=VIDEO`
  instead of `type=VOICE` on the start call.
- **Wake-up** — same PushKit → CallKit path. The incoming overlay reads
  `call.callType` to decide whether to ask for the camera and which page to
  push, but the *transport* is the same.
- **Lifecycle** — same iOS carve-out (don't self-hang-up on `detached` during a
  call), and `didChangeAppLifecycleState(resumed)` calls
  `reconcileActive()` to recover state after backgrounding.
- **Root-navigator push, `isMounted` flag, cold-start re-push** — all identical.

---

## 8. Sequence diagram (only the video-specific bits highlighted)

```
Caller (VideoCallPage)      Backend            Callee
  tap 🎥
   │ ensureCallPermissions(needCamera:true)   ← Δ camera too
   │ startOutgoing(type: video)               ← Δ video
   │── POST /calls?type=VIDEO ──►              ← Δ VIDEO
   │◄── {id, streamCallCid} ─────┤
   │                             │── STOMP invite ──►  overlay/CallKit
   │ outgoingRinging             │                     (Accept asks camera) ← Δ
   │◄── STOMP accept ────────────┤◄── POST /accept ────┤
   │ connected                   │
   │ configureIosCallAudio(videoChat)          ← Δ videoChat mode
   │ join(cid) with camera+mic tracks          ← Δ camera track
   │◄═══ WebRTC audio + VIDEO (Stream SFU) ═══►│        ← Δ video media
   │ StreamCallParticipants (remote, spotlight)         ← Δ render
   │ _LiveLocalPip (local, mirrored, draggable)         ← Δ PiP
   │ controls auto-hide after 3s                        ← Δ chrome
   │ tap End → hangup() → 📹 Video call · m:ss in history
```

The `← Δ` lines are the *only* places video diverges. Strip them and you have
the voice diagram verbatim.

---

## 9. Reuse recipe — video deltas on top of the voice recipe

You already have the voice checklist in `IOS_VOICE_CALL_FLOW.md §12`. To add
video on top:

1. **Page:** clone the in-call page; add a remote-video `Stack` layer + a
   draggable, mirrored local PiP. Gate the remote widget on
   `remotes.isNotEmpty` (avoid the spotlight empty-list crash).
2. **Permissions:** thread a `needCamera` flag through your permission gate;
   request camera + mic for video.
3. **Connect options:** map each declined permission to a **disabled** track so
   `join()` still succeeds (never abort the call on partial grant).
4. **Audio mode:** use `videoChat` (not `voiceChat`) in the iOS audio session.
5. **Controls:** add Camera-toggle and Flip on top of Mute/Speaker/End, wired to
   `setCameraEnabled` / `flipCamera`.
6. **Chrome:** add a 3-second auto-hide timer + `AnimatedOpacity` + tap-to-show,
   with `IgnorePointer` while hidden.
7. **Type tag:** send `type=VIDEO` and read `callType` in the overlay to choose
   the page and whether to ask for the camera.

Do **not** rebuild signaling, the state machine, the wake-up path, or the
lifecycle handling — reuse them as-is.

---

## 10. Gotchas unique to video (add to the voice list)

- **Spotlight throws on an empty participant list** — always guard
  `remotes.isEmpty` and pass a pre-filtered `participants:` list.
- **Partial permission must not abort the join** — disabled track, not refused
  join. (Camera denied → connected call with camera off.)
- **Front camera must be mirrored** or the user's preview moves the "wrong" way.
- **`videoChat` audio mode**, not `voiceChat`.
- **Auto-hide controls** need `IgnorePointer` while invisible, or users tap
  buttons they can't see.
- Everything else: see the voice doc's gotcha list — it all still applies.
