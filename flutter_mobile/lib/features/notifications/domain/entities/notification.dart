import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';

/// One notification in the user's inbox (Slice 2.3.1).
///
/// Named `AppNotification` (not `Notification`) to avoid shadowing the
/// Flutter framework's `Notification` widget class — feature code that
/// imports both wins.
///
/// **Pure data**: no Flutter, no drift. The DAO maps `CachedNotificationRow`
/// ↔ `AppNotification` at the boundary; the bloc + UI work with this
/// type alone.
///
/// **Categories** are free-form strings — the server can introduce new
/// ones without a client schema bump. The UI maps unknown categories
/// to a generic icon.
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String title,
    required String body,

    /// Discriminator like `'invoice'`, `'leave-request'`, `'system'` —
    /// drives icon / colour selection in the inbox UI.
    required String category,

    /// Optional `go_router` named route for the deep-link target.
    /// `null` means the notification is informational only.
    String? routeName,

    /// Path parameters for the deep-link target. Empty when the route
    /// has no params (or [routeName] is null).
    @Default(<String, String>{}) Map<String, String> pathParameters,

    /// When the notification was first emitted (server / push timestamp).
    required DateTime receivedAt,

    /// `null` when unread. Set the first time the user opens the row.
    DateTime? readAt,

    /// Tombstone — true when the user swiped to dismiss. Kept (not
    /// deleted) so a future "show dismissed" toggle can restore.
    @Default(false) bool dismissed,
  }) = _AppNotification;

  const AppNotification._();

  /// Convenience predicate — `true` iff the user hasn't opened it yet.
  /// Dismissal is independent: a dismissed row can still be unread.
  bool get isUnread => readAt == null;

  /// `true` iff a tap on this notification should trigger navigation.
  bool get hasDeepLink => routeName != null;
}
