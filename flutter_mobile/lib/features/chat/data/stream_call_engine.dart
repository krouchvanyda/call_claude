import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
// ignore: depend_on_referenced_packages — pulled in transitively by
// stream_video_flutter; we touch it directly only to pre-configure the
// iOS AVAudioSession before a Stream join (see [_connectOptions]).
import 'package:stream_webrtc_flutter/stream_webrtc_flutter.dart' as rtc;
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

import '../../../core/di/injection.dart';
import 'chat_settings.dart';
import 'chats_remote_data_source.dart';
import 'users_cache.dart';

/// Why Stream signalled that the active call ended. Lets the consumer
/// distinguish DEFINITIVE ends (which must always tear the call down)
/// from the one POSSIBLY-TRANSIENT case (a raw `Disconnected` that the
/// SDK sometimes emits during media setup and then self-recovers, which
/// is the only kind worth settle-guarding).
enum StreamCallEndReason {
  /// A remote participant that WAS present left the call (the peer hung
  /// up / left). Definitive — never a transient SDK blip.
  remoteLeft,

  /// Stream's WebSocket flipped to `Disconnected`. May be a transient
  /// media-setup blip that self-recovers, so the consumer settle-guards
  /// it within the first couple seconds of a fresh connect.
  disconnected,

  /// Reconnection permanently failed. Definitive.
  reconnectFailed,

  /// Stream cleared the incoming-call slot — the caller withdrew before
  /// we answered. Definitive.
  incomingCleared,
}

/// Thin wrapper around `stream_video_flutter` so the rest of the
/// chat module doesn't import the SDK directly. Exposes just three
/// operations: lazy [_ensureClient] (one client per process), [join]
/// (called after our REST POST has produced a `streamCallCid`), and
/// [leave] (called on every end-of-call path).
///
/// Failures are deliberately swallowed — call media is best-effort
/// on top of the chat ceremony. If Stream is unreachable we still
/// want the signalling state machine, timers, and call logs to
/// behave correctly so the user can hang up cleanly.
class StreamCallEngine {
  StreamCallEngine({required this.remote}) {
    _primeWebRtcAudioEventSink();
  }

  /// Workaround for a use-after-free in `stream_webrtc_flutter` 1.0.13.
  ///
  /// Its `FlutterWebRTCPlugin.handleInterruption` posts to the
  /// `FlutterWebRTC.Event` sink WITHOUT a nil-check (unlike
  /// `didSessionRouteChange`, which guards `if (self.eventSink)`):
  ///
  /// ```objc
  /// postEvent(self.eventSink, @{@"event": @"onInterruptionStart"});
  /// ```
  ///
  /// When iOS fires an `AVAudioSession` interruption during a call's
  /// audio setup and nothing has ever subscribed to that channel,
  /// `self.eventSink` is nil, so `postEvent` does
  /// `dispatch_async(^{ nil(event); })` → calling a nil block →
  /// `EXC_BAD_ACCESS`. That is the crash the callee hits the instant
  /// they accept and grant the mic (granting it enables the recording
  /// unit, whose session activation triggers the interruption).
  ///
  /// Touching `navigator.mediaDevices` instantiates the package's
  /// `MediaDeviceNative` singleton, whose constructor subscribes to
  /// `FlutterWebRTC.Event` — so the native `_eventSink` becomes a
  /// VALID block and the unguarded `postEvent` lands harmlessly (the
  /// event is just ignored on the Dart side). One canonical subscription
  /// for the whole process; never cancelled. iOS-only — Android's
  /// (working) call flow is untouched.
  void _primeWebRtcAudioEventSink() {
    if (!Platform.isIOS) return;
    try {
      // ignore: unnecessary_statements
      rtc.navigator.mediaDevices;
    } catch (_) {/* best-effort priming — never block engine creation */}
  }

  /// EARLY static prime — call this as the very FIRST thing in `main()`
  /// (before the awaited Firebase/DI bootstrap), iOS-only.
  ///
  /// The constructor-time [_primeWebRtcAudioEventSink] runs during DI setup,
  /// which on a VoIP COLD-START happens after a chunk of awaited init — and
  /// a background-launched (killed-app) process can be SUSPENDED before the
  /// async native `onListen` for `FlutterWebRTC.Event` registers its sink.
  /// Then CallKit activates the audio session on the first Accept, the
  /// plugin's unguarded `postEvent` fires for the AVAudioSession
  /// interruption, the sink is still nil → `EXC_BAD_ACCESS` at
  /// `__postEvent_block_invoke` (confirmed in the device .ips). Establishing
  /// the subscription FIRST gives the native onListen the entire launch
  /// window to register before any call can arrive. Idempotent (the
  /// underlying `MediaDeviceNative`/`FlutterWebRTCEventChannel` are
  /// singletons), so the constructor call later is a harmless no-op.
  static void primeWebRtcAudioEventSinkEarly() {
    if (!Platform.isIOS) return;
    try {
      // ignore: unnecessary_statements
      rtc.navigator.mediaDevices;
    } catch (_) {/* best-effort — never block launch */}
  }

  final ChatsRemoteDataSource remote;

  StreamVideo? _client;
  Call? _activeCall;

  /// The call currently being set up by [join] but NOT yet promoted to
  /// [_activeCall] (we only promote after `join()` resolves). Its
  /// `getOrCreate(ringing: true)` already started Stream's outgoing
  /// "Call in progress / Connecting…" foreground-service notification,
  /// so if the callee rejects DURING this window, [leave] must leave
  /// THIS ref too — otherwise that notification lingers forever because
  /// `_activeCall` was still null when teardown ran.
  Call? _inFlightCall;

  /// True while an outgoing [join] or an in-app [acceptPendingIncoming]
  /// is bringing the media leg up but BEFORE it has been promoted to
  /// [_activeCall]. iOS-only: [disconnectForBackground] reads this to
  /// avoid dropping the Stream WebSocket mid-`call.join()` — doing so
  /// kills the connect with "connect cancelled", so the caller never
  /// enters the call and BOTH sides hear silence (the reported bug).
  /// Android never reads it, so its call flow is unchanged.
  bool _callSetupInProgress = false;

  /// iOS-only: a Stream [Call] that's already been `getOrCreate`d (the
  /// coordinator handshake that fetches SFU credentials) WHILE the phone
  /// was still ringing, but NOT yet joined. When the callee accepts,
  /// [join] reuses this ref and skips its own `getOrCreate`, so only the
  /// SFU media connect happens on the accept→audio critical path —
  /// shaving the variable coordinator round-trip off call setup. Null
  /// when nothing is prepared. Android never sets it (prepareIncoming is
  /// a no-op there), so its join path is byte-for-byte unchanged.
  Call? _preparedCall;
  String? _preparedCid;

  /// Monotonic counter incremented on every join / accept entry.
  /// Each invocation captures its value, then re-checks at every
  /// await checkpoint — if `_callSeq` has moved on since, a newer
  /// invocation is in flight and we abandon ours (leave the half-set-
  /// up Call ref) so the newer one wins. This is the only thing that
  /// stops back-to-back call attempts from racing and producing
  /// Stream "Disconnected: Replaced" events on the brand-new call.
  int _callSeq = 0;

  /// Cached identity used to bring the client up. We re-fetch the
  /// token if [_clientUserId] doesn't match the one we're being asked
  /// to join as (rare: sign-out → sign-in mid-session).
  String? _clientUserId;

  /// Display name the live [_client] was built with. Tracked so a client
  /// first built with only the bare userId (the cold-start warmUp-vs-
  /// setIdentity race, when neither UsersCache nor ChatSettings had the name
  /// yet) is REBUILT once the real name is available — otherwise Stream's
  /// ring push keeps showing the caller's id ("9") instead of "Mr A" on the
  /// callee's CallKit screen for the rest of the session.
  String? _clientUserName;

  /// Last apiKey + user token fetched from `/chats/calls/stream-token`. Cached
  /// so [_reregisterApnDeviceAfterDisconnect] can re-create the push device via
  /// a direct Stream REST call WITHOUT another backend round-trip (and without
  /// the Stream WS, which we just dropped). Refreshed on every client build.
  String? _lastApiKey;
  String? _lastStreamToken;

  /// Live handle to the currently-joined Stream [Call] (or null when
  /// idle). The voice/video pages listen to this so they can mount a
  /// [StreamCallParticipants] / video renderer the instant Stream
  /// finishes its join — without it, the UI sits on the placeholder
  /// avatar forever even though the media leg is healthy.
  final ValueNotifier<Call?> callNotifier = ValueNotifier<Call?>(null);

  /// True when the active Stream call currently has at least one REMOTE
  /// (non-local) participant connected.
  ///
  /// This is the reliable discriminator the signalling layer uses to tell
  /// a REAL peer hang-up from a stale backend hangup that raced a fresh
  /// accept: when the caller deliberately ends the call they leave the
  /// media session (→ false), whereas a backend ring-timer hangup fires
  /// while the caller is still sitting in the call (→ true).
  bool get hasRemoteParticipant {
    final call = _activeCall ?? callNotifier.value;
    if (call == null) return false;
    final participants = call.state.valueOrNull?.callParticipants ?? const [];
    return participants.any((p) => !p.isLocal);
  }

  /// Fires every time Stream pushes a new incoming-call event over
  /// the live WebSocket (i.e. when B is FOREGROUNDED and A initiates
  /// a call with `ring=true`). The native CallKit ringer only fires
  /// for backgrounded/killed apps — for foreground, Stream just sets
  /// `client.state.incomingCall` and expects the app to render its
  /// own incoming-call UI.
  ///
  /// `CallSignalingService` subscribes to this and forwards the data
  /// into `handleIncomingFromPush(...)` so the existing
  /// `IncomingCallOverlay` (the Flutter widget that paints the in-app
  /// Accept/Reject sheet) lights up.
  Stream<Call> get onStreamIncomingCall => _incomingCallController.stream;
  final StreamController<Call> _incomingCallController =
      StreamController<Call>.broadcast();
  StreamSubscription<Call?>? _incomingCallSub;

  /// Pending incoming Stream Call — the one currently ringing. We keep
  /// a reference because Stream needs us to call `accept()` / `reject()`
  /// on the SAME object that fired in `state.incomingCall`. Creating a
  /// new Call via `client.makeCall(id)` and joining it would bypass
  /// Stream's ringing-acceptance flow → no audio.
  Call? _pendingIncomingCall;

  /// True when there's a Stream incoming Call awaiting accept/reject.
  /// Signaling layer uses this to decide between
  /// `acceptPendingIncoming()` (preserves ringing acceptance, audio
  /// flows) and a fresh `join()` (FCM-push fallback path).
  bool get hasPendingIncoming => _pendingIncomingCall != null;

  /// iOS back-to-back race: CallKit's audio-session toggle
  /// (`onCallKitAudioSessionActivated`) can arrive BEFORE `join()` has
  /// promoted the call to `_activeCall` — so the re-assert finds no live
  /// call and bails. We latch the intent here; `join()`'s post-join hook
  /// applies it the instant `_activeCall` is set. Fixes "second
  /// back-to-back call, accept, no audio" where CallKit fired only a
  /// `didDeactivate` (no `didActivate`) and the re-assert lost the race
  /// with a slow coordinator handshake.
  bool _pendingCallkitAudioReassert = false;

  /// Fires when Stream signals the active call has ended (caller hung
  /// up before callee answered, peer left, etc.). The signaling layer
  /// subscribes so it can pop the local UI even when the end event
  /// came from Stream instead of our STOMP/REST backend.
  ///
  /// The emitted [StreamCallEndReason] tells the consumer whether the
  /// end is DEFINITIVE (a peer truly left / reconnect permanently failed
  /// / caller withdrew) or POSSIBLY-TRANSIENT (a raw `Disconnected` that
  /// Stream sometimes emits mid media-setup and then self-recovers).
  /// Only the latter should be settle-guarded — see
  /// `_handleStreamCallEnded` in CallSignalingService. Collapsing both
  /// into a bare signal was a bug: B accepting from a LOCKED screen, then
  /// A hanging up within the settle window, produced a definitive
  /// `remoteLeft` that the guard wrongly swallowed → B stuck Connected.
  Stream<StreamCallEndReason> get onStreamCallEnded =>
      _callEndedController.stream;
  final StreamController<StreamCallEndReason> _callEndedController =
      StreamController<StreamCallEndReason>.broadcast();
  StreamSubscription<CallState>? _activeStateSub;

