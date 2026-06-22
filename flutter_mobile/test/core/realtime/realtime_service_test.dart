import 'dart:async';

import 'package:erp_mobile/core/realtime/realtime_channel.dart';
import 'package:erp_mobile/core/realtime/realtime_connection_state.dart';
import 'package:erp_mobile/core/realtime/realtime_message.dart';
import 'package:erp_mobile/core/realtime/realtime_service.dart';
import 'package:erp_mobile/core/sync/backoff_strategy.dart';
import 'package:erp_mobile/core/utils/logger/app_logger.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:test/test.dart';

/// Test double — pumps messages on demand and tracks send / close calls.
class _FakeChannel implements RealtimeChannel {
  _FakeChannel();

  final _msgs = StreamController<RealtimeMessage>();
  final sent = <String>[];
  bool closed = false;

  @override
  Stream<RealtimeMessage> get messages => _msgs.stream;

  @override
  void send(String frame) => sent.add(frame);

  @override
  Future<void> close() async {
    closed = true;
    if (!_msgs.isClosed) await _msgs.close();
  }

  /// Push a server-side close (clean done).
  Future<void> closeFromServer() async {
    if (!_msgs.isClosed) await _msgs.close();
  }

  /// Push a transport error.
  void errorFromServer(Object e) {
    _msgs.addError(e);
  }
}

class _NoopLogger extends AppLogger {
  @override
  void log(LogLevel level, String message,
      {Object? error,
      StackTrace? stackTrace,
      Map<String, Object?>? context}) {}
}

/// Predictable backoff for reconnect-timing tests — every attempt sleeps
/// for the same tiny window so the test runs fast.
class _FixedBackoff extends BackoffStrategy {
  const _FixedBackoff(this._d);
  final Duration _d;
  @override
  Duration delayFor(int attempts) => _d;
}

