import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/inventory/data/repositories/items_repository.dart';
import 'package:erp_mobile/features/inventory/data/repositories/stock_movements_repository.dart';
import 'package:erp_mobile/features/inventory/entities/inventory_item.dart';
import 'package:erp_mobile/features/inventory/entities/stock_movement.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockItemsRepo extends Mock implements ItemsRepository {}

class _MockMovementsRepo extends Mock implements StockMovementsRepository {}

InventoryItem _item({
  num onHandQty = 100,
  InventoryItemStatus status = InventoryItemStatus.active,
}) =>
    InventoryItem(
      id: 'inv-1',
      sku: 'WID',
      name: 'Widget',
      warehouseCode: 'WH',
      locationCode: 'A1',
      onHandQty: onHandQty,
      reorderPoint: 10,
      unitCost: r'$1',
      status: status,
    );

StockMovement _fakeMovement() => StockMovement(
      id: 'mov-x',
      itemId: 'inv-1',
      postedAt: DateTime.utc(2026, 5, 13),
      type: StockMovementType.receipt,
      quantity: 1,
      runningQty: 0,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_fakeMovement());
  });

  late _MockItemsRepo items;
  late _MockMovementsRepo movements;
  final clock = DateTime.utc(2026, 5, 13, 10);

  setUp(() {
    items = _MockItemsRepo();
    movements = _MockMovementsRepo();
  });

  test('receipt: adds qty + appends a movement with the new runningQty',
      () async {
    when(() => items.findById('inv-1')).thenAnswer((_) async => _item());
    when(() => items.setOnHand('inv-1', 110))
        .thenAnswer((_) async => _item(onHandQty: 110));
    when(() => movements.append(any()))
        .thenAnswer((inv) async => inv.positionalArguments.single as StockMovement);

    final out = await recordStockMovement(
      itemsRepo: items,
      movementsRepo: movements,
      itemId: 'inv-1',
      type: StockMovementType.receipt,
      quantity: 10,
      reference: 'PO-1',
      clock: () => clock,
    );
    expect(out.item.onHandQty, 110);
    verify(() => items.setOnHand('inv-1', 110)).called(1);
    final captured =
        verify(() => movements.append(captureAny())).captured.single as StockMovement;
    expect(captured.runningQty, 110);
    expect(captured.type, StockMovementType.receipt);
    expect(captured.postedAt, clock);
    expect(captured.reference, 'PO-1');
  });

  test('issue: subtracts qty', () async {
    when(() => items.findById('inv-1')).thenAnswer((_) async => _item());
    when(() => items.setOnHand('inv-1', 60))
        .thenAnswer((_) async => _item(onHandQty: 60));
    when(() => movements.append(any())).thenAnswer(
        (inv) async => inv.positionalArguments.single as StockMovement);

    final out = await recordStockMovement(
      itemsRepo: items,
      movementsRepo: movements,
      itemId: 'inv-1',
      type: StockMovementType.issue,
      quantity: 40,
      clock: () => clock,
    );
    expect(out.item.onHandQty, 60);
  });

  test('issue: refuses to over-issue (ValidationFailure exceeds_on_hand)',
      () async {
    when(() => items.findById('inv-1'))
        .thenAnswer((_) async => _item(onHandQty: 5));
    await expectLater(
      recordStockMovement(
        itemsRepo: items,
        movementsRepo: movements,
        itemId: 'inv-1',
        type: StockMovementType.issue,
        quantity: 10,
        clock: () => clock,
      ),
      throwsA(isA<ValidationFailure>().having(
        (f) => f.fieldErrors,
        'fieldErrors',
        containsPair('quantity', ['exceeds_on_hand']),
      )),
    );
    verifyNever(() => items.setOnHand(any(), any()));
  });

  test('receipt: rejects non-positive quantity', () async {
    when(() => items.findById('inv-1')).thenAnswer((_) async => _item());
    await expectLater(
      recordStockMovement(
        itemsRepo: items,
        movementsRepo: movements,
        itemId: 'inv-1',
        type: StockMovementType.receipt,
        quantity: 0,
        clock: () => clock,
      ),
      throwsA(isA<ValidationFailure>().having(
        (f) => f.fieldErrors,
        'fieldErrors',
        containsPair('quantity', ['must_be_positive']),
      )),
    );
  });

  test('receipt on a discontinued item → ConflictFailure', () async {
    when(() => items.findById('inv-1')).thenAnswer(
        (_) async => _item(status: InventoryItemStatus.discontinued));
    await expectLater(
      recordStockMovement(
        itemsRepo: items,
        movementsRepo: movements,
        itemId: 'inv-1',
        type: StockMovementType.receipt,
        quantity: 1,
        clock: () => clock,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('adjustment accepts signed quantities (both directions)', () async {
    when(() => items.findById('inv-1')).thenAnswer((_) async => _item());
    when(() => items.setOnHand('inv-1', 99))
        .thenAnswer((_) async => _item(onHandQty: 99));
    when(() => movements.append(any())).thenAnswer(
        (inv) async => inv.positionalArguments.single as StockMovement);

    await recordStockMovement(
      itemsRepo: items,
      movementsRepo: movements,
      itemId: 'inv-1',
      type: StockMovementType.adjustment,
      quantity: -1,
      clock: () => clock,
    );
    verify(() => items.setOnHand('inv-1', 99)).called(1);
  });

  test('unknown id → NotFoundFailure', () async {
    when(() => items.findById('nope')).thenAnswer((_) async => null);
    await expectLater(
      recordStockMovement(
        itemsRepo: items,
        movementsRepo: movements,
        itemId: 'nope',
        type: StockMovementType.receipt,
        quantity: 1,
        clock: () => clock,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('transfer type rejected — caller must use transferStock', () async {
    await expectLater(
      recordStockMovement(
        itemsRepo: items,
        movementsRepo: movements,
        itemId: 'inv-1',
        type: StockMovementType.transfer,
        quantity: 1,
        clock: () => clock,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