  /// Fires on the CALLER's side the first time a remote participant
  /// joins the Stream call — i.e. our peer accepted on their device.
  /// Used as a backup signal when the chat-ceremony backend never
  /// broadcasts `call.accept` to us (its own 30 s timer fired and
  /// closed the row before the callee tapped Accept). Without this,
  /// A's UI stays on "Calling…" indefinitely even though B is already
  /// in the media call.
  Stream<void> get onStreamPeerJoined => _peerJoinedController.stream;
  final StreamController<void> _peerJoinedController =
      StreamController<void>.broadcast();
  StreamSubscription<CallState>? _peerJoinedSub;

  /// Join the media leg of the call carried by [streamCallCid]
  /// (e.g. `default:abc123`). The chat ceremony is responsible for
  /// reaching the "connected" state BEFORE this is called — Stream
  /// is just the audio/video pipe under it.
  ///
  /// No-op when [streamCallCid] is null/empty (backend hasn't shipped
  /// Stream integration for this call) or the token endpoint fails.
  /// Build the [CallConnectOptions] for a Stream join, gating each media
  /// track on the OS permission **on iOS only**. Enabling a track the user
  /// declined makes `call.join()` fail — and the failure path calls
  /// `leave()`, which cancels the call (for the caller that stops the
  /// callee's ring; for the callee it drops the call they just accepted).
  /// Mapping a declined permission to a DISABLED track lets the join
  /// succeed: the call connects, the user just publishes nothing on that
  /// track. Android requests mic/camera up-front at launch, so both stay
  /// enabled there exactly as before.
  Future<CallConnectOptions> _connectOptions({required bool isVideo}) async {
    var micEnabled = true;
    var camEnabled = isVideo;
    if (Platform.isIOS) {
      micEnabled = await Permission.microphone.isGranted;
      camEnabled = isVideo && await Permission.camera.isGranted;
      // ignore: avoid_print
      print('[StreamCallEngine] iOS track gating · '
          'mic=$micEnabled cam=$camEnabled');
      await configureIosCallAudio(isVideo: isVideo);
    }
    return CallConnectOptions(
      camera: camEnabled ? TrackOption.enabled() : TrackOption.disabled(),
      microphone:
          micEnabled ? TrackOption.enabled() : TrackOption.disabled(),
    );
  }

