import 'push_message.dart';

/// Project-owned seam between push transport (FCM, APNs, custom WS)
/// and the rest of the app (Slice 2.3.2).
///
/// Implementations live in `data/` and own the SDK-specific bits;
/// every consumer (the [PushMessageRouter], the dev simulator button,
/// tests) talks to this interface only.
///
/// **Pure-Dart**: no Flutter, no firebase_messaging — keeps the routing
/// layer unit-testable without spinning up a real provider, and lets
/// us swap the FCM impl in via a one-line DI rebind once platform
/// configuration (`google-services.json`, AppDelegate edits) is in
/// place.
abstract class PushNotificationService {
  /// One-shot init — register listeners, claim the device token, etc.
  /// Idempotent: safe to call from multiple lifecycle hooks (app start,
  /// post-sign-in re-register).
  Future<void> initialize();

  /// Ask the OS for permission to display notifications. Returns
  /// `true` when granted (or already granted), `false` when denied.
  /// Implementations should treat "provisional" / "limited" grants
  /// (iOS) as `true` so the inbox keeps working.
  Future<bool> requestPermission();

  /// Current device push token, or `null` when permission was denied
  /// / the provider hasn't issued one yet. The router stores this
  /// via [PushTokenStorage] (`flutter_secure_storage` only, never
  /// drift — per CLAUDE.md storage rule).
  Future<String?> getToken();

  /// Token-rotation events from the provider. The router persists
  /// each new token and (later slice) syncs it with the auth backend.
  Stream<String> get onTokenRefresh;

  /// Inbound payloads, normalised to the project envelope. Hot stream:
  /// late subscribers do NOT replay missed messages — the router
  /// subscribes early in app start to catch the foreground stream
  /// from the moment a user could trigger one.
  Stream<PushMessage> get messages;

  /// Tear down listeners and release resources. Called from the DI
  /// reset path on sign-out so a different account on the same device
  /// doesn't inherit stale subscriptions.
  Future<void> dispose();
}
