import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/token_storage.dart';
import '../employees/data/datasources/employees_remote_data_source.dart';
import 'data/datasources/roles_remote_data_source.dart';
import 'data/datasources/users_remote_data_source.dart';
import 'data/repositories/admin_repositories.dart';
import 'data/repositories/my_profile_repository.dart';
import 'data/repositories/preferences_repository.dart';
import 'data/repositories/security_repositories.dart';

/// Manual DI registration for Module 9 (Settings & Administration).
///
/// Same pattern as Modules 4–8: avoids re-running build_runner per
/// repo tweak. Call once from `main.dart` after `configureDependencies()`.
void registerSettingsModule(GetIt getIt) {
  // Phase 9.1 — preferences.
  if (!getIt.isRegistered<PreferencesRepository>()) {
    getIt.registerLazySingleton<PreferencesRepository>(
      PreferencesRepository.new,
    );
  }
  // Slice 9.1.4 — signed-in user's own profile, backed by Spring
  // `/api/v1/employees`. The data source MUST be registered before
  // the repository so the lazy resolve below finds it on first use.
  if (!getIt.isRegistered<EmployeesRemoteDataSource>()) {
    getIt.registerLazySingleton<EmployeesRemoteDataSource>(
      () => DioEmployeesRemoteDataSource(dio: getIt<Dio>()),
    );
  }
  if (!getIt.isRegistered<MyProfileRepository>()) {
    getIt.registerLazySingleton<MyProfileRepository>(
      () => MyProfileRepository(
        employees: getIt<EmployeesRemoteDataSource>(),
        // Token storage is already registered upstream (Module 1's
        // auth DI). Pulled here so the repo can stamp `Authorization`
        // headers onto auth-gated avatar URLs.
        tokens: getIt<TokenStorage>(),
      ),
    );
  }
  // Phase 9.2 — admin backend wiring.
  // Remote data sources (Spring `/api/v1/roles` + `/api/v1/users`).
  // Registered alongside the in-memory `RolesRepository` /
  // `ManagedUsersRepository` below — callers pick the source they want
  // (real backend vs demo seed) until the page-level swap lands.
  if (!getIt.isRegistered<RolesRemoteDataSource>()) {
    getIt.registerLazySingleton<RolesRemoteDataSource>(
      () => DioRolesRemoteDataSource(dio: getIt<Dio>()),
    );
  }
  if (!getIt.isRegistered<UsersRemoteDataSource>()) {
    getIt.registerLazySingleton<UsersRemoteDataSource>(
      () => DioUsersRemoteDataSource(dio: getIt<Dio>()),
    );
  }
  // Phase 9.2 — admin (in-memory demo repositories).
  if (!getIt.isRegistered<ManagedUsersRepository>()) {
    getIt.registerLazySingleton<ManagedUsersRepository>(
      ManagedUsersRepository.new,
    );
  }
  if (!getIt.isRegistered<RolesRepository>()) {
    getIt.registerLazySingleton<RolesRepository>(
      RolesRepository.new,
    );
  }
  if (!getIt.isRegistered<ApiEnvironmentsRepository>()) {
    getIt.registerLazySingleton<ApiEnvironmentsRepository>(
      ApiEnvironmentsRepository.new,
    );
  }
  // Phase 9.3 — security.
  if (!getIt.isRegistered<DeviceSessionsRepository>()) {
    getIt.registerLazySingleton<DeviceSessionsRepository>(
      DeviceSessionsRepository.new,
    );
  }
  if (!getIt.isRegistered<AuditLogRepository>()) {
    getIt.registerLazySingleton<AuditLogRepository>(
      AuditLogRepository.new,
    );
  }
  if (!getIt.isRegistered<AppLockSettingsRepository>()) {
    getIt.registerLazySingleton<AppLockSettingsRepository>(
      AppLockSettingsRepository.new,
    );
  }
  if (!getIt.isRegistered<InMemoryPinSecretStore>()) {
    getIt.registerLazySingleton<InMemoryPinSecretStore>(
      InMemoryPinSecretStore.new,
    );
  }
}
