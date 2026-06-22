import 'package:get_it/get_it.dart';

import 'data/repositories/purchase_orders_repository.dart';
import 'data/repositories/purchase_requests_repository.dart';
import 'data/repositories/vendors_repository.dart';
import 'presentation/bloc/pr_list_bloc.dart';

/// Manual DI registration for Module 4 (Procurement).
///
/// **Why not @injectable**: this module deliberately avoids running
/// build_runner — keeps the slice landable without re-running codegen
/// on every entity tweak. Wires into the same global `getIt` so call
/// sites (`getIt<PurchaseRequestsRepository>()`, etc.) work the same.
///
/// Call once from `main.dart` after `configureDependencies()`.
void registerProcurementModule(GetIt getIt) {
  if (!getIt.isRegistered<PurchaseRequestsRepository>()) {
    getIt.registerLazySingleton<PurchaseRequestsRepository>(
      PurchaseRequestsRepository.new,
    );
  }
  if (!getIt.isRegistered<PurchaseOrdersRepository>()) {
    getIt.registerLazySingleton<PurchaseOrdersRepository>(
      PurchaseOrdersRepository.new,
    );
  }
  if (!getIt.isRegistered<VendorsRepository>()) {
    getIt.registerLazySingleton<VendorsRepository>(
      VendorsRepository.new,
    );
  }
  if (!getIt.isRegistered<PurchaseRequestListBloc>()) {
    getIt.registerFactory<PurchaseRequestListBloc>(
      () => PurchaseRequestListBloc(repository: getIt()),
    );
  }
}
