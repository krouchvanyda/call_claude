// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/datasources/biometric_service.dart' as _i506;
import '../../features/auth/data/datasources/biometric_settings_dao.dart'
    as _i18;
import '../../features/auth/data/datasources/cached_user_dao.dart' as _i1072;
import '../../features/auth/data/datasources/oauth_flow_session.dart' as _i196;
import '../../features/auth/data/datasources/oauth_token_data_source.dart'
    as _i828;
import '../../features/auth/data/datasources/pkce_generator.dart' as _i397;
import '../../features/auth/data/datasources/secret_store.dart' as _i145;
import '../../features/auth/data/demo_sign_in.dart' as _i391;
import '../../features/auth/data/repositories/permissions_repository.dart'
    as _i605;
import '../../features/finance/data/datasources/accounts_dao.dart' as _i1029;
import '../../features/finance/data/datasources/invoices_dao.dart' as _i1019;
import '../../features/inventory/data/datasources/items_dao.dart' as _i341;
import '../../features/notifications/data/datasources/notifications_dao.dart'
    as _i617;
import '../../features/notifications/domain/repositories/notifications_repository.dart'
    as _i563;
import '../../features/notifications/presentation/bloc/notification_inbox_bloc.dart'
    as _i698;
import '../analytics/analytics_service.dart' as _i726;
import '../database/app_database.dart' as _i982;
import '../database/app_metadata_dao.dart' as _i453;
import '../database/cache_freshness_dao.dart' as _i298;
import '../database/sync_queue_dao.dart' as _i733;
import '../error/crash_reporter.dart' as _i267;
import '../i18n/locale_service.dart' as _i705;
import '../network/auth_interceptor.dart' as _i908;
import '../network/connectivity_checker.dart' as _i402;
import '../network/error_interceptor.dart' as _i1004;
import '../network/session_signal.dart' as _i940;
import '../network/token_refresher.dart' as _i1058;
import '../network/token_storage.dart' as _i964;
import '../push/push_message_router.dart' as _i170;
import '../push/push_notification_service.dart' as _i992;
import '../push/push_token_storage.dart' as _i599;
import '../realtime/realtime_service.dart' as _i854;
import '../router/app_router.dart' as _i81;
import '../router/auth_session.dart' as _i778;
import '../router/permissions_snapshot.dart' as _i407;
import '../sync/conflict_policy.dart' as _i83;
import '../sync/conflict_policy_registry.dart' as _i662;
import '../sync/sync_bloc.dart' as _i454;
import '../sync/sync_engine.dart' as _i846;
import '../sync/sync_op_executor.dart' as _i687;
import '../utils/logger/app_logger.dart' as _i712;
import 'app_env.dart' as _i89;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.lazySingleton<_i89.AppEnv>(() => appModule.appEnv);
    gh.lazySingleton<_i712.AppLogger>(() => appModule.appLogger);
    gh.lazySingleton<_i726.AnalyticsService>(() => appModule.analyticsService);
    gh.lazySingleton<_i705.LocaleService>(() => appModule.localeService);
    gh.lazySingleton<_i83.ConflictPolicy>(
      () => appModule.defaultConflictPolicy,
    );
    gh.lazySingleton<_i895.Connectivity>(() => appModule.connectivity);
    gh.lazySingleton<_i145.SecretStore>(() => appModule.secretStore);
    gh.lazySingleton<_i506.BiometricService>(() => appModule.biometricService);
    gh.lazySingleton<_i397.PkceGenerator>(() => appModule.pkceGenerator);
    gh.lazySingleton<_i196.OAuthFlowSession>(() => appModule.oauthFlowSession);
    gh.lazySingleton<_i1004.ErrorInterceptor>(() => appModule.errorInterceptor);
    gh.lazySingleton<_i982.AppDatabase>(() => appModule.appDatabase());
    gh.lazySingleton<_i453.AppMetadataDao>(
      () => appModule.appMetadataDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i298.CacheFreshnessDao>(
      () => appModule.cacheFreshnessDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i733.SyncQueueDao>(
      () => appModule.syncQueueDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i1072.CachedUserDao>(
      () => appModule.cachedUserDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i18.BiometricSettingsDao>(
      () => appModule.biometricSettingsDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i617.NotificationsDao>(
      () => appModule.notificationsDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i1019.InvoicesDao>(
      () => appModule.invoicesDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i341.ItemsDao>(
      () => appModule.itemsDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i1029.AccountsDao>(
      () => appModule.accountsDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i778.AuthSession>(() => _i778.StubAuthSession());
    gh.lazySingleton<_i391.DemoSignInService>(
      () => _i391.DemoSignInService(gh<_i1072.CachedUserDao>()),
    );
    gh.lazySingleton<_i992.PushNotificationService>(
      () => appModule.localPushSimulator(),
    );
    gh.lazySingleton<_i267.CrashReporter>(
      () => appModule.crashReporter(gh<_i712.AppLogger>()),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => appModule.authRemoteDataSource(gh<_i89.AppEnv>()),
    );
    gh.lazySingleton<_i828.OAuthTokenDataSource>(
      () => appModule.oauthTokenDataSource(gh<_i89.AppEnv>()),
    );
    gh.lazySingleton<_i402.ConnectivityChecker>(
      () => appModule.connectivityChecker(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i662.ConflictPolicyRegistry>(
      () => appModule.conflictPolicyRegistry(gh<_i83.ConflictPolicy>()),
    );
    gh.lazySingleton<_i854.RealtimeService>(
      () => appModule.realtimeService(gh<_i89.AppEnv>(), gh<_i712.AppLogger>()),
    );
    gh.lazySingleton<_i407.PermissionsSnapshot>(
      () => _i407.PermissionsSnapshot(
        cachedUserDao: gh<_i1072.CachedUserDao>(),
        permissionsRepository: gh<_i605.PermissionsRepository>(),
      ),
    );
    gh.lazySingleton<_i964.TokenStorage>(
      () => appModule.tokenStorage(gh<_i145.SecretStore>()),
    );
    gh.lazySingleton<_i599.PushTokenStorage>(
      () => appModule.pushTokenStorage(gh<_i145.SecretStore>()),
    );
    gh.lazySingleton<_i563.NotificationsRepository>(
      () => appModule.notificationsRepository(gh<_i617.NotificationsDao>()),
    );
    gh.lazySingleton<_i1058.TokenRefresher>(
      () => appModule.tokenRefresher(
        gh<_i89.AppEnv>(),
        gh<_i1072.CachedUserDao>(),
        gh<_i712.AppLogger>(),
        gh<_i267.CrashReporter>(),
      ),
    );
    gh.factory<_i698.NotificationInboxBloc>(
      () =>
          appModule.notificationInboxBloc(gh<_i563.NotificationsRepository>()),
    );
    gh.lazySingleton<_i940.SessionSignal>(
      () => appModule.sessionSignal(gh<_i778.AuthSession>()),
    );
    gh.lazySingleton<_i81.AppRouter>(
      () => _i81.AppRouter(
        gh<_i778.AuthSession>(),
        gh<_i407.PermissionsSnapshot>(),
      ),
    );
    gh.lazySingleton<_i908.AuthInterceptor>(
      () => appModule.authInterceptor(
        gh<_i964.TokenStorage>(),
        gh<_i1058.TokenRefresher>(),
        gh<_i940.SessionSignal>(),
      ),
    );
    gh.lazySingleton<_i170.PushMessageRouter>(
      () => appModule.pushMessageRouter(
        gh<_i992.PushNotificationService>(),
        gh<_i563.NotificationsRepository>(),
        gh<_i599.PushTokenStorage>(),
        gh<_i712.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => appModule.dio(
        gh<_i89.AppEnv>(),
        gh<_i908.AuthInterceptor>(),
        gh<_i1004.ErrorInterceptor>(),
      ),
    );
    gh.lazySingleton<_i687.SyncOpExecutor>(
      () => appModule.syncOpExecutor(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i846.SyncEngine>(
      () => appModule.syncEngine(
        gh<_i733.SyncQueueDao>(),
        gh<_i687.SyncOpExecutor>(),
        gh<_i402.ConnectivityChecker>(),
      ),
    );
    gh.lazySingleton<_i454.SyncBloc>(
      () =>
          appModule.syncBloc(gh<_i846.SyncEngine>(), gh<_i733.SyncQueueDao>()),
    );
    return this;
  }
}

class _$AppModule extends _i291.AppModule {}
