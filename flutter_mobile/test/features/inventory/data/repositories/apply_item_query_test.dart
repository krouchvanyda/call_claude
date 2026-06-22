import 'package:erp_mobile/features/inventory/data/repositories/items_repository.dart';
import 'package:erp_mobile/features/inventory/entities/inventory_item.dart';
import 'package:test/test.dart';

InventoryItem _i({
  required String id,
  String? sku,
  String name = 'Generic widget',
  String warehouseCode = 'WH-MAIN',
  String locationCode = 'A1-01',
  num onHandQty = 100,
  num reorderPoint = 20,
  String? barcode,
  InventoryItemStatus status = InventoryItemStatus.active,
}) =>
    InventoryItem(
      id: id,
      sku: sku ?? id.toUpperCase(),
      name: name,
      warehouseCode: warehouseCode,
      locationCode: locationCode,
      onHandQty: onHandQty,
      reorderPoint: reorderPoint,
      unitCost: r'$1.00',
      barcode: barcode,
      status: status,
    );

void main() {
  final a = _i(
    id: 'a',
    sku: 'WID-A',
    name: 'Widget A',
    warehouseCode: 'WH-MAIN',
    onHandQty: 200,
    barcode: '7000000000017',
  );
  final b = _i(
    id: 'b',
    sku: 'WID-B',
    name: 'Widget B',
    warehouseCode: 'WH-MAIN',
    onHandQty: 5,
    reorderPoint: 10,
  );
  final c = _i(
    id: 'c',
    sku: 'GIZ-C',
    name: 'Gizmo C',
    warehouseCode: 'WH-NORTH',
    onHandQty: 0,
    reorderPoint: 4,
  );
  final all = [a, b, c];

  group('isLowStock', () {
    test('on-hand at or below reorderPoint counts as low', () {
      expect(b.isLowStock, isTrue, reason: '5 <= 10');
      expect(c.isLowStock, isTrue, reason: '0 <= 4');
    });
    test('on-hand above reorderPoint is fine', () {
      expect(a.isLowStock, isFalse);
    });
  });

  group('applyItemQuery — filter', () {
    test('empty filter returns everything (default sort: nameAsc)', () {
      expect(applyItemQuery(all).map((i) => i.id), ['c', 'a', 'b']);
    });

    test('warehouse filter narrows to the requested set', () {
      final out = applyItemQuery(all, warehouseFilter: {'WH-MAIN'});
      expect(out.map((i) => i.id), unorderedEquals(['a', 'b']));
    });

    test('onlyLowStock keeps only items at or below reorderPoint', () {
      expect(
        applyItemQuery(all, onlyLowStock: true).map((i) => i.id),
        unorderedEquals(['b', 'c']),
      );
    });

    test('search hits sku', () {
      expect(applyItemQuery(all, searchQuery: 'wid').map((i) => i.id),
          unorderedEquals(['a', 'b']));
    });

    test('search hits name (case-insensitive)', () {
      expect(applyItemQuery(all, searchQuery: 'GIZMO').single.id, 'c');
    });

    test('search hits barcode', () {
      expect(
        applyItemQuery(all, searchQuery: '7000000000017').single.id,
        'a',
      );
    });

    test('search hits location code', () {
      final scoped = [
        _i(id: 'x', locationCode: 'A1-01'),
        _i(id: 'y', locationCode: 'B3-04'),
      ];
      expect(applyItemQuery(scoped, searchQuery: 'B3').single.id, 'y');
    });

    test('combined filter + search + low-stock compose', () {
      expect(
        applyItemQuery(
          all,
          warehouseFilter: {'WH-MAIN'},
          onlyLowStock: true,
        ).map((i) => i.id),
        ['b'],
      );
    });
  });

  group('applyItemQuery — sort', () {
    test('nameAsc (default)', () {
      expect(applyItemQuery(all).map((i) => i.id), ['c', 'a', 'b']);
    });
    test('skuAsc', () {
      expect(
        applyItemQuery(all, sort: InventoryItemSort.skuAsc).map((i) => i.id),
        ['c', 'a', 'b'],
        reason: 'GIZ-C < WID-A < WID-B',
      );
    });
    test('onHandAsc', () {
      expect(
        applyItemQuery(all, sort: InventoryItemSort.onHandAsc)
            .map((i) => i.id),
        ['c', 'b', 'a'],
      );
    });
    test('onHandDesc', () {
      expect(
        applyItemQuery(all, sort: InventoryItemSort.onHandDesc)
            .map((i) => i.id),
        ['a', 'b', 'c'],
      );
    });
  });

  test('does not mutate the input list', () {
    final input = [a, b, c];
    applyItemQuery(input, sort: InventoryItemSort.skuAsc);
    expect(input, [a, b, c]);
  });
}
