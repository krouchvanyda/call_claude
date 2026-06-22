import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:erp_callkit/erp_callkit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/environments.dart';
import '../../features/chat/data/callkit_call_id.dart';
import 'local_notification_provider.dart';

/// Top-level background message handler. **Must be a top-level (or
/// static) function annotated with `@pragma('vm:entry-point')`** so
/// the Flutter background isolate can find it. Registered ONCE from
/// `main.dart` via `FirebaseMessaging.onBackgroundMessage(...)` — that
/// call MUST sit before `runApp(...)` for terminated-app pushes to
/// reach this entry point.
///
/// Runs in a separate isolate: no access to your app's singletons,
/// providers, or BLoCs. Keep the work minimal — log + show a local
/// notification so the user sees something in the tray. Persisting to
/// the inbox repository requires re-opening drift in this isolate
/// (not done here; deferred to when the app reopens).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Fires when a push arrives while the app is either MINIMISED (in
  // recents but not on screen) OR KILLED (swiped away). The Firebase
  // SDK doesn't distinguish those two cases here — both run this
  // background isolate. If you need to tell them apart, set a flag
  // in `WidgetsBindingObserver.didChangeAppLifecycleState` and check
  // it from the foreground (impossible in this isolate).
  _logPush('🟡 MINI / KILLED (tray)', message);
  if (kDebugMode) {
    // Belt-and-braces: same rationale as the foreground listener — make
    // sure this line shows up even in consoles that filter dart:developer.
    debugPrint('🟡 FCM BG/KILLED · messageId=${message.messageId} · '
        'data=${message.data} · notification=${message.notification?.title}');
  }

  // ── De-duplication rule ─────────────────────────────────────────
  // When the FCM payload includes a `notification` block AND the app
  // is in the background (which is the only state this handler runs
  // in), the OS already rendered the system notification automatically
  // — both Android and iOS. Showing another LocalNotification here
  // would produce TWO entries in the tray for the same push.
  //
  // We only render locally when the payload is DATA-ONLY (no
  // `notification` block). That's the case the OS does NOT auto-show
  // — typical for silent / custom-rendered chat pushes.
  if (message.notification != null) {
    return;
  }

  // Data-only push → render manually. The plugin must be re-init'd in
  // the background isolate because each isolate has its own plugin
  // registry.
  final local = LocalNotificationProvider();
  await local.initialize();

  // ── Stream Video VoIP push handoff ───────────────────────────────
  // Stream's `stream_video_push_notification` package does NOT register
  // its own FirebaseMessagingService, so every Stream push (sender =
  // 'stream.video', type = 'call.ring' / 'call.missed') lands HERE in
  // our handler. To get the native full-screen ringer the user
  // expects, we must hand the call.ring payload off to
  // `flutter_callkit_incoming` directly — `LocalNotificationProvider`
  // can only render a plain tray notification, not a CallKit UI.
  //
  // call.missed pushes fall through to the legacy renderer below
  // (which shows the "Missed call from …" tray entry).
  if (message.data['sender'] == 'stream.video' &&
      message.data['type'] == 'call.ring') {
    // iOS keeps the CallKit/PushKit ringer (killed-app reject is an
    // Android-specific problem; iOS handles decline natively via CallKit).
    if (Platform.isIOS) {
      if (kDebugMode) {
        log('📞 [stream.call.ring] iOS — handoff to CallKit · '
            'cid=${message.data['call_cid']}');
      }
      await _showStreamCallkitRinger(message);
      return;
    }
    final data = message.data;
    final callCid = data['call_cid']?.toString() ?? '';
    final callId = _parseBackendCallId(callCid);
    final callerName = data['created_by_display_name']?.toString() ??
        data['call_display_name']?.toString() ??
        'Unknown caller';
    final callerId = data['created_by_id']?.toString() ?? '';
    final isVideo = (data['call_type']?.toString() == 'video') ||
        (data['video']?.toString() == 'true');
    // call_display_name is usually the conversation/group name; treat a
    // non-empty value that differs from the caller as a group title.
    final convName = data['call_display_name']?.toString() ?? '';
    final isGroup = convName.isNotEmpty && convName != callerName;
    if (kDebugMode) {
      log('📞 [stream.call.ring] BG/KILLED → native call notif · '
          'cid=$callCid · callId=$callId · caller=$callerName');
    }
    debugPrint('[FCM-BG] call.ring → ErpCallKit.showIncomingCall '
        'callId=$callId callCid=$callCid caller=$callerName');
    await ErpCallKit.showIncomingCall(
      callId: callId,
      callCid: callCid,
      callerId: callerId,
      callerName: callerName,
      isVideo: isVideo,
      baseUrl: _callRejectBaseUrl,
      conversationName: isGroup ? convName : '',
      isGroup: isGroup,
    );
    return;
  }

  // Any OTHER Stream Video push (sender == 'stream.video' but NOT
  // 'call.ring') means a ringing call is OVER: the caller cancelled
  // before we answered, another of our devices picked up, or the
  // session ended. Stream does NOT emit a single uniform "cancel" type
  // (it ships call.ended / call.session_ended / call.missed / …), and
  // because this app draws the ring with its OWN `erp_callkit`
  // notification — not Stream's CallKit integration — nothing else
  // dismisses it. Treat every non-ring stream.video event as a dismiss
  // signal, keyed on the SAME CID the call.ring branch used to show the
  // notification, so only the matching ring is cancelled.
  //
  // This is the path that clears B's heads-up when A ends an unanswered
  // call while B is backgrounded / killed (the STOMP `call.hangup`
  // handler can't fire there — the socket is down).
  if (message.data['sender'] == 'stream.video') {
    final callCid = message.data['call_cid']?.toString() ?? '';
    if (kDebugMode) {
      log('📞 [stream.${message.data['type']}] BG/KILLED → dismiss ring · '
          'cid=$callCid');
    }
    if (callCid.isNotEmpty) {
      final dismissId = _parseBackendCallId(callCid);
      debugPrint('[FCM-BG] stream.video ${message.data['type']} → '
          'ErpCallKit.dismiss callId=$dismissId (cid=$callCid)');
      if (dismissId.isNotEmpty) {
        await ErpCallKit.dismiss(dismissId);
      }
      // iOS / flutter_callkit_incoming ringer is keyed on the CID-derived
      // CallKit id (see _showStreamCallkitRinger). Best-effort end it too.
      try {
        await FlutterCallkitIncoming.endCall(callkitIdForCid(callCid));
      } catch (_) {/* swallow — entry may already be gone */}
    }
    return;
  }

  // call.cancel — caller hung up before the callee answered, or
  // another device for the same user already picked up. Dismiss the
  // ring so the wrong device doesn't keep showing the heads-up.
  // Must run BEFORE the invite branch since the two share the
  // stableId derivation (so cancel + invite for the same callId
  // collapse to the same row id).
  if (message.data['type'] == 'call.cancel') {
    if (kDebugMode) {
      log('📞 [call.cancel] BG/KILLED · '
          'callId=${message.data['callId']} · '
          'reason=${message.data['reason']}');
    }
    // Build a synthetic stable id matching the one the invite used —
    // same `messageId == null` fallback path uses the data map's
    // hashCode, so we have to feed it the SAME callId-keyed shape.
    // Easiest: just cancel by the local notification's id (`_stableId`
    // is deterministic per RemoteMessage). Backend MUST set
    // `messageId` on both invite and cancel to the SAME value (e.g.
    // "call-{callId}") for this dedupe to work — see plan §3.
    await local.cancelNotification(_stableId(message));
    // Also dismiss the native incoming-call notification (keyed on the
    // backend callId) so a caller hang-up before answer clears the ring.
    final cancelCallId = message.data['callId']?.toString() ??
        _parseBackendCallId(message.data['streamCallCid']?.toString() ??
            message.data['call_cid']?.toString() ??
            '');
    if (cancelCallId.isNotEmpty) {
      debugPrint('[FCM-BG] call.cancel → ErpCallKit.dismiss callId=$cancelCallId');
      await ErpCallKit.dismiss(cancelCallId);
    }
    // iOS: the ring is a flutter_callkit_incoming / Stream-PushKit CallKit
    // entry, NOT an `erp_callkit` Android notification — so the dismiss above
    // is a no-op here. Mirror the `stream.video` branch and end the CallKit
    // call so a caller hang-up before answer clears D's native ring while
    // minimized/killed. Best-effort: end by the CID-derived id first, then
    // sweep any remaining entry (the ring's UUID may differ from ours).
    // iOS-only; Android is untouched (it uses ErpCallKit above).
    if (Platform.isIOS) {
      final callCid = message.data['streamCallCid']?.toString() ??
          message.data['call_cid']?.toString() ??
          '';
      try {
        if (callCid.isNotEmpty) {
          await FlutterCallkitIncoming.endCall(callkitIdForCid(callCid));
        }
      } catch (_) {/* swallow — entry may already be gone */}
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {/* swallow */}
    }
    return;
  }

  // Call invites get a ring-style notification with Accept / Reject
  // action buttons instead of a plain banner. The payload is round-
  // tripped so the response router can seed `CallSignalingService`
  // when the user taps Accept (handled by `CallNotificationRouter`).
  if (message.data['type'] == 'call.invite') {
    if (kDebugMode) {
      log('📞 [call.invite] BG/KILLED · '
          'callId=${message.data['callId']} · '
          'conversationId=${message.data['conversationId']} · '
          'callerId=${message.data['callerId']} · '
          'callerName=${message.data['callerName']} · '
          'callType=${message.data['callType']} · '
          'streamCallCid=${message.data['streamCallCid']} · '
          'startedAt=${message.data['startedAt']}');
    }
    final data = message.data;
    final callerName = data['callerName']?.toString() ?? 'Unknown';
    final isVideo = data['callType']?.toString() == 'video';
    // iOS keeps the existing heads-up; only Android gets the native
    // own-notification path (the one with the killed-app Reject hook).
    if (Platform.isIOS) {
      await local.sendCallInvite(
        title: 'Incoming ${isVideo ? 'video' : 'voice'} call',
        body: callerName,
        id: _stableId(message),
        data: Map<String, dynamic>.from(data),
      );
      return;
    }
    final callId = data['callId']?.toString() ??
        _parseBackendCallId(data['streamCallCid']?.toString() ?? '');
    debugPrint('[FCM-BG] call.invite → ErpCallKit.showIncomingCall '
        'callId=$callId caller=$callerName');
    await ErpCallKit.showIncomingCall(
      callId: callId,
      callCid: data['streamCallCid']?.toString() ?? '',
      callerId: data['callerId']?.toString() ?? '',
      callerName: callerName,
      isVideo: isVideo,
      baseUrl: _callRejectBaseUrl,
      conversationId: data['conversationId']?.toString() ?? '',
      conversationName: data['conversationName']?.toString() ?? '',
      isGroup: data['isGroup']?.toString() == 'true',
    );
    return;
  }

  await local.sendNotification(
    title: message.data['title']?.toString(),
    body: message.data['body']?.toString(),
    id: _stableId(message),
    dataPayload: message.data,
  );
}

