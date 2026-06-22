import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../utils/logger/app_logger.dart';
import '../../features/auth/data/datasources/secret_store.dart';
import 'device_id_storage.dart';
import 'device_registrar.dart';
import 'devices_remote_data_source.dart';
import 'push_notification_service.dart';
import 'push_token_storage.dart';

/// Manual DI wiring for the device-registration stack.
///
/// The `@lazySingleton` annotations in `register_module.dart` are the
/// preferred path, but they require `build_runner` to regenerate
/// `injection.config.dart`. Until that runs, this hand-rolled module
/// fills the gap so `AuthRepository` can resolve [DeviceRegistrar] at
/// startup. Same `isRegistered` guards every other manual module
/// uses, so re-running codegen later won't cause a double-register.
///
/// Must be called from `main.dart` AFTER `configureDependencies(...)`
/// (so [SecretStore], [Dio], [AppLogger], and [PushNotificationService]
/// are present) and BEFORE `registerAuthModule(...)` (since
/// `AuthRepository` consumes [DeviceRegistrar]).
void registerPushModule(GetIt getIt) {
  if (!getIt.isRegistered<DeviceIdStorage>()) {
    getIt.registerLazySingleton<DeviceIdStorage>(
      () => SecretStoreDeviceIdStorage(secrets: getIt<SecretStore>()),
    );
  }
  if (!getIt.isRegistered<DevicesRemoteDataSource>()) {
    getIt.registerLazySingleton<DevicesRemoteDataSource>(
      () => DioDevicesRemoteDataSource(dio: getIt<Dio>()),
    );
  }
  if (!getIt.isRegistered<DeviceRegistrar>()) {
    getIt.registerLazySingleton<DeviceRegistrar>(
      () => DeviceRegistrar(
        remote: getIt<DevicesRemoteDataSource>(),
        push: getIt<PushNotificationService>(),
        tokenStorage: getIt<PushTokenStorage>(),
        deviceIdStorage: getIt<DeviceIdStorage>(),
        logger: getIt<AppLogger>().child('devices'),
      ),
    );
  }
}
