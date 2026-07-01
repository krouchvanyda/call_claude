import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:erp_callkit/erp_callkit.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/environments.dart';
import '../../../core/router/app_router.dart';
import '../entities/call_log.dart';
import '../presentation/pages/video_call_page.dart';
import '../presentation/pages/voice_call_page.dart';
import 'call_signaling_service.dart';
import 'repositories/conversations_repository.dart';
import 'stream_call_engine.dart';

/// Bridges `flutter_callkit_incoming` user actions (Accept / Reject)
/// into the call ceremony. Subscribes once at app start and stays
/// alive for the whole process — necessary because the user can hit
/// Accept on the native ringer at any moment, including after a
/// cold-start triggered by the tap itself.
///
/// On **Accept**: extracts the call CID from the CallKit event's
/// `extra` map, asks [StreamCallEngine.acceptByCid] to bring the
/// media leg up, and pushes the matching call page via the root
/// navigator so the user lands on the in-call screen.
///
/// On **Decline**: routes through [StreamCallEngine.rejectByCid] so
/// the caller gets the "declined" signal and the call log records
/// it as rejected.
///
/// Handles BOTH the minimize case (app alive, event arrives in
/// foreground process) AND the killed case (cold-start delivers the
/// event after [attach] subscribes during main()).
class CallkitEventHandler {
  CallkitEventHandler._();
  static final CallkitEventHandler instance = CallkitEventHandler._();

  StreamSubscription<CallEvent?>? _sub;
  bool _attached = false;

  /// Dedupe guard for `_handleAccept`. On a minimize→accept the live
  /// `actionCallAccept` event AND the +2 s `_maybeAcceptStaleCallkit`
  /// recovery can BOTH fire `_handleAccept` for the same call — the
  /// second invocation runs another `acceptByCid` whose `leave()`
  /// tears down the just-connected call, killing the audio. Track
  /// which callCid we've already handled (or are handling) so the
  /// duplicate is a no-op.
  final Set<String> _handledCallCids = <String>{};

  /// When each callCid was accepted (iOS only). Used by `_handleHangup`
  /// to ignore the spurious `actionCallEnded` that CallKit fires moments
  /// after Accept — otherwise it becomes a `signaling.hangup()` that
  /// closes the CALLER's call. A genuine End tap arrives well after this
  /// window, so it still hangs up normally.
  final Map<String, DateTime> _acceptedAt = <String, DateTime>{};

  /// How long after Accept a CallKit `actionCallEnded` is treated as the
  /// spurious post-accept handoff rather than a real hang-up.
  static const Duration _acceptHandoffWindow = Duration(seconds: 6);

  /// iOS foreground-suppression (callCid + CallKit UUID). When a native
  /// CallKit incoming screen appears while the app is in the FOREGROUND,
  /// we dismiss it (the in-app IncomingCallOverlay shows the ring instead
  /// — the user does not want a native header when the app is open).
  /// That dismiss makes CallKit emit a spurious `actionCallEnded` /
  /// `actionCallDecline`; the ids parked here let the end/decline
  /// handlers ignore that one event so it isn't turned into a real
  /// reject/hangup of the call the overlay is showing. iOS-only.
  final Set<String> _suppressedIncoming = <String>{};

  /// Backend call id of the most recent native CallKit ring shown while the
  /// app was backgrounded/killed (captured from `actionCallIncoming`). Lets a
  /// killed-app DECLINE that arrives via the native `incomingCallEnded` bridge
  /// — when no in-app call was ever seeded (`signaling.current == null`) —
  /// still POST the reject so the CALLER stops ringing. iOS-only.
  String? _lastIncomingBgCallId;

  /// iOS-only native→Dart bridge. The native `CXCallObserver`
  /// (AppDelegate.swift) invokes `incomingCallAnswered` on this channel the
  /// instant an incoming CallKit call transitions to `hasConnected` — i.e.
  /// the user tapped Accept on the native CallKit screen (lock screen /
  /// killed cold-start). It's the ONLY signal for that accept that survives
  /// when the `flutter_callkit_incoming` `actionCallAccept` event is missed
  /// (isolate/subscription not ready) and Stream's native push handler has
  /// already consumed the call. We route it into the same `_handleAccept`
  /// flow so the backend POST + Stream join run exactly as elsewhere.
  static const MethodChannel _iosCallkitChannel = MethodChannel(
    'erp/ios_callkit',
  );

  /// (Removed: was a pushed-call-id dedupe set. Replaced with
  /// `VoiceCallPage.isMounted` / `VideoCallPage.isMounted` checks in
  /// IncomingCallOverlay — those reflect actual route state on the
  /// navigator stack, so they correctly detect when go_router wiped
  /// our push, whereas a set entry stayed populated forever.)

  /// Idempotent — safe to call from multiple bootstrap points.
  void attach() {
    if (_attached) return;
    _attached = true;
    _resubscribe();
    // iOS: listen for the native CXCallObserver's `incomingCallAnswered`
    // push (AppDelegate.swift). This is the reliable accept signal for a
    // killed/locked cold-start where `actionCallAccept` never reaches the
    // onEvent subscription. No-op on Android (the channel is never invoked
    // there).
    if (Platform.isIOS) {
      _iosCallkitChannel.setMethodCallHandler(_onIosNativeCallkit);
    }
    // Request the two Android-runtime permissions flutter_callkit_incoming
    // needs to render the proper full-screen ringer with Accept/Decline
    // buttons. Without these the plugin silently falls back to a plain
    // tray notification (no buttons) and the Accept event NEVER fires:
    //
    //   - POST_NOTIFICATIONS (Android 13+) — required for any notif to show
    //   - USE_FULL_SCREEN_INTENT (Android 14+) — required for the
    //     full-screen ring overlay. On 14+ this needs explicit user
    //     approval via Settings, not just a manifest declaration.
    //
    // Fire-and-forget: we want the prompt to show up on first launch
    // but app init must not block on it.
    unawaited(_requestCallkitPermissions());

    // Cold-start recovery. When the OS launches the app from a
    // CallKit Accept tap, the `actionCallAccept` event fires BEFORE
    // the Flutter isolate is alive — `onEvent` never sees it and
    // the call accept is silently dropped. Symptom: user taps Accept
    // on a killed/backgrounded app, the ringer dismisses, the app
    // opens to the home screen, no audio, no in-call page.
    //
    // Workaround: shortly after attach, query CallKit's own
    // `activeCalls()` — if there's still an entry there, the OS
    // believes the user accepted, so synthesise the accept ourselves.
    // Also schedule a Stream-side resync check at a longer delay,
    // since Stream's WS handshake takes a couple of seconds after a
    // cold start.
    Future.delayed(const Duration(seconds: 2), _maybeAcceptStaleCallkit);
    Future.delayed(const Duration(seconds: 5), _maybeAutoAcceptOnStreamResync);
  }

