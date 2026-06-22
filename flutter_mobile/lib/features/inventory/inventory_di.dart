import 'package:get_it/get_it.dart';

import '../../core/database/sync_queue_dao.dart';
import '../../core/push/push_notification_service.dart';
import 'data/datasources/items_dao.dart';
import 'data/low_stock_notifier.dart';
import 'data/repositories/items_repository.dart';
import 'data/repositories/stock_movements_repository.dart';
import 'presentation/bloc/items_list_bloc.dart';

/// Manual DI registration for Module 5 (Inventory).
///
/// **Why manual** (same rationale as `registerProcurementModule`):
/// avoids re-running build_runner for every repo / use-case tweak.
/// The drift `ItemsDao` itself is registered upstream in
/// `register_module.dart` (alongside the other DAO bindings); this
/// function consumes that registration.
///
/// Call once from `main.dart` after `configureDependencies()`. Also
/// starts the [`LowStockNotifier`] watcher so Slice 5.1.3 alerts
/// fire from boot.
void registerInventoryModule(GetIt getIt) {
  if (!getIt.isRegistered<ItemsRepository>()) {
    getIt.registerLazySingleton<ItemsRepository>(
      () => ItemsRepository(
        dao: getIt<ItemsDao>(),
        syncQueue: getIt<SyncQueueDao>(),
      ),
    );
  }
  if (!getIt.isRegistered<StockMovementsRepository>()) {
    getIt.registerLazySingleton<StockMovementsRepository>(
      () => StockMovementsRepository(
        dao: getIt<ItemsDao>(),
        syncQueue: getIt<SyncQueueDao>(),
      ),
    );
  }
  if (!getIt.isRegistered<ItemsListBloc>()) {
    getIt.registerFactory<ItemsListBloc>(
      () => ItemsListBloc(repository: getIt()),
    );
  }
  if (!getIt.isRegistered<LowStockNotifier>()) {
    getIt.registerLazySingleton<LowStockNotifier>(
      () => LowStockNotifier(
        items: getIt(),
        push: getIt<PushNotificationService>(),
      ),
    );
    // Kick the watcher into life so the first low-stock dip fires a
    // notification without waiting for the alerts page to open.
    getIt<LowStockNotifier>().start();
  }
}
