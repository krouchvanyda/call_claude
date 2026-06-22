import 'dart:convert';

import '../../../../core/database/sync_queue_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_op_type.dart';
import '../../../../core/utils/clock.dart';
import '../../entities/cycle_count.dart';
import '../../entities/inventory_item.dart';
import '../../entities/stock_movement.dart';
import '../datasources/items_dao.dart';
import '../inventory_seed.dart';
import 'items_repository.dart';

/// Drift-backed stock movements repository (Slice 5.1.2 / 5.3.1). Flat
/// MVVM: single concrete repo — no abstract interface. The class-based
/// use cases that used to orchestrate items + movements
/// ([recordStockMovement], [transferStock], [applyCycleCount]) live as
/// free top-level functions at the bottom of this file (same precedent
/// as `convertQuotationToOrder` in sales).
///
/// **Append-only ledger** — the only mutation is [append], which the
/// DAO inserts and the SyncQueue picks up (Slice 5.3.2). The repo
/// also seeds [`InventorySeed.movements`] once the parent items have
/// landed, so the detail view has history out of the box.
class StockMovementsRepository {
  StockMovementsRepository({
    required ItemsDao dao,
    required SyncQueueDao syncQueue,
  })  : _dao = dao,
        _syncQueue = syncQueue;

  final ItemsDao _dao;
  final SyncQueueDao _syncQueue;
  Future<void>? _bootstrap;
  static int _idCounter = 100;

  Future<void> _ensureBootstrapped() {
    return _bootstrap ??= _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    // Movements seed depends on items being present — if items haven't
    // been seeded yet (race between two repos hitting first call), the
    // FK would explode. Defensive: re-check parent existence per row.
    final seed = InventorySeed.movements();
    for (final m in seed) {
      final parent = await _dao.findItemById(m.itemId);
      if (parent == null) continue;
      // Skip duplicates on app restart.
      final existing = await _dao.movementsForItem(m.itemId);
      if (existing.any((e) => e.id == m.id)) continue;
      await _dao.appendMovement(m);
    }
  }

  Future<List<StockMovement>> forItem(String itemId) async {
    await _ensureBootstrapped();
    return _dao.movementsForItem(itemId);
  }

  Stream<List<StockMovement>> watchForItem(String itemId) async* {
    await _ensureBootstrapped();
    yield* _dao.watchMovementsForItem(itemId);
  }

  /// Appends a new movement (Slices 5.2.2 / 5.2.3 / 5.2.4). Returns
  /// the persisted record (the repo assigns the id + timestamp).
  Future<StockMovement> append(StockMovement draft) async {
    await _ensureBootstrapped();
    _idCounter++;
    final assignedId =
        draft.id == 'tmp' ? 'mov-${DateTime.now().microsecondsSinceEpoch}-$_idCounter' : draft.id;
    final persisted = StockMovement(
      id: assignedId,
      itemId: draft.itemId,
      postedAt: draft.postedAt,
      type: draft.type,
      quantity: draft.quantity,
      runningQty: draft.runningQty,
      reference: draft.reference,
      note: draft.note,
    );
    await _dao.appendMovement(persisted);
    await _enqueueSyncOp(persisted);
    return persisted;
  }

  Future<void> _enqueueSyncOp(StockMovement m) async {
    try {
      await _syncQueue.enqueue(
        entityType: 'inventory.movement',
        entityId: m.id,
        // Append-only; semantically `create` even though SyncOpType
        // is a coarse vocabulary. The replay endpoint POSTs.
        operation: SyncOpType.create,
        payloadJson: jsonEncode({
          'item_id': m.itemId,
          'posted_at': m.postedAt.toUtc().toIso8601String(),
          'type': m.type.name,
          'quantity': m.quantity,
          'running_qty': m.runningQty,
          'reference': m.reference,
          'note': m.note,
        }),
        endpointMethod: 'POST',
        endpointPath: '/inventory/movements',
      );
    } catch (_) {
      // Best-effort enqueue (see DriftInvoicesRepository).
    }
  }
}

// ── Free-function orchestrations ─────────────────────────────────────
//
// The three class-based use cases that used to live under
// `domain/usecases/` are now plain top-level functions, mirroring the
// precedent set by `convertQuotationToOrder` in sales. Each takes the
// two repos explicitly so we don't introduce a constructor-level coupling
// between them.

/// Result bundle from a successful [recordStockMovement] call —
/// callers usually want both the updated item (to refresh the list)
/// and the appended movement (to navigate to the audit row).
class RecordStockMovementResult {
  const RecordStockMovementResult({required this.item, required this.movement});
  final InventoryItem item;
  final StockMovement movement;
}

