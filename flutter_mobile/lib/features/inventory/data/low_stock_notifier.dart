import 'dart:async';

import '../../../core/push/local_push_simulator.dart';
import '../../../core/push/push_notification_service.dart';
import '../entities/inventory_item.dart';
import 'repositories/items_repository.dart';

/// Watches the items feed and fires *one* local notification per item
/// that newly drops below its reorder point (Slice 5.1.3).
///
/// **Why not @injectable bloc?**: there's no UI bloc here — the watcher
/// is a fire-and-forget service that runs for the app's lifetime.
/// The alerts page reads the latest [LowStockReport] from
/// [latestReport]; the notification side-effect is a write into the
/// existing push provider — when that's [`LocalPushSimulator`] (dev
/// default), the inbox bloc surfaces the message immediately.
///
/// **Real push provider**: under FCM, [LowStockNotifier] does the
/// in-memory bookkeeping but skips the local-notification call —
/// remote pushes for low-stock would originate on the server side.
class LowStockNotifier {
  LowStockNotifier({
    required ItemsRepository items,
    required PushNotificationService push,
  })  : _items = items,
        _push = push;

  final ItemsRepository _items;
  final PushNotificationService _push;

  StreamSubscription<List<InventoryItem>>? _sub;
  final Set<String> _alerted = <String>{};

  LowStockReport _latest = const LowStockReport(
    allLowStock: [],
    newlyAlerted: [],
  );

  /// Latest cached report — the alerts page reads this on rebuild.
  LowStockReport get latestReport => _latest;

  /// Start listening. Idempotent: a second call is a no-op.
  void start() {
    if (_sub != null) return;
    _sub = _items.watchAll().listen(_onFeed);
  }

  void _onFeed(List<InventoryItem> feed) {
    final report = checkLowStock(feed, previouslyAlertedIds: _alerted);
    _latest = report;
    for (final item in report.newlyAlerted) {
      _alerted.add(item.id);
      // Local simulation in dev; under FCM this is a server-side
      // push so we no-op locally.
      final push = _push;
      if (push is LocalPushSimulator) {
        push.simulateNow(
          title: 'Low stock — ${item.sku}',
          body: '${item.name} at ${item.onHandQty} '
              '(reorder point ${item.reorderPoint})',
          category: 'inventory.low_stock',
          data: {'itemId': item.id},
        );
      }
    }
    // Drop items that climbed back above the threshold so the next
    // dip re-fires.
    _alerted.removeWhere(
      (id) => !report.allLowStock.any((i) => i.id == id),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
