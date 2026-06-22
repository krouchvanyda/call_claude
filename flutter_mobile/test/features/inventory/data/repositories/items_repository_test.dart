import 'dart:convert';

import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/database/sync_queue_dao.dart';
import 'package:erp_mobile/core/sync/sync_op_status.dart';
import 'package:erp_mobile/features/inventory/data/datasources/items_dao.dart';
import 'package:erp_mobile/features/inventory/data/inventory_seed.dart';
import 'package:erp_mobile/features/inventory/data/repositories/items_repository.dart';
import 'package:erp_mobile/features/inventory/data/repositories/stock_movements_repository.dart';
import 'package:erp_mobile/features/inventory/entities/inventory_item.dart';
import 'package:erp_mobile/features/inventory/entities/stock_movement.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late ItemsDao dao;
  late SyncQueueDao syncQueue;
  late ItemsRepository itemsRepo;
  late StockMovementsRepository movementsRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.itemsDao;
    syncQueue = db.syncQueueDao;
    itemsRepo = ItemsRepository(dao: dao, syncQueue: syncQueue);
    movementsRepo =
        StockMovementsRepository(dao: dao, syncQueue: syncQueue);
  });

  tearDown(() => db.close());

  group('Slice 5.3.1 — lazy seed', () {
    test(
        'first read writes InventorySeed.items into drift when the table is empty',
        () async {
      expect(await dao.countItems(), 0);
      final all = await itemsRepo.getAll();
      expect(all, hasLength(InventorySeed.items.length));
      // Confirm a specific seed row survived the round-trip.
      final apple = all.firstWhere((i) => i.sku == 'TV-APL-4K');
      expect(apple.onHandQty, 0);
      expect(apple.barcode, '0190199098473');
    });

    test('second read is idempotent (no re-seed)', () async {
      await itemsRepo.getAll();
      final first = await dao.countItems();
      await itemsRepo.getAll();
      expect(await dao.countItems(), first);
    });

    test('pre-existing rows are preserved; only missing seed IDs are inserted', () async {
      // Bootstrap is idempotent and additive: any row already in the DB
      // stays untouched, and any seed row whose ID isn't in the DB gets
      // inserted. This lets new entries in InventorySeed.items take
      // effect across app upgrades without nuking user-edited data.
      await dao.upsertItems([
        InventoryItem(
          id: 'inv-existing',
          sku: 'X',
          name: 'X',
          warehouseCode: 'W',
          locationCode: 'L',
          onHandQty: 1,
          reorderPoint: 1,
          unitCost: r'$1',
          status: InventoryItemStatus.active,
        ),
      ]);
      final all = await itemsRepo.getAll();
      // 1 pre-existing + all seed rows (none share the 'inv-existing' id)
      expect(all, hasLength(1 + InventorySeed.items.length));
      // Pre-existing row preserved verbatim.
      final preserved = all.firstWhere((i) => i.id == 'inv-existing');
      expect(preserved.sku, 'X');
      expect(preserved.onHandQty, 1);
    });

    test('findByBarcode resolves through the drift cache', () async {
      await itemsRepo.getAll(); // trigger seed
      final hit = await itemsRepo.findByBarcode('5397184468036');
      expect(hit, isNotNull);
      expect(hit!.sku, 'MON-DELL-24');
    });

    test('warehouseCodes returns the seeded set, sorted', () async {
      await itemsRepo.getAll();
      final wh = await itemsRepo.warehouseCodes();
      expect(wh, isNotEmpty);
      final sorted = List<String>.of(wh)..sort();
      expect(wh, sorted, reason: 'DAO should sort the result');
    });
  });

  group('Slice 5.3.2 — SyncQueue enqueue on mutation', () {
    test('setOnHand enqueues a PATCH sync op with the new qty payload',
        () async {
      await itemsRepo.getAll(); // seed first
      await itemsRepo.setOnHand('inv-itm-001', 42);

      final pending = await syncQueue.pendingReady();
      expect(pending, hasLength(1));
      final op = pending.single;
      expect(op.entityType, 'inventory.item');
      expect(op.entityId, 'inv-itm-001');
      expect(op.endpointMethod, 'PATCH');
      expect(op.endpointPath, '/inventory/items/inv-itm-001/on-hand');
      expect(jsonDecode(op.payloadJson)['on_hand_qty'], 42);
    });

    test('movement append enqueues a POST sync op with the full payload',
        () async {
      await itemsRepo.getAll();
      await movementsRepo.append(StockMovement(
        id: 'tmp',
        itemId: 'inv-itm-001',
        postedAt: DateTime.utc(2026, 5, 13, 10),
        type: StockMovementType.issue,
        quantity: 4,
        runningQty: 236,
        reference: 'SO-001',
      ));

      final pending = await syncQueue.pendingReady();
      // Bootstrap also seeded movements, those are NOT enqueued (the
      // seed bypasses the public `append` path). So we expect exactly
      // one pending op — the one we just posted.
      expect(pending, hasLength(1));
      final op = pending.single;
      expect(op.entityType, 'inventory.movement');
      expect(op.endpointMethod, 'POST');
      expect(op.endpointPath, '/inventory/movements');
      final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
      expect(payload['item_id'], 'inv-itm-001');
      expect(payload['type'], 'issue');
      expect(payload['quantity'], 4);
      expect(payload['reference'], 'SO-001');
    });

    test('multiple mutations queue FIFO by createdAt', () async {
      await itemsRepo.getAll();
      await itemsRepo.setOnHand('inv-itm-001', 200);
      await itemsRepo.setOnHand('inv-itm-002', 30);
      await itemsRepo.setOnHand('inv-itm-003', 5);

      final pending = await syncQueue.pendingReady();
      expect(pending, hasLength(3));
      expect(pending.map((p) => p.entityId),
          ['inv-itm-001', 'inv-itm-002', 'inv-itm-003']);
    });
  });

  group('Slice 5.3.3 — batch drain on reconnect', () {
    test(
        'simulated drain: SyncEngine consumer flow (claim → mark complete) '
        'empties the queue in FIFO order',
        () async {
      await itemsRepo.getAll();
      // Stage three offline mutations.
      await itemsRepo.setOnHand('inv-itm-001', 50);
      await itemsRepo.setOnHand('inv-itm-002', 12);
      await movementsRepo.append(StockMovement(
        id: 'tmp',
        itemId: 'inv-itm-003',
        postedAt: DateTime.utc(2026, 5, 13),
        type: StockMovementType.adjustment,
        quantity: -1,
        runningQty: 3,
      ));

      expect(await syncQueue.pendingCount(), 3);

      // Simulate the SyncEngine drain: pop pending, claim each, and
      // mark complete (as if the HTTP PATCH/POST succeeded).
      var drained = 0;
      while (true) {
        final ready = await syncQueue.pendingReady();
        if (ready.isEmpty) break;
        final next = ready.first;
        final claimed = await syncQueue.markInFlight(next.id);
        expect(claimed, isTrue);
        await syncQueue.markCompleted(next.id);
        drained++;
      }
      expect(drained, 3);
      expect(await syncQueue.pendingCount(), 0);
    });

    test(
        'a failed op (markFailed without backoff) re-surfaces in pendingReady',
        () async {
      await itemsRepo.getAll();
      await itemsRepo.setOnHand('inv-itm-001', 99);

      final firstPass = await syncQueue.pendingReady();
      expect(firstPass, hasLength(1));
      final op = firstPass.single;
      await syncQueue.markInFlight(op.id);
      await syncQueue.markFailed(op.id, error: 'simulated 503');

      // Resurfaces (status flipped back to pending, attempts incremented).
      final reattempt = await syncQueue.pendingReady();
      expect(reattempt, hasLength(1));
      expect(reattempt.single.id, op.id);
      expect(reattempt.single.attempts, 1);
      expect(reattempt.single.status, SyncOpStatus.pending);
    });
  });

  test('watchAll re-emits after a setOnHand', () async {
    await itemsRepo.getAll(); // seed
    final emitted = <num>[];
    final sub = itemsRepo.watchAll().listen((rows) {
      final hit = rows.firstWhere((i) => i.id == 'inv-itm-001');
      emitted.add(hit.onHandQty);
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await itemsRepo.setOnHand('inv-itm-001', 50);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(emitted, contains(50));
    await sub.cancel();
  });
}
