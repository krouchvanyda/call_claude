import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../entities/call_log.dart';
import 'call_signaling_service.dart';
import 'callkit_event_handler.dart';
import 'chat_settings.dart';
import 'chat_transport.dart';
import 'repositories/presence_repository.dart';
import 'stream_call_engine.dart';

/// Slice 10.2.6 — keeps [ChatTransport] in sync with the app's
/// foreground / background lifecycle.
///
/// **What this fixes:**
/// - Android / iOS routinely suspend long-lived TCP sockets when the
///   app is backgrounded; the OS may keep them alive for a few minutes
///   but typically not longer. When the user returns to the app the
///   socket can be silently dead, so the auto-reconnect needs a kick.
/// - Some manufacturer ROMs throttle networking aggressively in the
///   background, which can drop call invites that arrive during that
///   window. Forcing a reconnect on `resumed` makes sure we catch the
///   missed-call rows the next time the transport syncs.
///
/// **What this CANNOT fix (and the killed-app honesty note):**
/// The WebSocket relay is a local-LAN demo. When the OS terminates
/// the app process (force-stop, low memory kill, swipe-away on some
/// devices) the socket is gone and there is no background service to
/// re-open it. A peer's `call.invite` envelope hits nobody and the
/// log row stays in `noAnswer` / `missed` forever. The production
/// path for this is FCM / APNs push: a backend wakes the device with
/// a high-priority push, which spins up a background isolate that
/// shows the incoming call sheet via `flutter_local_notifications`.
/// None of that is wired here — see CLAUDE.md slice 10.2.6.
class ChatLifecycleBridge with WidgetsBindingObserver {
  ChatLifecycleBridge({
    required this.transport,
    required this.settings,
    required this.presence,
    required this.streamEngine,
    required this.signaling,
  });

  final ChatTransport transport;
  final ChatSettings settings;
  final PresenceRepository presence;
  final StreamCallEngine streamEngine;
  final CallSignalingService signaling;

