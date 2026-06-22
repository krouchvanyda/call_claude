import 'package:erp_mobile/features/finance/data/repositories/trial_balance_repository.dart';
import 'package:test/test.dart';

void main() {
  group('paginate', () {
    test('first page slices the front of the list', () {
      expect(
        paginate(const [1, 2, 3, 4, 5], pageIndex: 0, pageSize: 2),
        [1, 2],
      );
    });

    test('middle page', () {
      expect(
        paginate(const [1, 2, 3, 4, 5], pageIndex: 1, pageSize: 2),
        [3, 4],
      );
    });

    test('last page short of full size returns the remainder', () {
      expect(
        paginate(const [1, 2, 3, 4, 5], pageIndex: 2, pageSize: 2),
        [5],
      );
    });

    test('out-of-range page → empty (no exception)', () {
      expect(
        paginate(const [1, 2, 3], pageIndex: 99, pageSize: 5),
        isEmpty,
      );
    });

    test('empty list → empty page (no exception)', () {
      expect(paginate(const <int>[], pageIndex: 0, pageSize: 5), isEmpty);
    });

    test('exact-fit boundary — last page is full, no phantom next page', () {
      expect(
        paginate(const [1, 2, 3, 4], pageIndex: 1, pageSize: 2),
        [3, 4],
      );
      expect(
        paginate(const [1, 2, 3, 4], pageIndex: 2, pageSize: 2),
        isEmpty,
      );
    });

    test('throws on invalid pageSize', () {
      expect(
        () => paginate(const [1], pageIndex: 0, pageSize: 0),
        throwsArgumentError,
      );
      expect(
        () => paginate(const [1], pageIndex: 0, pageSize: -1),
        throwsArgumentError,
      );
    });

    test('throws on negative pageIndex', () {
      expect(
        () => paginate(const [1], pageIndex: -1, pageSize: 5),
        throwsArgumentError,
      );
    });
  });

  group('pageCount', () {
    test('total 0 → 1 page (so a "page 1 of 1" header still renders)', () {
      expect(pageCount(totalItems: 0, pageSize: 10), 1);
    });

    test('exact divisor', () {
      expect(pageCount(totalItems: 20, pageSize: 10), 2);
    });

    test('rounds up on partial last page', () {
      expect(pageCount(totalItems: 23, pageSize: 10), 3);
    });

    test('throws on invalid pageSize', () {
      expect(
        () => pageCount(totalItems: 5, pageSize: 0),
        throwsArgumentError,
      );
    });
  });
}
