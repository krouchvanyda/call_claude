import 'package:erp_mobile/features/sales/data/repositories/customers_repository.dart';
import 'package:erp_mobile/features/sales/entities/customer.dart';
import 'package:test/test.dart';

Customer _c({
  required String id,
  String? name,
  String email = 'x@example.com',
  CustomerSegment segment = CustomerSegment.smb,
  CustomerStatus status = CustomerStatus.active,
  DateTime? onboardedAt,
  String lifetimeValue = r'$0.00',
  String? industry,
}) =>
    Customer(
      id: id,
      name: name ?? id,
      email: email,
      phone: '+855',
      billingAddress: 'PP',
      segment: segment,
      status: status,
      onboardedAt: onboardedAt ?? DateTime.utc(2025, 1, 1),
      lifetimeValue: lifetimeValue,
      industry: industry,
    );

void main() {
  final a = _c(
    id: 'a',
    name: 'Acme Corp',
    email: 'ap@acme.example',
    segment: CustomerSegment.enterprise,
    status: CustomerStatus.active,
    onboardedAt: DateTime.utc(2024, 6, 12),
    lifetimeValue: r'$184,200.00',
    industry: 'Manufacturing',
  );
  final b = _c(
    id: 'b',
    name: 'Globex',
    segment: CustomerSegment.midMarket,
    status: CustomerStatus.active,
    onboardedAt: DateTime.utc(2025, 2, 4),
    lifetimeValue: r'$48,500.00',
  );
  final c = _c(
    id: 'c',
    name: 'Initech',
    segment: CustomerSegment.smb,
    status: CustomerStatus.onHold,
    onboardedAt: DateTime.utc(2025, 6, 1),
    lifetimeValue: r'$12,300.00',
  );
  final all = [a, b, c];

  group('applyCustomerQuery — filter', () {
    test('empty filter set returns all (default sort: nameAsc)', () {
      expect(applyCustomerQuery(all).map((x) => x.id), ['a', 'b', 'c']);
    });
    test('status filter narrows', () {
      expect(
        applyCustomerQuery(all, statusFilter: {CustomerStatus.onHold})
            .map((x) => x.id),
        ['c'],
      );
    });
    test('segment filter narrows', () {
      expect(
        applyCustomerQuery(all, segmentFilter: {CustomerSegment.enterprise})
            .map((x) => x.id),
        ['a'],
      );
    });
    test('search hits name', () {
      expect(applyCustomerQuery(all, searchQuery: 'globex').single.id, 'b');
    });
    test('search hits email', () {
      expect(applyCustomerQuery(all, searchQuery: 'acme.example').single.id,
          'a');
    });
    test('search hits industry', () {
      expect(applyCustomerQuery(all, searchQuery: 'manufact').single.id, 'a');
    });
  });

  group('applyCustomerQuery — sort', () {
    test('nameAsc (default)', () {
      expect(applyCustomerQuery(all).map((x) => x.id), ['a', 'b', 'c']);
    });
    test('lifetimeValueDesc — strips currency punctuation before compare',
        () {
      expect(
        applyCustomerQuery(all, sort: CustomerSort.lifetimeValueDesc)
            .map((x) => x.id),
        ['a', 'b', 'c'],
      );
    });
    test('recentlyAdded — newest onboarding first', () {
      expect(
        applyCustomerQuery(all, sort: CustomerSort.recentlyAdded)
            .map((x) => x.id),
        ['c', 'b', 'a'],
      );
    });
  });

  test('does not mutate input', () {
    final input = [a, b, c];
    applyCustomerQuery(input, sort: CustomerSort.recentlyAdded);
    expect(input, [a, b, c]);
  });
}
