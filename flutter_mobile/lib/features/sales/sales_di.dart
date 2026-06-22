import 'package:get_it/get_it.dart';

import 'data/repositories/activities_repository.dart';
import 'data/repositories/contacts_repository.dart';
import 'data/repositories/customers_repository.dart';
import 'data/repositories/quotations_repository.dart';
import 'data/repositories/sales_orders_repository.dart';
import 'data/repositories/sales_reps_repository.dart';
import 'presentation/bloc/customer_list_bloc.dart';

/// Manual DI registration for Module 6 (Sales & CRM).
///
/// **Why manual** (same rationale as Modules 4 + 5): keeps the slice
/// landable without re-running build_runner for every repo / bloc
/// tweak. Call once from `main.dart` after `configureDependencies()`.
void registerSalesModule(GetIt getIt) {
  if (!getIt.isRegistered<CustomersRepository>()) {
    getIt.registerLazySingleton<CustomersRepository>(
      CustomersRepository.new,
    );
  }
  if (!getIt.isRegistered<ContactsRepository>()) {
    getIt.registerLazySingleton<ContactsRepository>(
      ContactsRepository.new,
    );
  }
  if (!getIt.isRegistered<ActivitiesRepository>()) {
    getIt.registerLazySingleton<ActivitiesRepository>(
      ActivitiesRepository.new,
    );
  }
  if (!getIt.isRegistered<QuotationsRepository>()) {
    getIt.registerLazySingleton<QuotationsRepository>(
      QuotationsRepository.new,
    );
  }
  if (!getIt.isRegistered<SalesOrdersRepository>()) {
    getIt.registerLazySingleton<SalesOrdersRepository>(
      SalesOrdersRepository.new,
    );
  }
  if (!getIt.isRegistered<SalesRepsRepository>()) {
    getIt.registerLazySingleton<SalesRepsRepository>(
      SalesRepsRepository.new,
    );
  }
  if (!getIt.isRegistered<CustomerListBloc>()) {
    getIt.registerFactory<CustomerListBloc>(
      () => CustomerListBloc(repository: getIt()),
    );
  }
}