/// Posts a single ledger row + updates the item's on-hand quantity
/// (Slice 5.2.2). Handles every non-transfer movement type:
/// `receipt`, `issue`, `adjustment`. Transfers go through
/// [transferStock] because they touch two locations.
///
/// **Invariants**:
///   - `quantity` must be `> 0` for receipts and issues
///     (use `adjustment` for signed corrections).
///   - An `issue` whose quantity exceeds on-hand throws
///     [`ValidationFailure`] with field `quantity: ['exceeds_on_hand']`
///     so the form can surface an inline error.
///   - Discontinued / blocked items refuse new receipts but allow
///     adjustments (the latter is the only way to wind them down).
Future<RecordStockMovementResult> recordStockMovement({
  required ItemsRepository itemsRepo,
  required StockMovementsRepository movementsRepo,
  required String itemId,
  required StockMovementType type,
  required num quantity,
  String? reference,
  String? note,
  Clock clock = DateTime.now,
}) async {
  if (type == StockMovementType.transfer) {
    throw Failure.validation(
      message: 'Use transferStock for transfers',
      fieldErrors: const {
        'type': ['use_transfer_usecase'],
      },
    );
  }

  final item = await itemsRepo.findById(itemId);
  if (item == null) {
    throw Failure.notFound(message: 'item $itemId');
  }

  if (type == StockMovementType.receipt &&
      item.status != InventoryItemStatus.active) {
    throw Failure.conflict(
      message: 'Receipts blocked for ${item.status.name} items',
    );
  }

  if (type == StockMovementType.receipt || type == StockMovementType.issue) {
    if (quantity <= 0) {
      throw const Failure.validation(
        fieldErrors: {
          'quantity': ['must_be_positive'],
        },
      );
    }
  }

  final delta = switch (type) {
    StockMovementType.receipt => quantity,
    StockMovementType.issue => -quantity,
    StockMovementType.adjustment => quantity, // signed
    StockMovementType.transfer => 0, // unreachable
  };

  final nextOnHand = item.onHandQty + delta;
  if (nextOnHand < 0) {
    throw const Failure.validation(
      fieldErrors: {
        'quantity': ['exceeds_on_hand'],
      },
    );
  }

  final updatedItem = await itemsRepo.setOnHand(itemId, nextOnHand);
  final persistedMovement = await movementsRepo.append(StockMovement(
    id: 'tmp', // overwritten by repo
    itemId: itemId,
    postedAt: clock(),
    type: type,
    quantity: quantity.abs(),
    runningQty: nextOnHand,
    reference: reference,
    note: note,
  ));
  return RecordStockMovementResult(
    item: updatedItem,
    movement: persistedMovement,
  );
}

/// Two-leg result: one row per location.
class TransferStockResult {
  const TransferStockResult({
    required this.sourceItem,
    required this.destinationItem,
    required this.outboundMovement,
    required this.inboundMovement,
  });

  final InventoryItem sourceItem;
  final InventoryItem destinationItem;

  /// Movement on the source row (negative `quantity`).
  final StockMovement outboundMovement;

  /// Movement on the destination row (positive `quantity`).
  final StockMovement inboundMovement;
}

/// Stock transfer between two location bins (Slice 5.2.3).
///
/// **Why two legs**: each [`InventoryItem`] in the catalog is keyed
/// by (sku, warehouse, location). A transfer is one item with the
/// same sku in two different bins. We post **two** ledger rows so
/// the per-location history reads honestly — the source loses N, the
/// destination gains N, both reference the same transfer correlation
/// id.
///
/// **Invariants**:
///   - Source and destination must be different items.
///   - Quantity > 0.
///   - Source on-hand >= quantity (no negative balance).
///   - Both items must be `active`.
///   - Source and destination should typically share the same SKU.
///     We don't enforce that here (in case warehouse staff re-bin into
///     a different sku for repackaging), but a stricter caller can
///     pre-check.
Future<TransferStockResult> transferStock({
  required ItemsRepository itemsRepo,
  required StockMovementsRepository movementsRepo,
  required String sourceItemId,
  required String destinationItemId,
  required num quantity,
  String? reference,
  String? note,
  Clock clock = DateTime.now,
}) async {
  if (sourceItemId == destinationItemId) {
    throw const Failure.validation(
      fieldErrors: {
        'destinationItemId': ['same_as_source'],
      },
    );
  }
  if (quantity <= 0) {
    throw const Failure.validation(
      fieldErrors: {
        'quantity': ['must_be_positive'],
      },
    );
  }

  final src = await itemsRepo.findById(sourceItemId);
  if (src == null) {
    throw Failure.notFound(message: 'source item $sourceItemId');
  }
  final dst = await itemsRepo.findById(destinationItemId);
  if (dst == null) {
    throw Failure.notFound(message: 'destination item $destinationItemId');
  }

  if (src.status != InventoryItemStatus.active ||
      dst.status != InventoryItemStatus.active) {
    throw Failure.conflict(
      message: 'Both ends of a transfer must be active',
    );
  }
  if (src.onHandQty < quantity) {
    throw const Failure.validation(
      fieldErrors: {
        'quantity': ['exceeds_on_hand'],
      },
    );
  }

  final nextSrc = src.onHandQty - quantity;
  final nextDst = dst.onHandQty + quantity;

  final updatedSrc = await itemsRepo.setOnHand(src.id, nextSrc);
  final updatedDst = await itemsRepo.setOnHand(dst.id, nextDst);

  final ts = clock();
  final correlation = reference ?? 'TRF-${ts.microsecondsSinceEpoch}';
  final outbound = await movementsRepo.append(StockMovement(
    id: 'tmp',
    itemId: src.id,
    postedAt: ts,
    type: StockMovementType.transfer,
    quantity: -quantity,
    runningQty: nextSrc,
    reference: correlation,
    note: note,
  ));
  final inbound = await movementsRepo.append(StockMovement(
    id: 'tmp',
    itemId: dst.id,
    postedAt: ts,
    type: StockMovementType.transfer,
    quantity: quantity,
    runningQty: nextDst,
    reference: correlation,
    note: note,
  ));

  return TransferStockResult(
    sourceItem: updatedSrc,
    destinationItem: updatedDst,
    outboundMovement: outbound,
    inboundMovement: inbound,
  );
}

