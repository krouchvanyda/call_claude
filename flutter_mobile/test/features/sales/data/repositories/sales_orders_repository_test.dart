import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/sales/data/repositories/sales_orders_repository.dart';
import 'package:erp_mobile/features/sales/entities/sales_order.dart';
import 'package:erp_mobile/features/sales/entities/sales_quotation.dart';
import 'package:test/test.dart';

SalesOrder _o({
  String id = 'o-1',
  SalesOrderStatus status = SalesOrderStatus.pending,
  String customerId = 'c',
  String customerName = 'C',
  DateTime? createdAt,
  String total = r'$100.00',
  List<SalesLineItem> lines = const <SalesLineItem>[],
}) =>
    SalesOrder(
      id: id,
      number: id,
      customerId: customerId,
      customerName: customerName,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 1),
      status: status,
      totalAmount: total,
      lineItems: lines,
    );

void main() {
  final now = DateTime.utc(2026, 5, 13, 10);
  final repo = SalesOrdersRepository();

  group('SalesOrdersRepository.advanceFulfillment — legal transitions', () {
    test('pending → packing', () {
      final out =
          repo.advanceFulfillment(_o(), to: SalesOrderStatus.packing, now: now);
      expect(out.status, SalesOrderStatus.packing);
      expect(out.shippedAt, isNull);
    });
    test('packing → shipped (requires tracking, stamps shippedAt)', () {
      final out = repo.advanceFulfillment(
        _o(status: SalesOrderStatus.packing),
        to: SalesOrderStatus.shipped,
        now: now,
        trackingReference: 'TR-1',
      );
      expect(out.status, SalesOrderStatus.shipped);
      expect(out.trackingReference, 'TR-1');
      expect(out.shippedAt, now);
    });
    test('shipped → delivered (stamps deliveredAt)', () {
      final out = repo.advanceFulfillment(
        _o(status: SalesOrderStatus.shipped),
        to: SalesOrderStatus.delivered,
        now: now,
      );
      expect(out.status, SalesOrderStatus.delivered);
      expect(out.deliveredAt, now);
    });
    test('pending → cancelled', () {
      final out = repo.advanceFulfillment(
        _o(),
        to: SalesOrderStatus.cancelled,
        now: now,
      );
      expect(out.status, SalesOrderStatus.cancelled);
    });
    test('packing → cancelled', () {
      final out = repo.advanceFulfillment(
        _o(status: SalesOrderStatus.packing),
        to: SalesOrderStatus.cancelled,
        now: now,
      );
      expect(out.status, SalesOrderStatus.cancelled);
    });
  });

  group('SalesOrdersRepository.advanceFulfillment — illegal transitions', () {
    test('pending → shipped (skips packing)', () {
      expect(
        () => repo.advanceFulfillment(
          _o(),
          to: SalesOrderStatus.shipped,
          now: now,
          trackingReference: 'X',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
    test('shipped → cancelled', () {
      expect(
        () => repo.advanceFulfillment(
          _o(status: SalesOrderStatus.shipped),
          to: SalesOrderStatus.cancelled,
          now: now,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
    test('delivered → anything', () {
      for (final s in SalesOrderStatus.values) {
        expect(
          () => repo.advanceFulfillment(
            _o(status: SalesOrderStatus.delivered),
            to: s,
            now: now,
            trackingReference: 'X',
          ),
          throwsA(isA<ConflictFailure>()),
        );
      }
    });
    test('cancelled is terminal', () {
      expect(
        () => repo.advanceFulfillment(
          _o(status: SalesOrderStatus.cancelled),
          to: SalesOrderStatus.packing,
          now: now,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  test('shipping without a tracking reference → ValidationFailure', () {
    expect(
      () => repo.advanceFulfillment(
        _o(status: SalesOrderStatus.packing),
        to: SalesOrderStatus.shipped,
        now: now,
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => repo.advanceFulfillment(
        _o(status: SalesOrderStatus.packing),
        to: SalesOrderStatus.shipped,
        now: now,
        trackingReference: '   ',
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  group('revenueByPeriod — monthly', () {
    test('sums orders into their containing month', () {
      final from = DateTime.utc(2026, 1, 1);
      final to = DateTime.utc(2026, 4, 1);
      final buckets = revenueByPeriod(
        [
          _o(id: '1', createdAt: DateTime.utc(2026, 1, 15), total: r'$100'),
          _o(id: '2', createdAt: DateTime.utc(2026, 1, 28), total: r'$50'),
          _o(id: '3', createdAt: DateTime.utc(2026, 3, 4), total: r'$1,000',
              status: SalesOrderStatus.delivered),
        ],
        period: RevenuePeriod.monthly,
        from: from,
        to: to,
      );
      expect(buckets, hasLength(3));
      expect(buckets[0].start, DateTime.utc(2026, 1, 1));
      expect(buckets[0].amount, 150);
      expect(buckets[1].start, DateTime.utc(2026, 2, 1));
      expect(buckets[1].amount, 0, reason: 'February has no orders');
      expect(buckets[2].start, DateTime.utc(2026, 3, 1));
      expect(buckets[2].amount, 1000);
    });

    test('excludes cancelled orders', () {
      final buckets = revenueByPeriod(
        [
          _o(
            id: '1',
            createdAt: DateTime.utc(2026, 5, 10),
            total: r'$100',
          ),
          _o(
            id: '2',
            createdAt: DateTime.utc(2026, 5, 11),
            total: r'$1,000',
            status: SalesOrderStatus.cancelled,
          ),
        ],
        period: RevenuePeriod.monthly,
        from: DateTime.utc(2026, 5, 1),
        to: DateTime.utc(2026, 6, 1),
      );
      expect(buckets.single.amount, 100);
    });

    test('orders outside [from, to) are ignored', () {
      final buckets = revenueByPeriod(
        [
          _o(id: '1', createdAt: DateTime.utc(2025, 12, 31), total: r'$1'),
          _o(id: '2', createdAt: DateTime.utc(2026, 1, 1), total: r'$2'),
          _o(id: '3', createdAt: DateTime.utc(2026, 2, 1), total: r'$3'),
        ],
        period: RevenuePeriod.monthly,
        from: DateTime.utc(2026, 1, 1),
        to: DateTime.utc(2026, 2, 1),
      );
      expect(buckets, hasLength(1));
      expect(buckets.single.amount, 2);
    });

    test('year boundary wraps correctly', () {
      final buckets = revenueByPeriod(
        const [],
        period: RevenuePeriod.monthly,
        from: DateTime.utc(2025, 12, 1),
        to: DateTime.utc(2026, 2, 1),
      );
      expect(buckets.map((b) => b.start), [
        DateTime.utc(2025, 12, 1),
        DateTime.utc(2026, 1, 1),
      ]);
    });
  });

  group('revenueByPeriod — weekly', () {
    test('snaps every order to its Monday', () {
      // 2026-05-13 is a Wednesday — bucket should be Monday 2026-05-11.
      final buckets = revenueByPeriod(
        [
          _o(id: '1', createdAt: DateTime.utc(2026, 5, 13), total: r'$100'),
          _o(id: '2', createdAt: DateTime.utc(2026, 5, 17), total: r'$50'),
        ],
        period: RevenuePeriod.weekly,
        from: DateTime.utc(2026, 5, 11),
        to: DateTime.utc(2026, 5, 18),
      );
      expect(buckets, hasLength(1));
      expect(buckets.single.start.weekday, DateTime.monday);
      expect(buckets.single.amount, 150);
    });
  });

  test('revenueByPeriod — to <= from returns empty', () {
    final buckets = revenueByPeriod(
      const [],
      period: RevenuePeriod.monthly,
      from: DateTime.utc(2026, 1, 1),
      to: DateTime.utc(2026, 1, 1),
    );
    expect(buckets, isEmpty);
  });

  test('revenueByPeriod — malformed amount strings sort as zero (no crash)',
      () {
    final buckets = revenueByPeriod(
      [_o(id: 'broken', createdAt: DateTime.utc(2026, 5, 1), total: '???')],
      period: RevenuePeriod.monthly,
      from: DateTime.utc(2026, 5, 1),
      to: DateTime.utc(2026, 6, 1),
    );
    expect(buckets.single.amount, 0);
  });

  group('topCustomers', () {
    test('sums per customer, sorts desc, takes top N', () {
      final out = topCustomers(
        [
          _o(id: '1', customerId: 'a', customerName: 'A', total: r'$100'),
          _o(id: '2', customerId: 'a', customerName: 'A', total: r'$200'),
          _o(id: '3', customerId: 'b', customerName: 'B', total: r'$500'),
          _o(id: '4', customerId: 'c', customerName: 'C', total: r'$50'),
        ],
        limit: 2,
      );
      expect(out, hasLength(2));
      expect(out.first.key, 'b');
      expect(out.first.label, 'B');
      expect(out.first.amount, r'$500.00');
      expect(out.first.units, 1);
      expect(out.last.key, 'a');
      expect(out.last.units, 2);
    });

    test('cancelled orders excluded', () {
      final out = topCustomers([
        _o(id: '1', customerId: 'a', total: r'$100'),
        _o(
          id: '2',
          customerId: 'a',
          total: r'$1,000',
          status: SalesOrderStatus.cancelled,
        ),
      ]);
      expect(out.single.amount, r'$100.00');
    });

    test('empty input → empty output', () {
      expect(topCustomers(const []), isEmpty);
    });
  });

  group('topProducts', () {
    SalesLineItem li({
      required String id,
      String? sku,
      required String description,
      required num qty,
      required String lineTotal,
    }) =>
        SalesLineItem(
          id: id,
          description: description,
          sku: sku,
          quantity: qty,
          unitPrice: r'$1',
          lineTotal: lineTotal,
        );

    test('keys on SKU when present, descriptions otherwise', () {
      final out = topProducts([
        _o(id: '1', total: r'$200', lines: [
          li(id: 'l1', sku: 'A', description: 'Apple', qty: 2, lineTotal: r'$200'),
        ]),
        _o(id: '2', total: r'$50', lines: [
          li(id: 'l2', description: 'Banana', qty: 5, lineTotal: r'$50'),
        ]),
      ]);
      expect(out, hasLength(2));
      expect(out.first.key, 'A');
      expect(out.first.label, contains('Apple'));
      expect(out.last.key, 'Banana');
    });

    test('aggregates units across orders', () {
      final out = topProducts([
        _o(id: '1', total: r'$30', lines: [
          li(id: 'l1', sku: 'X', description: 'X', qty: 3, lineTotal: r'$30'),
        ]),
        _o(id: '2', total: r'$50', lines: [
          li(id: 'l2', sku: 'X', description: 'X', qty: 5, lineTotal: r'$50'),
        ]),
      ]);
      expect(out.single.units, 8);
      expect(out.single.amount, r'$80.00');
    });

    test('cancelled order contributes nothing', () {
      final out = topProducts([
        _o(
          id: '1',
          status: SalesOrderStatus.cancelled,
          total: r'$1,000',
          lines: [
            li(id: 'l1', sku: 'X', description: 'X', qty: 10, lineTotal: r'$1,000'),
          ],
        ),
      ]);
      expect(out, isEmpty);
    });
  });
}