  Future<void> _requestCallkitPermissions() async {
    // Delay briefly so the first Activity is alive and can host the
    // system permission dialogs. Without this delay (firing during
    // main() before runApp), the prompts queue but never surface and
    // the user never sees them — which is exactly what was happening.
    await Future.delayed(const Duration(seconds: 1));

    // Step 1: POST_NOTIFICATIONS (Android 13+). Use permission_handler
    // directly — it's the standard runtime-permission request path
    // and reliably shows the system dialog.
    try {
      final status = await Permission.notification.status;
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] Notification permission '
        'status (before request)=$status',
      );
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] Notification permission '
          'request result=$result',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[CallkitEventHandler] notification permission error: $e');
    }

    // Step 1b: RECORD_AUDIO (mic). Stream's `call.join()` triggers
    // a runtime prompt the first time the mic is accessed, but that
    // prompt is easy to miss in the middle of an active call — and
    // if the user dismisses or denies, A or B silently publishes
    // nothing and the other side just hears silence. Asking up-front
    // means the permission is already granted by the time any call
    // is placed or accepted.
    //
    // iOS-only carve-out: on iOS we do NOT ask up-front. The user wants
    // the native mic/camera prompt to appear only when they tap the call
    // button — that's handled by `ensureCallPermissions()` in the call
    // pages. Android keeps the up-front request (the full-screen CallKit
    // ringer depends on it).
    if (!Platform.isIOS) {
      try {
        final micStatus = await Permission.microphone.status;
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] Microphone permission '
          'status (before request)=$micStatus',
        );
        if (!micStatus.isGranted) {
          final result = await Permission.microphone.request();
          // ignore: avoid_print
          print(
            '[CallkitEventHandler] Microphone permission '
            'request result=$result',
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('[CallkitEventHandler] microphone permission error: $e');
      }
    }

    // Step 2: USE_FULL_SCREEN_INTENT (Android 14+). NOT a normal
    // runtime permission — `canUseFullScreenIntent` returns false
    // until the user manually toggles a setting. The plugin's
    // `requestFullIntentPermission` opens the matching system
    // Settings page so the user can grant it with one tap.
    try {
      final canUse = await FlutterCallkitIncoming.canUseFullScreenIntent();
      // ignore: avoid_print
      print('[CallkitEventHandler] canUseFullScreenIntent=$canUse');
      if (canUse == false) {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] opening Settings page for '
          'full-screen intent grant — user must toggle it on',
        );
        await FlutterCallkitIncoming.requestFullIntentPermission();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[CallkitEventHandler] fullScreenIntent check error: $e');
    }
  }

  /// Re-subscribe to the CallKit event channel. Used on app resume
  /// (when minimize → foreground may have caused the prior
  /// subscription to miss events). Called via [onAppResumed].
  void _resubscribe() {
    _sub?.cancel();
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] (re)subscribing to FlutterCallkitIncoming.onEvent',
    );
    _sub = FlutterCallkitIncoming.onEvent.listen(
      (event) {
        // Trace EVERY event hitting the subscription so we can confirm
        // delivery. Print is unconditional so it fires in release too
        // while we triangulate the ring-not-accepted bug.
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] RAW event received: '
          'type=${event?.event} body=${event?.body}',
        );
        _onEvent(event);
      },
      onError: (Object e, StackTrace s) {
        // ignore: avoid_print
        print('[CallkitEventHandler] subscription ERROR: $e\n$s');
      },
      onDone: () {
        // ignore: avoid_print
        print('[CallkitEventHandler] subscription CLOSED — events stop here');
      },
      cancelOnError: false,
    );
  }

  /// Called from `ChatLifecycleBridge` when the app comes back to
  /// foreground. The fix for the minimize→accept dead-event problem:
  /// `FlutterCallkitIncoming.onEvent` events fired while the app was
  /// backgrounded may not be delivered to our previous subscription.
  /// We:
  ///   1. Re-subscribe so a fresh stream handler is in place for any
  ///      buffered events the OS may now flush.
  ///   2. Check `activeCalls()` to detect if there's a CallKit call
  ///      the OS thinks we're in but our state doesn't know about
  ///      (means user tapped Accept and we missed the event).
  ///      Treat that as an implicit accept and route through.
  Future<void> onAppResumed() async {
    if (!_attached) return;
    _resubscribe();
    // Orphan sweep: if the process was frozen/killed mid-call by an OEM
    // battery saver (Samsung Freecess), the call could have ended on the
    // peer side while we were suspended — and the call notification(s)
    // (our ring + Stream's ongoing-call notif) get stranded on the lock
    // screen, reading as a phantom "Connected". On resume, when there is
    // NO call still in flight, wipe any leftover call notifications.
    // Guarded so we never clear the notification of a genuinely-live call.
    final signaling = _safelyGet<CallSignalingService>();
    final engine = _safelyGet<StreamCallEngine>();
    final hasLiveCall =
        (signaling?.current != null &&
            signaling!.current!.state != CallSignalState.ended) ||
        (engine?.hasPendingIncoming ?? false);
    if (!hasLiveCall) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] resume orphan sweep — no live call, '
        'clearing any stranded call notifications',
      );
      unawaited(ErpCallKit.dismissAllCalls().catchError((Object _) {}));
    }
    await _maybeAcceptStaleCallkit();
    // Fallback path B: if activeCalls() didn't surface the call
    // (Android's "content is null" quirk), wait for Stream's WS to
    // resync after warmUp and check for a pending incoming Stream
    // call. If one exists, the user almost certainly just tapped
    // Accept on the CallKit ringer — auto-accept it so they land
    // on the call page with audio flowing.
    Future.delayed(const Duration(seconds: 2), _maybeAutoAcceptOnStreamResync);
  }

  /// After the WS reconnects on resume, Stream's client should have
  /// the still-ringing call back in `state.incomingCall`. If it's
  /// there, treat the recent CallKit tap as an accept (because if
  /// the user had tapped Reject, the call would have been ended on
  /// Stream's side already via `rejectByCid` event).
  Future<void> _maybeAutoAcceptOnStreamResync() async {
    final engine = _safelyGet<StreamCallEngine>();
    if (engine == null) return;
    if (!engine.hasPendingIncoming) {
      // ignore: avoid_print
      print('[CallkitEventHandler] resync check: no pending Stream call');
      return;
    }
    final signaling = _safelyGet<CallSignalingService>();
    if (signaling == null) return;
    // If signaling already saw it via the WS bridge AND we're
    // already past incomingRinging (e.g. user accepted in-app), do
    // nothing.
    final active = signaling.current;
    if (active != null && active.state != CallSignalState.incomingRinging) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] resync check: active call already in '
        'state=${active.state}, skipping',
      );
      return;
    }
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] resync check: pending Stream call found — '
      'auto-accepting (user must have tapped Accept on CallKit)',
    );
    await signaling.acceptIncoming();
  }

  /// Inspect the plugin's `activeCalls()` to see if there's a call
  /// the OS thinks is connected but we never got the Accept event
  /// for. If so, this is the missed-event case — synthesize an
  /// Accept by treating the call as accepted (so audio + UI flow).
  ///
  /// Wrapped in try/catch because activeCalls() on Android has a
  /// known PlatformException("content is null") quirk when there
  /// are no calls — we just want to silently no-op on that.
  Future<void> _maybeAcceptStaleCallkit() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] activeCalls() returned: '
        'type=${calls.runtimeType} value=$calls',
      );
      if (calls is! List || calls.isEmpty) {
        // Empty has two meanings (we can't tell them apart from this
        // signal alone):
        //   (a) user declined — the plugin's broadcast receiver
        //       `removeCall`s on ACTION_CALL_DECLINE, so the entry is
        //       gone before we look.
        //   (b) call never reached this device, or already ended.
        // Either way, fall through to the Stream resync path scheduled
        // at +5 s — if Stream still has the call ringing, that path
        // can decide what to do.
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] no active CallKit call — '
          'either user declined, call ended, or app opened outside '
          'a call. Stream resync will follow at +5 s.',
        );
        return;
      }
      final first = calls.first;
      if (first is! Map) {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] active call entry is not a Map: '
          '${first.runtimeType}',
        );
        return;
      }
      // The plugin sets `isAccepted: true` when the user taps Accept
      // (CallkitIncomingBroadcastReceiver.kt line 126:
      //   addCall(context, Data.fromBundle(data), true)).
      // Anything else (isAccepted=false or missing) means the call is
      // still ringing — user opened the app via the notification body
      // without tapping Accept. In that case let the in-app
      // IncomingCallOverlay handle it; don't auto-accept.
      final isAccepted = first['isAccepted'] == true;
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] stale CallKit call detected · '
        'isAccepted=$isAccepted · entry=$first',
      );
      if (!isAccepted) {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] call still ringing (user opened '
          'the app body without tapping Accept) — leaving the in-app '
          'IncomingCallOverlay to handle it',
        );
        return;
      }
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] user already tapped Accept on '
        'CallKit — synthesising the missed actionCallAccept event',
      );
      await _handleAccept(first);
    } catch (e) {
      // PlatformException("content is null") = no active calls.
      // ignore: avoid_print
      print('[CallkitEventHandler] resume: activeCalls() failed ($e)');
    }
  }

  Future<void> detach() async {
    await _sub?.cancel();
    _sub = null;
    _attached = false;
  }

  Future<void> _onEvent(CallEvent? event) async {
    if (event == null) return;
    // ignore: avoid_print
    print('[CallkitEventHandler] event=${event.event} body=${event.body}');
    // iOS: a CallKit accept/decline/end that arrives while the app is
    // foreground AND an in-app call is already active is an artifact of the
    // native screen we suppress in foreground (the user actually used the
    // in-app overlay, which calls signaling directly). Acting on it would
    // wrongly reject/hangup the live call. Ignore those.
    //
    // CRITICAL: this is gated on `signaling.current != null`. When a
    // MINIMIZED call is accepted from CallKit, iOS resumes the app FIRST,
    // so `actionCallAccept` also arrives "foreground" — but there's no
    // in-app call yet (no STOMP invite reached the backgrounded app), so
    // `signaling.current` is null and we MUST process it. Without this
    // gate, minimized-accept would be swallowed → no audio.
    if (Platform.isIOS &&
        _isForeground() &&
        _safelyGet<CallSignalingService>()?.current != null &&
        (event.event == Event.actionCallAccept ||
            event.event == Event.actionCallDecline ||
            event.event == Event.actionCallEnded ||
            event.event == Event.actionCallTimeout)) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] ignoring CallKit ${event.event} · app '
        'foreground with active in-app call — overlay owns it',
      );
      return;
    }
    switch (event.event) {
      case Event.actionCallIncoming:
        // A native CallKit incoming screen just appeared (iOS VoIP push).
        // If the app is in the FOREGROUND, suppress it — the in-app
        // overlay shows the ring there. Backgrounded/killed: left alone.
        await _maybeSuppressForegroundCallkit(event.body);
      case Event.actionCallAccept:
        await _handleAccept(event.body);
      case Event.actionCallToggleAudioSession:
        // iOS-only: CallKit activated (or deactivated) ITS AVAudioSession.
        // On activation we must restart WebRTC's audio unit on the now-live
        // session — the engine join() asserted the route a beat too early
        // (before CallKit took over), which is why a minimized/killed accept
        // connected but was SILENT. No-op on deactivate. Android never emits
        // this event.
        if (Platform.isIOS) {
          final activated =
              event.body is Map && (event.body as Map)['isActivate'] == true;
          if (activated) {
            // ignore: avoid_print
            print(
              '[CallkitEventHandler] CallKit audio session activated → '
              'engine.onCallKitAudioSessionActivated()',
            );
            await _safelyGet<StreamCallEngine>()
                ?.onCallKitAudioSessionActivated();
          } else {
            // {isActivate: false} — CallKit DEACTIVATED the shared
            // AVAudioSession. Normally that's the current call ENDING
            // (harmless). But in a back-to-back A→B→B scenario it's call
            // #1's LATE didDeactivate arriving AFTER call #2 already
            // connected — and because the session was still active from
            // call #1, CallKit never fires a fresh didActivate for call
            // #2, so the engine never restarts WebRTC's audio unit and B
            // hears nothing ("second call, accept, no audio"). Detect that
            // case: if a call is STILL connected, the deactivate pulled the
            // session out from under it → re-assert + bounce the mic on
            // whatever session is now live, exactly as we do on activate.
            // When the current call is genuinely ending, signaling state is
            // already `ended`/null here, so this stays a no-op. iOS-only.
            final signaling = _safelyGet<CallSignalingService>();
            final liveConnected =
                signaling?.current?.state == CallSignalState.connected;
            if (liveConnected) {
              // ignore: avoid_print
              print(
                '[CallkitEventHandler] CallKit audio session DEACTIVATED '
                'while a call is still connected → re-asserting '
                '(back-to-back call audio race)',
              );
              await _safelyGet<StreamCallEngine>()
                  ?.onCallKitAudioSessionActivated();
            } else {
              // ignore: avoid_print
              print(
                '[CallkitEventHandler] CallKit audio session deactivated '
                '· no live connected call → no-op',
              );
            }
          }
        }
      case Event.actionCallDecline:
        // User tapped Decline on the INCOMING ringer (the call is
        // still in incomingRinging state, no media leg up yet).
        await _handleDecline(event.body);
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        // User tapped Hang Up on the ONGOING-CALL notification (the
        // persistent heads-up that shows while a call is connected
        // and the app is minimized), or the call timed out. These
        // are NOT the same as Decline — at this point the local
        // signaling state is `connected` and we need to call
        // hangup() not rejectIncoming(). rejectIncoming() bails out
        // when state != incomingRinging, which is why tapping Hang
        // Up on the notification used to do nothing.
        await _handleHangup(event.body);
      default:
        // Ignore lifecycle/diagnostic events (incoming/start/etc.) —
        // they're informational only.
        break;
    }
  }

  /// iOS only: dismiss the native CallKit incoming screen when it shows
  /// while the app is in the FOREGROUND, so only the in-app overlay
  /// rings. When the app is minimized or killed the lifecycle state is
  /// NOT `resumed`, so we leave CallKit up — that's the whole point of
  /// the background ring. The dismiss makes CallKit fire a spurious
  /// `actionCallEnded`; we park the ids in [_suppressedIncoming] so the
  /// end handler ignores that one event instead of rejecting the call.
  /// True when the app is on-screen. NOTE: when CallKit presents over a
  /// foreground app, iOS flips the state to `inactive` (NOT `resumed`), so
  /// we must treat `inactive` as foreground too — otherwise we'd miss the
  /// exact moment we care about. Only paused/hidden/detached = backgrounded.
  bool _isForeground() {
    final lc = WidgetsBinding.instance.lifecycleState;
    return lc == AppLifecycleState.resumed ||
        lc == AppLifecycleState.inactive ||
        lc == null;
  }

  Future<void> _maybeSuppressForegroundCallkit(dynamic body) async {
    if (!Platform.isIOS) return;
    // Belt-and-suspenders: also suppress when our in-app ring is already
    // showing (the STOMP invite arrived → we're online/foreground) to
    // cover the race where the lifecycle hasn't settled yet.
    final signaling = _safelyGet<CallSignalingService>();
    final hasInAppRing =
        signaling?.current?.state == CallSignalState.incomingRinging;
    // CRITICAL (killed-app fix): suppress ONLY when a genuine in-app ring is
    // already up (`hasInAppRing`). We must NOT key off `_isForeground()` here:
    // a KILLED app cold-launched BY this very VoIP push boots all the way to
    // foreground (full splash/auth), so `_isForeground()` reads true at the
    // moment we process `actionCallIncoming` — and we'd dismiss our OWN
    // legitimate incoming ring ("killed app: ring shows a beat then closes").
    // `signaling.current` is null on a cold-launch-from-push (no STOMP invite
    // ever reached the dead app), but non-null (incomingRinging) for a real
    // foreground call. Pure-foreground suppression where the STOMP invite
    // hasn't landed yet is handled by (a) the native `CXCallObserver` in
    // AppDelegate (its `isAppForeground` is correctly false at push time on a
    // cold launch) and (b) the `_suppressForegroundCallkit` loop that
    // `handleIncomingFromPush` starts once the in-app ring appears.
    if (!hasInAppRing) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] keeping native CallKit ring · '
        'no in-app ring (backgrounded / killed cold-launch)',
      );
      // NOTE: do NOT `warmUp()` / connect the Stream client here. Connecting
      // the Stream WebSocket while a ring is showing in the background makes
      // Stream consider this device "online", so the NEXT call is delivered
      // over the WS (which a backgrounded app can't render) instead of the
      // apn/VoIP push that raises the native CallKit screen — the "2nd call:
      // no ring" regression. The WS must stay DOWN while backgrounded so every
      // incoming call rings via apn. The caller-cancel dismiss is handled
      // WITHOUT the WS by the deterministic backend poll below
      // (`watchBackgroundRingForCancel` → `reportCall(endedAt:)`).
      //
      // Deterministic fallback: while minimized, neither STOMP, the Stream WS,
      // nor (often) the apn/FCM push route can deliver the caller-cancel — but
      // the app is still alive and can hit REST. Poll the backend for the
      // call's terminal status and dismiss the ring when the caller ends it.
      // Derive the backend call id from the CallKit entry's cid
      // ("default:erp-call-1662" → "1662").
      final p = _params(body);
      final cid = (p['call_cid'] ?? p['callCid'])?.toString() ?? '';
      final callId = cid.isEmpty ? '' : _parseBackendCallId(cid);
      // Remember it so a killed-app DECLINE (which arrives via the native
      // incomingCallEnded bridge with no seeded in-app call) can still POST
      // the reject and stop the caller ringing.
      if (callId.isNotEmpty) _lastIncomingBgCallId = callId;
      final signaling = _safelyGet<CallSignalingService>();
      if (signaling != null && callId.isNotEmpty) {
        signaling.watchBackgroundRingForCancel(callId);
      }
      return; // backgrounded / killed → keep the native ring
    }
    final params = _params(body);
    final callCid = (params['call_cid'] ?? params['callCid'])?.toString() ?? '';
    final uuid = params['id']?.toString() ?? '';
    if (callCid.isNotEmpty) _suppressedIncoming.add(callCid);
    if (uuid.isNotEmpty) _suppressedIncoming.add(uuid);
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] foreground incoming — dismissing native '
      'CallKit header (in-app overlay handles the ring) · callCid=$callCid '
      'uuid=$uuid',
    );
    try {
      // End by the specific uuid AND sweep all — Stream's native push may
      // have reported the call under a uuid we don't see here, so endAll is
      // the reliable hammer.
      if (uuid.isNotEmpty) await FlutterCallkitIncoming.endCall(uuid);
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {
      /* best-effort */
    }
    // Start the persistent dismiss loop keyed on the backend call id. This
    // is the ONE place we KNOW the CallKit screen actually appeared, so it
    // covers the case where the STOMP/WS invite path never kicked the loop
    // off (or kicked it off before the late VoIP push raised the screen).
    final backendId = _parseBackendCallId(callCid);
    if (backendId.isNotEmpty) {
      signaling?.suppressForegroundCallkitFor(backendId);
    }
  }

  /// True (and consumes the entry) if [callCid] is an end/decline event
  /// produced by our own foreground CallKit suppression — meaning it must
  /// be ignored rather than treated as a real reject/hangup.
  bool _isSuppressedEnd(String callCid) {
    if (callCid.isEmpty) return false;
    return _suppressedIncoming.remove(callCid);
  }

  /// Hang-up tap on the ongoing-call notification (or a CallKit
  /// timeout while we were already connected). Routes through
  /// `signaling.hangup()` if the call is connected, or
  /// `signaling.rejectIncoming()` if somehow still ringing.
  Future<void> _handleHangup(dynamic body) async {
    final params = _params(body);
    // iOS VoIP-push entries use `callCid` (camelCase); FCM uses `call_cid`.
    // Check both before the CallKit-UUID `id` fallback. (Additive — Android
    // unaffected.)
    final callCid =
        (params['call_cid'] ?? params['callCid'])?.toString() ??
        params['id']?.toString() ??
        '';
    // ignore: avoid_print
    print('[CallkitEventHandler] _handleHangup · callCid=$callCid');

    // Ignore the spurious end that our own foreground suppression caused
    // (we dismissed the native CallKit header; the in-app overlay is the
    // live ring — must NOT reject/hangup it).
    if (_isSuppressedEnd(callCid)) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleHangup IGNORED · end is from our '
        'foreground CallKit suppression · callCid=$callCid',
      );
      return;
    }

    // iOS only: CallKit fires a spurious `actionCallEnded` right after Accept
    // (we can't call setCallConnected — it crashes the PushKit path). Ignore
    // an end that lands within the handoff window of accepting THIS call, so
    // it isn't turned into a `signaling.hangup()` that closes the caller's
    // call. A real End tap arrives long after this window. (Android never
    // populates `_acceptedAt`, so this is a no-op there.)
    if (Platform.isIOS && callCid.isNotEmpty) {
      final acceptedAt = _acceptedAt[callCid];
      if (acceptedAt != null &&
          DateTime.now().difference(acceptedAt) < _acceptHandoffWindow) {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] _handleHangup IGNORED · spurious '
          'actionCallEnded within ${_acceptHandoffWindow.inSeconds}s of '
          'accept (CallKit handoff, not a real hang-up) · callCid=$callCid',
        );
        return;
      }
      // Past the window (or a genuine end) — let it proceed and stop tracking.
      _acceptedAt.remove(callCid);
    }

    final signaling = _safelyGet<CallSignalingService>();
    if (signaling == null) {
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleHangup BAIL · no signaling');
      // Killed-app cold-start: DI isn't ready. If this is a still-ringing call
      // (the user declined the native screen), POST the reject directly so the
      // CALLER stops ringing — DI-less, same as the decline path.
      await _directRejectNoDi(_parseBackendCallId(callCid));
      // Best-effort: tell Stream so its foreground service notification
      // dismisses even without our local state.
      final engine = _safelyGet<StreamCallEngine>();
      if (engine != null) await engine.leave();
      return;
    }

    final active = signaling.current;
    if (active == null) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleHangup: no active local call '
        '— calling engine.leave() so Stream releases the foreground '
        'service notification',
      );
      // Killed/minimized decline that never seeded an in-app call: relay the
      // reject to the backend so the CALLER stops ringing. Skip when this end
      // is our OWN programmatic dismiss (caller-cancel already handled by the
      // bg-ring poll). Backend reject is idempotent for an already-ended call.
      final ownDismiss = signaling.recentlyDismissedNativeCallkit();
      final relayId = _parseBackendCallId(callCid);
      final bgId = relayId.isNotEmpty ? relayId : (_lastIncomingBgCallId ?? '');
      if (!ownDismiss && bgId.isNotEmpty) {
        // ignore: avoid_print
        print('[CallkitEventHandler] _handleHangup · no active call → direct '
            'reject POST for callId=$bgId (killed/bg decline)');
        await _directRejectNoDi(bgId);
      }
      final engine = _safelyGet<StreamCallEngine>();
      if (engine != null) await engine.leave();
      return;
    }

    if (active.state == CallSignalState.connected) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleHangup: active call is '
        'connected — calling signaling.hangup()',
      );
      await signaling.hangup(finalStatus: ChatCallStatus.answered);
    } else if (active.state == CallSignalState.incomingRinging) {
      // Don't convert a native-CallKit end into a DECLINE when WE just
      // dismissed that native screen ourselves (foreground/overlay takeover or
      // the suppression loop). On a minimize the call can arrive over BOTH the
      // STOMP invite (→ in-app `incomingRinging`) AND the native CallKit push;
      // dismissing the native screen then fires `actionCallEnded`, and turning
      // that into `rejectIncoming()` auto-declines a call the user never
      // touched (the reported "minimize → call gets declined" bug). Mirrors the
      // guard already in `_handleNativeCallEnded`. A GENUINE decline never
      // follows our own dismiss (there's no native screen left to decline), so
      // real declines — including killed+locked — are unaffected.
      if (signaling.recentlyDismissedNativeCallkit()) {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] _handleHangup: incomingRinging end follows '
          'our OWN native-CallKit dismiss — NOT rejecting (keeps the call '
          'ringing instead of auto-declining)',
        );
      } else {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] _handleHangup: state still '
          'incomingRinging — treating as decline',
        );
        await signaling.rejectIncoming();
      }
    } else if (active.state == CallSignalState.outgoingRinging) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleHangup: outgoing call '
        'cancelled before answer — hangup',
      );
      await signaling.hangup(finalStatus: ChatCallStatus.noAnswer);
    } else {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleHangup: state=${active.state} '
        '— nothing actionable',
      );
    }
    // Clear dedupe entry so a future call with this CID can run
    // (in practice CIDs are unique per call, but defensive cleanup
    // keeps the set from growing unbounded across a long session).
    _handledCallCids.remove(callCid);
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] ✅ CALL ENDED via Hang Up · '
      'callCid=$callCid · finalState=${signaling.current?.state}',
    );
  }

  /// iOS-only. Handles `incomingCallAnswered` pushed by the native
  /// CXCallObserver (AppDelegate.swift) when the user accepts on the native
  /// CallKit screen. The argument carries the matching
  /// `flutter_callkit_incoming` entry under `call` (with the Stream cid in
  /// `extra.callCid`); route it through the normal [_handleAccept] so the
  /// early backend accept POST + Stream join run exactly as on a
  /// foreground/minimized accept. The `_handledCallCids` dedupe inside
  /// [_handleAccept] makes this a no-op if the live `actionCallAccept`
  /// event also lands.
  Future<dynamic> _onIosNativeCallkit(MethodCall call) async {
    final args = call.arguments;
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] native CXCallObserver → '
      '${call.method} · args=$args',
    );
    // Normalise the payload: native sends `{uuid, call: {…extra.callCid…}}`
    // when the flutter_callkit_incoming entry is still listed, or just
    // `{uuid}` once it's gone. Both `_handleAccept` and `_handleHangup`
    // tolerate the bare-uuid shape (hangup falls back to `_active.callId`).
    final dynamic body =
        (args is Map && args['call'] is Map) ? args['call'] : args;
    if (body is! Map) return null;
    switch (call.method) {
      case 'incomingCallAnswered':
        // User accepted on the native CallKit screen (lock screen / killed
        // cold-start). `_handledCallCids` dedupe makes this a no-op if the
        // live `actionCallAccept` event also lands.
        await _handleAccept(body);
      case 'incomingCallEnded':
        // User tapped End on the native CallKit screen while backgrounded/
        // locked. `actionCallEnded` doesn't reach the Dart onEvent
        // subscription there, so this bridge is the only signal that lets us
        // POST the hang-up and stop the CALLER being stuck "in call".
        await _handleNativeCallEnded(body);
    }
    return null;
  }

  /// iOS-only. Handles `incomingCallEnded` from the native CXCallObserver
  /// (AppDelegate.swift) when the user tapped End on the native CallKit
  /// screen while the app was backgrounded/locked.
  ///
  /// Drives the hang-up straight off the live signaling state rather than the
  /// bridged CallKit payload — by the time the call ends, the
  /// flutter_callkit_incoming entry may already be gone, so its `callCid`
  /// can be absent. `_active` always carries the backend call id, so
  /// `signaling.hangup()` POSTs `/end` reliably → the backend broadcasts
  /// `call.hangup` and the CALLER's call ends.
  Future<void> _handleNativeCallEnded(dynamic body) async {
    final signaling = _safelyGet<CallSignalingService>();
    final active = signaling?.current;
    if (signaling == null || active == null) {
      // Killed-app cold-start: the dead app never processed a STOMP invite, so
      // no in-app call was ever seeded — there's nothing to hang up LOCALLY.
      // But a genuine user DECLINE on the native CallKit screen must still
      // reach the backend or the CALLER keeps ringing (the reported bug). POST
      // the reject directly using the id captured when the ring appeared.
      //
      // Skip when this `hasEnded` is our OWN programmatic dismiss — e.g. the
      // bg-ring poll already cleared the ring because the CALLER cancelled, in
      // which case the call is already over and there's no decline to relay.
      // The backend `reject()` is idempotent for an already-answered/ended
      // participant, so a late/duplicate POST is harmless either way.
      final ownDismiss = signaling?.recentlyDismissedNativeCallkit() ?? false;
      var bgId = _lastIncomingBgCallId ?? '';
      if (bgId.isEmpty) {
        // Killed-app FAST reject: the Dart `actionCallIncoming` that sets
        // `_lastIncomingBgCallId` may not have run before the user tapped
        // Decline, leaving bgId empty (the reported bug — caller kept
        // ringing). Recover the backend id straight from the native payload's
        // call entry (extra.callCid), which AppDelegate stashes when the ring
        // first appears so it survives the decline removing the entry from
        // activeCalls().
        final p = _params(body);
        final cid = (p['call_cid'] ?? p['callCid'])?.toString() ?? '';
        if (cid.isNotEmpty) bgId = _parseBackendCallId(cid);
      }
      if (!ownDismiss && bgId.isNotEmpty) {
        // ignore: avoid_print
        print('[CallkitEventHandler] native End · no active call → direct '
            'reject POST for callId=$bgId (killed-app decline)');
        await _directRejectNoDi(bgId);
      } else {
        // ignore: avoid_print
        print('[CallkitEventHandler] native End · no active call — nothing to '
            'hang up (ownDismiss=$ownDismiss bgId=$bgId)');
      }
      return;
    }
    // CRITICAL: ignore a `hasEnded` that WE caused by dismissing the native
    // CallKit screen ourselves (the foreground/unlocked case-1 takeover ends
    // the CXCall via reportCall(endedAt:) so the in-app UI can show). That is
    // NOT a user End tap — treating it as one hangs up the live, just-
    // connected call (the reported case-1 crash). A genuine native End (case
    // 3, locked) never runs `_clearNativeIncoming` during the call, so this
    // window is clear there and the hang-up proceeds normally.
    if (signaling.recentlyDismissedNativeCallkit()) {
      // ignore: avoid_print
      print('[CallkitEventHandler] native End IGNORED · this hasEnded is our '
          'own native-CallKit dismiss (foreground takeover), not a user End');
      return;
    }
    // Spurious-end guard: iOS can fire a connect→end blip in the first instant
    // after Accept. Ignore an end within a SHORT window of accepting THIS call
    // so it can't tear down a just-connected call. Kept deliberately small (1 s,
    // NOT the 6 s `_handleHangup` uses) because on this native CXCallObserver
    // path the only "spurious" end is an immediate sub-second blip, and a real
    // user End can land just 2–3 s in — a wide window would swallow it and
    // leave the caller ringing. (Keyed on the same streamCallCid `_acceptedAt`
    // was written with in `_handleAccept`.)
    const nativeEndHandoff = Duration(seconds: 1);
    final cid = active.streamCallCid;
    if (cid != null && cid.isNotEmpty) {
      final acceptedAt = _acceptedAt[cid];
      if (acceptedAt != null &&
          DateTime.now().difference(acceptedAt) < nativeEndHandoff) {
        // ignore: avoid_print
        print('[CallkitEventHandler] native End IGNORED · within '
            '${nativeEndHandoff.inMilliseconds}ms accept handoff window');
        return;
      }
    }
    // ignore: avoid_print
    print('[CallkitEventHandler] native End → hanging up active call '
        '${active.callId} (state=${active.state})');
    if (active.state == CallSignalState.connected) {
      await signaling.hangup(finalStatus: ChatCallStatus.answered);
    } else if (active.state == CallSignalState.incomingRinging) {
      await signaling.rejectIncoming();
    } else if (active.state == CallSignalState.outgoingRinging) {
      await signaling.hangup(finalStatus: ChatCallStatus.noAnswer);
    }
    if (cid != null) _handledCallCids.remove(cid);
  }

  Future<void> _handleAccept(dynamic body) async {
    // ignore: avoid_print
    print('[CallkitEventHandler] _handleAccept ENTER · body=$body');
    final params = _params(body);
    // The CallKit entry built by Stream's native iOS VoIP-push handler stores
    // the Stream cid under `callCid` (camelCase) in `extra`, whereas our own
    // FCM path (Android) uses `call_cid` (snake_case). Check both before the
    // `id` fallback — `id` is the CallKit UUID, never a Stream cid, so it's a
    // last resort only. (Additive: Android's `call_cid` still wins first.)
    final rawCid =
        (params['call_cid'] ?? params['callCid'])?.toString() ??
        params['id']?.toString();
    if (rawCid == null || rawCid.isEmpty) {
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleAccept BAIL · missing call_cid');
      return;
    }
    // Non-final so the UUID-only locked-accept path can rewrite it to the REAL
    // Stream cid once recovered from the backend (see the recovery block after
    // the dedupe below). Dedupe + `_acceptedAt` intentionally key off the
    // ORIGINAL native identity (the UUID) — that's what the duplicate native
    // events carry.
    var callCid = rawCid;
    // Dedupe: on minimize→accept the live `actionCallAccept` event
    // AND the +2 s stale-CallKit recovery can BOTH fire for the same
    // call. The second pass would run another `acceptByCid` whose
    // `leave()` tears down the just-connected call — that's why the
    // user heard nothing despite the chat backend returning 200 OK.
    // Skip if we've already handled this CID in the current session
    // OR if signaling already shows the call as connected.
    if (_handledCallCids.contains(callCid)) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleAccept SKIPPED (duplicate) · '
        'callCid=$callCid is already being handled in another '
        'invocation',
      );
      return;
    }
    final priorSignaling = _safelyGet<CallSignalingService>();
    final prior = priorSignaling?.current;
    if (prior != null &&
        prior.streamCallCid == callCid &&
        prior.state == CallSignalState.connected) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleAccept SKIPPED (already connected) · '
        'callCid=$callCid is already in connected state — '
        'second pass would tear down the working call',
      );
      _handledCallCids.add(callCid);
      return;
    }
    _handledCallCids.add(callCid);
    // Remember WHEN we accepted this call. iOS CallKit fires a spurious
    // `actionCallEnded` a moment after Accept (we can't call the plugin's
    // setCallConnected — its native PushKit path force-unwraps a nil and
    // crashes). `_handleHangup` uses this timestamp to ignore that spurious
    // end so it doesn't get turned into a hangup that closes the CALLER's
    // call. iOS-only; Android neither writes nor reads this map.
    if (Platform.isIOS) _acceptedAt[callCid] = DateTime.now();
    final isVideo = (params['type']?.toString() == '1');
    final signaling = _safelyGet<CallSignalingService>();

    // LOCKED/killed accept recovery. On iOS the ring is presented by Stream's
    // native VoIP push, whose CallKit call is owned by Stream's PushKit
    // provider — so the accept payload that reaches us is frequently UUID-ONLY
    // (no `extra.callCid`). Parsing that UUID would mis-read its leading hex as
    // a stale numeric call id and POST /accept to a long-dead call, leaving the
    // CALLER stuck on "Calling…" (exactly the reported bug). Detect the
    // UUID-only case (no `:` AND not a pure numeric id) and recover the REAL
    // ringing call straight from the authoritative backend before anything
    // posts. If nothing is ringing, ABORT rather than corrupt a stale call.
    // iOS-only + additive: Android's FCM path always carries `call_cid`, so
    // `hasRealCid` is true there and this block is skipped.
    if (Platform.isIOS && signaling != null) {
      final hasRealCid =
          callCid.contains(':') || _parseBackendCallId(callCid).isNotEmpty;
      if (!hasRealCid) {
        // ignore: avoid_print
        print('[CallkitEventHandler] _handleAccept · UUID-only accept '
            '($callCid) → recovering real ringing call from backend');
        final rec = await signaling.recoverRingingInviteFromBackend();
        if (rec != null) {
          callCid = (rec.streamCallCid != null && rec.streamCallCid!.isNotEmpty)
              ? rec.streamCallCid!
              : 'default:erp-call-${rec.callId}';
          // ignore: avoid_print
          print('[CallkitEventHandler] _handleAccept · recovered real cid '
              '$callCid (backend call id=${rec.callId})');
        } else {
          // ignore: avoid_print
          print('[CallkitEventHandler] _handleAccept ABORT · UUID-only accept '
              'and no ringing call on backend — a stale CallKit notification, '
              'nothing to accept');
          return;
        }
      }
    }

    // iOS killed/locked cold-start safety net — fire the BACKEND accept
    // POST FIRST, decoupled from everything below. The reported bug: the
    // callee accepts (native CallKit shows the in-call timer) but the
    // CALLER stays stuck on "Calling…" because nothing tells the backend
    // we answered. The normal signal lives at the END of the flow
    // (acceptIncoming → POST), behind a seed-`_active` + page-push chain
    // that a LOCKED cold-start can suspend before it reaches the POST.
    // Posting here — using the numeric id parsed straight from the
    // CallKit cid — guarantees the backend records the answer and
    // re-broadcasts `call.accept` to the caller at the earliest possible
    // moment, so the caller's ring stops regardless of what happens to
    // the media/UI legs afterwards. Fire-and-forget + idempotent; the
    // acceptIncoming POST below is harmless after it. iOS-only +
    // additive: Android keeps its single accept inside acceptIncoming.
    if (Platform.isIOS && signaling != null) {
      final earlyId = _parseBackendCallId(callCid);
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] iOS early accept → '
        'notifyBackendAcceptEarly($earlyId) so the caller stops ringing '
        'even if the rest of the accept flow is suspended/slow',
      );
      unawaited(signaling.notifyBackendAcceptEarly(earlyId));
    }
    // VoIP-push CallKit entries carry the caller under CallKit's native keys
    // (`handle` / `nameCaller`); our FCM path uses `caller_id` / `caller_name`.
    // Accept both so the iOS background-accept flow has the caller context it
    // needs to seed signaling (without it, step 1 below is skipped and
    // acceptIncoming bails). Additive — Android's keys still take priority.
    final callerId =
        (params['caller_id'] ?? params['handle'])?.toString() ?? '';
    final callerName =
        (params['caller_name'] ?? params['nameCaller'])?.toString() ?? callerId;
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] _handleAccept · '
      'callCid=$callCid · callerId=$callerId · callerName=$callerName · '
      'isVideo=$isVideo · signaling=${signaling != null}',
    );

    // Resolve the LOCAL conversation id (not Stream's call CID) so
    // the call page's `ConversationsRepository.watchById(...)` finds
    // the real entity → caller name + avatar render correctly. Falls
    // back to the CID only if the lookup fails.
    String resolvedConvId = callCid;
    final conversations = _safelyGet<ConversationsRepository>();
    if (conversations != null && callerId.isNotEmpty) {
      try {
        final direct = await conversations.findDirectWith(callerId);
        if (direct != null) resolvedConvId = direct.id;
      } catch (_) {
        /* fall through to CID */
      }
    }
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] _handleAccept · resolvedConvId=$resolvedConvId',
    );

    // 1) Seed signaling state FIRST so the call page mounts with an
    //    ActiveCall already in place — no overlay flash. State is
    //    `incomingRinging` momentarily; acceptIncoming below flips it
    //    to `connected`.
    if (signaling != null && callerId.isNotEmpty) {
      final payload = <String, dynamic>{
        'type': 'call.invite',
        'callId': _parseBackendCallId(callCid),
        'conversationId': resolvedConvId,
        'callerId': callerId,
        'callerName': callerName,
        'callType': isVideo ? 'video' : 'voice',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'streamCallCid': callCid,
      };
      // ignore: avoid_print
      print('[CallkitEventHandler] step 1 → handleIncomingFromPush');
      await signaling.handleIncomingFromPush(payload);
    } else if (signaling != null &&
        signaling.current == null &&
        Platform.isIOS) {
      // iOS killed/locked cold-start: Stream's native VoIP-push CallKit
      // entry frequently carries NO caller id (`handle`/`caller_id`
      // empty), so the branch above is skipped and `_active` is never
      // seeded. Then step 3's `acceptIncoming()` bails ("no active call")
      // and — the reported bug — never POSTs `/accept`, so the CALLER is
      // never told we answered and stays stuck on "Calling…" (D's log
      // shows no action taken to update the call state).
      //
      // Seed from the CallKit cid alone: `_parseBackendCallId` yields the
      // numeric backend id, which is all `sendCallAccept` (an HTTP POST,
      // so it works even before the STOMP socket reconnects on cold
      // start) needs to record the answer — the backend then broadcasts
      // `call.accept` to the caller and the ring stops. The peer name is
      // backfilled from the conversation/STOMP once it resolves.
      //
      // Additive + iOS-guarded: Android's FCM path always carries
      // `caller_id`, so `callerId.isNotEmpty` is already true there and
      // this branch never runs — no Android behaviour change. The
      // `signaling.current == null` guard keeps it from disturbing a
      // foreground/minimized accept whose STOMP invite already seeded
      // `_active`.
      final payload = <String, dynamic>{
        'type': 'call.invite',
        'callId': _parseBackendCallId(callCid),
        'conversationId': resolvedConvId,
        'callerId': callerId,
        if (callerName.isNotEmpty) 'callerName': callerName,
        'callType': isVideo ? 'video' : 'voice',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'streamCallCid': callCid,
      };
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] step 1 (iOS no-caller-id) → '
        'handleIncomingFromPush · seeding _active from cid '
        '${_parseBackendCallId(callCid)} so acceptIncoming can POST '
        '/accept and stop the caller ringing',
      );
      await signaling.handleIncomingFromPush(payload);
    }

    // 2) Push the call page with the RESOLVED conv id so the page
    //    can render the caller's name + avatar from the local conv.
    //    On cold start the navigator key may briefly be null while
    //    MaterialApp.router is still building. Retry a few times
    //    (40 ms × 25 = 1 s total) before giving up — without this,
    //    the user lands on the home screen with audio flowing but
    //    no in-call UI ("Accept didn't work" from their POV).
    //
    // NOTE: even with the retry, on a true cold-start the push can
    // race with go_router's splash → dashboard redirect — go_router
    // replaces the stack and our pushed route is wiped. The
    // IncomingCallOverlay has a backup `_autoPushOnConnected`
    // listener that fires when state goes to connected and re-pushes
    // if the call page isn't mounted (checked via
    // `VoiceCallPage.isMounted` / `VideoCallPage.isMounted`).
    await _pushCallPageWithRetry(
      isVideo: isVideo,
      conversationId: resolvedConvId,
    );

    // 3) Run the full accept flow — POSTs to our backend's
    //    `/chats/calls/{id}/accept` AND calls `streamEngine.join`
    //    which does Stream's `accept()` + `join()`. This transitions
    //    ActiveCall to `connected`, collapses any overlay, audio
    //    starts flowing.
    if (signaling != null) {
      // ignore: avoid_print
      print('[CallkitEventHandler] step 3 → signaling.acceptIncoming()');
      await signaling.acceptIncoming();
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] step 3 done · '
        'active.state=${signaling.current?.state}',
      );
    } else {
      final engine = _safelyGet<StreamCallEngine>();
      if (engine != null) {
        // ignore: avoid_print
        print('[CallkitEventHandler] step 3 fallback → engine.acceptByCid');
        await engine.acceptByCid(callCid: callCid, isVideo: isVideo);
      }
    }
    // Terminal status log so the success/failure of the whole flow
    // is unambiguous in the log stream — easy to grep for.
    final finalState = signaling?.current?.state;
    if (finalState == CallSignalState.connected) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] ✅ CALL CONNECTED · callCid=$callCid '
        '· _handleAccept EXIT',
      );
    } else {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] ⚠ ACCEPT DID NOT REACH CONNECTED · '
        'finalState=$finalState callCid=$callCid · _handleAccept EXIT',
      );
    }
  }

  Future<void> _handleDecline(dynamic body) async {
    // ignore: avoid_print
    print('[CallkitEventHandler] _handleDecline ENTER · body=$body');
    final params = _params(body);
    // iOS VoIP-push entries use `callCid` (camelCase); FCM uses `call_cid`.
    // Check both before the CallKit-UUID `id` fallback. (Additive — Android
    // unaffected.)
    final callCid =
        (params['call_cid'] ?? params['callCid'])?.toString() ??
        params['id']?.toString();
    if (callCid == null || callCid.isEmpty) {
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleDecline BAIL · missing call_cid');
      return;
    }
    // Ignore a decline produced by our own foreground CallKit suppression.
    if (_isSuppressedEnd(callCid)) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleDecline IGNORED · from foreground '
        'CallKit suppression · callCid=$callCid',
      );
      return;
    }
    // VoIP-push CallKit entries use CallKit's native keys (`handle` /
    // `nameCaller`); the FCM path uses `caller_id` / `caller_name`. Read both
    // so step 2 (backend reject + call-log) runs on an iOS background decline
    // instead of being skipped for an empty callerId. Additive — Android keys
    // take priority and are unaffected.
    final callerId =
        (params['caller_id'] ?? params['handle'])?.toString() ?? '';
    final callerName =
        (params['caller_name'] ?? params['nameCaller'])?.toString() ?? callerId;
    final isVideo = (params['type']?.toString() == '1');
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] _handleDecline · callCid=$callCid '
      'callerId=$callerId callerName=$callerName isVideo=$isVideo',
    );

    // 1) Tell Stream we're declining the ringing call. Uses a fresh
    //    Call reference + `.reject()` so the caller sees a "declined"
    //    signal immediately (without waiting for the ring timeout).
    final engine = _safelyGet<StreamCallEngine>();
    if (engine != null) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleDecline step 1 → '
        'streamEngine.rejectByCid(cid=$callCid)',
      );
      await engine.rejectByCid(callCid: callCid);
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleDecline step 1 done');
    } else {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleDecline step 1 SKIPPED · '
        'no StreamCallEngine in GetIt yet (cold-start race)',
      );
    }

    // 2) Tell our backend via /chats/calls/{id}/reject. This requires
    //    `_active` to be set — seed it first if needed (the user may
    //    have hit Decline without ever opening the in-app overlay, so
    //    no prior path populated _active). Lookup the local conv id
    //    too so the call-log entry attaches to the right conversation.
    final signaling = _safelyGet<CallSignalingService>();
    if (signaling == null) {
      // Killed-app cold-start: the VoIP push woke the process but DI hasn't
      // finished wiring up, so the normal reject path (rejectIncoming → REST)
      // can't run — and unlike Android (native erp_callkit reject receiver),
      // iOS has no native fallback, so the CALLER keeps ringing. POST the
      // reject directly with the stored access token so the backend broadcasts
      // `call.reject` to the caller. iOS-only; idempotent on the backend.
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleDecline step 2 · no DI yet '
          '(killed cold-start) → direct reject POST');
      await _directRejectNoDi(_parseBackendCallId(callCid));
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleDecline EXIT (direct reject)');
      return;
    }
    if (callerId.isEmpty) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleDecline step 2 SKIPPED · '
        'callerId empty — falling back to direct reject POST',
      );
      // Still tell the backend so the caller stops ringing.
      await _directRejectNoDi(_parseBackendCallId(callCid));
      // ignore: avoid_print
      print('[CallkitEventHandler] _handleDecline EXIT (partial)');
      return;
    }
    if (signaling.current == null) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] _handleDecline step 2 · '
        'seeding signaling state via handleIncomingFromPush',
      );
      String resolvedConvId = callCid;
      final conversations = _safelyGet<ConversationsRepository>();
      if (conversations != null) {
        try {
          final direct = await conversations.findDirectWith(callerId);
          if (direct != null) resolvedConvId = direct.id;
        } catch (_) {
          /* ignore */
        }
      }
      final payload = <String, dynamic>{
        'type': 'call.invite',
        'callId': _parseBackendCallId(callCid),
        'conversationId': resolvedConvId,
        'callerId': callerId,
        'callerName': callerName,
        'callType': isVideo ? 'video' : 'voice',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'streamCallCid': callCid,
      };
      await signaling.handleIncomingFromPush(payload);
    }
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] _handleDecline step 2 → '
      'signaling.rejectIncoming()',
    );
    await signaling.rejectIncoming();
    // Clear dedupe entry — declines also count as a terminal action.
    _handledCallCids.remove(callCid);
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] _handleDecline EXIT · '
      'active.state=${signaling.current?.state}',
    );
  }

  /// Push the in-call page onto the root navigator, retrying briefly
  /// if the navigator key isn't attached yet (happens on cold start
  /// when this fires before `MaterialApp.router` has finished its
  /// first build). 40 ms × 25 = 1 s total ceiling — well under the
  /// time it takes a user to notice the missing UI.
  Future<void> _pushCallPageWithRetry({
    required bool isVideo,
    required String conversationId,
  }) async {
    // Skip if a call page is already mounted (from a prior accept's
    // push that succeeded, or from the IncomingCallOverlay's
    // auto-push fallback that fired first). The mount flag is the
    // single source of truth — it reflects ACTUAL route state, so
    // it correctly says "no" when go_router wiped a prior push.
    final alreadyMounted = isVideo
        ? VideoCallPage.isMounted
        : VoiceCallPage.isMounted;
    if (alreadyMounted) {
      // ignore: avoid_print
      print(
        '[CallkitEventHandler] step 2 SKIPPED · '
        '${isVideo ? "Video" : "Voice"}CallPage already mounted',
      );
      return;
    }
    for (var attempt = 0; attempt < 25; attempt++) {
      final navigator = AppRouter.rootNavigatorKey.currentState;
      if (navigator != null) {
        // ignore: avoid_print
        print(
          '[CallkitEventHandler] step 2 → pushing '
          '${isVideo ? "VideoCallPage" : "VoiceCallPage"}'
          '(conversationId=$conversationId) on attempt ${attempt + 1}',
        );
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => isVideo
                ? VideoCallPage(conversationId: conversationId)
                : VoiceCallPage(conversationId: conversationId),
            fullscreenDialog: true,
          ),
        );
        return;
      }
      await Future.delayed(const Duration(milliseconds: 40));
    }
    // ignore: avoid_print
    print(
      '[CallkitEventHandler] step 2 GAVE UP → root navigator '
      'never came up after 1 s — call audio may flow but user is '
      'stuck on whatever screen was visible at cold start',
    );
  }

  /// CallKit event body is `Map` on Android / iOS — wraps params we
  /// passed via `CallKitParams.extra` plus the call id under top-level
  /// keys. Defensive accessor — returns empty map on any oddity.
  Map<dynamic, dynamic> _params(dynamic body) {
    if (body is Map) {
      // Common shape: {id, nameCaller, extra: {call_cid: ..., ...}}
      final extra = body['extra'];
      if (extra is Map) {
        return {...body, ...extra};
      }
      return body;
    }
    return const <String, dynamic>{};
  }

  /// Self-contained `POST /chats/calls/{id}/reject` that does NOT depend on
  /// `get_it` / DI being wired up. Used on a KILLED-app decline: the VoIP push
  /// woke the process and showed the CallKit ring, but the cold-started engine
  /// may not have finished `configureDependencies()` when the user taps
  /// Decline, so `CallSignalingService` (and its authed Dio) aren't available.
  /// Without this the backend never learns D declined and the CALLER keeps
  /// ringing (Android has a native reject receiver; iOS did not). Reads the
  /// access token straight from secure storage (same key/options as
  /// `SecureTokenStorage`) and hits the REST endpoint with a throwaway Dio.
  /// iOS-only, best-effort; the backend reject is idempotent.
  Future<void> _directRejectNoDi(String callId) async {
    if (!Platform.isIOS) return;
    final n = int.tryParse(callId);
    if (n == null) {
      // ignore: avoid_print
      print('[CallkitEventHandler] _directRejectNoDi BAIL · bad callId=$callId');
      return;
    }
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
      );
      // SecureTokenStorage persists all tokens as one JSON blob under this key.
      final raw = await storage.read(key: 'auth.tokens.v1');
      if (raw == null || raw.isEmpty) {
        // ignore: avoid_print
        print('[CallkitEventHandler] _directRejectNoDi BAIL · no stored tokens');
        return;
      }
      final decoded = jsonDecode(raw);
      final token =
          decoded is Map ? decoded['accessToken'] as String? : null;
      if (token == null || token.isEmpty) {
        // ignore: avoid_print
        print('[CallkitEventHandler] _directRejectNoDi BAIL · no accessToken');
        return;
      }
      final dio = Dio(BaseOptions(
        baseUrl: Environments.prodApiBaseUrl,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      await dio.post<dynamic>(
        '/chats/calls/$n/reject',
        queryParameters: <String, dynamic>{'reason': 'declined'},
      );
      // ignore: avoid_print
      print('[CallkitEventHandler] _directRejectNoDi · POST /reject OK '
          'callId=$n — caller should stop ringing');
      // CRITICAL (killed-app "2nd call no ring" fix): the cold-start that woke
      // this killed app connected STOMP, which marks us ONLINE on the backend
      // AND clears any prior `backgrounded` flag. With presence ONLINE the
      // backend's ring gate SKIPS the apn/VoIP push for the NEXT call — so a
      // follow-up call shows no ring. Re-assert OFFLINE with the SAME DI-less
      // Dio: the backend's `backgrounded` flag overrides the live STOMP session
      // in `statusOf()`, so the next call rings via apn again. Best-effort.
      try {
        await dio.post<dynamic>('/chats/presence/background');
        // ignore: avoid_print
        print('[CallkitEventHandler] _directRejectNoDi · POST '
            '/presence/background OK — next call will ring via apn');
      } catch (e) {
        // ignore: avoid_print
        print('[CallkitEventHandler] _directRejectNoDi · presence/background '
            'failed: $e');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[CallkitEventHandler] _directRejectNoDi · POST /reject failed: $e');
    }
    // DI-available path (engine alive): also drop STOMP + Stream WS locally so
    // they don't reconnect and clear the `backgrounded` flag we just set.
    // No-op when foreground / DI not ready.
    await _safelyGet<CallSignalingService>()?.goOfflineForPushIfBackground();
  }

  /// Extract backend numeric id from Stream's CID format
  /// (e.g. `default:erp-call-42` → `42`). Falls back to the CID
  /// verbatim if the format doesn't match.
  String _parseBackendCallId(String callCid) {
    final id = callCid.contains(':') ? callCid.split(':').last : callCid;
    // ANCHORED at both ends: the token must be a pure number (optionally
    // `erp-call-` prefixed). A bare CallKit UUID like "3CEBBE0D-74E2-…" must
    // NOT match — otherwise its leading hex digit is read as a (stale) call id
    // and we POST /accept to a long-dead call, stranding the caller on
    // "Calling…". Returns '' on no-match so callers can detect "not a real id".
    final match = RegExp(r'^(?:erp-call-)?(\d+)$').firstMatch(id);
    return match?.group(1) ?? '';
  }

  /// `GetIt.I<T>()` throws if not yet registered (rare on cold-start
  /// from CallKit). Log + skip rather than crash on the event handler.
  T? _safelyGet<T extends Object>() {
    try {
      return GetIt.I<T>();
    } catch (_) {
      return null;
    }
  }
}

// ChatCallType is referenced via the existing entities/call_log.dart
// only to keep import lists tidy; the handler itself doesn't reach
// for its enum members directly.
// ignore: unused_element
ChatCallType? _unusedTypeAnchor() => null;