/// Result of applying a cycle count (Slice 5.2.4).
class ApplyCycleCountResult {
  const ApplyCycleCountResult({
    required this.adjustmentsPosted,
    required this.totalVariance,
  });

  /// One entry per *non-zero-variance* line — zero-variance lines
  /// don't produce ledger noise.
  final List<StockMovement> adjustmentsPosted;

  /// Sum of `|variance|` across all lines — used as a sanity number
  /// in the success snackbar ("posted 14 unit adjustments").
  final num totalVariance;
}

/// Applies a [CycleCount] by posting one `adjustment` ledger row per
/// non-zero-variance line + updating each item's on-hand (Slice 5.2.4).
///
/// **Invariants**:
///   - The count must not already be completed (rerunning would
///     double-count the variance).
///   - Every line must reference a known item.
///   - Counted quantities must be non-negative.
///
/// **Idempotency note**: this function mutates the items repo and
/// appends movements. The caller (UI / sync engine) is responsible
/// for not invoking it twice for the same `CycleCount.id` — the
/// completedAt timestamp on the persisted cycle count is the natural
/// guard once 5.2.4 has its own repo.
Future<ApplyCycleCountResult> applyCycleCount(
  CycleCount count, {
  required ItemsRepository itemsRepo,
  required StockMovementsRepository movementsRepo,
  Clock clock = DateTime.now,
}) async {
  if (count.isCompleted) {
    throw const Failure.conflict(message: 'Cycle count already applied');
  }
  if (count.lines.isEmpty) {
    throw const Failure.validation(
      fieldErrors: {
        'lines': ['empty'],
      },
    );
  }
  for (final line in count.lines) {
    if (line.countedQty < 0) {
      throw const Failure.validation(
        fieldErrors: {
          'countedQty': ['must_be_non_negative'],
        },
      );
    }
  }

  final ts = clock();
  final adjustments = <StockMovement>[];
  num totalVariance = 0;

  for (final line in count.lines) {
    final variance = line.variance;
    if (variance == 0) continue;

    final item = await itemsRepo.findById(line.itemId);
    if (item == null) {
      throw Failure.notFound(message: 'item ${line.itemId}');
    }
    // Honour `discontinued` items by writing the adjustment but
    // skipping `blocked` ones — blocked is an admin freeze.
    if (item.status == InventoryItemStatus.blocked) {
      throw Failure.conflict(
        message: 'Blocked items cannot be cycle-adjusted (${item.id})',
      );
    }

    final nextOnHand = item.onHandQty + variance;
    // A cycle count can drive on-hand to 0 but never below — the
    // counter physically saw zero on the shelf.
    if (nextOnHand < 0) {
      throw const Failure.validation(
        fieldErrors: {
          'countedQty': ['exceeds_capacity'],
        },
      );
    }
    await itemsRepo.setOnHand(item.id, nextOnHand);
    final movement = await movementsRepo.append(StockMovement(
      id: 'tmp',
      itemId: item.id,
      postedAt: ts,
      type: StockMovementType.adjustment,
      quantity: variance,
      runningQty: nextOnHand,
      reference: count.id,
      note: count.note,
    ));
    adjustments.add(movement);
    totalVariance = totalVariance + variance.abs();
  }

  return ApplyCycleCountResult(
    adjustmentsPosted: adjustments,
    totalVariance: totalVariance,
  );
}
