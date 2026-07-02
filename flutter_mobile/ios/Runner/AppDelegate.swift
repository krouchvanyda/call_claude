import Flutter
import UIKit
import Firebase
import flutter_local_notifications
import stream_video_push_notification
import flutter_callkit_incoming
import CallKit
import AVFAudio
import StreamWebRTC

@main
@objc class AppDelegate: FlutterAppDelegate, CXCallObserverDelegate, CallkitIncomingAppDelegate {
  // Genuine on-screen state. Updated ONLY on real lifecycle transitions —
  // deliberately NOT on the transient `.inactive` that CallKit triggers when
  // it presents over a foreground app, and it starts `false` so a VoIP-push
  // COLD LAUNCH (killed app) is treated as background. So this is true only
  // when the app is actually on screen. This is the accurate, device-local,
  // zero-lag answer to "is the user in the app right now?" — far better than
  // backend presence, which can't know the instant the user backgrounds.
  private var isAppForeground = false

  // Observes every CallKit call so we can instantly tear down an incoming
  // screen that appears while the app is foreground.
  private let callObserver = CXCallObserver()

  // The Dart-side method channel (`erp/ios_callkit`). Kept as a property so
  // the CXCallObserver can push a native→Dart `incomingCallAnswered` event
  // (see callObserver below). nil until the FlutterViewController is ready.
  private var callkitChannel: FlutterMethodChannel?

  // UUIDs we've already reported as answered, so the CXCallObserver (which
  // fires repeatedly for one call) drives the Dart accept flow only once.
  private var answeredCallUUIDs = Set<String>()

