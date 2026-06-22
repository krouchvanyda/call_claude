import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/notification.dart';

part 'notification_inbox_state.freezed.dart';

/// State machine for [NotificationInboxBloc] (Slice 2.3.1).
///
/// **Why one `Loaded` state with a derived unread count, not separate
/// states for empty / non-empty**: the inbox view rebuilds the same
/// scaffold either way; an `if (notifications.isEmpty)` in the widget
/// is cheaper than a state-shape branch.
@freezed
sealed class NotificationInboxState with _$NotificationInboxState {
  /// Pre-subscribe — the bloc hasn't loaded the first snapshot yet.
  const factory NotificationInboxState.initial() = NotificationInboxInitial;

  /// First snapshot in flight.
  const factory NotificationInboxState.loading() = NotificationInboxLoading;

  /// Latest inbox snapshot. [notifications] is newest-first, dismissed
  /// rows already filtered. [unreadCount] is derived once at emit time
  /// rather than re-counted per UI rebuild.
  const factory NotificationInboxState.loaded({
    required List<AppNotification> notifications,
    required int unreadCount,
  }) = NotificationInboxLoaded;

  /// Watch stream errored. Rare in practice — drift errors are usually
  /// fatal — but a typed state lets the UI render a retry hint instead
  /// of an indefinite spinner.
  const factory NotificationInboxState.failure(String message) =
      NotificationInboxFailure;
}
