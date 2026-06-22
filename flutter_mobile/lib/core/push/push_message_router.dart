import 'dart:async';

import '../../features/notifications/domain/entities/notification.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../utils/logger/app_logger.dart';
import '../utils/uuid_generator.dart';
import 'push_message.dart';
import 'push_notification_service.dart';
import 'push_token_storage.dart';

/// Wires [PushNotificationService] into the rest of the app (Slice 2.3.2).
///
/// **Responsibilities**:
/// - Initialise the push provider on `start()` and persist the device
///   token via [PushTokenStorage] (secure storage — never drift, per
///   the CLAUDE.md storage rule for any auth-equivalent secret).
/// - Watch for token rotation and re-persist.
/// - Translate inbound [PushMessage]s to [AppNotification]s using the
///   route / category / params conventions documented in [PushMessage]
///   and write them through the inbox repository.
/// - Dedupe on the server-supplied id so the same message arriving via
///   multiple transports (foreground stream + background isolate) only
///   produces one inbox row.
///
/// Pure-Dart so the routing rules live in unit tests rather than in
/// the dashboard's `initState`.
class PushMessageRouter {
  PushMessageRouter({
    required PushNotificationService service,
    required NotificationsRepository notifications,
    required PushTokenStorage tokenStorage,
    required AppLogger logger,
  })  : _service = service,
        _notifications = notifications,
        _tokenStorage = tokenStorage,
        _logger = logger;

  final PushNotificationService _service;
  final NotificationsRepository _notifications;
  final PushTokenStorage _tokenStorage;
  final AppLogger _logger;

  StreamSubscription<PushMessage>? _messageSub;
  StreamSubscription<String>? _tokenSub;
  bool _started = false;

  /// In-memory dedupe set — small bounded LRU would be ideal long
  /// term, but for the foreground+background single-app case the
  /// session is short enough that a plain set won't bloat. Cleared
  /// on `stop()`.
  final Set<String> _seenIds = <String>{};

  /// Idempotent — calling `start()` twice is a no-op (the second
  /// call returns once subscriptions are already in place).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _service.initialize();
    final granted = await _service.requestPermission();
    if (!granted) {
      _logger.warn('push: permission denied; staying subscribed in case '
          'the user grants later');
    }

    final token = await _service.getToken();
    if (token != null) {
      await _tokenStorage.saveToken(token);
    }

    _tokenSub = _service.onTokenRefresh.listen(
      _tokenStorage.saveToken,
      onError: (Object e, StackTrace s) =>
          _logger.warn('push: token refresh error', error: e, stackTrace: s),
    );

    _messageSub = _service.messages.listen(
      _onMessage,
      onError: (Object e, StackTrace s) =>
          _logger.warn('push: message stream error', error: e, stackTrace: s),
    );
  }

  /// Releases subscriptions and clears the dedupe set. Called from
  /// the sign-out path so a different account on the same device
  /// doesn't inherit cached message ids.
  Future<void> stop() async {
    _started = false;
    await _messageSub?.cancel();
    _messageSub = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    _seenIds.clear();
  }

  /// Translates a [PushMessage] to an [AppNotification] using the
  /// data-map conventions and writes through the repository.
  ///
  /// Visible for testing — production callers go through `start()` and
  /// the message stream.
  Future<void> handle(PushMessage message) async {
    final notification = mapToNotification(message);
    if (!_seenIds.add(notification.id)) {
      _logger.debug('push: deduped message ${notification.id}');
      return;
    }
    await _notifications.upsert(notification);
  }

  void _onMessage(PushMessage message) {
    // Fire-and-forget — handle() owns the await + the failure path.
    handle(message).catchError((Object e, StackTrace s) {
      _logger.warn('push: handle failed', error: e, stackTrace: s);
    });
  }

  /// Pure-Dart mapping from the wire envelope to the domain entity.
  /// Conventions:
  /// - `data['category']` → category (defaults to `'system'`).
  /// - `data['route']` → optional named route for the deep link.
  /// - `data['route.<key>']` → individual path parameters.
  /// - `message.id` → notification id (or a generated UUID when null).
  /// - `message.sentAt` → received-at (or `DateTime.now().toUtc()`).
  static AppNotification mapToNotification(PushMessage message) {
    final category = message.data['category'] ?? 'system';
    final routeName = message.data['route'];

    // Pull every `route.<key>` entry into the path-params map.
    const prefix = 'route.';
    final pathParams = <String, String>{
      for (final e in message.data.entries)
        if (e.key.startsWith(prefix) && e.key.length > prefix.length)
          e.key.substring(prefix.length): e.value,
    };

    return AppNotification(
      id: message.id ?? newUuid(),
      title: message.title,
      body: message.body,
      category: category,
      routeName: routeName,
      pathParameters: pathParams,
      receivedAt: message.sentAt ?? DateTime.now().toUtc(),
    );
  }
}
