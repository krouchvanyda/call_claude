import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/inventory/data/repositories/items_repository.dart';
import 'package:erp_mobile/features/inventory/data/repositories/stock_movements_repository.dart';
import 'package:erp_mobile/features/inventory/entities/cycle_count.dart';
import 'package:erp_mobile/features/inventory/entities/inventory_item.dart';
import 'package:erp_mobile/features/inventory/entities/stock_movement.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockItemsRepo extends Mock implements ItemsRepository {}

class _MockMovementsRepo extends Mock implements StockMovementsRepository {}

InventoryItem _i({
  required String id,
  num onHandQty = 50,
  InventoryItemStatus status = InventoryItemStatus.active,
}) =>
    InventoryItem(
      id: id,
      sku: id.toUpperCase(),
      name: id,
      warehouseCode: 'WH',
      locationCode: 'A',
      onHandQty: onHandQty,
      reorderPoint: 5,
      unitCost: r'$1',
      status: status,
    );

CycleCount _count({
  required List<CycleCountLine> lines,
  bool completed = false,
}) =>
    CycleCount(
      id: 'CYCLE-1',
      warehouseCode: 'WH',
      locationCode: 'A',
      startedAt: DateTime.utc(2026, 5, 13, 9),
      completedAt: completed ? DateTime.utc(2026, 5, 13, 10) : null,
      lines: lines,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(StockMovement(
      id: 'x',
      itemId: 'x',
      postedAt: DateTime.utc(2026, 5, 13),
      type: StockMovementType.adjustment,
      quantity: 1,
      runningQty: 0,
    ));
  });

  late _MockItemsRepo items;
  late _MockMovementsRepo movements;
  final clock = DateTime.utc(2026, 5, 13, 10);

  setUp(() {
    items = _MockItemsRepo();
    movements = _MockMovementsRepo();
  });

  test('posts one adjustment per non-zero-variance line', () async {
    when(() => items.findById('a'))
        .thenAnswer((_) async => _i(id: 'a', onHandQty: 10));
    when(() => items.findById('b'))
        .thenAnswer((_) async => _i(id: 'b', onHandQty: 4));
    when(() => items.setOnHand(any(), any()))
        .thenAnswer((inv) async => _i(
              id: inv.positionalArguments[0] as String,
              onHandQty: inv.positionalArguments[1] as num,
            ));
    when(() => movements.append(any())).thenAnswer(
        (inv) async => inv.positionalArguments.single as StockMovement);

    final out = await applyCycleCount(
      _count(lines: const [
        CycleCountLine(itemId: 'a', expectedQty: 10, countedQty: 12), // +2
        CycleCountLine(itemId: 'b', expectedQty: 4, countedQty: 3),    // -1
      ]),
      itemsRepo: items,
      movementsRepo: movements,
      clock: () => clock,
    );

    expect(out.adjustmentsPosted, hasLength(2));
    expect(out.totalVariance, 3);
    verify(() => items.setOnHand('a', 12)).called(1);
    verify(() => items.setOnHand('b', 3)).called(1);
  });

  test('zero-variance lines produce NO ledger noise', () async {
    when(() => items.findById('a'))
        .thenAnswer((_) async => _i(id: 'a', onHandQty: 10));
    when(() => movements.append(any())).thenAnswer(
        (inv) async => inv.positionalArguments.single as StockMovement);

    final out = await applyCycleCount(
      _count(lines: const [
        CycleCountLine(itemId: 'a', expectedQty: 10, countedQty: 10),
      ]),
      itemsRepo: items,
      movementsRepo: movements,
      clock: () => clock,
    );

    expect(out.adjustmentsPosted, isEmpty);
    expect(out.totalVariance, 0);
    verifyNever(() => items.setOnHand(any(), any()));
    verifyNever(() => movements.append(any()));
  });

  test('already-completed count → ConflictFailure (no double-apply)',
      () async {
    await expectLater(
      applyCycleCount(
        _count(
          lines: const [
            CycleCountLine(itemId: 'a', expectedQty: 5, countedQty: 6),
          ],
          completed: true,
        ),
        itemsRepo: items,
        movementsRepo: movements,
        clock: () => clock,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('empty lines → ValidationFailure', () async {
    await expectLater(
      applyCycleCount(
        _count(lines: const []),
        itemsRepo: items,
        movementsRepo: movements,
        clock: () => clock,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('negative countedQty → ValidationFailure', () async {
    await expectLater(
      applyCycleCount(
        _count(lines: const [
          CycleCountLine(itemId: 'a', expectedQty: 5, countedQty: -1),
        ]),
        itemsRepo: items,
        movementsRepo: movements,
        clock: () => clock,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('unknown item id → NotFoundFailure (only on non-zero variance)',
      () async {
    when(() => items.findById('ghost')).thenAnswer((_) async => null);
    await expectLater(
      applyCycleCount(
        _count(lines: const [
          CycleCountLine(itemId: 'ghost', expectedQty: 5, countedQty: 4),
        ]),
        itemsRepo: items,
        movementsRepo: movements,
        clock: () => clock,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('blocked items refuse adjustment', () async {
    when(() => items.findById('a')).thenAnswer(
      (_) async => _i(id: 'a', status: InventoryItemStatus.blocked),
    );
    await expectLater(
      applyCycleCount(
        _count(lines: const [
          CycleCountLine(itemId: 'a', expectedQty: 5, countedQty: 4),
        ]),
        itemsRepo: items,
        movementsRepo: movements,
        clock: () => clock,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });
}