  /// Put the iOS `AVAudioSession` into `playAndRecord` / voiceChat
  /// (videoChat for video) so the WebRTC recording unit can start.
  ///
  /// This MUST run before anything touches the audio route — both the
  /// WebRTC mic unit that `call.join()` starts AND the call page's
  /// `setSpeakerphoneOn(defaultToSpeaker)`. On iOS, accepting from the
  /// in-app overlay (not CallKit's UI) means CallKit never activates the
  /// session, so it stays in `playback`; starting the mic unit / setting
  /// `defaultToSpeaker` on a non-`playAndRecord` session is the native
  /// abort the callee hits the moment they grant the mic. Call this
  /// EARLY (before flipping the call to `connected`), not just inside
  /// [_connectOptions], because the page touches the route the instant
  /// the connected state lands.
  ///
  /// No-op off iOS, and skipped when the mic isn't granted —
  /// configuring `playAndRecord` without mic permission itself trips
  /// iOS's privacy guard. Best-effort: failures are swallowed so they
  /// can never crash the call. iOS-only — Android audio is untouched.
  Future<void> configureIosCallAudio({required bool isVideo}) async {
    if (!Platform.isIOS) return;
    if (!await Permission.microphone.isGranted) return;
    try {
      await rtc.Helper.setAppleAudioConfiguration(
        rtc.AppleAudioConfiguration(
          appleAudioCategory: rtc.AppleAudioCategory.playAndRecord,
          appleAudioCategoryOptions: <rtc.AppleAudioCategoryOption>{
            rtc.AppleAudioCategoryOption.allowBluetooth,
            rtc.AppleAudioCategoryOption.allowBluetoothA2DP,
            rtc.AppleAudioCategoryOption.defaultToSpeaker,
          },
          appleAudioMode: isVideo
              ? rtc.AppleAudioMode.videoChat
              : rtc.AppleAudioMode.voiceChat,
        ),
      );
      // ignore: avoid_print
      print('[StreamCallEngine] iOS audio session → playAndRecord/'
          '${isVideo ? "videoChat" : "voiceChat"}');
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] setAppleAudioConfiguration failed: $e');
    }
  }

  /// Explicitly publish the local microphone after a join. The
  /// `CallConnectOptions(microphone: enabled)` passed to `join()` sets
  /// the intent, but in practice the local audio track sometimes isn't
  /// published (the SFU shows `publishesAudio=false, tracks=[]`) — so we
  /// force it on here. Gated on mic permission on iOS (enabling without
  /// permission trips the privacy guard); best-effort. iOS-only.
  Future<void> _ensureMicPublishing(Call call) async {
    try {
      if (Platform.isIOS && !await Permission.microphone.isGranted) {
        // ignore: avoid_print
        print('[StreamCallEngine] _ensureMicPublishing skipped — mic denied');
        return;
      }
      final r = await call.setMicrophoneEnabled(enabled: true);
      // ignore: avoid_print
      print('[StreamCallEngine] setMicrophoneEnabled(true) → '
          '${r.isSuccess ? "OK (mic now publishing)" : r}');
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] setMicrophoneEnabled threw: $e');
    }
  }

  /// iOS-only: re-apply the audio route AFTER the media `join()` has
  /// completed — the fix for "connected but both sides are silent".
  ///
  /// The call page sets the speaker route the instant the signalling
  /// state flips to `connected`. On the callee that flip happens BEFORE
  /// the `unawaited` `join()` finishes, so WebRTC's audio device module
  /// (ADM) starts a beat LATER and reconfigures the shared
  /// `RTCAudioSession` with its own `webRTCConfiguration` defaults —
  /// silently overriding the route the page just set, which the page then
  /// never re-applies. Net effect on both phones: the session ends up on a
  /// route that produces no audible output even though the SFU media is
  /// healthy.
  ///
  /// Re-asserting here, once the ADM is up, restores output.
  /// `ensureAudioSession()` first guarantees the category is
  /// `playAndRecord` (the native `setSpeakerphoneOn` is a no-op otherwise,
  /// see stream_webrtc `AudioUtils.setSpeakerphoneOn`). One-shot — runs
  /// only at connect, so a later user earpiece/speaker toggle from the
  /// page is NOT overridden. Best-effort; never throws. No-op off iOS, so
  /// Android's route handling (managed entirely by the call page) is
  /// untouched.
  Future<void> _reassertIosAudioRoute() async {
    if (!Platform.isIOS) return;
    try {
      await rtc.Helper.ensureAudioSession();
      await rtc.Helper.setSpeakerphoneOn(true);
      // ignore: avoid_print
      print('[StreamCallEngine] iOS post-join audio re-assert · '
          'ensureAudioSession + speakerphone(on)');
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] post-join audio re-assert failed: $e');
    }
  }

  /// iOS-only: re-run the audio route + mic publish the instant CallKit
  /// hands us the ACTIVATED `AVAudioSession`.
  ///
  /// The fix for "minimized/killed accept connects but is SILENT". On a
  /// CallKit-accepted call the engine `join()`s and asserts the route
  /// immediately — but CallKit activates ITS own session a beat LATER
  /// (`CXProvider.provider(_:didActivate:)`, surfaced to Flutter as
  /// `Event.actionCallToggleAudioSession { isActivate: true }`). That
  /// activation resets WebRTC's audio unit, which had started on a
  /// not-yet-active session → both sides hear nothing. Re-asserting the
  /// route AND re-publishing the mic at THIS moment (not just after join)
  /// restarts the unit on the now-live CallKit session. The foreground /
  /// in-app-overlay accept never triggers this because CallKit never takes
  /// over the session there. No-op off iOS / when no call is active.
  Future<void> onCallKitAudioSessionActivated() async {
    if (!Platform.isIOS) return;
    // The activation event races the accept→join flow: CallKit can call
    // didActivate a beat BEFORE join() has promoted the call to _activeCall.
    // Wait briefly (up to ~3 s) for the live call to appear so we don't
    // no-op on a real activation. 12 × 250 ms.
    Call? call;
    for (var i = 0; i < 12; i++) {
      call = _activeCall ?? callNotifier.value;
      if (call != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (call == null) {
      // join() hasn't promoted the call yet — on a back-to-back accept the
      // coordinator handshake (token + getOrCreate) can outlast this 3 s
      // wait, so giving up here leaves the call SILENT. Latch the intent
      // instead; join()'s post-join hook applies the re-assert the instant
      // `_activeCall` is set.
      _pendingCallkitAudioReassert = true;
      // ignore: avoid_print
      print('[StreamCallEngine] CallKit audio activated · no active call after '
          'wait — DEFERRING re-assert until join() promotes the call');
      return;
    }
    // ignore: avoid_print
    print('[StreamCallEngine] CallKit audio session ACTIVATED · '
        're-asserting route + bouncing mic on the live session');
    await _applyCallkitAudioReassert(call);
  }

  /// Re-assert the iOS audio route + bounce the mic (off→on) on [call] so
  /// WebRTC's capture/playback unit restarts on the now-live CallKit
  /// session. Shared by the immediate activation handler and the deferred
  /// post-join path (see [_pendingCallkitAudioReassert]). iOS-only.
  Future<void> _applyCallkitAudioReassert(Call call) async {
    if (!Platform.isIOS) return;
    await _reassertIosAudioRoute();
    // Bounce the mic OFF→ON. A plain setMicrophoneEnabled(true) is a no-op
    // when the track already "enabled", so it won't restart WebRTC's capture
    // unit that died on the not-yet-active session. Toggling forces the ADM
    // to tear down and re-create the audio unit on the now-live CallKit
    // session — the actual fix for the silent minimized/killed accept.
    try {
      if (await Permission.microphone.isGranted) {
        await call.setMicrophoneEnabled(enabled: false);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await call.setMicrophoneEnabled(enabled: true);
        // ignore: avoid_print
        print('[StreamCallEngine] CallKit-activated mic bounce done '
            '(off→on) — capture unit restarted on live session');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] CallKit-activated mic bounce failed: $e');
      // Fall back to the plain publish so we at least try.
      await _ensureMicPublishing(call);
    }
  }

  /// Post-join hook: if a CallKit audio toggle fired BEFORE this join
  /// promoted the call (so [onCallKitAudioSessionActivated] latched
  /// [_pendingCallkitAudioReassert] instead of acting), apply the
  /// re-assert now on the freshly-live [call]. No-op off iOS / when
  /// nothing is pending.
  void _consumePendingCallkitReassert(Call call) {
    if (!Platform.isIOS || !_pendingCallkitAudioReassert) return;
    _pendingCallkitAudioReassert = false;
    // ignore: avoid_print
    print('[StreamCallEngine] applying DEFERRED CallKit audio re-assert — '
        'join() has now promoted the call');
    unawaited(_applyCallkitAudioReassert(call));
  }


  /// iOS-only: warm up an INCOMING call's media leg WHILE it's ringing.
  /// Runs the Stream `getOrCreate` (coordinator handshake → SFU
  /// credentials) on the call identified by [streamCallCid] but does NOT
  /// join — so the callee isn't a participant yet (the caller doesn't see
  /// them as "answered") and no mic/foreground-service starts. When the
  /// user later accepts, [join] reuses this ref and skips its own
  /// `getOrCreate`, removing the variable coordinator round-trip from the
  /// accept→audio path.
  ///
  /// No-op off iOS, when a call is already active/in-flight, or when the
  /// same cid is already prepared. Best-effort: failures are swallowed so
  /// a warm-up miss just falls back to the normal accept path.
  Future<void> prepareIncoming({
    required String streamCallCid,
    required bool isVideo,
  }) async {
    if (!Platform.isIOS) return;
    if (streamCallCid.isEmpty) return;
    if (_activeCall != null || _inFlightCall != null) return;
    if (_preparedCid == streamCallCid && _preparedCall != null) return;
    // A different cid was prepared (stale from a prior ring) — drop it.
    if (_preparedCall != null && _preparedCid != streamCallCid) {
      final old = _preparedCall;
      _preparedCall = null;
      _preparedCid = null;
      try { await old?.leave(); } catch (_) {}
    }
    // Capture the seq WITHOUT bumping it — prepare is not a join/accept.
    // If a real accept's join() (or a teardown) bumps _callSeq while our
    // getOrCreate is in flight, abandon so we don't fight the real call.
    final mySeq = _callSeq;
    try {
      await _ensureClient();
      if (mySeq != _callSeq) return;
      final client = _client;
      if (client == null) return;
      final parts = streamCallCid.split(':');
      final callType = parts.length > 1 ? parts[0] : 'default';
      final callId = parts.length > 1 ? parts[1] : streamCallCid;
      final call = client.makeCall(
        callType: StreamCallType.fromString(callType),
        id: callId,
      );
      final res = await call.getOrCreate(ringing: false, video: isVideo);
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return;
      }
      if (res.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] prepareIncoming getOrCreate failed: $res');
        return;
      }
      _preparedCall = call;
      _preparedCid = streamCallCid;
      // ignore: avoid_print
      print('[StreamCallEngine] prepared incoming call $streamCallCid '
          '(getOrCreate done during ring, not joined)');
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] prepareIncoming threw: $e');
    }
  }

  /// Drop a prepared-but-unjoined incoming call (callee rejected or the
  /// ring was withdrawn). Best-effort; iOS-only state, harmless no-op
  /// when nothing is prepared.
  Future<void> discardPrepared() async {
    final p = _preparedCall;
    _preparedCall = null;
    _preparedCid = null;
    if (p != null) {
      try { await p.leave(); } catch (_) {}
    }
  }

  Future<void> join({
    required String streamCallCid,
    required bool isVideo,
    // ── Stream ring-on-call wiring ───────────────────────────────
    // [calleeUserIds]: Stream user ids of everyone we want the SDK
    //   to RING when this call is created. Empty list means caller-
    //   only (no push will fire on anyone else). For a 1:1 call
    //   from A→B, pass `['10']`. For a group, pass every other
    //   participant.
    // [shouldRing]: create the Stream call with `ringing: true` so Stream
    //   fires its VoIP push to [calleeUserIds] — the push that lights the
    //   native CallKit / FCM ring header on a BACKGROUNDED / KILLED callee.
    //   The caller passes true on BOTH platforms; the callee side passes
    //   false (it's joining a call that already rang it). The iOS
    //   "connect cancelled" race that `ringing:true` used to trigger is
    //   neutralised by creating the caller's call with
    //   `dropIfAloneInRingingFlow: false` (see the makeCall below), NOT by
    //   dropping the ring.
    // [isOutgoing]: marks the caller's leg so the peer-joined fallback
    //   listener is attached. Defaults to [shouldRing] for back-compat;
    //   passed explicitly by the outgoing path for clarity.
    List<String> calleeUserIds = const [],
    bool shouldRing = true,
    bool? isOutgoing,
  }) async {
    final outgoing = isOutgoing ?? shouldRing;
    if (streamCallCid.isEmpty) return;
    // Stake our claim BEFORE any await — anything kicked off after
    // this call bumps the counter, so we'll see we've been superseded
    // at the next checkpoint and bail out. Bumping (instead of just
    // reading) also forces the prior in-flight join() to notice that
    // a newer one started.
    final mySeq = ++_callSeq;
    // Drop any stale in-flight ref from a prior attempt — this attempt
    // sets its own below once the Call is created.
    _inFlightCall = null;
    _callSetupInProgress = true;
    try {
      // CRITICAL: tear down any prior Stream call before starting a
      // new one. Stream's internal state can only host one active call
      // per client — joining a second one fires a "Disconnected:
      // Replaced" event on the previous one, and if that listener is
      // still wired up it'll bubble through `onStreamCallEnded` and
      // tear down our brand-new local signaling state for the NEW
      // call. Symptom: A taps Call, A's UI immediately ends with
      // "Call ended" even though B was never reached.
      if (_activeCall != null) {
        if (kDebugMode) {
          debugPrint('[StreamCallEngine] leaving prior Stream call '
              'before starting new one (cid=$streamCallCid)');
        }
        await leave();
      }
      if (mySeq != _callSeq) return; // superseded
      await _ensureClient();
      if (mySeq != _callSeq) return; // superseded
      final client = _client;
      if (client == null) return;

      // CID is `type:id` — split and feed both halves to the SDK.
      // Tolerant of a missing `:` (treat the whole string as the id
      // and use the default call type).
      final parts = streamCallCid.split(':');
      final callType = parts.length > 1 ? parts[0] : 'default';
      final callId = parts.length > 1 ? parts[1] : streamCallCid;

      // iOS fast-path: if this exact call was already `getOrCreate`d
      // during ringing ([prepareIncoming]), reuse that ref and skip the
      // coordinator round-trip here — only the SFU media connect remains
      // on the accept→audio path. Only for the non-ringing (callee) join;
      // the ringing caller path always creates fresh. Android never has a
      // prepared call, so it always takes the original makeCall path.
      final Call call;
      var skipGetOrCreate = false;
      if (!shouldRing &&
          _preparedCall != null &&
          _preparedCid == streamCallCid) {
        call = _preparedCall!;
        _preparedCall = null;
        _preparedCid = null;
        skipGetOrCreate = true;
        // ignore: avoid_print
        print('[StreamCallEngine] reusing prepared call $streamCallCid '
            '— skipping getOrCreate (warmed during ringing)');
      } else {
        call = client.makeCall(
          callType: StreamCallType.fromString(callType),
          id: callId,
        );
      }
      // Track as in-flight from the moment it exists: getOrCreate below
      // starts Stream's outgoing foreground-service notification, and a
      // reject can land before we promote this to _activeCall.
      _inFlightCall = call;
      if (!skipGetOrCreate) {
        // `ringing: true` tells Stream to push the VoIP notification to
        // every `memberId` — that's what lights up the full-screen
        // ringer on the callees' phones via the SDK's native
        // PushNotificationManager. Without this, Stream creates the
        // call silently and nobody else's phone ever rings.
        //
        // `ring` extends Stream's server-side ring timeouts from the
        // 30 s default to 60 s. Without this extension the call is
        // auto-cancelled on the coordinator before the callee has had
        // time to: (1) notice the CallKit notification, (2) tap it,
        // (3) the app wakes up, and (4) the accept POST round-trips.
        // On a backgrounded device that whole chain easily eats 20–30 s.
        // 60 s matches what most VoIP apps (WhatsApp, Telegram) use.
        // ignore: avoid_print
        print('[StreamCallEngine] getOrCreate(callId=$callId, '
            'members=$calleeUserIds, ringing=$shouldRing, ringTimeout=60s)');
        final getOrCreateResult = await call.getOrCreate(
          memberIds: calleeUserIds,
          ringing: shouldRing,
          video: isVideo,
          ring: const StreamRingSettings(
            autoCancelTimeout: Duration(seconds: 60),
            autoRejectTimeout: Duration(seconds: 60),
            missedCallTimeout: Duration(seconds: 60),
          ),
        );
        if (getOrCreateResult.isFailure) {
          // ignore: avoid_print
          print('[StreamCallEngine] getOrCreate FAILED: '
              '$getOrCreateResult — aborting join');
          try { await call.leave(); } catch (_) {}
          return;
        }
        // iOS-ONLY: `getOrCreate(ringing:true)` fired the VoIP push AND
        // registered this call as the SDK's "outgoing call". On iOS that
        // outgoing-call state machine cancels our in-flight `call.join()`
        // the instant the callee accepts → "connect cancelled", no audio.
        // The push is already sent (server-side), so detach the call from
        // the outgoing-call slot here: the callee still rings, but accept
        // can no longer cancel our join. Our CallSignalingService drives
        // the caller's ringing→connected UI, so Stream's outgoing-call
        // state is unused. Android is NOT touched.
        if (Platform.isIOS && shouldRing) {
          try {
            await client.state.setOutgoingCall(null);
            // ignore: avoid_print
            print('[StreamCallEngine] cleared SDK outgoing-call slot after '
                'ring (iOS) so accept cannot cancel the join');
          } catch (e) {
            // ignore: avoid_print
            print('[StreamCallEngine] setOutgoingCall(null) failed: $e');
          }
        }
      }
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return;
      }
      // Gate mic/camera on iOS so a declined permission becomes a disabled
      // track instead of a join failure that would cancel B's ring.
      final joinResult = await call.join(
        connectOptions: await _connectOptions(isVideo: isVideo),
      );
      if (joinResult.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] call.join FAILED on outgoing: '
            '$joinResult — A has no mic, B will hear silence');
        try { await call.leave(); } catch (_) {}
        return;
      }
      // ignore: avoid_print
      print('[StreamCallEngine] call.join OK on outgoing — '
          'setting _activeCall, mic should publish now');
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return;
      }
      // NOTE: We deliberately do NOT call _waitForCallSettled here.
      // For the OUTGOING caller path, Stream's call status only
      // transitions to Connected AFTER a remote participant joins —
      // which can't happen until the callee taps Accept (potentially
      // 30+ seconds after we placed the call). Waiting for Connected
      // here would always time out, we'd leave() our own call, our
      // mic would die, and when the callee finally joined they'd
      // hear silence because the caller already bowed out. Trust
      // that call.join() resolving means we're in the call as
      // participant; the `_attachPeerJoinedListener` handles the
      // moment the remote actually arrives. The settle-wait stays in
      // acceptByCid / acceptPendingIncoming because on those paths a
      // remote IS already in the call (the caller).
      _activeCall = call;
      _inFlightCall = null; // promoted — no longer "in flight"
      callNotifier.value = call;
      // Caller-side path only: watch for the first remote participant
      // to join so we can flip the chat-ceremony state to connected
      // even when the backend's `call.accept` STOMP broadcast never
      // reaches us. Keyed on [outgoing] (not [shouldRing]) so the iOS
      // caller — which now joins with shouldRing:false — still gets it.
      if (outgoing) {
        _attachPeerJoinedListener(call);
      }
      _attachEndListener(call);
      unawaited(_ensureMicPublishing(call));
      // iOS: re-apply the speaker route now that the ADM is up (the page
      // set it before this join finished — see [_reassertIosAudioRoute]).
      unawaited(_reassertIosAudioRoute());
      _consumePendingCallkitReassert(call);
      if (kDebugMode) {
        debugPrint(
          '[StreamCallEngine] joined cid=$streamCallCid '
          '(video=$isVideo) — Call ready for rendering',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('StreamCallEngine.join failed: $e\n$st');
      }
    } finally {
      _callSetupInProgress = false;
    }
  }

  /// Subscribe to [call.state] and fire [onStreamPeerJoined] the first
  /// time a non-local participant appears. Used on the caller's side
  /// as a fallback signal when the chat-ceremony backend fails to
  /// broadcast `call.accept` to us (its own ring timer fired before
  /// the callee tapped Accept, but the callee's media leg came up
  /// anyway via the Stream-only fallback). Single-fire: we cancel the
  /// subscription as soon as a peer is seen.
  void _attachPeerJoinedListener(Call call) {
    _peerJoinedSub?.cancel();
    _peerJoinedSub = call.state.valueStream.listen((s) {
      if (s.callParticipants.any((p) => !p.isLocal)) {
        // ignore: avoid_print
        print('[StreamCallEngine] remote peer joined the Stream call '
            '— firing onStreamPeerJoined');
        if (!_peerJoinedController.isClosed) {
          _peerJoinedController.add(null);
        }
        _peerJoinedSub?.cancel();
        _peerJoinedSub = null;
      }
    });
  }

  /// Accept a Stream call directly by its CID (e.g. from a CallKit
  /// notification accept event). Used when there's no
  /// `_pendingIncomingCall` to attach to — typically because the app
  /// was minimized (Stream WS was down) or killed (no Dart isolate
  /// running) when the ring push arrived.
  ///
  /// Reconnects the Stream client if needed, then `accept()` +
  /// `join()`. Stream reconciles the call state from the coordinator.
  Future<void> acceptByCid({
    required String callCid,
    required bool isVideo,
  }) async {
    if (callCid.isEmpty) return;
    // Claim this accept ONCE for the whole retry loop. Previously each
    // attempt re-bumped `_callSeq` inside `_doAcceptByCid`, which meant a
    // terminal teardown's `_callSeq` bump was immediately overwritten by
    // the next retry — so the loop happily re-joined a call that had
    // already ended, producing a ghost Stream call with no signaling
    // state (the second "stuck Connected"). Now the loop owns one seq and
    // aborts the instant anything else (a teardown via endActiveCall, or a
    // newer call) bumps `_callSeq` past it.
    final mySeq = ++_callSeq;
    // Retry on cold-start coordinator timeouts. The Stream SDK has a
    // hardcoded 5 s ceiling in CoordinatorClientOpenApi._waitUntilConnected
    // — on a CallKit-triggered cold-start the coordinator WS often
    // isn't ready in time and the FIRST call.join() resolves but then
    // the call asynchronously emits Disconnected{reason: Failure} via
    // a TimeoutException. By the 2nd attempt the WS is up and join
    // succeeds. Up to 3 attempts × 1 s back-off = ~3 s extra in the
    // worst case, but resolves the cold-start race transparently.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (mySeq != _callSeq) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptByCid superseded (call ended or a '
            'newer call started) — aborting before attempt $attempt');
        return;
      }
      final ok = await _doAcceptByCid(
        callCid: callCid,
        isVideo: isVideo,
        attempt: attempt,
        maxAttempts: maxAttempts,
        mySeq: mySeq,
      );
      if (ok) return;
      if (mySeq != _callSeq) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptByCid superseded after attempt '
            '$attempt — not retrying');
        return;
      }
      if (attempt < maxAttempts) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptByCid attempt $attempt failed '
            '— retrying after 1 s');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    // ignore: avoid_print
    print('[StreamCallEngine] acceptByCid exhausted $maxAttempts '
        'attempts for cid=$callCid');
  }

  /// Single attempt of acceptByCid. Returns true if the accept + join
  /// succeeded AND the call reached a Connected/Joined state within
  /// 6 s. Returns false on cold-start timeout, network failure, or
  /// when superseded by a newer invocation.
  Future<bool> _doAcceptByCid({
    required String callCid,
    required bool isVideo,
    required int attempt,
    required int maxAttempts,
    required int mySeq,
  }) async {
    // NOTE: do NOT bump `_callSeq` here — the seq is claimed once by the
    // [acceptByCid] loop and passed in, so a terminal teardown can abort
    // every retry. Bumping per-attempt was the ghost-call bug.
    try {
      // Same protection as join(): tear down any prior Stream call so
      // Stream's "Replaced" disconnect on the OLD call doesn't fire
      // through onStreamCallEnded and kill our NEW signaling state.
      if (_activeCall != null) {
        if (kDebugMode) {
          debugPrint('[StreamCallEngine] acceptByCid: leaving prior '
              'Stream call before accepting new one (cid=$callCid)');
        }
        await leave();
      }
      if (mySeq != _callSeq) return true; // superseded — caller stops too
      await _ensureClient();
      if (mySeq != _callSeq) return true;
      final client = _client;
      if (client == null) return false;
      final parts = callCid.split(':');
      final callType = parts.length > 1 ? parts[0] : 'default';
      final callId = parts.length > 1 ? parts[1] : callCid;
      // ignore: avoid_print
      print('[StreamCallEngine] acceptByCid attempt $attempt/$maxAttempts: '
          '$callCid (type=$callType id=$callId)');

      // CRITICAL: Stream's `Call.accept()` only works on a Call ref
      // that's in `Incoming` state. A fresh ref from `client.makeCall`
      // starts in `Idle` — accept() fails with "invalid status: Idle".
      // The proper Incoming Call ref comes from Stream's
      // `state.incomingCall` (populated when the WS receives the ring
      // push). On cold-start the WS connect we just awaited might not
      // have delivered that event yet — wait briefly for it to land
      // and use it if it does. Falls through to the makeCall path only
      // if Stream still hasn't surfaced the call after 3 s (in which
      // case the accept WILL fail, but we tried).
      final waited = await _waitForPendingIncoming(callCid,
          timeout: const Duration(seconds: 3));
      if (mySeq != _callSeq) return true;
      if (waited != null) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptByCid attempt $attempt: '
            'using Stream-provided incoming Call ref (cid=${waited.callCid}) '
            'instead of fresh makeCall — accept will succeed');
        return _acceptOnCallRef(waited, isVideo: isVideo, mySeq: mySeq,
            attemptLabel: 'attempt $attempt');
      }
      // No pending incoming — Stream's WS connected after the ring
      // already happened via FCM, and the coordinator doesn't replay
      // missed ring events on reconnect, so `state.incomingCall`
      // never populates.
      //
      // Use Stream's documented `consumeIncomingCall(uuid, cid)` —
      // it calls `_client.getCall(cid)` internally then constructs
      // the Call via `_makeCallFromRinging(data, ...)` which yields
      // a Call ref in proper Incoming state. This is what the SDK
      // intends for CallKit-fired accepts where state.incomingCall
      // wasn't populated by a live WS event.
      // ignore: avoid_print
      print('[StreamCallEngine] acceptByCid attempt $attempt: '
          'no pending incoming Call — using consumeIncomingCall to '
          'fetch a proper Incoming Call ref');
      final consumeResult = await client.consumeIncomingCall(
        uuid: callCid, // any unique id; CID itself works
        cid: callCid,
      );
      if (consumeResult.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptByCid attempt $attempt: '
            'consumeIncomingCall FAILED: $consumeResult');
        return false;
      }
      if (mySeq != _callSeq) return true;
      final call = (consumeResult as Success<Call>).data;
      // ignore: avoid_print
      print('[StreamCallEngine] acceptByCid attempt $attempt: '
          'consumeIncomingCall returned Call ref · routing through '
          '_acceptOnCallRef for accept+join');
      return _acceptOnCallRef(call,
          isVideo: isVideo, mySeq: mySeq,
          attemptLabel: 'attempt $attempt (consumed)');
    } catch (e, st) {
      // ignore: avoid_print
      print('[StreamCallEngine] acceptByCid attempt $attempt threw: $e\n$st');
      return false;
    }
  }

  /// Poll [_pendingIncomingCall] for up to [timeout] looking for a
  /// Call ref whose CID matches [expectedCid]. Returns the Call if
  /// found, null if it never arrives within the window.
  ///
  /// Used by [acceptByCid] on cold-start: after `_ensureClient`
  /// connects the Stream WS, the coordinator may take a couple of
  /// seconds to deliver the incoming-call event that populates
  /// `state.incomingCall`. Calling `.accept()` on a fresh
  /// `client.makeCall(id)` ref before that happens fails with
  /// "invalid status: Idle" because the fresh ref starts in Idle —
  /// only the Stream-provided ref is in Incoming state.
  Future<Call?> _waitForPendingIncoming(
    String expectedCid, {
    required Duration timeout,
  }) async {
    // Fast path: already populated.
    final existing = _pendingIncomingCall;
    if (existing != null && existing.callCid.value == expectedCid) {
      return existing;
    }
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
      final current = _pendingIncomingCall;
      if (current != null && current.callCid.value == expectedCid) {
        return current;
      }
    }
    return null;
  }

  /// Shared accept-and-join body. Called from both acceptByCid (when
  /// it got a Stream-provided Call ref via _waitForPendingIncoming)
  /// and could be called from acceptPendingIncoming. Encapsulates the
  /// accept + join + settle-wait + listener attachment so the retry
  /// loop in acceptByCid doesn't need two near-identical code paths.
  Future<bool> _acceptOnCallRef(
    Call call, {
    required bool isVideo,
    required int mySeq,
    required String attemptLabel,
  }) async {
    try {
      final acceptResult = await call.accept();
      if (acceptResult.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] $attemptLabel: call.accept on '
            'Stream-provided ref FAILED: $acceptResult');
        try { await call.leave(); } catch (_) {}
        return false;
      }
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return true;
      }
      final joinResult = await call.join(
        connectOptions: await _connectOptions(isVideo: isVideo),
      );
      if (joinResult.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] $attemptLabel: call.join on '
            'Stream-provided ref FAILED: $joinResult');
        try { await call.leave(); } catch (_) {}
        return false;
      }
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return true;
      }
      final settled = await _waitForCallSettled(call);
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return true;
      }
      if (!settled) {
        // ignore: avoid_print
        print('[StreamCallEngine] $attemptLabel: Stream-provided ref '
            'did NOT settle to Connected — leaving and bailing');
        try { await call.leave(); } catch (_) {}
        return false;
      }
      _activeCall = call;
      callNotifier.value = call;
      _pendingIncomingCall = null;
      _attachEndListener(call);
      unawaited(_ensureMicPublishing(call));
      unawaited(_reassertIosAudioRoute());
      _consumePendingCallkitReassert(call);
      // ignore: avoid_print
      print('[StreamCallEngine] $attemptLabel: accept+join OK on '
          'Stream-provided ref — media leg up');
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('[StreamCallEngine] $attemptLabel: _acceptOnCallRef threw: '
          '$e\n$st');
      return false;
    }
  }

  /// Wait up to 6 s for [call] to reach a steady Connected/Joined
  /// state. Returns false if the call hits Disconnected first or the
  /// 6 s window expires without success — signal to the caller that
  /// this attempt should be retried (typically the Stream SDK's
  /// cold-start coordinator timeout firing asynchronously).
  Future<bool> _waitForCallSettled(Call call) async {
    final completer = Completer<bool>();
    StreamSubscription<CallState>? sub;
    final timer = Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) completer.complete(false);
    });
    sub = call.state.valueStream.listen((s) {
      final status = s.status;
      // Treat Joined / Connected as success.
      if (status is CallStatusConnected || status is CallStatusJoined) {
        if (!completer.isCompleted) completer.complete(true);
      } else if (status is CallStatusDisconnected ||
          status is CallStatusReconnectionFailed) {
        if (!completer.isCompleted) completer.complete(false);
      }
    });
    final result = await completer.future;
    timer.cancel();
    await sub.cancel();
    return result;
  }

  /// Reject a Stream call by its CID (CallKit decline path).
  Future<void> rejectByCid({required String callCid}) async {
    if (callCid.isEmpty) return;
    try {
      await _ensureClient();
      final client = _client;
      if (client == null) return;
      final parts = callCid.split(':');
      final callType = parts.length > 1 ? parts[0] : 'default';
      final callId = parts.length > 1 ? parts[1] : callCid;
      final call = client.makeCall(
        callType: StreamCallType.fromString(callType),
        id: callId,
      );
      // ignore: avoid_print
      print('[StreamCallEngine] rejectByCid: $callCid');
      await call.reject();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[StreamCallEngine] rejectByCid failed: $e\n$st');
      }
    }
  }

  /// Accept the currently-pending incoming Stream call (the one
  /// surfaced via `onStreamIncomingCall`). MUST be called on the SAME
  /// `Call` instance Stream gave us — `client.makeCall(id)` returns
  /// a fresh reference that hasn't gone through ringing-acceptance,
  /// so `accept()` on a fresh ref would fail and audio wouldn't flow.
  ///
  /// Returns true when the accept succeeded and the call is live;
  /// false on any bail-out path (no pending ref, CID mismatch,
  /// superseded by a newer call attempt, accept/join threw). The
  /// caller uses this to decide whether to fall back to acceptByCid
  /// — WITHOUT this signal the caller used to check
  /// `hasPendingIncoming` which becomes false on BOTH success and
  /// bail, making it impossible to tell the two apart, so it would
  /// always re-run acceptByCid and tear down the just-connected call.
  Future<bool> acceptPendingIncoming({
    required bool isVideo,
    String? expectedCid,
  }) async {
    final call = _pendingIncomingCall;
    if (call == null) {
      // ignore: avoid_print
      print('[StreamCallEngine] acceptPendingIncoming: no pending call');
      return false;
    }
    // Guard against stale references: a Stream WS push from a PRIOR
    // call may have left _pendingIncomingCall set with the wrong CID.
    // If the caller knows which call they want to accept, verify the
    // pending one matches. Mismatch → bail out so caller's fallback
    // (`acceptByCid` with the explicit CID) runs instead.
    if (expectedCid != null &&
        expectedCid.isNotEmpty &&
        call.callCid.value != expectedCid) {
      // ignore: avoid_print
      print('[StreamCallEngine] acceptPendingIncoming: CID mismatch — '
          'pending=${call.callCid.value} expected=$expectedCid — '
          'clearing stale ref so caller falls back to acceptByCid');
      _pendingIncomingCall = null;
      return false;
    }
    final mySeq = ++_callSeq;
    _callSetupInProgress = true;
    try {
      if (_activeCall != null) {
        await leave();
      }
      if (mySeq != _callSeq) return false;
      // ignore: avoid_print
      print('[StreamCallEngine] accept() on incoming call ${call.callCid}');
      final acceptResult = await call.accept();
      if (acceptResult.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptPendingIncoming: '
            'call.accept FAILED: $acceptResult');
        try { await call.leave(); } catch (_) {}
        return false;
      }
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return false;
      }
      final joinResult = await call.join(
        connectOptions: await _connectOptions(isVideo: isVideo),
      );
      if (joinResult.isFailure) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptPendingIncoming: '
            'call.join FAILED: $joinResult');
        try { await call.leave(); } catch (_) {}
        return false;
      }
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return false;
      }
      // Wait for the call to actually settle to Connected/Joined.
      // Same cold-start coordinator race as acceptByCid — call.join()
      // resolves before the coordinator confirms, and on a fresh WS
      // (B was minimized, so disconnectForBackground had dropped it)
      // _waitUntilConnected can time out 5 s later → call drops →
      // both A and B end up with no audio.
      final settled = await _waitForCallSettled(call);
      if (mySeq != _callSeq) {
        try { await call.leave(); } catch (_) {}
        return false;
      }
      if (!settled) {
        // ignore: avoid_print
        print('[StreamCallEngine] acceptPendingIncoming: call did NOT '
            'settle to Connected — leaving so caller can retry via '
            'acceptByCid (which has its own retry loop)');
        try { await call.leave(); } catch (_) {}
        // Also clear _pendingIncomingCall so the caller's fallback
        // doesn't loop back into acceptPendingIncoming.
        _pendingIncomingCall = null;
        return false;
      }
      _activeCall = call;
      callNotifier.value = call;
      _pendingIncomingCall = null;
      _attachEndListener(call);
      // iOS-ONLY: force the local mic to publish on this FOREGROUND
      // in-app accept path (B was on-screen when A called, so Stream's
      // WS delivered the ring and `hasPendingIncoming` was true).
      // Without this the connect-options "microphone: enabled" intent
      // sometimes doesn't actually publish a track (SFU shows
      // publishesAudio=false) → the caller hears silence from B. The
      // other two accept/join paths (`join`, `_acceptOnCallRef`) already
      // do this; this was the one that missed it. Guarded to iOS so
      // Android's working call flow is left exactly as before.
      if (Platform.isIOS) {
        unawaited(_ensureMicPublishing(call));
        unawaited(_reassertIosAudioRoute());
        _consumePendingCallkitReassert(call);
      }
      // ignore: avoid_print
      print('[StreamCallEngine] accept+join OK — media leg up');
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[StreamCallEngine] acceptPendingIncoming failed: $e\n$st');
      }
      return false;
    } finally {
      _callSetupInProgress = false;
    }
  }

  /// Reject the currently-pending incoming Stream call.
  Future<void> rejectPendingIncoming() async {
    final call = _pendingIncomingCall;
    if (call == null) return;
    try {
      await call.reject();
      _pendingIncomingCall = null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[StreamCallEngine] rejectPendingIncoming failed: $e\n$st');
      }
    }
  }

  /// Subscribe to [call.state] so we detect Stream-side end events
  /// (peer hung up, network disconnect, etc.) and surface them
  /// through [onStreamCallEnded] for the signaling layer to pop the
  /// local UI. Only one active subscription at a time — replaces the
  /// previous one so we don't fan out duplicate end events when a new
  /// call comes in.
  void _attachEndListener(Call call) {
    _activeStateSub?.cancel();
    // Track whether a remote peer has EVER been present on this call.
    // Once one has, their later disappearance means "the other party
    // left" — which for a connected 1:1 is the ONLY end-signal we get:
    // Stream keeps OUR call alive when the peer leaves (it never fires a
    // Disconnected for us), and on a killed-app cold-start accept the
    // STOMP `call.hangup` may never reach us (socket not subscribed in
    // time). Watching the participant list works purely off the media
    // layer we DID join, so it survives all of that.
    var sawRemoteParticipant = false;
    _activeStateSub = call.state.valueStream.listen((s) {
      // Defence-in-depth: only fire `onStreamCallEnded` when the
      // disconnect is for our CURRENT active call. If `_activeCall`
      // has been swapped for a newer Call ref (e.g. by a back-to-back
      // call attempt that won the latest-wins race in join()), the
      // old call's disconnect event arriving late on this subscription
      // must NOT bubble through — it would tear down the NEW call's
      // local signaling state.
      if (_activeCall != call) return;

      final status = s.status;

      // Remote-participant-left detection (peer hung up / left the call).
      // Fires only AFTER a remote was seen, so the transient "no remote
      // yet" window during our own join doesn't trip it; and only while
      // WE are solidly connected/joined, so a reconnect blip that
      // momentarily clears the participant list doesn't read as a leave.
      // For groups this only fires when the LAST remote leaves (call
      // emptied) — matching the last-person-out semantics.
      final hasRemote = s.callParticipants.any((p) => !p.isLocal);
      if (hasRemote) {
        sawRemoteParticipant = true;
      } else if (sawRemoteParticipant &&
          (status is CallStatusConnected || status is CallStatusJoined)) {
        // ignore: avoid_print
        print('[StreamCallEngine] remote participant left (call emptied) '
            '— firing onStreamCallEnded');
        if (!_callEndedController.isClosed) {
          _callEndedController.add(StreamCallEndReason.remoteLeft);
        }
        return;
      }
      if (status is CallStatusDisconnected) {
        final reason = status.reason;
        // Filter out reasons that are NOT real "the call ended"
        // signals. Stream emits Disconnected for several lifecycle
        // events that aren't actual hangups:
        //   * Replaced — another call took our slot (handled via
        //     latest-wins guards in join()/acceptByCid; if a stale
        //     listener does emit it, ignore here too)
        //   * Reconnection states sometimes pass through Disconnected
        //     transiently before recovering — but those are
        //     CallStatusReconnecting, not Disconnected, so they don't
        //     hit this branch
        final reasonStr = reason.toString().toLowerCase();
        final isReplaced = reasonStr.contains('replaced');
        // ignore: avoid_print
        print('[StreamCallEngine] Stream Disconnected · '
            'reason=$reason · isReplaced=$isReplaced · '
            'firing-end-event=${!isReplaced}');
        if (isReplaced) return;
        if (!_callEndedController.isClosed) {
          _callEndedController.add(StreamCallEndReason.disconnected);
        }
      } else if (status is CallStatusReconnectionFailed) {
        // ignore: avoid_print
        print('[StreamCallEngine] Stream call ReconnectionFailed — '
            'firing onStreamCallEnded');
        if (!_callEndedController.isClosed) {
          _callEndedController.add(StreamCallEndReason.reconnectFailed);
        }
      } else {
        // Log every other state transition so we can see the call's
        // lifecycle (Joining → Joined → Connected → ...) and spot any
        // unexpected transitions that lead to a teardown.
        // ignore: avoid_print
        print('[StreamCallEngine] Stream state transition · status=$status');
      }
    });
  }

  /// Eagerly connect the Stream client so the SDK's
  /// [PushNotificationManager.registerDevice] runs against this
  /// user's identity — without it, Stream's backend has no FCM token
  /// recorded for this user and `call.getOrCreate({ring: true})` from
  /// the caller side silently drops the ring.
  ///
  /// Call this from the auth login path AND from the cold-start auto-
  /// login path. Safe to call repeatedly — `_ensureClient` short-
  /// circuits when the client is already live for the same userId.
  /// Failures (token fetch 401, network) are swallowed inside
  /// `_ensureClient`; this is best-effort.
  Future<void> warmUp() async {
    // Unconditional print so this also fires in release while we
    // triangulate the ring-not-arriving bug. Re-gate once confirmed.
    // ignore: avoid_print
    print('[StreamCallEngine] warmUp() invoked');
    // iOS "2nd call to a killed+locked callee: no ring" fix.
    //
    // A VoIP push wakes a killed app into a BACKGROUND process (the native
    // CallKit ring shows on the lock screen, the Flutter isolate boots behind
    // it). Splash → `markAuthenticated()` flips AuthSession false→true, which
    // fires the cold-start `warmUp()` (see `_wireStreamWarmUpToAuth`). If that
    // CONNECTS the Stream WS, this device becomes ONLINE to Stream — so the
    // NEXT call's ring is delivered over the WS (which a backgrounded/locked
    // app cannot render) instead of the APNs VoIP push that raises the native
    // CallKit screen. Net effect: the 1st call rings (truly killed → offline),
    // the 2nd does not (alive-in-background → online).
    //
    // So warmUp must connect ONLY when the app is genuinely on screen AND the
    // device is UNLOCKED — i.e. the in-app overlay can actually be shown. The
    // call paths that legitimately need a connection while backgrounded
    // (accepting a ring) go through `_ensureClient` ON DEMAND, NOT warmUp, so
    // they are unaffected; the resume handler calls warmUp when foreground, so
    // the WS comes back the moment the user opens the app. We keep the push
    // device registered (no `StreamVideo.reset`), so the genuinely-killed case
    // still rings. iOS-only — Android keeps its existing eager warm-up.
    //
    // The UNLOCK check (case #4): after B ACCEPTS a call from the LOCK SCREEN,
    // CallKit activates the app process, so `isAppForeground` reads true even
    // though the user never unlocked. When that call ends, the lifecycle
    // `resumed` + auth-transition both fire `warmUp()`; if it reconnected the
    // Stream WS there, B would be ONLINE again and the next call would ring
    // over the (invisible-on-a-locked-device) WS instead of the VoIP push.
    // Treating a locked device as "do not connect" keeps the push route armed.
    if (Platform.isIOS && !(await _appForeground() && await _deviceUnlocked())) {
      // ignore: avoid_print
      print('[StreamCallEngine] warmUp() SKIPPED — app backgrounded or device '
          'locked; staying offline to Stream so the next call rings via the '
          'VoIP push (accept still connects on demand via _ensureClient)');
      return;
    }
    await _ensureClient();
  }

  /// iOS genuine-foreground probe (native `isAppForeground` flag set in
  /// AppDelegate on real `didBecomeActive` / `didEnterBackground`). True only
  /// when the app is actually on screen; false for a killed/minimized/locked
  /// cold-start. Defaults to FALSE on any channel error (the safe "we're not
  /// confirmed foreground, so don't connect the Stream WS" answer). Mirrors
  /// `CallSignalingService._appForeground`. Non-iOS always returns true.
  static const MethodChannel _iosCallkitChannel =
      MethodChannel('erp/ios_callkit');
  Future<bool> _appForeground() async {
    if (!Platform.isIOS) return true;
    try {
      final v = await _iosCallkitChannel.invokeMethod<bool>('isAppForeground');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// iOS device-unlock probe (native `isDeviceUnlocked` →
  /// `UIApplication.isProtectedDataAvailable`). True when unlocked, false once
  /// locked. Paired with [_appForeground] so a lock-screen CallKit accept —
  /// which makes the app read "foreground" — is still treated as "do not
  /// connect the Stream WS" (case #4). Defaults to FALSE on channel error
  /// (safe "treat as locked → stay offline so the next call rings via push").
  Future<bool> _deviceUnlocked() async {
    if (!Platform.isIOS) return true;
    try {
      final v = await _iosCallkitChannel.invokeMethod<bool>('isDeviceUnlocked');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Disconnect Stream's WebSocket (but keep cached identity) when
  /// the app goes to background, IF there's no active call. Why:
  /// Stream prefers WS over FCM when a client is "online" — so a
  /// minimized peer with a live WS gets the incoming-call event in-
  /// process where we can't render UI (the app isn't visible). By
  /// dropping the WS on pause, we force Stream to use the FCM push
  /// path, which `flutter_callkit_incoming` renders as a native
  /// full-screen ringer. Reconnect on resume via [warmUp].
  ///
  /// Skipped during an active call so the audio leg isn't torn down
  /// when the user briefly backgrounds the app mid-conversation.
  ///
  /// [force] (iOS-only) is set by callers that KNOW the call is over
  /// (signaling has no active call). It bypasses the in-flight-setup /
  /// active-call guards below so a STALE `_callSetupInProgress` /
  /// `_inFlightCall` / `_activeCall` left over from a just-ended call
  /// can't keep the WS warm — which is what made the 2nd call to a
  /// minimized callee ring over WS (no native CallKit header) instead of
  /// via an APNs VoIP push. Honoured on iOS only; Android's background
  /// path (which never sets the iOS flag) is unchanged regardless.
  Future<void> disconnectForBackground({bool force = false}) async {
    final forced = force && Platform.isIOS;
    // Detect a STALE _activeCall: if the underlying Stream call is
    // already in a disconnected state, the reference is leftover from
    // a previous ended call. Clear it eagerly so the next minimize
    // doesn't get blocked by the leak (symptom: subsequent A→B calls
    // come in over WS we can't render → A times out → "missed call").
    final stale = _activeCall;
    if (stale != null) {
      final status = stale.state.valueOrNull?.status;
      final isLive = !(status is CallStatusDisconnected ||
          status is CallStatusReconnectionFailed ||
          status is CallStatusIdle);
      if (!isLive) {
        // ignore: avoid_print
        print('[StreamCallEngine] disconnectForBackground: '
            'stale _activeCall found (status=$status) — clearing');
        try {
          await stale.leave();
        } catch (_) {}
        _activeCall = null;
        callNotifier.value = null;
      }
    }
    // iOS: a call is mid-setup (outgoing join / in-app accept) but not
    // yet promoted to _activeCall. Dropping the Stream WS now cancels
    // the in-flight `call.join()` ("connect cancelled"), so the caller
    // never enters the call and BOTH sides hear silence — the reported
    // bug. Treat setup-in-progress like an active call and keep the
    // socket up. Android is untouched: it never sets the flag here.
    if (!forced &&
        Platform.isIOS &&
        (_callSetupInProgress || _inFlightCall != null)) {
      // ignore: avoid_print
      print('[StreamCallEngine] disconnectForBackground: skipped '
          '(call setup in flight — keeping Stream WS alive)');
      return;
    }
    if (!forced && _activeCall != null) {
      // ignore: avoid_print
      print('[StreamCallEngine] disconnectForBackground: skipped '
          '(active call in flight, audio must stay alive)');
      return;
    }
    // Forced path: the caller guarantees the signaling call is over, so
    // any leftover setup flags / call refs are stale. Clear them and drop
    // the leftover Stream leg (if one lingered) so the socket can close —
    // otherwise the guards above would have kept the WS warm and the next
    // incoming call would ring over WS (invisible while minimized).
    if (forced) {
      _callSetupInProgress = false;
      if (_activeCall != null || _inFlightCall != null) {
        // ignore: avoid_print
        print('[StreamCallEngine] disconnectForBackground: forced — '
            'leaving a lingering call ref before dropping WS');
        try {
          await leave();
        } catch (_) {}
      }
    }
    final client = _client;
    if (client == null) return;
    // Snapshot the token BEFORE we null our state below so the re-register
    // (which runs after disconnect) still has credentials.
    final apiKey = _lastApiKey ?? '';
    final streamToken = _lastStreamToken ?? '';
    try {
      // ignore: avoid_print
      print('[StreamCallEngine] disconnectForBackground: dropping WS '
          'so Stream falls back to FCM/APNs push for incoming calls');
      await _incomingCallSub?.cancel();
      _incomingCallSub = null;
      // `disconnect()` drops the WebSocket so Stream's coordinator marks this
      // device offline → the next call rings via the APNs VoIP push, not the
      // (invisible-while-backgrounded) WS event. Guard with a timeout: its
      // internal `disconnectUser()` can stall while the WS is torn down, and
      // we must not block the re-register that has to follow.
      await client.disconnect().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          // ignore: avoid_print
          print('[StreamCallEngine] disconnectForBackground: disconnect() '
              'timed out after 4s — proceeding to re-register the device');
          return const Result.success(none);
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] disconnectForBackground failed: $e');
    }
    // Null out so the next `warmUp` triggers a fresh _ensureClient
    // (re-fetch /stream-token, rebuild StreamVideo, reattach the
    // incoming-call listener). One extra HTTP per resume — acceptable.
    _client = null;
    _clientUserId = null;
    _clientUserName = null;
    _pendingIncomingCall = null;
    // CRITICAL ("answered call ends → next call to a killed+locked callee shows
    // no ring"): `disconnect()` above internally runs `unregisterDevice()` →
    // server-side `deleteDevice()` (stream_video `_disconnect`). That REMOVES
    // this device from Stream — so with the WS also down, Stream has NO route
    // left to deliver the next call and it never rings. We want the WS DOWN but
    // the device KEPT; the SDK bundles both into disconnect() and doesn't
    // expose its internal closeConnection(). So we RE-ADD the apn/VoIP device
    // here — OUTSIDE the try above so a disconnect throw/timeout can't skip it —
    // via a direct REST call (no WS needed). iOS-only.
    if (Platform.isIOS) {
      await _reregisterApnDeviceAfterDisconnect(
        apiKey: apiKey,
        streamToken: streamToken,
      );
    }
  }

  /// Re-register the apn/VoIP push device that [StreamVideo.disconnect] just
  /// deleted server-side (its `unregisterDevice()` → `deleteDevice()`), so a
  /// backgrounded/locked callee can still receive the NEXT call's VoIP push
  /// while its WebSocket stays down.
  ///
  /// We do NOT use the SDK's `addDevice` here: its `createDevice` first runs
  /// `_waitUntilConnected`, which TIMES OUT (5 s) because we just dropped the
  /// WS — the exact failure seen in the field. Instead we POST directly to
  /// Stream's coordinator REST device endpoint, which only needs the api key +
  /// user token (no WS). This mirrors `CoordinatorClientOpenApi.createDevice`:
  ///   POST https://video.stream-io-api.com/video/devices?api_key=<key>
  ///   headers: stream-auth-type: jwt · Authorization: <token>
  ///   body:    {id, push_provider: apn, push_provider_name: apn, voip_token}
  /// Best-effort; iOS-only. No-op when the PushKit VoIP token isn't available
  /// yet (the next foreground/accept `_ensureApnDeviceRegistered` recovers it).
  Future<void> _reregisterApnDeviceAfterDisconnect({
    required String apiKey,
    required String streamToken,
  }) async {
    if (!Platform.isIOS) return;
    try {
      final voip =
          (await FlutterCallkitIncoming.getDevicePushTokenVoIP())?.toString() ??
              '';
      if (voip.isEmpty) {
        // ignore: avoid_print
        print('[StreamCallEngine] re-register apn after disconnect SKIPPED — '
            'no VoIP token yet (next connect will register it)');
        return;
      }
      // Use the cached apiKey/token captured at client-build time. Fall back to
      // a fresh `/stream-token` fetch only if the cache is empty — a REST call
      // to our backend, independent of the Stream WS we just closed.
      var key = apiKey;
      var token = streamToken;
      if (key.isEmpty || token.isEmpty) {
        final tokenJson = await remote.getStreamToken();
        key = tokenJson['apiKey']?.toString() ?? '';
        token = tokenJson['token']?.toString() ?? '';
      }
      if (key.isEmpty || token.isEmpty) {
        // ignore: avoid_print
        print('[StreamCallEngine] re-register apn after disconnect SKIPPED — '
            'no stream token');
        return;
      }
      final dio = Dio(BaseOptions(
        baseUrl: 'https://video.stream-io-api.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: <String, dynamic>{
          'stream-auth-type': 'jwt',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      ));
      final res = await dio.post<dynamic>(
        '/video/devices',
        queryParameters: <String, dynamic>{'api_key': key},
        data: <String, dynamic>{
          'id': voip,
          'push_provider': 'apn',
          'push_provider_name': 'apn',
          'voip_token': true,
        },
      );
      // ignore: avoid_print
      print('[StreamCallEngine] re-registered apn device after disconnect via '
          'direct REST (keeps VoIP push alive while offline) → '
          'HTTP ${res.statusCode}');
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] re-register apn after disconnect '
          '(direct REST) threw: $e');
    }
  }

  /// Leave the active Stream call (if any) and clear the cached
  /// handle. Safe to call multiple times. Does NOT tear down the
  /// shared client — that stays for the next call.
  /// TERMINAL teardown — call this (not [leave]) when the call is
  /// actually ending (hangup / reject / peer-hangup). It bumps
  /// `_callSeq` FIRST so any in-flight `join()` / `acceptByCid()` /
  /// `acceptPendingIncoming()` sees `mySeq != _callSeq` at its next
  /// checkpoint and abandons (leaving its half-joined ref) instead of
  /// finishing and re-publishing the mic AFTER we tore down — the
  /// minimize→accept→end audio leak.
  ///
  /// MUST NOT be used for the transitional teardown inside
  /// join()/acceptByCid() ("leave the prior call before starting a new
  /// one") — those captured their own `mySeq` just before and a bump
  /// here would make them self-abort. They call [leave] (no bump).
  Future<void> endActiveCall() async {
    ++_callSeq;
    await leave();
  }

  /// Cancel an UNANSWERED outgoing call for EVERYONE on Stream's side.
  ///
  /// A plain [leave] / [endActiveCall] only drops OUR media leg — it does
  /// NOT tell Stream's coordinator that the ring is cancelled. So a callee
  /// that received the ring via push (minimized / killed iOS → native
  /// CallKit screen) keeps ringing until Stream's ~30 s ring timeout. That
  /// is the "D's native ring won't end when C hangs up" bug: while D is
  /// backgrounded its STOMP + Stream WS are both down, so the only thing
  /// that can dismiss the ring is Stream itself broadcasting the cancel.
  ///
  /// `reject(reason: cancel)` is the SDK's own cancel-outgoing path (see
  /// `Call.accept` → `outgoingCall.reject(CallRejectReason.cancel())`): the
  /// coordinator emits `call.rejected` to every member, which cancels the
  /// ring and makes the callee's CallKit auto-dismiss — no extra cancel
  /// push needed. Unlike [Call.end] it has no `CallStatusActive`
  /// requirement, so it works for a still-ringing call.
  ///
  /// Best-effort: always falls through to the normal [leave] teardown so
  /// our own leg / foreground service is freed even if the reject fails.
  Future<void> cancelOutgoingRing() async {
    ++_callSeq;
    // Grab the ref synchronously (before any await) so a concurrent
    // teardown can't null out `_activeCall` before we reject on it.
    final call = _activeCall ?? _inFlightCall ?? _preparedCall;
    if (call != null) {
      try {
        final res = await call.reject(reason: CallRejectReason.cancel());
        // ignore: avoid_print
        print('[StreamCallEngine] cancelOutgoingRing() · reject(cancel) → '
            '$res for ${call.callCid.value} — ring cancelled for all members');
      } catch (e) {
        // ignore: avoid_print
        print('[StreamCallEngine] cancelOutgoingRing() · reject(cancel) '
            'FAILED (${call.callCid.value}): $e — falling back to leave()');
      }
    }
    await leave();
  }

  Future<void> leave() async {
    final call = _activeCall;
    // Capture + clear the in-flight ref up front so a call that's still
    // mid-`join()` (callee rejected while A was "Connecting…") gets its
    // Stream foreground-service notification stopped too — `call.leave()`
    // is the only thing that dismisses it, and `_activeCall` is null at
    // that point.
    final inflight = _inFlightCall;
    _inFlightCall = null;
    // Drop any prepared-but-unjoined incoming call (iOS warm-up) that
    // wasn't consumed by a join — unless join already promoted it to the
    // active/in-flight ref (in which case it's handled below).
    final prepared = _preparedCall;
    _preparedCall = null;
    _preparedCid = null;
    if (prepared != null &&
        !identical(prepared, call) &&
        !identical(prepared, inflight)) {
      try { await prepared.leave(); } catch (_) {/* never joined */}
    }
    if (inflight != null && !identical(inflight, call)) {
      // ignore: avoid_print
      print('[StreamCallEngine] leave() · also leaving in-flight call '
          '${inflight.callCid.value} (connecting when teardown hit)');
      try {
        await inflight.leave();
      } catch (_) {/* already gone / never fully created */}
      await _stopCallForegroundService(inflight.callCid.value);
    }
    // Diagnostic (unconditional, release-visible) — proves whether a
    // teardown actually reached a live Call ref. If this logs
    // `activeCall=null` right after an End, the media leg we're hearing
    // was never tracked in `_activeCall` (double-join or in-flight
    // accept that finished after we cleared it).
    // ignore: avoid_print
    print('[StreamCallEngine] leave() ENTER · '
        'activeCall=${call?.callCid.value ?? "null"} · seq=$_callSeq');
    _activeCall = null;
    callNotifier.value = null;
    await _peerJoinedSub?.cancel();
    _peerJoinedSub = null;
    // CRITICAL: cancel the end-listener too. Without this, when we
    // leave THIS call and start a NEW one, Stream emits a "Replaced"
    // disconnect on the old call after our cancellation but before
    // its Future completes — the still-attached listener pushes it
    // into onStreamCallEnded and kills the brand-new call's state.
    await _activeStateSub?.cancel();
    _activeStateSub = null;
    if (call == null) {
      // ignore: avoid_print
      print('[StreamCallEngine] leave() · no active call ref to leave — '
          'if audio is still flowing, the live call was NOT tracked here');
      return;
    }
    try {
      await call.leave();
      // ignore: avoid_print
      print('[StreamCallEngine] leave() · call.leave() OK for '
          '${call.callCid.value} — mic/audio should now be released');
    } catch (e, st) {
      // ignore: avoid_print
      print('[StreamCallEngine] leave() · call.leave() FAILED for '
          '${call.callCid.value}: $e');
      if (kDebugMode) {
        debugPrint('StreamCallEngine.leave failed: $e\n$st');
      }
    }
    // CRITICAL (Samsung "still Connected" bug): `call.leave()` alone does
    // NOT reliably tear down the call's foreground SERVICE on One UI, so
    // its ongoing "call" notification (channel `stream_call_*`) lingers on
    // the lock screen as a phantom Connected call — and once the FGS is
    // still alive, NO `cancel()` / `cancelAll()` can remove that
    // notification (the OS protects an active foreground-service notif).
    // The ONLY reliable lever is to stop the service itself, which runs
    // `stopForeground(STOP_FOREGROUND_REMOVE)` + cancels the notification
    // natively. Do it explicitly for the call CID we just left.
    await _stopCallForegroundService(call.callCid.value);
  }

  /// Force-stop the Stream call foreground service for [callCid] so its
  /// ongoing notification is removed (see the note in [leave]). Best-effort
  /// and idempotent — safe if the service already stopped.
  Future<void> _stopCallForegroundService(String callCid) async {
    try {
      final stopped = await StreamVideoFlutterBackground.stopService(
        ServiceType.call,
        callCid: callCid,
      );
      // ignore: avoid_print
      print('[StreamCallEngine] stopService(call, $callCid) → $stopped');
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] stopService(call, $callCid) failed: $e');
    }
  }

  /// Coalesces concurrent `_ensureClient` calls into one rebuild.
  ///
  /// Without this, two near-simultaneous callers (e.g. the lifecycle
  /// `resumed → warmUp()` fired when the mic-permission dialog closes,
  /// AND `startOutgoing → join()` running right after) both pass the
  /// "client is null" check and both run `StreamVideo.reset(disconnect:
  /// true)` + `connect()`. The second reset CANCELS the first's
  /// in-flight connect, and the `call.join()` riding on it dies with
  /// `VideoError{message: connect cancelled}` — the caller never enters
  /// the call, so the callee sits alone and nobody hears anything.
  /// Sharing one Future means the second caller awaits the first's
  /// rebuild instead of starting a competing one.
  Future<void>? _ensureClientInFlight;

  Future<void> _ensureClient() {
    final existing = _ensureClientInFlight;
    if (existing != null) return existing;
    final fut = _ensureClientImpl();
    _ensureClientInFlight = fut;
    return fut.whenComplete(() {
      if (identical(_ensureClientInFlight, fut)) _ensureClientInFlight = null;
    });
  }

  /// Build (or rebuild) the `StreamVideo` client using a fresh token
  /// from `GET /chats/calls/stream-token`. Cached by `userId` so a
  /// sign-out / sign-in rotation rebuilds; otherwise re-used.
  Future<void> _ensureClientImpl() async {
    Map<String, dynamic> tokenJson;
    try {
      tokenJson = await remote.getStreamToken();
    } catch (e) {
      if (kDebugMode) debugPrint('StreamCallEngine token fetch failed: $e');
      return;
    }
    final apiKey = tokenJson['apiKey']?.toString() ?? '';
    final token = tokenJson['token']?.toString() ?? '';
    final userId = tokenJson['userId']?.toString() ?? '';

    // Unconditional (release-visible) while diagnosing the ring bug.
    // ignore: avoid_print
    print(
      '[StreamCallEngine] /stream-token → '
      'apiKey=$apiKey '
      'userId=$userId '
      'token=${_redactToken(token)}',
    );

    if (apiKey.isEmpty || token.isEmpty || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[StreamCallEngine] missing field(s) from /stream-token — '
          'apiKey.empty=${apiKey.isEmpty} '
          'token.empty=${token.isEmpty} '
          'userId.empty=${userId.isEmpty} — aborting join',
        );
      }
      return;
    }

    // Resolve the best display name we have NOW, BEFORE the reuse check.
    //
    // Look up our display name from the shared UsersCache (populated by
    // /users/me on login). Without it Stream falls back to the bare userId in
    // the VoIP notification body, so callees see a ringer saying "9 is
    // calling…" instead of "Mr A is calling…". UsersCache is IN-MEMORY only,
    // so it can be empty when this client is built before login finishes
    // populating it (a warmUp-vs-setIdentity race). Fall back to the PERSISTED
    // identity (`ChatSettings.userName`, written by setIdentity on login and
    // reloaded on cold start) and backfill the cache for later lookups.
    var displayName = UsersCache.instance.nameOf(userId) ?? '';
    if (displayName.trim().isEmpty) {
      final persisted = getIt<ChatSettings>().userName.trim();
      if (persisted.isNotEmpty) {
        displayName = persisted;
        UsersCache.instance.put(userId: userId, name: persisted);
      }
    }
    final haveRealName =
        displayName.trim().isNotEmpty && displayName.trim() != userId;

    if (_client != null && _clientUserId == userId) {
      final builtWithRealName = _clientUserName != null &&
          _clientUserName!.trim().isNotEmpty &&
          _clientUserName!.trim() != userId;
      // Reuse the live client UNLESS it was built without a real name AND we
      // now have one — then fall through to rebuild so the ring push carries
      // the caller's NAME, not the id (the reported "shows ID not name" bug).
      // One-time churn: once rebuilt with a real name, `builtWithRealName`
      // stays true so it never rebuilds for this reason again.
      if (builtWithRealName || !haveRealName) return;
      // ignore: avoid_print
      print('[StreamCallEngine] rebuilding client — caller name upgraded '
          'from "${_clientUserName ?? ''}" to "$displayName" so the ring '
          'push shows the name, not the id');
    }
    // Identity changed (or first use, or name upgrade) — rebuild.
    try {
      await _client?.disconnect();
    } catch (_) {/* swallow */}
    // Reset Stream's GLOBAL singleton too. Nulling our local `_client`
    // isn't enough — Stream's internal `InstanceHolder` still holds a
    // reference to the previous client, so a fresh `StreamVideo(...)`
    // throws "already initialised". This happens after
    // `disconnectForBackground` on minimize → warmUp on resume.
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {/* swallow — reset has no effect if no instance */}
    final avatarUrl = UsersCache.instance.avatarOf(userId);
    // ignore: avoid_print
    print('[StreamCallEngine] building client as userId=$userId '
        'name="$displayName" avatar=${avatarUrl ?? "none"}');
    _client = StreamVideo(
      apiKey,
      user: User.regular(
        userId: userId,
        name: displayName,
        image: avatarUrl,
      ),
      userToken: token,
      // Native incoming-call ring screen. Without a PN manager the
      // SDK falls back to a silent grouped notification (the one that
      // was spamming `notify(...)` in the receiver logs). With this
      // wired, Stream's backend ring=true push lands in the SDK's
      // native handler → flutter_callkit_incoming renders the
      // FaceTime/Connection-Service style fullscreen ringer.
      //
      // ⚠ Requires Stream Dashboard config (one-time, server side):
      //   - Stream Console → your app → Push Notifications
      //   - Add a Firebase provider, name it EXACTLY 'firebase'
      //     (matching `androidPushProvider.name` below)
      //   - Upload the Firebase Admin SDK service-account JSON
      //   - Same for APNs on iOS (provider name 'apn')
      pushNotificationManagerProvider:
          StreamVideoPushNotificationManager.create(
        iosPushProvider: const StreamVideoPushProvider.apn(
          name: 'apn',
        ),
        androidPushProvider: const StreamVideoPushProvider.firebase(
          name: 'firebase',
        ),
      ),
    );
    _clientUserId = userId;
    _clientUserName = displayName;
    _lastApiKey = apiKey;
    _lastStreamToken = token;
    // Install the foreground-service bridge so the mic/camera stay
    // alive when the user backgrounds the app mid-call. Without this,
    // Android 14+ silences the mic the instant the activity loses
    // focus — the peer hears nothing. The plugin's own manifest
    // declares the service + foregroundServiceType, so we only have
    // to call init once per client; it auto-starts on every join and
    // auto-stops on every leave.
    StreamBackgroundService.init(_client!);
    // Subscribe to Stream's live incoming-call channel BEFORE we
    // connect — Stream sets `state.incomingCall` the instant the
    // backend fan-outs a `ring=true` call to a foregrounded peer.
    // For backgrounded/killed peers the native push handler kicks in
    // instead; this stream only fires while the WebSocket is alive.
    await _incomingCallSub?.cancel();
    _incomingCallSub = _client!.state.incomingCall.valueStream.listen((call) {
      if (call == null) {
        // Stream cleared the incoming call — caller withdrew before
        // we answered. Surface as "ended" so the local overlay pops.
        _pendingIncomingCall = null;
        if (!_callEndedController.isClosed) {
          _callEndedController.add(StreamCallEndReason.incomingCleared);
        }
        return;
      }
      _pendingIncomingCall = call;
      // ignore: avoid_print
      print('[StreamCallEngine] 📞 incoming Stream call · '
          'cid=${call.callCid} · type=${call.type}');
      // Listen for THIS call's lifecycle so we can detect caller-end
      // even after the incoming-call slot has been cleared (e.g. once
      // we accept). When Stream's status flips to disconnected /
      // ended, surface it through onStreamCallEnded.
      _attachEndListener(call);
      if (!_incomingCallController.isClosed) {
        _incomingCallController.add(call);
      }
    });
    try {
      await _client!.connect();
      // ignore: avoid_print
      print('[StreamCallEngine] connected as userId=$userId');
      // iOS-only push diagnostic — answers "does APN work?" without a
      // backend round-trip. Guarded to iOS so Android runtime is untouched.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _logPushDiagnostics();
        // Close the "first minimized call has no ring" race: the SDK
        // registers push devices once on connect, but the PushKit VoIP
        // token often isn't ready yet, so the `apn` device (the iOS ring
        // route) is missing. Re-run registerDevice() until it appears.
        unawaited(_ensureApnDeviceRegistered());
      }
    } catch (e) {
      // ignore: avoid_print
      print('[StreamCallEngine] ❌ connect failed: $e');
    }
  }

  /// One-shot iOS push diagnostic. Logs two independent facts:
  ///   1. Did iOS hand us an **APNs token**? (proves the push entitlement +
  ///      provisioning profile are working — null means no push can arrive.)
  ///   2. Is this device **registered with Stream** for call push, and is
  ///      there an `apn` provider entry? (proves Stream knows where to send
  ///      the incoming-call VoIP push.)
  /// Both are read-only lookups; nothing here changes call behaviour. iOS
  /// only — never runs on Android.
  Future<void> _logPushDiagnostics() async {
    // (1) FCM/remote APNs token — proves the push entitlement works.
    try {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      // ignore: avoid_print
      print(apns == null
          ? '[PushDiag] ❌ APN NOT WORKING — iOS APNs token is NULL. '
              '(entitlement/provisioning/paid-account issue.)'
          : '[PushDiag] ✅ APN TOKEN OK — iOS APNs token present '
              '(len=${apns.length}).');
    } catch (e) {
      // ignore: avoid_print
      print('[PushDiag] APNs token lookup threw: $e');
    }
    // (2) VoIP (PushKit) token — the token Stream actually registers for
    // CALL push. Separate from the APNs token above; delivered async by
    // PushKit, so it may be empty for a beat right after launch.
    try {
      final voip = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      // ignore: avoid_print
      print(voip == null || voip.isEmpty
          ? '[PushDiag] ⏳ VoIP (PushKit) token EMPTY so far — PushKit not yet '
              'delivered. If still empty after +delay, call push can\'t register.'
          : '[PushDiag] ✅ VoIP token present (len=${voip.length}).');
    } catch (e) {
      // ignore: avoid_print
      print('[PushDiag] VoIP token lookup threw: $e');
    }
    // (3) Stream device list — check now AND again after registration has
    // had time to settle (the VoIP token stream registers async).
    await _checkStreamDevices('at-connect');
    Future.delayed(const Duration(seconds: 3),
        () => _checkStreamDevices('+3s'));
  }

  /// Logs whether this user has any push devices registered with Stream,
  /// and whether an `apn` provider entry exists (the iOS call-push route).
  Future<void> _checkStreamDevices(String when) async {
    // No live client = nothing to query. This is the common delayed case:
    // the call ended and `disconnectForBackground` nulled the client before
    // the delayed check ran. It does NOT mean the devices were lost — they
    // stay registered with Stream. Log it as a skip, not a failure.
    if (_client == null) {
      // ignore: avoid_print
      print('[PushDiag/$when] ⓘ skipped — Stream client not connected '
          '(call ended / backgrounded); registered devices unchanged.');
      return;
    }
    try {
      // Retry a few times — a lone null is a transient backend/WS blip,
      // NOT a registration loss. The device stays registered with Stream
      // from login until logout regardless of this read.
      final devices = await _getDevicesWithRetry();
      if (devices == null) {
        // ignore: avoid_print
        print('[PushDiag/$when] ⓘ device list unavailable after retries '
            '(transient API/WS blip) — registration is unchanged; the '
            'device stays registered until logout.');
        return;
      }
      if (devices.isEmpty) {
        // ignore: avoid_print
        print('[PushDiag/$when] ⚠ Stream has 0 registered push devices — '
            'call push will NOT be delivered.');
        return;
      }
      final hasApn = devices.any((d) =>
          d.pushProviderName == 'apn' ||
          d.pushProvider.toString().toLowerCase().contains('apn'));
      // ignore: avoid_print
      print('[PushDiag/$when] Stream devices: ${devices.length} · apn '
          'provider present: ${hasApn ? "✅ YES" : "❌ NO"}');
      for (final d in devices) {
        final tok = d.pushToken.length > 12
            ? '${d.pushToken.substring(0, 12)}…'
            : d.pushToken;
        // ignore: avoid_print
        print('[PushDiag/$when]   • provider=${d.pushProviderName ?? d.pushProvider} '
            'voip=${d.voip} disabled=${d.disabled} token=$tok');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[PushDiag/$when] getDevices() threw: $e');
    }
  }

  /// Reads the Stream device list with a few quiet retries.
  ///
  /// `getDevices()` occasionally returns null for a transient backend / WS
  /// blip even while the client is connected — that is NOT a registration
  /// loss. The device stays registered with Stream server-side from login
  /// until logout (the SDK writes it on connect; nothing here unregisters
  /// it). Retrying a handful of times lets the blip self-heal so callers
  /// don't surface a false error. Returns the device list, or null only if
  /// every attempt failed.
  Future<List<dynamic>?> _getDevicesWithRetry({int attempts = 4}) async {
    for (var i = 1; i <= attempts; i++) {
      try {
        final devices = (await _client?.getDevices())?.getDataOrNull();
        if (devices != null) return devices;
      } catch (_) {/* transient — fall through and retry */}
      if (i < attempts) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
    return null;
  }

  /// Returns true if Stream has an `apn` push device for this user, false
  /// if not, null if the lookup failed. Pure read — the retry loop owns
  /// the logging.
  Future<bool?> _streamHasApnDevice() async {
    final devices = await _getDevicesWithRetry();
    if (devices == null) return null;
    return devices.any((d) =>
        d.pushProviderName == 'apn' ||
        d.pushProvider.toString().toLowerCase().contains('apn'));
  }

  /// iOS-only: the SDK registers push devices ONCE on connect, but the
  /// PushKit VoIP token arrives async — on a cold start / client rebuild
  /// it's often not ready yet, so only the FCM device registers and the
  /// `apn` provider (the route that lights the native CallKit ring when
  /// the app is minimized/killed) never appears. The SDK has no retry, so
  /// the FIRST call after launch reaches a phone Stream can't push to →
  /// "no header ring". This closes that race: poll `getDevices()`; while
  /// no `apn` device is present, re-run `registerDevice()` (by now the
  /// VoIP token is more likely available) and wait, up to ~15 s.
  ///
  /// Doubles as a diagnostic: if the `apn` device STILL never appears
  /// after the retries, the cause is NOT timing — it's the cert/infra
  /// layer (Stream dashboard APN VoIP provider env mismatch: sandbox vs
  /// production). The final log says so explicitly. Additive, iOS-only —
  /// never runs on Android / web.
  Future<void> _ensureApnDeviceRegistered() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    const maxAttempts = 5; // 5 × 2 s ≈ 10 s — covers the async VoIP token delivery
    String lastVoip = '';
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (await _streamHasApnDevice() == true) {
        // ignore: avoid_print
        print('[PushDiag/apn-retry] apn provider registered after '
            '$attempt check(s) — minimized/killed-call ring route is ready');
        return;
      }
      // Read the PushKit VoIP token so we can tell WHY apn isn't registering:
      //   • token EMPTY   → iOS hasn't delivered it yet (timing/provisioning/
      //                     Simulator). registerDevice has nothing to register.
      //   • token PRESENT → the token exists but Stream has no apn device →
      //                     re-run registerDevice; if it still never appears it
      //                     is the Stream-dashboard side (provider/cert), not us.
      try {
        lastVoip =
            (await FlutterCallkitIncoming.getDevicePushTokenVoIP())?.toString() ??
                '';
      } catch (_) {
        lastVoip = '';
      }
      if (lastVoip.isEmpty) {
        // ignore: avoid_print
        print('[PushDiag/apn-retry] attempt $attempt/$maxAttempts — VoIP '
            '(PushKit) token still EMPTY; cannot register apn yet (waiting on '
            'iOS to deliver the token)');
      } else {
        // Register the apn device DIRECTLY via `addDevice`, NOT the package's
        // `registerDevice()`. The package short-circuits when this VoIP token
        // was registered before (cached in SharedPreferences) — so if the
        // device was later removed from Stream (logout / token refresh /
        // StreamVideo.reset), `registerDevice()` silently NEVER re-creates it,
        // and `apn` stays missing forever. `addDevice` bypasses that cache AND
        // returns a real Result, so we both fix the cache-skip AND see the
        // actual Stream error if the registration is genuinely rejected
        // (dashboard provider/cert).
        try {
          final res = await _client?.addDevice(
            pushToken: lastVoip,
            pushProvider: PushProvider.apn,
            pushProviderName: 'apn',
            voipToken: true,
          );
          // ignore: avoid_print
          print('[PushDiag/apn-retry] attempt $attempt/$maxAttempts — VoIP '
              'token present (len=${lastVoip.length}); addDevice(apn) → '
              '${res is Success ? "OK" : res}');
        } catch (e) {
          // ignore: avoid_print
          print('[PushDiag/apn-retry] addDevice(apn) threw: $e');
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (await _streamHasApnDevice() == true) {
      // ignore: avoid_print
      print('[PushDiag/apn-retry] apn provider registered on final check '
          '— ring route ready');
      return;
    }
    // Definitive diagnosis — the token tells us which layer is at fault.
    if (lastVoip.isEmpty) {
      // ignore: avoid_print
      print('[PushDiag/apn-retry] ❌ apn NEVER registered AND the VoIP (PushKit) '
          'token is EMPTY after ~10 s. iOS never gave us a VoIP token → this is '
          'the DEVICE/provisioning layer, NOT Stream: check (1) a REAL device '
          '(the Simulator never issues a VoIP token), (2) Push Notifications '
          'capability + "Voice over IP" background mode, (3) the provisioning '
          'profile includes push. Once the token appears, apn registers '
          'automatically and persists on Stream for all future calls.');
    } else {
      // ignore: avoid_print
      print('[PushDiag/apn-retry] ❌ apn NEVER registered but the VoIP token IS '
          'present (len=${lastVoip.length}). The token exists, so this is the '
          'STREAM side: the dashboard APN provider must be named exactly "apn" '
          'and its cert environment must match aps-environment '
          '(development = sandbox). Code cannot fix a dashboard/cert mismatch.');
    }
  }

  /// JWTs are sensitive — log only head + tail so we can verify shape
  /// (3 dot-separated base64 segments) without leaking the full token.
  static String _redactToken(String token) {
    if (token.length <= 16) return '***';
    return '${token.substring(0, 8)}…${token.substring(token.length - 6)} '
        '(len=${token.length})';
  }

  /// Tear down for tests / hot-restart. Production code doesn't need
  /// to call this — the client lives for the app's lifetime.
  Future<void> dispose() async {
    await leave();
    await _incomingCallSub?.cancel();
    _incomingCallSub = null;
    await _activeStateSub?.cancel();
    _activeStateSub = null;
    await _peerJoinedSub?.cancel();
    _peerJoinedSub = null;
    await _incomingCallController.close();
    await _callEndedController.close();
    await _peerJoinedController.close();
    try {
      await _client?.disconnect();
    } catch (_) {}
    _client = null;
    _clientUserId = null;
    _clientUserName = null;
    _pendingIncomingCall = null;
  }
}
