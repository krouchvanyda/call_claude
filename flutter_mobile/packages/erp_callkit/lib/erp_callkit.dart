import 'package:flutter/services.dart';

/// Dart facade over the native `erp_callkit` notification subsystem.
///
/// Why this package exists: on Android, when the app is **killed** and
/// the callee taps **Reject** on an incoming-call notification, no Dart
/// code can run (no live isolate; flutter_callkit_incoming / Stream both
/// rely on a live `onEvent`; action launches report no actionId on
/// Samsung OEMs). The only way to make Reject reach the backend from a
/// dead app is a native `BroadcastReceiver` — but that receiver must be
/// the explicit target of the notification's Reject `PendingIntent`,
/// which means *we* must build the notification natively.
///
/// This class is the bridge. [showIncomingCall] is safe to call from
/// the FCM **background isolate** (the plugin is registered on the
/// background `FlutterEngine` via `GeneratedPluginRegistrant`), so it
/// works on a killed-app `call.ring` / `call.invite` push.
class ErpCallKit {
  ErpCallKit._();

  static const MethodChannel _channel = MethodChannel('erp_callkit');

  /// Render the native incoming-call notification (full-screen-intent
  /// heads-up with Accept / Reject actions).
  ///
  /// - [callId]   backend numeric call id (string) — used by the native
  ///   Reject receiver to `POST /chats/calls/{callId}/reject`.
  /// - [callCid]  Stream CID (e.g. `default:erp-call-637`) — the stable
  ///   notification id key so a later [dismiss] can cancel it.
  /// - [baseUrl]  REST base (e.g. `http://host:8080/api/v1`) so the
  ///   native receiver knows where to POST without DI.
  ///
  /// Reject runs entirely in Kotlin (reads the JWT from secure storage,
  /// refreshes on 401) — the app never opens. Accept / body-tap launch
  /// MainActivity with the call data for Dart to consume via
  /// [consumeLaunchAction].
  static Future<void> showIncomingCall({
    required String callId,
    required String callCid,
    required String callerId,
    required String callerName,
    required bool isVideo,
    required String baseUrl,
    String conversationId = '',
    String conversationName = '',
    bool isGroup = false,
  }) async {
    await _channel.invokeMethod<void>('showIncomingCall', <String, dynamic>{
      'callId': callId,
      'callCid': callCid,
      'callerId': callerId,
      'callerName': callerName,
      'isVideo': isVideo,
      'baseUrl': baseUrl,
      'conversationId': conversationId,
      'conversationName': conversationName,
      'isGroup': isGroup,
    });
  }

  /// Cancel a previously shown incoming-call notification by its backend
  /// [callId] (called on `call.cancel` — caller hung up before answer).
  static Future<void> dismiss(String callId) async {
    await _channel.invokeMethod<void>('dismiss', <String, dynamic>{
      'callId': callId,
    });
  }

  /// Nuke EVERY call notification this app currently has on screen — our
  /// own `erp_incoming_calls` ring AND the Stream SDK's `stream_call_*`
  /// ongoing-call notification — regardless of id or channel.
  ///
  /// Why a separate "all" sweep: a plain per-id [dismiss] doesn't clear
  /// the Stream notification (we don't own its id) and Samsung One UI
  /// keeps ongoing `CallStyle` notifications pinned even after `cancel()`.
  /// The native side enumerates the app's OWN active notifications, filters
  /// to CATEGORY_CALL / call channels, demotes the sticky ongoing flag and
  /// cancels each — so nothing lingers as a phantom "Connected" call on the
  /// lock screen after the call has actually ended.
  ///
  /// Call on every terminal call path and on app resume (orphan sweep).
  static Future<void> dismissAllCalls() async {
    await _channel.invokeMethod<void>('dismissAll');
  }

  /// If the app was launched/resumed by tapping the notification body or
  /// the **Accept** action, returns the call payload (with an extra
  /// `accept` bool) and clears it. Returns null otherwise.
  ///
  /// Call this on app start AND on resume — the in-app layer routes the
  /// payload into the existing signalling (`handleIncomingFromPush` +,
  /// when `accept == true`, `acceptIncoming`).
  static Future<Map<String, dynamic>?> consumeLaunchAction() async {
    final res =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('consumeLaunchAction');
    if (res == null) return null;
    return res.map((k, v) => MapEntry(k.toString(), v));
  }
}
