import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notification_inbox_event.dart';
import 'notification_inbox_state.dart';

/// Bloc behind the notification inbox view (Slice 2.3.1).
///
/// **Watch-only data flow**: the bloc subscribes to
/// [NotificationsRepository.watchInbox] once on `Started`. User actions
/// (mark-read / dismiss / mark-all) write through the repository; drift
/// then re-emits, the watch stream forwards, and the bloc emits a
/// fresh `Loaded`. No imperative refresh path is needed because the
/// source of truth never lags the view.
///
/// **Why an internal `_InboxUpdated` event** instead of emitting from
/// the stream subscription directly: bloc handlers serialise state
/// transitions, so funnelling stream updates through `add()` keeps the
/// "user clicks dismiss → drift writes → watch fires → state emits"
/// path on the same lane as the user-initiated handlers.
class NotificationInboxBloc
    extends Bloc<NotificationInboxEvent, NotificationInboxState> {
  NotificationInboxBloc({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationInboxState.initial()) {
    on<NotificationInboxStarted>(_onStarted);
    on<NotificationInboxMarkedRead>(_onMarkedRead);
    on<NotificationInboxMarkedAllRead>(_onMarkedAllRead);
    on<NotificationInboxDismissed>(_onDismissed);
    on<NotificationInboxUpdated>(_onUpdated);
    on<NotificationInboxFailed>(_onFailed);
  }

  final NotificationsRepository _repository;
  StreamSubscription<List<AppNotification>>? _sub;

  Future<void> _onStarted(
    NotificationInboxStarted event,
    Emitter<NotificationInboxState> emit,
  ) async {
    if (_sub != null) return; // Idempotent — already subscribed.
    emit(const NotificationInboxState.loading());
    _sub = _repository.watchInbox().listen(
          (list) => add(NotificationInboxEvent.inboxUpdated(list)),
          onError: (Object e) =>
              add(NotificationInboxEvent.inboxFailed(e.toString())),
        );
  }

  Future<void> _onMarkedRead(
    NotificationInboxMarkedRead event,
    Emitter<NotificationInboxState> emit,
  ) async {
    await _repository.markRead(event.id);
    // No emit here — the drift write triggers the watch stream which
    // emits an Updated event the bloc handles below.
  }

  Future<void> _onMarkedAllRead(
    NotificationInboxMarkedAllRead event,
    Emitter<NotificationInboxState> emit,
  ) async {
    await _repository.markAllRead();
  }

  Future<void> _onDismissed(
    NotificationInboxDismissed event,
    Emitter<NotificationInboxState> emit,
  ) async {
    await _repository.dismiss(event.id);
  }

  void _onUpdated(
    NotificationInboxUpdated event,
    Emitter<NotificationInboxState> emit,
  ) {
    final unread = event.notifications.where((n) => n.isUnread).length;
    emit(NotificationInboxState.loaded(
      notifications: event.notifications,
      unreadCount: unread,
    ));
  }

  void _onFailed(
    NotificationInboxFailed event,
    Emitter<NotificationInboxState> emit,
  ) {
    emit(NotificationInboxState.failure(event.message));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
