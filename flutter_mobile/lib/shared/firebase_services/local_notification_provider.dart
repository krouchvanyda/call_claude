import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/chat/presentation/widgets/call_notification_router.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class LocalNotificationProvider {
  static const String _channelId = 'high_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription = 'This channel is for important notifications';

  /// Dedicated channel for incoming calls. Android requires a SEPARATE
  /// channel from the regular one because the ringtone / vibrate /
  /// LED pattern is per-channel, not per-notification. Users also
  /// expect to be able to mute chat notifications without muting
  /// calls.
  static const String _callChannelId = 'calls';
  static const String _callChannelName = 'Incoming calls';
  static const String _callChannelDescription =
      'Heads-up ringer for incoming voice and video calls';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _callChannel = AndroidNotificationChannel(
    _callChannelId,
    _callChannelName,
    description: _callChannelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Idempotent guard so a stray double-call from `main.dart` + a
  /// background isolate doesn't register the channel twice or create
  /// duplicate tap listeners.
  bool _initialized = false;

  LocalNotificationProvider();

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse? payload) async {
        // FIX: null-safe — `payload` itself can be null on cancellation
        // events. Old code did `payload!.payload != null` which would
        // crash before checking. Guard both layers.
        final body = payload?.payload;
        if (body == null) return;
        // Call invites get first crack — if it dispatches, the legacy
        // (no-op) handler is skipped. Accept / Reject action buttons
        // route here too (the OS attaches the actionId).
        final handled = await CallNotificationRouter.dispatch(
          body,
          actionId: payload?.actionId,
        );
        if (!handled) {
          _handleNotificationResponse(body);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // FIX (critical): create the Android notification channel.
    // Without this, Android 8.0+ silently drops every notification
    // because the channel id we reference in `sendNotification` does
    // not exist on the device. iOS doesn't need this — channels are
    // an Android-only concept; the plugin returns null on iOS.
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    // Separate channel for incoming calls so the ringtone / vibrate
    // pattern is independent of regular chat pushes (and users can
    // mute one without muting the other).
    await androidPlugin?.createNotificationChannel(_callChannel);

    _initialized = true;

    if (kDebugMode) {
      log("🟢 Local Notification Initialized: $initialized");
      if (initialized != true) {
        log("🔴 Failed to initialize notifications");
      }
    }
  }

  Future<void> sendNotification({
    String? title,
    String? body,
    required int id,
    required dynamic dataPayload,
  }) async {
    try {
      if (kDebugMode) {
        log("📦 Local notification id=$id payload=$dataPayload");
      }

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(dataPayload),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log("❌ Error sending notification: $e", stackTrace: stackTrace);
      }
    }
  }

  /// Heads-up incoming-call notification with Accept / Reject action
  /// buttons. Used when an FCM `call.invite` arrives while the app
  /// is paused/killed — `LocalNotificationProvider.sendNotification`
  /// renders a plain banner, this renders the ring-style sheet.
  ///
  /// Persists until the user taps a button (`ongoing: true` +
  /// `autoCancel: false`) so it behaves like a real phone ring rather
  /// than fading away after a few seconds.
  ///
  /// [data] is round-tripped as the payload — the response handler
  /// uses it to seed `CallSignalingService._active` so accept /
  /// reject can resolve the right call.
  Future<void> sendCallInvite({
    required String title,
    required String body,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (kDebugMode) {
        log('📞 Local CALL invite id=$id data=$data');
      }
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _callChannel.id,
          _callChannel.name,
          channelDescription: _callChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          // Keep the notification on screen until the user picks one
          // of the actions (or the caller hangs up, which cancels it
          // via id).
          ongoing: true,
          autoCancel: false,
          // Heads-up + lockscreen visibility so the user actually
          // sees the ring on Android 13+ even from a locked device.
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              kCallRejectActionId,
              'Reject',
              titleColor: const Color.fromARGB(255, 220, 38, 38),
              cancelNotification: true,
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              kCallAcceptActionId,
              'Accept',
              titleColor: const Color.fromARGB(255, 22, 163, 74),
              cancelNotification: true,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // CallKit / PushKit is the right way to do this on iOS;
          // for now we just heads-up the same payload so the user at
          // least sees something.
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );
    } catch (e, st) {
      if (kDebugMode) {
        log('❌ Error sending call invite notification: $e', stackTrace: st);
      }
    }
  }

  /// Cancel a single notification by its display id.
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      if (kDebugMode) log("❌ Error cancelling notification $id: $e");
    }
  }

  /// Cancel every active notification (typically called on sign-out).
  Future<void> cancelAllNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      if (kDebugMode) log("❌ Error cancelling all notifications: $e");
    }
  }
}

/// This will be called when a notification is tapped while app is in
/// background or terminated. Runs in a SEPARATE isolate — cannot touch
/// app state, providers, or navigation. Keep work minimal; route the
/// tap intent through native channels or a hand-off file if you need
/// to drive UI from here.
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse payload) {
  if (kDebugMode) {
    log("🔔 Background notification tapped: ${payload.payload}");
  }
  final body = payload.payload;
  if (body != null) {
    _handleNotificationResponse(body);
  }
}

@pragma('vm:entry-point')
void _handleNotificationResponse(String payload) {
  try {
    final Map<String, dynamic> notificationData =
        jsonDecode(payload) as Map<String, dynamic>;
    if (kDebugMode) {
      log("📲 Notification tapped: $notificationData");
    }
    // TODO(navigation): deep-link to the relevant screen using the
    // payload's `route` field once the router-side handler exists.
    // Currently a no-op beyond the log.
  } catch (e) {
    if (kDebugMode) {
      log("❌ Error handling notification response: $e");
    }
  }
}