  // Ringing incoming entries (each carries extra.callCid) stashed by uuid the
  // moment the call appears, ONLY while backgrounded/killed. A fast DECLINE
  // removes the call from `activeCalls()` before our `notifyIncomingCallEnded`
  // runs, so without this stash Dart receives a bare uuid and can't POST the
  // reject → the CALLER stays stuck "Calling…". iOS-only; additive.
  private var lastIncomingCallByUuid: [String: [String: Any]] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // WebRTC MANUAL AUDIO — the fix for "locked accept connects (call.join OK)
    // but both sides are silent". In the default AUTOMATIC mode, WebRTC's audio
    // device module activates the shared AVAudioSession itself; on the LOCK
    // SCREEN iOS forbids an app from activating the session (device log:
    // "Session activation failed"), so the capture/playback unit never starts →
    // silence, even though the SFU media leg is healthy. In manual mode WebRTC
    // does NOT touch the session on its own — we enable audio explicitly
    // (RTCAudioSession.isAudioEnabled) once the session is live: via CallKit's
    // didActivate on the lock screen (below), and via the erp/ios_callkit
    // `setWebRtcAudioEnabled` channel after every join for the
    // foreground/outgoing/in-app paths (which CallKit never activates). Must be
    // set before any peer connection is built.
    RTCAudioSession.sharedInstance().useManualAudio = true
    RTCAudioSession.sharedInstance().isAudioEnabled = false

    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
          GeneratedPluginRegistrant.register(with: registry)
      }
    GeneratedPluginRegistrant.register(with: self)
    // Register the VoIP PushKit registry so iOS issues a VoIP token and
    // routes incoming-call pushes to CallKit. Without this, PushKit never
    // initializes → getDevicePushTokenVoIP() stays empty → the device never
    // registers with Stream → backgrounded incoming calls never ring.
    // (iOS-only; Android handles call push via FCM and is unaffected.)
    StreamVideoPKDelegateManager.shared.registerForPushNotifications()

    // FOREGROUND CallKit suppression (the real fix for "header shows while the
    // user is in the app").
    //
    // The backend always rings (ring: true) so a minimized/killed callee gets
    // the native CallKit screen. But Stream's VoIP push handler reports the
    // call to CallKit even when the app is FOREGROUND, where we want only the
    // in-app overlay. We can't decide this on the backend (it can't know the
    // instant the user backgrounds) — but the DEVICE knows its own state with
    // zero lag. So we observe every call and, the moment an incoming screen
    // appears while the app is genuinely on screen, end it via
    // CXProvider.reportCall(endedAt:) — the only API that dismisses a
    // PushKit-reported incoming call (a CXEndCallAction does NOT). A
    // backgrounded/killed app is NOT foreground here, so its ring is kept.
    callObserver.setDelegate(self, queue: DispatchQueue.main)

    // Track genuine on-screen state via NotificationCenter (not by overriding
    // FlutterAppDelegate's lifecycle methods). didBecomeActive / didEnterBackground
    // are the ONLY transitions we trust: CallKit presenting over a foreground
    // app fires willResignActive → .inactive but NOT didEnterBackground, so
    // `isAppForeground` correctly stays true through a foreground ring.
    NotificationCenter.default.addObserver(
      self, selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(appDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification, object: nil)

    // Dart-side safety-net channel (kept): lets the signaling layer also nudge
    // a dismiss for the rare group-call case where a foreground member is rung
    // alongside an offline one. Same reportCall path as the observer.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "erp/ios_callkit",
        binaryMessenger: controller.binaryMessenger)
      callkitChannel = channel
      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "isDeviceUnlocked":
          // Lock-state probe used by the Dart CallKit-suppression sweep.
          // `isProtectedDataAvailable` is true when the device is unlocked
          // and false once it locks (passcode devices). The sweep dismisses
          // the native CallKit ONLY when unlocked — on a locked accept the
          // native CallKit is the only call UI iOS permits on the lock
          // screen, so we must NOT dismiss it there. Defaults handled on the
          // Dart side. Public API; read-only; nothing else changes.
          result(UIApplication.shared.isProtectedDataAvailable)
        case "isAppForeground":
          // Genuine on-screen state — true ONLY after a real `didBecomeActive`
          // (set above), false for a killed/minimized accept and during a
          // CallKit-over-foreground `.inactive` blip is kept true. The Dart
          // side dismisses the native CallKit ONLY when this is true (the
          // in-app sheet is actually visible to replace it); a killed/locked/
          // minimized accept reads false → the native screen is kept, which is
          // the only call UI the user can see there. Read-only.
          result(self.isAppForeground)
        case "setWebRtcAudioEnabled":
          // Manual-audio toggle from Dart. With useManualAudio=true (set in
          // didFinishLaunching) WebRTC won't start its audio unit on its own;
          // the engine calls this with `true` right after a successful join so
          // audio flows on the foreground/outgoing/in-app paths (where CallKit
          // never activates the session), and `false` on leave. On the lock
          // screen the CallKit didActivate below ALSO flips it true the moment
          // the OS activates the session — whichever happens first wins, both
          // are idempotent. Enabling audio starts WebRTC's capture/playback
          // unit on the now-live session.
          if let on = (call.arguments as? [String: Any])?["enabled"] as? Bool {
            RTCAudioSession.sharedInstance().isAudioEnabled = on
            result(true)
          } else {
            result(FlutterError(code: "bad_args",
                                message: "enabled bool required", details: nil))
          }
        case "dismissIncoming":
          if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
            let calls = plugin.activeCalls()
            for c in calls {
              if let uuid = (c["id"] as? String) ?? (c["uuid"] as? String),
                 !uuid.isEmpty {
                plugin.saveEndCall(uuid, 6) // remoteEnded → reportCall(endedAt:)
              }
            }
            result(calls.count)
          } else {
            result(0)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func appDidBecomeActive() { isAppForeground = true }
  @objc private func appDidEnterBackground() { isAppForeground = false }

  // ── CXCallObserverDelegate ───────────────────────────────────────────────
  func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    // INCOMING call we ANSWERED has now ENDED while the app is in the
    // BACKGROUND (lock screen / minimized) = the user tapped End on the
    // native CallKit screen. Exactly like the accept case below, the
    // `flutter_callkit_incoming` `actionCallEnded` event does NOT reach the
    // Dart `onEvent` subscription while the isolate is backgrounded — so
    // without this bridge the hang-up HTTP POST never fires and the CALLER
    // stays stuck "in call" (the reported bug after we kept the native
    // CallKit screen on a locked accept). Bridge it to Dart, which runs the
    // normal hangup → POST /end → the backend broadcasts `call.hangup` so
    // the caller's call ends. Only for calls we actually bridged an answer
    // for (`answeredCallUUIDs`), and only when NOT genuinely foreground — a
    // foreground End goes through the in-app End button / onEvent path. iOS
    // CallKit only; Android is unaffected.
    if call.hasEnded {
      let uuid = call.uuid.uuidString
      // Bridge ANY end that happens while the app is NOT foreground. We must
      // NOT gate on `answeredCallUUIDs` here: the accept can arrive via the
      // plugin's `actionCallAccept` onEvent (handled entirely in Dart) instead
      // of our `notifyIncomingCallAnswered` bridge, so `answeredCallUUIDs` is
      // often empty even for a call we DID answer — which made the End on the
      // native screen never reach the backend and left the CALLER ringing.
      // Dart's `_handleNativeCallEnded` is the real decision-maker: it hangs up
      // only a live CONNECTED call, ignores the spurious connect→end blip via
      // its accept-handoff window, and ignores our own native-CallKit dismiss.
      // A foreground end goes through the in-app End / onEvent path instead.
      if !isAppForeground, callkitChannel != nil {
        notifyIncomingCallEnded(uuid: uuid)
      }
      return
    }
    // INCOMING call just became CONNECTED = the user tapped Accept on the
    // native CallKit screen (lock screen / minimized / killed cold-start).
    // This is the ONLY reliable, timing-independent signal for that accept:
    // on a killed/locked cold-start the flutter_callkit_incoming
    // `actionCallAccept` event is missed (the Dart isolate/subscription
    // isn't ready when it fires) and Stream's native push handler consumes
    // the call before Dart's resync runs — so nothing tells OUR backend the
    // callee answered, and the CALLER stays stuck on "Calling…". Bridge it
    // to Dart, which runs the normal accept flow (POST /accept → the backend
    // re-broadcasts call.accept so the caller connects, + joins the Stream
    // media leg). Only when NOT genuinely foreground — a foreground accept
    // goes through the in-app overlay/signaling directly, and the native
    // ring is suppressed below so it never reaches `hasConnected` there.
    if !call.isOutgoing, call.hasConnected, !call.hasEnded {
      if !isAppForeground {
        let uuid = call.uuid.uuidString
        if !answeredCallUUIDs.contains(uuid), callkitChannel != nil {
          answeredCallUUIDs.insert(uuid)
          notifyIncomingCallAnswered(uuid: uuid)
        }
      }
      return
    }
    // Act only on a freshly-appeared INCOMING call (ringing — not outgoing,
    // not answered, not already ended). After we end it, hasEnded becomes true
    // and this guard skips the follow-up event (no loop).
    guard !call.isOutgoing, !call.hasConnected, !call.hasEnded else { return }
    // Stash the ringing entry (carries extra.callCid) keyed by uuid while it's
    // still listed — ONLY for backgrounded/killed, where the native ring is
    // kept and a later decline is the case that needs it. A fast Decline
    // removes the activeCalls() entry before `notifyIncomingCallEnded` runs, so
    // this is the only way Dart can still learn the backend call id to POST the
    // reject and stop the caller ringing.
    if !isAppForeground,
       let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
      let ringingUuid = call.uuid.uuidString
      for c in plugin.activeCalls() {
        let entryId = (c["id"] as? String) ?? (c["uuid"] as? String) ?? ""
        if entryId == ringingUuid {
          lastIncomingCallByUuid[ringingUuid] = c
          break
        }
      }
    }
    // Suppress ONLY when the app is genuinely on screen. Background/killed must
    // keep the native ring — that's the entire point of CallKit there.
    guard isAppForeground else { return }
    guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else { return }
    // reason 6 → remoteEnded → CXProvider.reportCall(endedAt:) dismisses the
    // incoming UI (CXEndCallAction does not).
    plugin.saveEndCall(call.uuid.uuidString, 6)
  }

  /// Push a native→Dart `incomingCallAnswered` event for a CallKit call the
  /// user just answered. Looks up the matching flutter_callkit_incoming
  /// entry (which carries the Stream cid under `extra.callCid`) so the Dart
  /// side has everything `_handleAccept` needs; falls back to the bare UUID
  /// if the entry isn't found. Runs on the observer's main queue.
  private func notifyIncomingCallAnswered(uuid: String) {
    var payload: [String: Any] = ["uuid": uuid]
    if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
      let calls = plugin.activeCalls()
      for c in calls {
        let entryId = (c["id"] as? String) ?? (c["uuid"] as? String) ?? ""
        if entryId == uuid {
          payload["call"] = c
          break
        }
      }
    }
    lastIncomingCallByUuid.removeValue(forKey: uuid)
    callkitChannel?.invokeMethod("incomingCallAnswered", arguments: payload)
  }

  /// Push a native→Dart `incomingCallEnded` event for a CallKit call the
  /// user just ended on the native screen while backgrounded/locked. Mirror
  /// of `notifyIncomingCallAnswered` — looks up the matching
  /// flutter_callkit_incoming entry (carrying the Stream cid under
  /// `extra.callCid`) if it's still listed, falling back to the bare UUID.
  /// The Dart side routes it to `_handleHangup`, which POSTs the hang-up so
  /// the caller stops being "in call".
  private func notifyIncomingCallEnded(uuid: String) {
    var payload: [String: Any] = ["uuid": uuid]
    if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
      let calls = plugin.activeCalls()
      for c in calls {
        let entryId = (c["id"] as? String) ?? (c["uuid"] as? String) ?? ""
        if entryId == uuid {
          payload["call"] = c
          break
        }
      }
    }
    // Fallback: the decline usually removes the entry from activeCalls() before
    // this runs, so attach the entry we stashed when the call first rang — it's
    // what carries extra.callCid to Dart on a killed-app fast reject so Dart can
    // POST /reject and the caller stops ringing.
    if payload["call"] == nil, let stashed = lastIncomingCallByUuid[uuid] {
      payload["call"] = stashed
    }
    lastIncomingCallByUuid.removeValue(forKey: uuid)
    callkitChannel?.invokeMethod("incomingCallEnded", arguments: payload)
  }

  // ── CallkitIncomingAppDelegate ───────────────────────────────────────────
  // Conforming lets flutter_callkit_incoming's CXProvider forward its
  // audio-session lifecycle to us. The accept/decline/end CEREMONY still runs
  // in Dart (the plugin fires ACTION_CALL_ACCEPT on its event stream BEFORE
  // calling onAccept, and our CXCallObserver drives the backend accept) — these
  // action hooks only fulfil the CXAction so CallKit completes the transition.
  //
  // The reason we conform is `didActivateAudioSession`: on a LOCKED accept the
  // Flutter `actionCallToggleAudioSession` event is unreliable, but this native
  // callback fires the moment CallKit activates the shared AVAudioSession. We
  // bridge it to Dart so the engine re-asserts the route + bounces the mic on
  // the now-live session — the fix for "locked accept connects but is silent".
  // We deliberately do NOT switch WebRTC to manual-audio mode: automatic mode
  // is what makes the working foreground/outgoing/in-app calls audible, and
  // this bridge is purely additive to the CallKit path.
  func onAccept(_ call: flutter_callkit_incoming.Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  func onDecline(_ call: flutter_callkit_incoming.Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: flutter_callkit_incoming.Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onTimeOut(_ call: flutter_callkit_incoming.Call) {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    // CallKit (whichever provider owns the locked call) just activated the
    // shared session. In manual-audio mode WebRTC must be told the session is
    // live AND enabled, or its audio unit never starts. Do it natively here so
    // it happens the instant the session is up — before the Dart bridge round
    // trip. Idempotent with the `setWebRtcAudioEnabled` channel.
    let rtcSession = RTCAudioSession.sharedInstance()
    rtcSession.audioSessionDidActivate(audioSession)
    rtcSession.isAudioEnabled = true
    callkitChannel?.invokeMethod("callkitAudioActivated", arguments: nil)
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    let rtcSession = RTCAudioSession.sharedInstance()
    rtcSession.isAudioEnabled = false
    rtcSession.audioSessionDidDeactivate(audioSession)
    callkitChannel?.invokeMethod("callkitAudioDeactivated", arguments: nil)
  }
}
