import 'package:get_it/get_it.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/di/app_env.dart';
import '../../core/error/crash_reporter.dart';
import '../../core/network/session_signal.dart';
import '../../core/network/token_storage.dart';
import '../../core/push/device_registrar.dart';
import '../../core/utils/logger/app_logger.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/biometric_service.dart';
import 'data/datasources/biometric_settings_dao.dart';
import 'data/datasources/cached_user_dao.dart';
import 'data/datasources/oauth_flow_session.dart';
import 'data/datasources/oauth_token_data_source.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/otp_repository.dart';
import 'data/repositories/permissions_repository.dart';
import 'presentation/bloc/otp_bloc.dart';

/// Manual DI registration for Module 1 (Authentication & Identity).
///
/// Same pattern as Modules 4–9: avoids re-running build_runner per
/// repo tweak. Call once from `main.dart` after `configureDependencies()`
/// has wired the auth datasources (DAOs, secure storage, biometric
/// service, OAuth plumbing) via `register_module.dart`.
void registerAuthModule(GetIt getIt) {
  // Slice 1.2.1 — OTP verifier (stub until the real MFA backend lands).
  if (!getIt.isRegistered<OtpRepository>()) {
    getIt.registerLazySingleton<OtpRepository>(OtpRepository.new);
  }
  // Factory — each `OtpEntryPage` mount gets a fresh bloc with
  // `code = ''`. Memory-only contract: nothing about the typed code
  // survives the bloc's `close()`.
  if (!getIt.isRegistered<OtpBloc>()) {
    getIt.registerFactory<OtpBloc>(
      () => OtpBloc(otpRepository: getIt<OtpRepository>()),
    );
  }
  // Slices 1.1.x / 1.2.2 / 1.2.3 / 1.1.4 — auth orchestration.
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        tokenStorage: getIt<TokenStorage>(),
        remote: getIt<AuthRemoteDataSource>(),
        cachedUserDao: getIt<CachedUserDao>(),
        biometricSettingsDao: getIt<BiometricSettingsDao>(),
        biometricService: getIt<BiometricService>(),
        oauthFlowSession: getIt<OAuthFlowSession>(),
        oauthTokenDataSource: getIt<OAuthTokenDataSource>(),
        env: getIt<AppEnv>(),
        sessionSignal: getIt<SessionSignal>(),
        analytics: getIt<AnalyticsService>(),
        logger: getIt<AppLogger>(),
        crashReporter: getIt<CrashReporter>(),
        deviceRegistrar: getIt<DeviceRegistrar>(),
      ),
    );
  }
  // Slice 1.1.2b / 1.3.1 — typed permission cache.
  if (!getIt.isRegistered<PermissionsRepository>()) {
    getIt.registerLazySingleton<PermissionsRepository>(
      () => PermissionsRepository(cachedUserDao: getIt<CachedUserDao>()),
    );
  }
}