  /// True when there is no live call right now — i.e. it's safe to force
  /// the Stream WS down on background. A call that's merely `ended` (or
  /// absent) counts as "no active call"; anything still ringing /
  /// connected must keep the socket so the audio leg survives a mid-call
  /// minimize.
  bool _noActiveCall() {
    final active = signaling.current;
    return active == null || active.state == CallSignalState.ended;
  }

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        // Process is about to die (user swiped from recents / OS
        // low-memory kill / Force Stop). End any in-flight call
        // FIRST so audio doesn't leak past the app and the peer
        // gets a clean hangup envelope instead of an unexplained
        // disconnect. detached is best-effort — Android sometimes
        // skips it under aggressive task removal, in which case
        // Stream's own 60 s ring timer will eventually catch up,
        // but for the common path this is what stops "phone keeps
        // ringing on A after B killed the app" cleanly.
        final active = signaling.current;
        if (active != null &&
            active.state == CallSignalState.connected) {
          if (Platform.isIOS) {
            // iOS carve-out — DO NOT hang up here. A lock-screen / killed-
            // app accept runs with NO foreground Flutter UI, so iOS fires
            // `detached` on the cold-started process a few seconds AFTER the
            // call connects, even though the user wants to keep talking.
            // Hanging up here self-terminates a perfectly live call — the
            // reported "D accepts, C and D connect, then the app closes the
            // call". On iOS `detached` is NOT a reliable "process dying"
            // signal during a call: the audio background mode + the live
            // CallKit audio session keep the process alive. A GENUINE kill
            // is still handled from the other side — the peer's connected-
            // heartbeat + Stream's remote-left detection end the call when
            // our media actually drops. So we leave the call running here.
            // Android keeps the eager hangup below (its `detached` IS a real
            // task-removal signal).
            // ignore: avoid_print
            print('[ChatLifecycle] iOS detached during active call '
                '${active.callId} — NOT hanging up (lock-screen accept has '
                'no foreground UI; CallKit audio session keeps us alive)');
          } else {
            // ignore: avoid_print
            print('[ChatLifecycle] detached during active call '
                '${active.callId} — hanging up before process death');
            // Fire-and-forget: the await won't complete because the
            // isolate is shutting down, but the wire call is queued
            // and Dio will flush it before the OS reclaims the
            // process in most cases. Same for streamEngine.leave().
            unawaited(signaling.hangup(
              finalStatus: ChatCallStatus.answered,
            ));
          }
        }
        transport.pause();
        streamEngine.disconnectForBackground(force: _noActiveCall());
        // Beacon: mark us OFFLINE on the server now (process dying) so a
        // follow-up call rings this device via VoIP/CallKit.
        unawaited(presence.reportBackground());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Explicitly drop the STOMP socket so the backend's
        // heartbeat detects the disconnect immediately and fans
        // `presence.update {status: OFFLINE, lastSeenAt: now}` to
        // every peer's `/topic/presence`. Without this, the OS would
        // keep the TCP socket alive for minutes after minimise — so
        // peers would keep seeing us as Online instead of Away (the
        // 5-min effectiveStatus heuristic on the receiver maps a
        // fresh-OFFLINE to AWAY for the right amber-dot rendering).
        transport.pause();
        // ALSO drop Stream's WebSocket so the SDK's coordinator marks
        // this client offline. Stream prefers WS over FCM when it
        // thinks a client is online — if we leave the WS up while
        // backgrounded, Stream pushes the incoming-call event over
        // WS only, our in-app overlay can't render (app not visible),
        // and the native ringer never fires. Dropping the WS makes
        // Stream fall back to FCM, which `flutter_callkit_incoming`
        // renders as a native full-screen ringer.
        //
        // No-op when there's an active call (would kill audio mid-
        // conversation; the engine itself enforces that guard) —
        // standard calling-app behaviour: minimize keeps the call
        // alive so the user can multitask while talking.
        //
        // `force` (iOS-only) when there's NO active signaling call: a
        // just-ended call can leave a stale setup flag / call ref in the
        // engine that makes the plain `disconnectForBackground` skip the
        // WS drop — and then the NEXT call to this minimized device rings
        // over the still-warm WS (no native CallKit header). Forcing past
        // the guard once the call is provably over fixes the "2nd call no
        // ring" report. Mid-call minimize is untouched (`_noActiveCall`
        // is false then, so `force` is false → audio stays alive).
        streamEngine.disconnectForBackground(force: _noActiveCall());
        // Beacon: tell the server we minimized so it flips us OFFLINE
        // INSTANTLY — without this, the OS-suspended socket keeps our STOMP
        // session "ONLINE" for ~20-30s (heartbeat timeout), so a call placed
        // in that window is wrongly treated as foreground and the VoIP/CallKit
        // ring is skipped (the "minimized: no ring" bug). Fire-and-forget;
        // the heartbeat timeout is the fallback if the POST doesn't flush.
        unawaited(presence.reportBackground());
      case AppLifecycleState.resumed:
        // Re-open the socket so we're Online again. Once connected
        // our presence flips back to ONLINE server-side and peers'
        // dots turn green.
        transport.resume();
        // Beacon: tell the server we're foreground again so the next
        // incoming call uses the in-app overlay (no CallKit). The STOMP
        // reconnect also clears the backgrounded flag, but this is instant.
        unawaited(presence.reportForeground());
        // Re-hydrate presence: the broker may have advanced while we
        // were backgrounded, and `/topic/presence` only delivers
        // deltas (not the current snapshot) once we reconnect.
        presence.loadAll();
        // Re-warm Stream so incoming-call events flow over the live
        // WS path again while we're in foreground. Idempotent.
        streamEngine.warmUp();
        // Re-subscribe + check for any pending CallKit accept that
        // fired while we were backgrounded. The plugin's onEvent
        // stream drops events while the app's main isolate is paused,
        // so the user tapping Accept on the native ringer may have
        // brought us back to foreground without us catching the
        // Accept event. This re-runs the subscription and queries
        // `activeCalls()` to recover from that.
        CallkitEventHandler.instance.onAppResumed();
      case AppLifecycleState.inactive:
        // Brief transition (incoming call sheet, control-center on
        // iOS, etc.) — don't tear the socket down here, the user
        // hasn't actually backgrounded us.
        break;
    }
  }
}
