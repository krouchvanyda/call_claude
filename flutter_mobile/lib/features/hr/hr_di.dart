import 'package:get_it/get_it.dart';

import 'data/repositories/attendance_repository.dart';
import 'data/repositories/employees_repository.dart';
import 'data/repositories/leave_requests_repository.dart';
import 'data/repositories/payslips_repository.dart';
import 'presentation/bloc/employee_list_bloc.dart';

/// Manual DI registration for Module 7 (Human Resources).
///
/// **Why manual** (same rationale as Modules 4 + 5 + 6): keeps the
/// slice landable without re-running build_runner for every repo / bloc
/// tweak. Call once from `main.dart` after `configureDependencies()`.
void registerHrModule(GetIt getIt) {
  if (!getIt.isRegistered<EmployeesRepository>()) {
    getIt.registerLazySingleton<EmployeesRepository>(
      EmployeesRepository.new,
    );
  }
  if (!getIt.isRegistered<LeaveRequestsRepository>()) {
    getIt.registerLazySingleton<LeaveRequestsRepository>(
      LeaveRequestsRepository.new,
    );
  }
  if (!getIt.isRegistered<LeaveBalancesRepository>()) {
    getIt.registerLazySingleton<LeaveBalancesRepository>(
      LeaveBalancesRepository.new,
    );
  }
  if (!getIt.isRegistered<AttendanceRepository>()) {
    getIt.registerLazySingleton<AttendanceRepository>(
      AttendanceRepository.new,
    );
  }
  if (!getIt.isRegistered<PayslipsRepository>()) {
    getIt.registerLazySingleton<PayslipsRepository>(
      PayslipsRepository.new,
    );
  }
  if (!getIt.isRegistered<EmployeeListBloc>()) {
    getIt.registerFactory<EmployeeListBloc>(
      () => EmployeeListBloc(repository: getIt()),
    );
  }
}