/// REST base the native Reject receiver POSTs to. Resolved from a
/// compile-time const (the background isolate can't reach DI). All three
/// `Environments` URLs point at the same host today; `prod` matches the
/// `configureDependencies(environment: Environment.prod)` call in main().
const String _callRejectBaseUrl = Environments.prodApiBaseUrl;

/// Extract the backend numeric call id from a Stream CID
/// (`default:erp-call-637` → `637`). Falls back to the trailing segment,
/// then the raw input, so a non-standard id still yields *something*.
String _parseBackendCallId(String callCid) {
  if (callCid.isEmpty) return '';
  final tail = callCid.contains(':') ? callCid.split(':').last : callCid;
  final match = RegExp(r'^(?:erp-call-)?(\d+)').firstMatch(tail);
  return match?.group(1) ?? tail;
}

/// Unified push-state log so every entry point emits the same shape.
/// Look for these prefixes in the console to know which lifecycle
/// state the app was in when a push arrived:
///
///   🟢 IN APP            — foreground listener fired
///   🟡 MINI / KILLED     — background isolate fired (no tap)
///   🔵 TAP from MINI     — user tapped notification while backgrounded
///   🔴 TAP from KILLED   — user tapped notification to launch from killed
///
/// Gated on `kDebugMode` so release builds don't spam logcat with
/// notification metadata (and don't leak titles/bodies into crash
/// breadcrumbs).
void _logPush(String state, RemoteMessage m) {
  if (!kDebugMode) return;
  log('$state · id=${m.messageId} · '
      'title=${m.notification?.title ?? m.data['title']} · '
      'body=${m.notification?.body ?? m.data['body']} · '
      'data=${m.data}');
}

