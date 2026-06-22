import 'dart:async';

import 'push_message.dart';
import 'push_notification_service.dart';

/// Dev / demo / test [PushNotificationService] (Slice 2.3.2).
///
/// **Why this is the default DI binding** instead of an FCM impl:
/// firebase_messaging needs `google-services.json` /
/// `GoogleService-Info.plist`, AppDelegate edits, and a Firebase
/// project on Google's side — none of which is operational yet. The
/// simulator gives us:
/// - a working end-to-end demo (button on the dashboard pushes a
///   payload, the inbox bloc updates),
/// - tests for the router without faking the SDK,
/// - a fast iteration loop while the real provider is being set up.
///
/// Swap in `FirebaseMessagingPushService` (added when platform config
/// lands) by rebinding `PushNotificationService` in the DI module.
/// Nothing else changes.
class LocalPushSimulator implements PushNotificationService {
  LocalPushSimulator();

  final _messages = StreamController<PushMessage>.broadcast();
  final _tokenRefresh = StreamController<String>.broadcast();
  String? _token;
  bool _initialised = false;

  /// Manual push API — call from a debug button to feed a payload
  /// through the router. Returns the message that was pushed so the
  /// caller can echo it back via Snackbar.
  PushMessage simulate(PushMessage message) {
    _messages.add(message);
    return message;
  }

  /// Convenience for the dashboard's `[dev] Simulate push` button —
  /// wraps a title / body / category triple into a [PushMessage] and
  /// fires it through [simulate].
  PushMessage simulateNow({
    required String title,
    required String body,
    String category = 'system',
    Map<String, String> data = const {},
  }) {
    final merged = <String, String>{
      'category': category,
      ...data,
    };
    return simulate(PushMessage(
      title: title,
      body: body,
      data: merged,
      sentAt: DateTime.now().toUtc(),
    ));
  }

  /// Test-only: pretend the provider rotated the device token.
  void simulateTokenRefresh(String newToken) {
    _token = newToken;
    _tokenRefresh.add(newToken);
  }

  @override
  Future<void> initialize() async {
    _initialised = true;
    // Seed a synthetic device token so downstream code paths
    // (PushTokenStorage write) have something to persist.
    _token ??= 'dev-simulator-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => _initialised ? _token : null;

  @override
  Stream<String> get onTokenRefresh => _tokenRefresh.stream;

  @override
  Stream<PushMessage> get messages => _messages.stream;

  @override
  Future<void> dispose() async {
    await _messages.close();
    await _tokenRefresh.close();
  }
}
