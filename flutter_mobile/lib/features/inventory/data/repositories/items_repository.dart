import 'dart:convert';

import '../../../../core/database/sync_queue_dao.dart';
import '../../../../core/sync/sync_op_type.dart';
import '../../entities/inventory_item.dart';
import '../datasources/items_dao.dart';
import '../inventory_seed.dart';

/// Drift-backed items repository (Phase 5.1 / Slice 5.3.1 — spec:
/// "Download item master to local drift DB"). Flat MVVM: this is the
/// single concrete repo — no abstract interface, no separate use-case
/// classes. The pure helpers ([applyItemQuery], [checkLowStock]) are
/// colocated at the bottom of the file.
///
/// **Lazy seed**: on first read, if the table is missing any
/// [`InventorySeed.items`] row, the bootstrap inserts only the missing
/// ones (preserves user-touched rows on app upgrade). Mirrors the
/// [`DriftAccountsRepository`] / [`DriftInvoicesRepository`] pattern.
///
/// **SyncQueue integration** (Slice 5.3.2): every [setOnHand] write
/// also enqueues a `PATCH /inventory/items/{id}/on-hand` payload via
/// [`SyncQueueDao`]. The SyncEngine retry path drains the queue on
/// reconnect (Slice 5.3.3).
class ItemsRepository {
  ItemsRepository({
    required ItemsDao dao,
    required SyncQueueDao syncQueue,
  })  : _dao = dao,
        _syncQueue = syncQueue;

  final ItemsDao _dao;
  final SyncQueueDao _syncQueue;
  Future<void>? _bootstrap;

  Future<void> _ensureBootstrapped() {
    return _bootstrap ??= _seedMissing();
  }

  // Idempotent seed: inserts any [`InventorySeed.items`] whose IDs
  // aren't already in the DB. Lets the seed file pick up new rows
  // (e.g. sibling bins for Slice 5.2.3 Transfer) without overwriting
  // mutable fields on existing items the user has touched.
  Future<void> _seedMissing() async {
    final existing = await _dao.getAllItems();
    final existingIds = existing.map((i) => i.id).toSet();
    final missing = InventorySeed.items
        .where((i) => !existingIds.contains(i.id))
        .toList(growable: false);
    if (missing.isEmpty) return;
    await _dao.upsertItems(missing);
  }

  Future<List<InventoryItem>> getAll() async {
    await _ensureBootstrapped();
    return _dao.getAllItems();
  }

  Stream<List<InventoryItem>> watchAll() async* {
    await _ensureBootstrapped();
    yield* _dao.watchAllItems();
  }

  Future<InventoryItem?> findById(String id) async {
    await _ensureBootstrapped();
    return _dao.findItemById(id);
  }

  /// Lookup by exact barcode payload (Slice 5.2.1 scanner flow).
  Future<InventoryItem?> findByBarcode(String barcode) async {
    await _ensureBootstrapped();
    return _dao.findItemByBarcode(barcode);
  }

  /// Distinct warehouse codes — drives the toolbar filter chips.
  Future<List<String>> warehouseCodes() async {
    await _ensureBootstrapped();
    return _dao.distinctWarehouses();
  }

  /// Persists a new on-hand value for [itemId] (Slice 5.2.x mutations
  /// flow through here). Throws [StateError] when the id is unknown.
  Future<InventoryItem> setOnHand(String itemId, num newQty) async {
    await _ensureBootstrapped();
    final updated = await _dao.setOnHand(itemId, newQty);
    await _enqueueSyncOp(
      itemId: itemId,
      endpointPath: '/inventory/items/$itemId/on-hand',
      payload: {'on_hand_qty': newQty},
    );
    return updated;
  }

  Future<void> _enqueueSyncOp({
    required String itemId,
    required String endpointPath,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _syncQueue.enqueue(
        entityType: 'inventory.item',
        entityId: itemId,
        operation: SyncOpType.update,
        payloadJson: jsonEncode(payload),
        endpointMethod: 'PATCH',
        endpointPath: endpointPath,
      );
    } catch (_) {
      // Best-effort enqueue — see the DriftInvoicesRepository note.
    }
  }
}

/// Pure filter + sort over an inventory catalog (Slice 5.1.1). Mirrors
/// the shape of `applyInvoiceQuery` so the bloc stays thin and the
/// business rules are exhaustively testable.
List<InventoryItem> applyItemQuery(
  List<InventoryItem> all, {
  Set<String> warehouseFilter = const {},
  bool onlyLowStock = false,
  String searchQuery = '',
  InventoryItemSort sort = InventoryItemSort.nameAsc,
}) {
  Iterable<InventoryItem> result = all;

  if (warehouseFilter.isNotEmpty) {
    result = result.where((i) => warehouseFilter.contains(i.warehouseCode));
  }
  if (onlyLowStock) {
    result = result.where((i) => i.isLowStock);
  }

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((i) =>
        i.sku.toLowerCase().contains(q) ||
        i.name.toLowerCase().contains(q) ||
        i.locationCode.toLowerCase().contains(q) ||
        (i.barcode?.toLowerCase().contains(q) ?? false));
  }

  final list = result.toList();
  switch (sort) {
    case InventoryItemSort.nameAsc:
      list.sort((a, b) => a.name.compareTo(b.name));
    case InventoryItemSort.skuAsc:
      list.sort((a, b) => a.sku.compareTo(b.sku));
    case InventoryItemSort.onHandAsc:
      list.sort((a, b) => a.onHandQty.compareTo(b.onHandQty));
    case InventoryItemSort.onHandDesc:
      list.sort((a, b) => b.onHandQty.compareTo(a.onHandQty));
  }
  return list;
}

/// Result of a low-stock sweep (Slice 5.1.3).
class LowStockReport {
  const LowStockReport({
    required this.allLowStock,
    required this.newlyAlerted,
  });

  /// Every active item currently at or below its reorder point.
  final List<InventoryItem> allLowStock;

  /// Subset of [allLowStock] that wasn't on the previous alert pass —
  /// the caller fires *one* notification per new event so we don't
  /// spam the user with the same item every minute.
  final List<InventoryItem> newlyAlerted;
}

/// Pure low-stock sweep. The `previouslyAlertedIds` set lets the caller
/// debounce notifications across runs — only items that *just* crossed
/// the reorder threshold land in [LowStockReport.newlyAlerted].
///
/// **Discontinued / blocked** items are skipped — they shouldn't push
/// alerts even when their on-hand is zero.
LowStockReport checkLowStock(
  Iterable<InventoryItem> items, {
  Set<String> previouslyAlertedIds = const {},
}) {
  final all = <InventoryItem>[];
  final fresh = <InventoryItem>[];
  for (final item in items) {
    if (item.status != InventoryItemStatus.active) continue;
    if (!item.isLowStock) continue;
    all.add(item);
    if (!previouslyAlertedIds.contains(item.id)) {
      fresh.add(item);
    }
  }
  return LowStockReport(allLowStock: all, newlyAlerted: fresh);
}
