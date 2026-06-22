import 'analytics_event.dart';

/// Cross-cutting analytics surface — the only contract feature code talks
/// to. The framework ships a no-op default ([NoopAnalyticsService]); a
/// vendor binding (Firebase / Segment / Mixpanel) plugs in later by
/// implementing this interface and overriding the DI registration.
///
/// Method-return shape is intentional:
/// - **Fire-and-forget UX events** (`track`, `screen`, `setUserProperty`)
///   return `void` so widgets can call without ceremony.
/// - **Identity transitions** (`identify`, `reset`) return `Future<void>`
///   because callers must be able to await them — events recorded after
///   identify must be attributed to the new user.
/// - **`flush()`** returns `Future<void>` for explicit force-send paths
///   (logout, app-lifecycle pause).
abstract class AnalyticsService {
  const AnalyticsService();

  void track(AnalyticsEvent event);

  void screen(String name, {Map<String, Object?>? properties});

  void setUserProperty(String key, Object? value);

  /// Associates the current session with [userId] and the supplied [traits].
  /// Subsequent events are attributed to this user until [reset].
  Future<void> identify(String userId, {Map<String, Object?>? traits});

  /// Clears the current user identity — call on sign-out so the next
  /// session starts anonymous and pre-existing user traits are not
  /// carried forward.
  Future<void> reset();

  /// Force-send any queued events. Vendor SDKs typically batch internally;
  /// callers invoke this around critical handoffs (e.g. just before
  /// deauth) so the dashboard reflects the last user actions.
  Future<void> flush();
}
