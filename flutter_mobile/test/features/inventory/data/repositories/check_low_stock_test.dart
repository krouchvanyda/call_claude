import 'package:erp_mobile/features/inventory/data/repositories/items_repository.dart';
import 'package:erp_mobile/features/inventory/entities/inventory_item.dart';
import 'package:test/test.dart';

InventoryItem _i({
  required String id,
  num onHandQty = 100,
  num reorderPoint = 20,
  InventoryItemStatus status = InventoryItemStatus.active,
}) =>
    InventoryItem(
      id: id,
      sku: id,
      name: id,
      warehouseCode: 'WH',
      locationCode: 'L',
      onHandQty: onHandQty,
      reorderPoint: reorderPoint,
      unitCost: r'$1',
      status: status,
    );

void main() {
  group('checkLowStock', () {
    test('empty input → empty report', () {
      final r = checkLowStock(const <InventoryItem>[]);
      expect(r.allLowStock, isEmpty);
      expect(r.newlyAlerted, isEmpty);
    });

    test('skips items above their reorder point', () {
      final r = checkLowStock([_i(id: 'ok', onHandQty: 50, reorderPoint: 10)]);
      expect(r.allLowStock, isEmpty);
    });

    test('captures items at or below the reorder point', () {
      final r = checkLowStock([
        _i(id: 'a', onHandQty: 10, reorderPoint: 10),
        _i(id: 'b', onHandQty: 4, reorderPoint: 10),
        _i(id: 'c', onHandQty: 11, reorderPoint: 10),
      ]);
      expect(r.allLowStock.map((i) => i.id), unorderedEquals(['a', 'b']));
    });

    test('discontinued / blocked items never fire alerts', () {
      final r = checkLowStock([
        _i(id: 'a', onHandQty: 0, status: InventoryItemStatus.discontinued),
        _i(id: 'b', onHandQty: 0, status: InventoryItemStatus.blocked),
        _i(id: 'c', onHandQty: 0, status: InventoryItemStatus.active),
      ]);
      expect(r.allLowStock.map((i) => i.id), ['c']);
    });

    test('newlyAlerted excludes items in previouslyAlertedIds', () {
      final items = [
        _i(id: 'a', onHandQty: 0),
        _i(id: 'b', onHandQty: 0),
      ];
      final r = checkLowStock(items, previouslyAlertedIds: {'a'});
      expect(r.allLowStock.map((i) => i.id), unorderedEquals(['a', 'b']));
      expect(r.newlyAlerted.map((i) => i.id), ['b']);
    });

    test('second pass with the same input → no new alerts', () {
      final items = [_i(id: 'a', onHandQty: 0)];
      final first = checkLowStock(items);
      expect(first.newlyAlerted, isNotEmpty);

      final second = checkLowStock(
        items,
        previouslyAlertedIds: first.newlyAlerted.map((i) => i.id).toSet(),
      );
      expect(second.newlyAlerted, isEmpty);
      expect(second.allLowStock, isNotEmpty,
          reason: 'allLowStock is still current state, not just deltas');
    });
  });
}
