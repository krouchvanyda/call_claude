import 'realtime_message.dart';

/// Transport-agnostic seam between the [RealtimeService] and the actual
/// network library (web_socket_channel today, possibly socket.io / SSE
/// tomorrow). Pure-Dart so tests fake it without flutter_test.
///
/// **Lifecycle**: callers connect once, drain [messages] until it
/// completes, optionally [send] frames, then [close]. A channel that
/// has emitted `done` on [messages] is dead — the service builds a
/// fresh channel via the factory for the next attempt.
abstract class RealtimeChannel {
  /// Inbound frames from the server. Completes (without error) on a
  /// clean close, errors on transport failure.
  Stream<RealtimeMessage> get messages;

  /// Send a raw text frame upstream — the channel doesn't enforce a
  /// schema; the service decides what to send (subscribe/unsubscribe
  /// directives, heartbeats).
  void send(String frame);

  /// Idempotent — calling twice is fine. Future completes once the
  /// underlying socket has fully shut down.
  Future<void> close();
}

/// Factory that produces a fresh [RealtimeChannel] per (re)connect
/// attempt. Lets the service open new sockets without owning a
/// reference to dio / web_socket_channel itself.
typedef RealtimeChannelFactory = Future<RealtimeChannel> Function(Uri url);
