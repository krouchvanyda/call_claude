import 'package:erp_mobile/core/push/local_push_simulator.dart';
import 'package:erp_mobile/core/push/push_message.dart';
import 'package:test/test.dart';

void main() {
  group('LocalPushSimulator', () {
    test('initialize seeds a synthetic token', () async {
      final sim = LocalPushSimulator();
      expect(await sim.getToken(), isNull,
          reason: 'no token before initialize()');
      await sim.initialize();
      expect(await sim.getToken(), isNotNull);
      await sim.dispose();
    });

    test('requestPermission always grants (dev impl)', () async {
      final sim = LocalPushSimulator();
      expect(await sim.requestPermission(), isTrue);
      await sim.dispose();
    });

    test('simulate emits the same message to subscribers', () async {
      final sim = LocalPushSimulator();
      final received = <PushMessage>[];
      final sub = sim.messages.listen(received.add);

      const msg = PushMessage(id: 'm-1', title: 't', body: 'b');
      sim.simulate(msg);
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.single, msg);

      await sub.cancel();
      await sim.dispose();
    });

    test(
        'simulateNow wraps title/body/category into a PushMessage and '
        'merges supplied data',
        () async {
      final sim = LocalPushSimulator();
      final received = <PushMessage>[];
      final sub = sim.messages.listen(received.add);

      sim.simulateNow(
        title: 'Hello',
        body: 'World',
        category: 'invoice',
        data: const {'route': 'invoiceDetail', 'route.id': 'INV-1'},
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final msg = received.single;
      expect(msg.title, 'Hello');
      expect(msg.body, 'World');
      expect(msg.data['category'], 'invoice');
      expect(msg.data['route'], 'invoiceDetail');
      expect(msg.data['route.id'], 'INV-1');
      expect(msg.sentAt, isNotNull);

      await sub.cancel();
      await sim.dispose();
    });

    test('simulateTokenRefresh emits on onTokenRefresh and updates getToken',
        () async {
      final sim = LocalPushSimulator();
      await sim.initialize();
      final emitted = <String>[];
      final sub = sim.onTokenRefresh.listen(emitted.add);

      sim.simulateTokenRefresh('rotated-1');
      await pumpEventQueue();

      expect(emitted, ['rotated-1']);
      expect(await sim.getToken(), 'rotated-1');

      await sub.cancel();
      await sim.dispose();
    });

    test('messages stream is broadcast (multiple subscribers OK)', () async {
      final sim = LocalPushSimulator();
      final a = <PushMessage>[];
      final b = <PushMessage>[];
      final subA = sim.messages.listen(a.add);
      final subB = sim.messages.listen(b.add);

      sim.simulateNow(title: 't', body: 'b');
      await pumpEventQueue();

      expect(a, hasLength(1));
      expect(b, hasLength(1));

      await subA.cancel();
      await subB.cancel();
      await sim.dispose();
    });
  });
}
