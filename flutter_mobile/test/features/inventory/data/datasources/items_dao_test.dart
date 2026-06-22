import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/inventory/data/datasources/items_dao.dart';
import 'package:erp_mobile/features/inventory/entities/inventory_item.dart';
import 'package:erp_mobile/features/inventory/entities/stock_movement.dart';
import 'package:test/test.dart';

InventoryItem _item({
  String id = 'inv-1',
  String warehouseCode = 'WH',
  num onHandQty = 100,
  num reorderPoint = 10,
  String? barcode,
  InventoryItemStatus status = InventoryItemStatus.active,
}) =>
    InventoryItem(
      id: id,
      sku: id.toUpperCase(),
      name: id,
      warehouseCode: warehouseCode,
      locationCode: 'L1',
      onHandQty: onHandQty,
      reorderPoint: reorderPoint,
      unitCost: r'$1',
      barcode: barcode,
      status: status,
    );

StockMovement _mov({
  String id = 'mov-1',
  String itemId = 'inv-1',
  StockMovementType type = StockMovementType.receipt,
  num quantity = 10,
  num runningQty = 110,
}) =>
    StockMovement(
      id: id,
      itemId: itemId,
      postedAt: DateTime.utc(2026, 5, 13, 9),
      type: type,
      quantity: quantity,
      runningQty: runningQty,
      reference: 'PO-1',
    );

void main() {
  late AppDatabase db;
  late ItemsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.itemsDao;
  });

  tearDown(() => db.close());

  group('items: upsert + reads', () {
    test('round-trips every field including the InventoryItemStatus enum',
        () async {
      final item = _item(
        barcode: '7000000000017',
        status: InventoryItemStatus.discontinued,
      );
      await dao.upsertItems([item]);
      final got = await dao.findItemById('inv-1');
      expect(got, isNotNull);
      expect(got!.barcode, '7000000000017');
      expect(got.status, InventoryItemStatus.discontinued);
      expect(got.onHandQty, 100);
      expect(got.reorderPoint, 10);
    });

    test('getAllItems sorts by name ASC', () async {
      await dao.upsertItems([
        _item(id: 'b'),
        _item(id: 'a'),
        _item(id: 'c'),
      ]);
      final names = (await dao.getAllItems()).map((i) => i.name).toList();
      expect(names, ['a', 'b', 'c']);
    });

    test('findItemByBarcode returns the only match', () async {
      await dao.upsertItems([
        _item(id: 'a', barcode: '111'),
        _item(id: 'b', barcode: '222'),
      ]);
      final got = await dao.findItemByBarcode('222');
      expect(got!.id, 'b');
    });

    test('distinctWarehouses dedups + sorts', () async {
      await dao.upsertItems([
        _item(id: 'a', warehouseCode: 'WH-NORTH'),
        _item(id: 'b', warehouseCode: 'WH-MAIN'),
        _item(id: 'c', warehouseCode: 'WH-MAIN'),
      ]);
      expect(await dao.distinctWarehouses(), ['WH-MAIN', 'WH-NORTH']);
    });

    test('setOnHand on unknown id → StateError', () async {
      await expectLater(
        dao.setOnHand('nope', 5),
        throwsA(isA<StateError>()),
      );
    });

    test('setOnHand returns the updated row', () async {
      await dao.upsertItems([_item()]);
      final out = await dao.setOnHand('inv-1', 42);
      expect(out.onHandQty, 42);
    });
  });

  group('movements: append + reads', () {
    setUp(() async {
      await dao.upsertItems([_item()]);
    });

    test('appendMovement persists and reads newest-first by postedAt',
        () async {
      await dao.appendMovement(_mov(
        id: 'a',
        runningQty: 50,
      ));
      await dao.appendMovement(StockMovement(
        id: 'b',
        itemId: 'inv-1',
        postedAt: DateTime.utc(2026, 5, 14),
        type: StockMovementType.issue,
        quantity: 5,
        runningQty: 45,
      ));
      final history = await dao.movementsForItem('inv-1');
      expect(history.map((m) => m.id), ['b', 'a']);
    });

    test('movementsForItem returns only that item\'s rows', () async {
      await dao.upsertItems([_item(id: 'inv-2')]);
      await dao.appendMovement(_mov(id: 'a', itemId: 'inv-1'));
      await dao.appendMovement(_mov(id: 'b', itemId: 'inv-2'));
      expect((await dao.movementsForItem('inv-1')).single.id, 'a');
      expect((await dao.movementsForItem('inv-2')).single.id, 'b');
    });

    test('watchMovementsForItem re-emits on each append', () async {
      final emitted = <int>[];
      final sub = dao.watchMovementsForItem('inv-1').listen(
            (rows) => emitted.add(rows.length),
          );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await dao.appendMovement(_mov(id: 'a'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await dao.appendMovement(_mov(id: 'b'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.length, greaterThanOrEqualTo(3));
      expect(emitted.last, 2);
      await sub.cancel();
    });

    test('FK cascade — deleting an item drops its history', () async {
      await dao.appendMovement(_mov(id: 'a'));
      await dao.wipeAll();
      expect(await dao.countItems(), 0);
      expect((await dao.movementsForItem('inv-1')), isEmpty);
    });
  });
}
