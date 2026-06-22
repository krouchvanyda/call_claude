import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/notification.dart';

part 'notification_inbox_event.freezed.dart';

/// Inputs to [NotificationInboxBloc] (Slice 2.3.1).
///
/// Sealed union — adding a new event is one freezed factory + one
/// `on<...>` handler. Internal `_InboxUpdated` is fired by the bloc's
/// own subscription to the repository's watch stream (private so the
/// UI can't dispatch it directly — that's the bloc's concern alone).
@freezed
sealed class NotificationInboxEvent with _$NotificationInboxEvent {
  /// Subscribe to the repo's watch stream. Idempotent — calling twice
  /// is a no-op (the bloc tracks its own subscription).
  const factory NotificationInboxEvent.started() = NotificationInboxStarted;

  /// User opened a single notification. Drives the read flag + (later)
  /// triggers deep-link navigation outside the bloc.
  const factory NotificationInboxEvent.markedRead(String id) =
      NotificationInboxMarkedRead;

  /// "Mark all as read" toolbar action.
  const factory NotificationInboxEvent.markedAllRead() =
      NotificationInboxMarkedAllRead;

  /// Swipe-to-dismiss (or a context-menu "Dismiss"). Tombstones the row.
  const factory NotificationInboxEvent.dismissed(String id) =
      NotificationInboxDismissed;

  /// Internal: the watch stream emitted a fresh inbox snapshot. Wired
  /// by `_subscribe()` in the bloc; not for UI dispatch.
  const factory NotificationInboxEvent.inboxUpdated(
    List<AppNotification> notifications,
  ) = NotificationInboxUpdated;

  /// Internal: the watch stream errored — rare (drift errors are
  /// usually fatal) but surfaced as a `Failure` state instead of an
  /// uncaught exception.
  const factory NotificationInboxEvent.inboxFailed(String message) =
      NotificationInboxFailed;
}