/// Hand off a Stream Video `call.ring` push to `flutter_callkit_incoming`
/// so the native full-screen ringer wakes the device. Runs in the
/// background isolate (no GetIt / no app state available).
///
/// Stream's push payload (data-only, no notification block):
/// ```
/// {
///   sender: stream.video,
///   type: call.ring,
///   call_cid: default:erp-call-141,
///   created_by_id: 9,
///   created_by_display_name: Mr A,
///   call_display_name: …,            -- usually conv/group name
///   version: v2
/// }
/// ```
///
/// Without this handoff Stream's ring push falls through to the
/// generic notification renderer (or gets silently dropped if it
/// doesn't match `call.invite` / `call.cancel`) — the user sees no
/// ringer and the call eventually times out as a missed call.
@pragma('vm:entry-point')
Future<void> _showStreamCallkitRinger(RemoteMessage message) async {
  final data = message.data;
  final callCid = data['call_cid']?.toString() ?? '';
  if (callCid.isEmpty) return;

  // Ringer id: on Android this is the call CID verbatim; on iOS CallKit
  // requires a UUID, so `callkitIdForCid` maps the CID to a deterministic
  // UUID. Every dismiss/end path runs the same mapping, so the matching
  // `call.cancel` / end push still cancels this exact entry. The raw CID is
  // preserved below in `extra.call_cid` for accept/decline routing.
  final id = callkitIdForCid(callCid);
  final callerName = data['created_by_display_name']?.toString() ??
      data['call_display_name']?.toString() ??
      'Unknown caller';
  final callerHandle = data['created_by_id']?.toString() ?? '';
  // Stream encodes video calls as type=video in custom data; default
  // to audio (type=0) when unknown.
  final isVideo = (data['call_type']?.toString() == 'video') ||
      (data['video']?.toString() == 'true');

  final params = CallKitParams(
    id: id,
    nameCaller: callerName,
    appName: 'ERP',
    handle: callerHandle,
    type: isVideo ? 1 : 0,
    // Persist the whole Stream payload so the accept/decline handler
    // (wired separately) can reconstruct what to do.
    extra: <String, dynamic>{
      'call_cid': callCid,
      'caller_id': callerHandle,
      'caller_name': callerName,
      'type': data['type']?.toString() ?? '',
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      incomingCallNotificationChannelName: 'Incoming Calls',
      missedCallNotificationChannelName: 'Missed Calls',
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );
  try {
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    if (kDebugMode) {
      log('📞 [stream.call.ring] CallKit shown · id=$id · caller=$callerName');
    }
  } catch (e, st) {
    if (kDebugMode) {
      log('📞 [stream.call.ring] CallKit handoff failed: $e', stackTrace: st);
    }
  }
}

/// Derive a stable notification id from the message so:
///   - the same push redelivered over multiple transports collapses
///     into one tray row (the OS uses id as the merge key)
///   - app restarts don't reset to 0 and overwrite previous rows
///
/// Special-case for calls: `call.invite` and `call.cancel` for the
/// SAME `callId` must hash to the same notification id, otherwise
/// the cancel can't dismiss the invite (FCM `messageId` is unique
/// per push, so it'd differ across the two messages). We key calls
/// on `call:<callId>` so the cancel finds + dismisses the ring.
///
/// All other pushes fall back to `messageId`, then to a hash of the
/// data payload. `.abs() & 0x7fffffff` keeps the value in the
/// non-negative int range that flutter_local_notifications requires.
int _stableId(RemoteMessage m) {
  final type = m.data['type']?.toString();
  final callId = m.data['callId']?.toString();
  if (callId != null && callId.isNotEmpty &&
      (type == 'call.invite' || type == 'call.cancel')) {
    return 'call:$callId'.hashCode.abs() & 0x7fffffff;
  }
  final raw = m.messageId ?? m.data.toString();
  return raw.hashCode.abs() & 0x7fffffff;
}

/// Singleton wrapper over `firebase_messaging`. Hold the same instance
/// app-wide so subscription state, dedupe counters, and the dispose
/// hook don't fragment across callers (the previous design created a
/// fresh instance on every `FirebaseNotificationProvider()` call,
/// which scattered the `index` counter and leaked listeners).
class FirebaseNotificationProvider {
  FirebaseNotificationProvider._();
  static final FirebaseNotificationProvider instance =
      FirebaseNotificationProvider._();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedAppSub;
  bool _listenersAttached = false;

  /// Request notification permission on both platforms. The iOS call
  /// is now AWAITED — previously it was fire-and-forget, which let
  /// downstream `getToken()` race against an undecided prompt and
  /// return null.
  Future<NotificationSettings?> requestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ POST_NOTIFICATIONS runtime permission. Older
        // Androids treat this as already granted.
        //
        // permission_handler routes through the current Activity. When
        // we're called from main() before runApp(), no Activity exists
        // yet → PlatformException("Unable to detect current Android
        // Activity."). Try once; if it throws with that exact error,
        // wait a beat (giving the framework time to mount the activity)
        // and retry. Failing both times is non-fatal — Android treats
        // the permission as denied and we can re-request later.
        try {
          await Permission.notification.request();
        } catch (e) {
          if (e.toString().contains('Unable to detect current Android Activity')) {
            if (kDebugMode) {
              log('🔔 notification permission request fired pre-Activity '
                  '— retrying after 1 s');
            }
            await Future.delayed(const Duration(seconds: 1));
            try {
              await Permission.notification.request();
            } catch (e2) {
              if (kDebugMode) {
                log('🔔 second attempt at notification permission '
                    'also failed: $e2 — skipping, will retry on next '
                    'app launch / lifecycle resume');
              }
              // Don't rethrow — let the iOS / foreground-presentation
              // setup below still run.
            }
          } else {
            rethrow;
          }
        }
      }

      // Foreground presentation: alert/badge/sound all ON so the user
      // sees heads-up banners while the app is open. The previous
      // `alert: false` contradicted the documenting comment and
      // suppressed in-app banners on iOS.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS / macOS notification permission prompt. Awaited so the
      // caller can decide what to do with denials.
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        log('🔔 Notification permission: ${settings.authorizationStatus}');
      }
      return settings;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('Error requesting notification permissions: $e',
            stackTrace: stackTrace);
      }
      return null;
    }
  }

  Future<void> removeForegroundSound() async {
    try {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('Error updating foreground sound: $e', stackTrace: stackTrace);
      }
    }
  }

  Future<void> setForegroundSound() async {
    try {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: true,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('Error updating foreground sound: $e', stackTrace: stackTrace);
      }
    }
  }

  /// Returns the FCM device token. On iOS the APNS token must be
  /// available BEFORE FCM can mint its own — older code fetched both
  /// in parallel and often got null on a cold start. Now we await APNS
  /// first and short-circuit if it's still pending.
  ///
  /// Token logging is gated on `kDebugMode` so release builds don't
  /// leak auth-equivalent material into logcat / Crashlytics breadcrumbs.
  /// Uses `debugPrint` (not `log`) so the lines always appear in
  /// `flutter run`'s default console — the previous `dart:developer`
  /// `log()` calls were silently filtered out of some terminals.
  Future<String?> getFirebaseToken() async {
    if (kDebugMode) debugPrint('🔥 FCM: getFirebaseToken() entered');
    try {
      if (Platform.isIOS) {
        if (kDebugMode) debugPrint('🔥 FCM: iOS — requesting APNs token…');
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          // APNS token not yet provisioned — common on simulator and
          // immediately after a fresh install. Caller can retry.
          if (kDebugMode) debugPrint('🔥 FCM: APNs token NOT READY yet (null)');
          return null;
        }
        if (kDebugMode) debugPrint('🔥 FCM: APNs token OK (len=${apnsToken.length})');
      }

      if (kDebugMode) debugPrint('🔥 FCM: calling messaging.getToken()…');
      final token = await messaging.getToken();
      if (kDebugMode) {
        if (token == null) {
          debugPrint(
              '🔥 FCM: ❌ getToken() returned NULL '
              '(no Play Services? token rotation? network blocked?)');
        } else {
          debugPrint('🔥 FCM: ✅ TOKEN (len=${token.length}) → $token');
        }
      }
      return token;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('🔥 FCM: ❌ getToken() THREW: $e');
        debugPrintStack(stackTrace: st, label: '🔥 FCM stack');
      }
      return null;
    }
  }

  /// Stream of token-rotation events. Wire this into `PushTokenStorage`
  /// so each new token is persisted + re-synced with the backend.
  Stream<String> get onTokenRefresh => messaging.onTokenRefresh;

  Future<bool> deleteFirebaseToken() async {
    try {
      await messaging.deleteToken();
      return true;
    } catch (e) {
      if (kDebugMode) log('Error deleting device token: $e');
      return false;
    }
  }

  /// Foreground message listener. Tracked via `_onMessageSub` so we
  /// can dispose on logout instead of leaking handlers across sessions.
  ///
  /// **Behaviour change**: the previous `type == null` short-circuit
  /// dropped every push that didn't carry a custom `type` data field —
  /// including standard notification-only payloads from the Firebase
  /// console. We now ALWAYS run the caller's `getData` callback and
  /// ALWAYS show a local notification, leaving filtering to the caller.
  void initOnMessageListener({required Function(RemoteMessage) getData}) {
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      try {
        _logPush('🟢 IN APP', message);
        // Belt-and-braces: also debugPrint so the line shows up in
        // `flutter run` consoles that filter `dart:developer` log()
        // output. This is what proves whether FCM is reaching B's
        // device AT ALL when diagnosing call.invite no-shows.
        if (kDebugMode) {
          debugPrint('🟢 FCM IN APP · messageId=${message.messageId} · '
              'data=${message.data} · notification=${message.notification?.title}');
        }
        getData(message);

        // ── De-duplication rule (foreground) ────────────────────
        // On iOS we asked for `alert: true` in
        // `setForegroundNotificationPresentationOptions`, so the OS
        // auto-displays any FCM payload with a `notification` block
        // even in foreground. If we ALSO render via LocalNotification
        // here, the user sees two.
        //
        // On Android the OS does NOT auto-display foreground pushes
        // regardless of payload shape, so we MUST render locally
        // there or the user sees nothing.
        //
        // Net rule:
        //   - Android foreground            → always render locally
        //   - iOS foreground + notif block  → skip (OS already shows)
        //   - iOS foreground + data-only    → render locally
        final notif = message.notification;
        final iosWillAutoDisplay = Platform.isIOS && notif != null;
        if (iosWillAutoDisplay) return;

        // Stream Video push in foreground — ring/connect is handled live
        // over Stream's WebSocket (StreamCallEngine), so the only thing
        // we owe a foreground FCM copy is housekeeping: a non-ring event
        // means a ring is over → clear any native heads-up still showing
        // and DON'T render a stray tray notification. (call.ring itself
        // is a no-op in foreground; the WS path already rang the user.)
        if (message.data['sender'] == 'stream.video') {
          if (message.data['type'] != 'call.ring') {
            final callCid = message.data['call_cid']?.toString() ?? '';
            if (callCid.isNotEmpty) {
              final dismissId = _parseBackendCallId(callCid);
              if (dismissId.isNotEmpty) {
                unawaited(ErpCallKit.dismiss(dismissId)
                    .catchError((Object _) {}));
              }
              FlutterCallkitIncoming.endCall(callkitIdForCid(callCid))
                  .catchError((Object _) {});
            }
          }
          return;
        }

        // call.cancel — mirror of the background-isolate branch:
        // dismiss the heads-up notification so the user doesn't keep
        // seeing the ring after the caller hung up.
        if (message.data['type'] == 'call.cancel') {
          if (kDebugMode) {
            log('📞 [call.cancel] FOREGROUND · '
                'callId=${message.data['callId']} · '
                'reason=${message.data['reason']}');
          }
          LocalNotificationProvider().cancelNotification(_stableId(message));
          return;
        }

        // Call invites get the same ring-style rendering as the
        // background isolate uses (Accept / Reject actions, persistent
        // heads-up). Without this branch the foreground path would
        // render a plain banner that the user couldn't act on.
        if (message.data['type'] == 'call.invite') {
          if (kDebugMode) {
            log('📞 [call.invite] FOREGROUND · '
                'callId=${message.data['callId']} · '
                'conversationId=${message.data['conversationId']} · '
                'callerId=${message.data['callerId']} · '
                'callerName=${message.data['callerName']} · '
                'callType=${message.data['callType']} · '
                'streamCallCid=${message.data['streamCallCid']} · '
                'startedAt=${message.data['startedAt']}');
          }
          final callerName =
              message.data['callerName']?.toString() ?? 'Unknown';
          final isVideo = message.data['callType']?.toString() == 'video';
          LocalNotificationProvider().sendCallInvite(
            title: 'Incoming ${isVideo ? 'video' : 'voice'} call',
            body: callerName,
            id: _stableId(message),
            data: Map<String, dynamic>.from(message.data),
          );
          return;
        }

        LocalNotificationProvider().sendNotification(
          title: notif?.title ?? message.data['title']?.toString(),
          body: notif?.body ?? message.data['body']?.toString(),
          id: _stableId(message),
          dataPayload: message.data,
        );
      } catch (e, stackTrace) {
        if (kDebugMode) {
          log('Error handling foreground push: $e', stackTrace: stackTrace);
        }
      }
    });
  }

  void initOnMessageOpenedApp({required Function(RemoteMessage) getData}) {
    _onOpenedAppSub?.cancel();
    _onOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _logPush('🔵 TAP from MINI', message);
      getData(message);
    });
  }

  /// Handle the notification that launched the app from a terminated
  /// state. Only delivers the message the user actually tapped — other
  /// pushes that were waiting in the tray are NOT replayed (reconcile
  /// them via `GET /notifications?unread=true` on cold start).
  Future<void> handleInitialMessage({
    required Function(RemoteMessage) getData,
  }) async {
    try {
      final message = await messaging.getInitialMessage();
      if (message != null) {
        _logPush('🔴 TAP from KILLED', message);
        getData(message);
      }
    } catch (e) {
      if (kDebugMode) log('Error retrieving initial message: $e');
    }
  }

  /// Convenience: attach BOTH listeners + handle the cold-start
  /// initial message in one call. Idempotent — guarded so a hot
  /// reload doesn't double-attach handlers.
  Future<void> attachAllHandlers({
    required Function(RemoteMessage) onMessage,
  }) async {
    if (_listenersAttached) return;
    _listenersAttached = true;
    initOnMessageListener(getData: onMessage);
    initOnMessageOpenedApp(getData: onMessage);
    await handleInitialMessage(getData: onMessage);
  }

  /// Tear down listeners — call on sign-out so the next user on the
  /// same device doesn't inherit subscriptions from the previous one.
  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedAppSub?.cancel();
    _onMessageSub = null;
    _onOpenedAppSub = null;
    _listenersAttached = false;
  }
}
