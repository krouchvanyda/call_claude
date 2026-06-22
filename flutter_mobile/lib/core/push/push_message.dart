import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_message.freezed.dart';

/// Server-pushed notification payload (Slice 2.3.2).
///
/// **Why not just import `firebase_messaging`'s `RemoteMessage`**: a
/// project-owned envelope keeps the rest of the app free of the FCM
/// SDK so we can:
/// - test routing without spinning up firebase,
/// - swap providers later (APNs direct, OneSignal, custom WS) without
///   a feature-wide refactor,
/// - run the dev simulator without platform config (firebase requires
///   `google-services.json` / `GoogleService-Info.plist` and AppDelegate
///   edits — the simulator side-steps all of that).
///
/// The shape mirrors a typical FCM payload — `notification.title/body`
/// for display + a `data` map for routing — so the firebase adapter
/// (when we ship it) is a one-method `RemoteMessage → PushMessage`
/// translator.
@freezed
class PushMessage with _$PushMessage {
  const factory PushMessage({
    /// Server-assigned message id. Used for dedupe — the same payload
    /// arriving via foreground + background isolate must collapse to
    /// one inbox row. Null when the source didn't supply one (the
    /// router falls back to a generated id).
    String? id,

    /// Display title — comes from FCM's `notification.title`.
    required String title,

    /// Display body — FCM's `notification.body`.
    required String body,

    /// App-specific routing data — FCM's `data` map. Convention:
    /// - `'category'` discriminates icon / colour in the inbox UI
    ///   (defaults to `'system'` when absent).
    /// - `'route'` is a `go_router` named route for the deep link.
    /// - `'route.<key>'` entries become `go_router` path parameters.
    @Default(<String, String>{}) Map<String, String> data,

    /// When the server / push transport says the message was emitted.
    /// `null` falls back to "now" at the router boundary so inbox
    /// ordering still works.
    DateTime? sentAt,
  }) = _PushMessage;
}
