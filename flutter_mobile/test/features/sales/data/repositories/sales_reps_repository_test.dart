import 'package:erp_mobile/features/sales/data/repositories/sales_reps_repository.dart';
import 'package:erp_mobile/features/sales/entities/activity_event.dart';
import 'package:erp_mobile/features/sales/entities/sales_rep.dart';
import 'package:test/test.dart';

ActivityEvent _order({
  required String actor,
  required String amount,
  String customerId = 'c-1',
  DateTime? at,
}) =>
    ActivityEvent(
      id: 'a',
      customerId: customerId,
      type: ActivityEventType.order,
      occurredAt: at ?? DateTime.utc(2026, 5, 1),
      summary: 'order',
      actor: actor,
      amount: amount,
    );

ActivityEvent _payment({
  required String actor,
  required String amount,
}) =>
    ActivityEvent(
      id: 'p',
      customerId: 'c-1',
      type: ActivityEventType.payment,
      occurredAt: DateTime.utc(2026, 5, 2),
      summary: 'pay',
      actor: actor,
      amount: amount,
    );

void main() {
  final repA = const SalesRep(
      id: 'r-a', name: 'Alice', targetAmount: r'$10,000.00');
  final repB = const SalesRep(
      id: 'r-b', name: 'Bob', targetAmount: r'$5,000.00');
  final repC = const SalesRep(
      id: 'r-c', name: 'Charlie', targetAmount: r'$0.00');

  group('salesRepLeaderboard', () {
    test('sorts reps by revenue desc and ranks 1-based', () {
      final out = salesRepLeaderboard(
        [
          _order(actor: 'Alice', amount: r'$2,000'),
          _order(actor: 'Alice', amount: r'$1,000'),
          _order(actor: 'Bob', amount: r'$5,000'),
        ],
        reps: [repA, repB],
      );
      expect(out.map((e) => e.rep.name), ['Bob', 'Alice']);
      expect(out.map((e) => e.rank), [1, 2]);
      expect(out.first.revenue, 5000);
      expect(out.last.revenue, 3000);
    });

    test('attainment % is revenue / target * 100', () {
      final out = salesRepLeaderboard(
        [_order(actor: 'Alice', amount: r'$2,500.00')],
        reps: [repA],
      );
      expect(out.single.attainmentPct, closeTo(25.0, 0.001));
    });

    test('zero or missing target → 0% (no NaN)', () {
      final out = salesRepLeaderboard(
        [_order(actor: 'Charlie', amount: r'$1,000')],
        reps: [repC],
      );
      expect(out.single.attainmentPct, 0.0);
    });

    test('ignores non-order events (no double-count via payments)', () {
      final out = salesRepLeaderboard(
        [
          _order(actor: 'Alice', amount: r'$1,000'),
          _payment(actor: 'Alice', amount: r'$1,000'),
        ],
        reps: [repA],
      );
      expect(out.single.revenue, 1000);
      expect(out.single.dealsClosed, 1);
    });

    test('reps without orders still appear at the bottom with 0 revenue',
        () {
      final out = salesRepLeaderboard(
        [_order(actor: 'Alice', amount: r'$1,000')],
        reps: [repA, repB],
      );
      expect(out, hasLength(2));
      final bob = out.firstWhere((e) => e.rep.name == 'Bob');
      expect(bob.revenue, 0);
      expect(bob.dealsClosed, 0);
    });

    test('unattributed actor still surfaces (no silent revenue loss)',
        () {
      final out = salesRepLeaderboard(
        [_order(actor: 'Ghost', amount: r'$10,000')],
        reps: const [],
      );
      expect(out, hasLength(1));
      expect(out.single.rep.name, 'Ghost');
      expect(out.single.targetAmount, '');
      expect(out.single.attainmentPct, 0.0);
    });

    test('limit truncates the result', () {
      final out = salesRepLeaderboard(
        [
          _order(actor: 'Alice', amount: r'$1,000'),
          _order(actor: 'Bob', amount: r'$2,000'),
        ],
        reps: [repA, repB],
        limit: 1,
      );
      expect(out, hasLength(1));
      expect(out.single.rep.name, 'Bob');
    });

    test('formattedRevenue uses thousands separators + 2 decimals', () {
      final out = salesRepLeaderboard(
        [_order(actor: 'Alice', amount: r'$8,400.00')],
        reps: [repA],
      );
      expect(out.single.formattedRevenue, r'$8,400.00');
    });
  });
}