void main() {
  group('RealtimeService', () {
    test('initial state is disconnected', () {
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async => _FakeChannel(),
        logger: _NoopLogger(),
      );
      expect(svc.state, RealtimeConnectionState.disconnected);
    });

    test('connect transitions disconnected → connecting → connected',
        () async {
      final ch = _FakeChannel();
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async => ch,
        logger: _NoopLogger(),
      );

      final states = <RealtimeConnectionState>[];
      final sub = svc.connectionState.listen(states.add);

      await svc.connect();
      await pumpEventQueue();

      expect(
        states,
        [
          RealtimeConnectionState.connecting,
          RealtimeConnectionState.connected,
        ],
      );
      expect(svc.state, RealtimeConnectionState.connected);

      await sub.cancel();
      await svc.dispose();
    });

    test('connect() is idempotent — second call during connected is a no-op',
        () async {
      final ch = _FakeChannel();
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async => ch,
        logger: _NoopLogger(),
      );

      await svc.connect();
      await pumpEventQueue();
      final stateBefore = svc.state;

      await svc.connect();
      await pumpEventQueue();

      expect(svc.state, stateBefore);
      await svc.dispose();
    });

    test(
        'pong messages are filtered out — they never reach the public '
        '`messages` stream',
        () async {
      final ch = _FakeChannel();
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async => ch,
        logger: _NoopLogger(),
      );

      final received = <RealtimeMessage>[];
      final sub = svc.messages.listen(received.add);

      await svc.connect();
      await pumpEventQueue();

      ch._msgs.add(const RealtimeMessage.pong());
      ch._msgs.add(const RealtimeMessage.kpiUpdate(
        id: 'x',
        value: '1',
        trend: 'up',
      ));
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.single, isA<RealtimeKpiUpdate>());

      await sub.cancel();
      await svc.dispose();
    });

    test(
        'transport done triggers reconnect — state passes through '
        'reconnecting then back to connected',
        () async {
      var built = 0;
      final channels = <_FakeChannel>[];
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async {
          built++;
          final c = _FakeChannel();
          channels.add(c);
          return c;
        },
        logger: _NoopLogger(),
        backoff: const _FixedBackoff(Duration(milliseconds: 10)),
      );

      final states = <RealtimeConnectionState>[];
      final sub = svc.connectionState.listen(states.add);

      await svc.connect();
      await pumpEventQueue();

      // Server closes.
      await channels[0].closeFromServer();
      // Wait past the backoff window for the reconnect attempt to fire.
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(built, 2, reason: 'a fresh channel must be built per attempt');
      expect(
        states,
        containsAllInOrder([
          RealtimeConnectionState.connecting,
          RealtimeConnectionState.connected,
          RealtimeConnectionState.reconnecting,
          RealtimeConnectionState.connecting,
          RealtimeConnectionState.connected,
        ]),
      );

      await sub.cancel();
      await svc.dispose();
    });

    test(
        'subscribe() while connected sends a subscribe frame; subscribe() '
        'is replayed on every reconnect',
        () async {
      final channels = <_FakeChannel>[];
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async {
          final c = _FakeChannel();
          channels.add(c);
          return c;
        },
        logger: _NoopLogger(),
        backoff: const _FixedBackoff(Duration(milliseconds: 10)),
      );

      await svc.connect();
      await pumpEventQueue();

      svc.subscribe('dashboard.kpi.revenue');
      svc.subscribe('dashboard.kpi.invoices');
      // Idempotent — second subscribe is a no-op (no extra frame sent).
      svc.subscribe('dashboard.kpi.revenue');

      expect(channels[0].sent.length, 2);
      expect(
        channels[0].sent.first,
        contains('dashboard.kpi.revenue'),
      );

      // Force reconnect.
      await channels[0].closeFromServer();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // The new channel got both subscribe frames replayed.
      expect(channels[1].sent.length, 2);
      expect(channels[1].sent.any((s) => s.contains('revenue')), isTrue);
      expect(channels[1].sent.any((s) => s.contains('invoices')), isTrue);

      await svc.dispose();
    });

    test(
        'unsubscribe removes the topic so it is NOT replayed after reconnect',
        () async {
      final channels = <_FakeChannel>[];
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async {
          final c = _FakeChannel();
          channels.add(c);
          return c;
        },
        logger: _NoopLogger(),
        backoff: const _FixedBackoff(Duration(milliseconds: 10)),
      );

      await svc.connect();
      await pumpEventQueue();

      svc.subscribe('topic-a');
      svc.subscribe('topic-b');
      svc.unsubscribe('topic-a');

      // First channel got: subscribe a, subscribe b, unsubscribe a.
      expect(channels[0].sent, hasLength(3));

      await channels[0].closeFromServer();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // Replay only includes topic-b.
      expect(channels[1].sent, hasLength(1));
      expect(channels[1].sent.single, contains('topic-b'));

      await svc.dispose();
    });

    test(
        'reconnect attempts are capped — service settles in disconnected '
        'after the cap is hit',
        () async {
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async => throw StateError('always fails'),
        logger: _NoopLogger(),
        backoff: const _FixedBackoff(Duration(milliseconds: 5)),
        maxReconnectAttempts: 2,
      );

      await svc.connect();
      // Wait long enough for ~2 retries to exhaust.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(svc.state, RealtimeConnectionState.disconnected);
      await svc.dispose();
    });

    test('disconnect() stops further reconnect attempts', () async {
      var attempts = 0;
      final svc = RealtimeService(
        url: Uri.parse('ws://x'),
        channelFactory: (_) async {
          attempts++;
          throw StateError('fail');
        },
        logger: _NoopLogger(),
        backoff: const _FixedBackoff(Duration(milliseconds: 10)),
        maxReconnectAttempts: 50,
      );

      await svc.connect();
      // Let one or two retries fire.
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await svc.disconnect();
      final attemptsAtStop = attempts;

      // Wait further — attempts should NOT keep climbing.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        attempts,
        attemptsAtStop,
        reason: 'disconnect() must cancel the pending reconnect timer',
      );
      expect(svc.state, RealtimeConnectionState.disconnected);

      await svc.dispose();
    });
  });
}
