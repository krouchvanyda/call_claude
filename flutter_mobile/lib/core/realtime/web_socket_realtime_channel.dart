import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'realtime_channel.dart';
import 'realtime_message.dart';

/// `web_socket_channel`-backed [RealtimeChannel].
///
/// **Why a wrapper, not raw `WebSocketChannel.connect()` at call sites**:
/// keeps the package import in one file and converts the package's
/// `dynamic` event stream into our typed [RealtimeMessage] stream so
/// the rest of the app never touches the raw frames.
class WebSocketRealtimeChannel implements RealtimeChannel {
  WebSocketRealtimeChannel._(this._socket) {
    // Map raw text frames → typed messages. Errors propagate so the
    // service can react (move to `reconnecting`); the close is signaled
    // by stream completion, not by emitting a sentinel.
    _messages = _socket.stream.map((frame) {
      // web_socket_channel hands strings or List<int>; for binary we
      // stringify what we can but leave the body intact for the
      // unknown-message path.
      final raw = frame is String
          ? frame
          : frame is List<int>
              ? String.fromCharCodes(frame)
              : frame.toString();
      return RealtimeMessage.fromWire(raw);
    }).asBroadcastStream();
  }

  /// Production constructor — opens a real socket against [url].
  /// `Future`-returning so the factory signature in
  /// [RealtimeChannelFactory] stays uniform with implementations that
  /// might do an async handshake before returning.
  static Future<WebSocketRealtimeChannel> connect(Uri url) async {
    final socket = WebSocketChannel.connect(url);
    // `ready` resolves when the handshake completes; surfaces TLS /
    // 4xx errors at this point rather than turning them into silent
    // stream errors later.
    await socket.ready;
    return WebSocketRealtimeChannel._(socket);
  }

  final WebSocketChannel _socket;
  late final Stream<RealtimeMessage> _messages;

  @override
  Stream<RealtimeMessage> get messages => _messages;

  @override
  void send(String frame) => _socket.sink.add(frame);

  @override
  Future<void> close() => _socket.sink.close();
}
