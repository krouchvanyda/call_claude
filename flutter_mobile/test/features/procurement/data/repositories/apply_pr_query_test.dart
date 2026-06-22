import 'package:erp_mobile/features/procurement/data/repositories/purchase_requests_repository.dart';
import 'package:erp_mobile/features/procurement/entities/purchase_request.dart';
import 'package:test/test.dart';

PurchaseRequest _pr({
  required String id,
  required String number,
  required String requester,
  required String costCenter,
  required PurchaseRequestStatus status,
  required DateTime createdAt,
  required String total,
}) =>
    PurchaseRequest(
      id: id,
      number: number,
      requesterName: requester,
      costCenter: costCenter,
      approverName: 'Anyone',
      createdAt: createdAt,
      status: status,
      totalAmount: total,
      lineItems: const [],
    );

void main() {
  final a = _pr(
    id: '1',
    number: 'PR-2026-001',
    requester: 'Sokha',
    costCenter: 'CC-ENG-101',
    status: PurchaseRequestStatus.draft,
    createdAt: DateTime.utc(2026, 5, 1),
    total: r'$100.00',
  );
  final b = _pr(
    id: '2',
    number: 'PR-2026-002',
    requester: 'Dara',
    costCenter: 'CC-MKT-305',
    status: PurchaseRequestStatus.submitted,
    createdAt: DateTime.utc(2026, 5, 5),
    total: r'$500.00',
  );
  final c = _pr(
    id: '3',
    number: 'PR-2026-003',
    requester: 'Sothea',
    costCenter: 'CC-ENG-101',
    status: PurchaseRequestStatus.approved,
    createdAt: DateTime.utc(2026, 5, 10),
    total: r'$250.00',
  );
  final all = [a, b, c];

  group('applyPurchaseRequestQuery — filter', () {
    test('empty filter set passes everything through', () {
      expect(applyPurchaseRequestQuery(all), hasLength(3));
    });

    test('status filter narrows to the requested set', () {
      final result = applyPurchaseRequestQuery(
        all,
        statusFilter: {PurchaseRequestStatus.submitted},
      );
      expect(result.map((p) => p.id), ['2']);
    });

    test('search hits the number, requester, OR cost center', () {
      expect(
        applyPurchaseRequestQuery(all, searchQuery: '001').single.id,
        '1',
      );
      expect(
        applyPurchaseRequestQuery(all, searchQuery: 'sothea').single.id,
        '3',
      );
      // Default sort is createdDesc → newer cost-center match comes first.
      expect(
        applyPurchaseRequestQuery(all, searchQuery: 'cc-eng')
            .map((p) => p.id),
        ['3', '1'],
      );
    });

    test('search is case-insensitive and trims whitespace', () {
      expect(
        applyPurchaseRequestQuery(all, searchQuery: '  SOKHA  ').single.id,
        '1',
      );
    });

    test('filter + search compose (both must hold)', () {
      expect(
        applyPurchaseRequestQuery(
          all,
          statusFilter: {PurchaseRequestStatus.draft},
          searchQuery: 'cc-eng',
        ).map((p) => p.id),
        ['1'],
      );
    });
  });

  group('applyPurchaseRequestQuery — sort', () {
    test('createdDesc (default) — newest first', () {
      expect(
        applyPurchaseRequestQuery(all).map((p) => p.id),
        ['3', '2', '1'],
      );
    });
    test('createdAsc — oldest first', () {
      expect(
        applyPurchaseRequestQuery(all, sort: PurchaseRequestSort.createdAsc)
            .map((p) => p.id),
        ['1', '2', '3'],
      );
    });
    test('numberAsc', () {
      expect(
        applyPurchaseRequestQuery(all, sort: PurchaseRequestSort.numberAsc)
            .map((p) => p.id),
        ['1', '2', '3'],
      );
    });
    test('totalDesc — lexical compare on pre-formatted string (seed-OK)', () {
      // r'$500.00' > r'$250.00' > r'$100.00' lexicographically
      expect(
        applyPurchaseRequestQuery(all, sort: PurchaseRequestSort.totalDesc)
            .map((p) => p.id),
        ['2', '3', '1'],
      );
    });
  });

  test('does not mutate the input list', () {
    final input = [a, b, c];
    applyPurchaseRequestQuery(input, sort: PurchaseRequestSort.numberAsc);
    expect(input, [a, b, c]);
  });
}
