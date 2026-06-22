import 'dart:async';
import 'dart:convert';

import '../sync/backoff_strategy.dart';
import '../utils/logger/app_logger.dart';
import 'realtime_channel.dart';
import 'realtime_connection_state.dart';
import 'realtime_message.dart';

/// Manages the dashboard's WebSocket lifecycle (Slice 2.2.4).
///
/// **Responsibilities**:
/// - Open / hold / tear down the [RealtimeChannel].
/// - Track [RealtimeConnectionState] and surface it as a stream the UI
///   subscribes to for the "live" indicator.
/// - Reconnect with exponential backoff on transport failure / clean
///   close.
/// - Track topic subscriptions across reconnects — every time the
///   channel comes back, replay each subscribe directive so the server
///   knows what the client cares about (server is stateless across
///   reconnects).
/// - Filter inbound [RealtimeMessage]s into a typed stream the UI /
///   feature blocs read.
///
/// **Pure-Dart** (no Flutter import, no dio): the channel factory
/// abstracts the transport so unit tests pump fake channels through.
class RealtimeService {
  RealtimeService({
    required Uri url,
    required RealtimeChannelFactory channelFactory,
    required AppLogger logger,
    BackoffStrategy? backoff,
    int maxReconnectAttempts = 8,
  })  : _url = url,
        _channelFactory = channelFactory,
        _logger = logger,
        _backoff = backoff ?? const ExponentialBackoff(),
        _maxAttempts = maxReconnectAttempts;

  final Uri _url;
  final RealtimeChannelFactory _channelFactory;
  final AppLogger _logger;
  final BackoffStrategy _backoff;
  final int _maxAttempts;

  RealtimeChannel? _channel;
  StreamSubscription<RealtimeMessage>? _channelSub;
  Timer? _reconnectTimer;
  int _attempts = 0;
  bool _stopped = false;

  /// Topics the caller wants subscribed. Replayed on every reconnect.
  final Set<String> _topics = <String>{};

  final StreamController<RealtimeConnectionState> _stateController =
      StreamController<RealtimeConnectionState>.broadcast();
  final StreamController<RealtimeMessage> _messageController =
      StreamController<RealtimeMessage>.broadcast();

  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;

  /// Live connection state. Replays the current value to new
  /// subscribers via [state] so late mounts don't see "nothing".
  Stream<RealtimeConnectionState> get connectionState =>
      _stateController.stream;

  /// Current (last-emitted) state. Synchronous, useful for the UI's
  /// initial render before the stream produces.
  RealtimeConnectionState get state => _state;

  /// Inbound payloads. [RealtimePong] is filtered out — heartbeat
  /// noise has no business reaching the UI.
  Stream<RealtimeMessage> get messages => _messageController.stream;

  // ── Public lifecycle ────────────────────────────────────────────

  /// Idempotent — subsequent calls during an active connection are
  /// no-ops. Returns once the first connection attempt has been
  /// initiated (not necessarily completed).
  Future<void> connect() async {
    if (_state != RealtimeConnectionState.disconnected) return;
    _stopped = false;
    _attempts = 0;
    await _open();
  }

  /// Stops reconnect attempts and closes the active channel. Safe to
  /// call from any state.
  Future<void> disconnect() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.close();
    _channel = null;
    _setState(RealtimeConnectionState.disconnected);
  }

  /// Subscribe to a server topic. Idempotent — subscribing to the
  /// same topic twice is a no-op. Replayed on reconnect.
  void subscribe(String topic) {
    if (!_topics.add(topic)) return;
    _sendIfConnected({'kind': 'subscribe', 'topic': topic});
  }

  /// Inverse of [subscribe]. Idempotent.
  void unsubscribe(String topic) {
    if (!_topics.remove(topic)) return;
    _sendIfConnected({'kind': 'unsubscribe', 'topic': topic});
  }

  /// Releases all resources — call from the DI container's
  /// teardown / app shutdown hook.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _messageController.close();
  }

  // ── Internals ───────────────────────────────────────────────────

  Future<void> _open() async {
    _setState(RealtimeConnectionState.connecting);
    try {
      final channel = await _channelFactory(_url);
      _channel = channel;
      _channelSub = channel.messages.listen(
        _onMessage,
        onError: (Object e, StackTrace s) => _onTransportError(e, s),
        onDone: _onTransportDone,
        cancelOnError: true,
      );
      _setState(RealtimeConnectionState.connected);
      _attempts = 0;
      // Re-establish every previously-requested topic.
      for (final topic in _topics) {
        _sendIfConnected({'kind': 'subscribe', 'topic': topic});
      }
    } catch (e, s) {
      _logger.warn('realtime: connect failed', error: e, stackTrace: s);
      _scheduleReconnect();
    }
  }

  void _onMessage(RealtimeMessage msg) {
    // Pongs are heartbeat-only — never surface them to the UI.
    if (msg is RealtimePong) return;
    _messageController.add(msg);
  }

  void _onTransportError(Object e, StackTrace s) {
    _logger.warn('realtime: transport error', error: e, stackTrace: s);
    _scheduleReconnect();
  }

  void _onTransportDone() {
    _logger.info('realtime: transport closed');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.close();
    _channel = null;

    if (_stopped) return;

    _attempts++;
    if (_attempts > _maxAttempts) {
      _logger.error('realtime: gave up after $_attempts attempts');
      _setState(RealtimeConnectionState.disconnected);
      return;
    }

    final delay = _backoff.delayFor(_attempts);
    _setState(RealtimeConnectionState.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _open);
  }

  void _sendIfConnected(Map<String, Object?> frame) {
    final ch = _channel;
    if (ch == null || _state != RealtimeConnectionState.connected) return;
    ch.send(jsonEncode(frame));
  }

  void _setState(RealtimeConnectionState next) {
    if (_state == next) return;
    _state = next;
    _stateController.add(next);
  }
}
