import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/di/app_env.dart';
import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/core/error/logging_crash_reporter.dart';
import 'package:erp_mobile/core/network/auth_tokens.dart';
import 'package:erp_mobile/core/network/session_signal.dart';
import 'package:erp_mobile/core/network/token_storage.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:erp_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:erp_mobile/features/auth/data/datasources/biometric_service.dart';
import 'package:erp_mobile/features/auth/data/datasources/biometric_settings_dao.dart';
import 'package:erp_mobile/features/auth/data/datasources/cached_user_dao.dart';
import 'package:erp_mobile/features/auth/data/datasources/oauth_flow_session.dart';
import 'package:erp_mobile/features/auth/data/datasources/oauth_token_data_source.dart';
import 'package:erp_mobile/features/auth/data/datasources/secure_token_storage.dart';
import 'package:erp_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:erp_mobile/features/auth/entities/pkce_challenge.dart';
import 'package:erp_mobile/features/auth/entities/user.dart';
import 'package:test/test.dart';

import '../../../../_support/in_memory_secret_store.dart';
import '../../../../_support/recording_analytics_service.dart';
import '../../../../_support/recording_logger.dart';

// ─────────────────────────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────────────────────────

class _RevokeCall {
  _RevokeCall(this.refreshToken);
  final String refreshToken;
}

/// Scriptable remote — tracks revoke calls and optionally throws.
class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({this.onRevoke});

  final Future<void> Function(String refreshToken)? onRevoke;
  final calls = <_RevokeCall>[];

  @override
  Future<void> revokeRefreshToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    calls.add(_RevokeCall(refreshToken));
    if (onRevoke != null) await onRevoke!(refreshToken);
  }
}

class _RecordingSessionSignal implements SessionSignal {
  _RecordingSessionSignal(this.log);
  final List<String> log;

  @override
  Future<void> invalidate() async {
    log.add('session.invalidate');
  }
}

class _ExchangeCall {
  _ExchangeCall({
    required this.code,
    required this.codeVerifier,
    required this.redirectUri,
    required this.clientId,
  });
  final String code;
  final String codeVerifier;
  final String redirectUri;
  final String clientId;
}

/// Scriptable token data source — tracks call args and lets the test
/// pin the response (or throw).
class _FakeTokenDataSource implements OAuthTokenDataSource {
  _FakeTokenDataSource({this.respond});
  final Future<AuthTokens> Function(_ExchangeCall call)? respond;
  final calls = <_ExchangeCall>[];

  @override
  Future<AuthTokens> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  }) {
    final c = _ExchangeCall(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
      clientId: clientId,
    );
    calls.add(c);
    return respond?.call(c) ??
        Future.value(const AuthTokens(
          accessToken: 'a',
          refreshToken: 'r',
        ));
  }
}

class _ScriptedBiometricService implements BiometricService {
  _ScriptedBiometricService({
    required this.available,
    required this.result,
  });

  bool available;
  BiometricUnlockResult result;
  int isAvailableCalls = 0;
  int authenticateCalls = 0;
  String? lastReason;

  @override
  Future<bool> isAvailable() async {
    isAvailableCalls++;
    return available;
  }

  @override
  Future<BiometricUnlockResult> authenticate({required String reason}) async {
    authenticateCalls++;
    lastReason = reason;
    return result;
  }
}

DioException _dioErr(int status, {String path = '/auth/logout'}) =>
    DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
      ),
    );

const _challenge = PkceChallenge(
  verifier: 'verifier-test-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  challenge: 'challenge-test',
);

const _env = AppEnv(
  apiBaseUrl: 'https://example.test',
  connectTimeoutMs: 1000,
  receiveTimeoutMs: 1000,
  enableNetworkLogging: false,
  oauthClientId: 'erp-mobile-dev',
  oauthRedirectUri: 'erpmobile://oauth/callback',
);

const _alice = User(
  id: 'u-1',
  email: 'alice@example.com',
  displayName: 'Alice',
);

// ─────────────────────────────────────────────────────────────────
// Fixture
// ─────────────────────────────────────────────────────────────────

class _Fixture {
  _Fixture({
    required this.repo,
    required this.storage,
    required this.remote,
    required this.cache,
    required this.db,
    required this.settings,
    required this.biometric,
    required this.session,
    required this.tokenDataSource,
    required this.secrets,
    required this.sessionSignalLog,
    required this.analytics,
    required this.logger,
  });

  final AuthRepository repo;
  final TokenStorage storage;
  final _FakeAuthRemoteDataSource remote;
  final CachedUserDao cache;
  final AppDatabase db;
  final BiometricSettingsDao settings;
  final _ScriptedBiometricService biometric;
  final OAuthFlowSession session;
  final _FakeTokenDataSource tokenDataSource;
  final InMemorySecretStore secrets;
  final List<String> sessionSignalLog;
  final RecordingAnalyticsService analytics;
  final RecordingLogger logger;
}

_Fixture _build({
  Future<void> Function(String refreshToken)? onRevoke,
  Future<AuthTokens> Function(_ExchangeCall call)? respondExchange,
  bool biometricAvailable = true,
  BiometricUnlockResult biometricResult = BiometricUnlockResult.succeeded,
}) {
  final db = AppDatabase(NativeDatabase.memory());
  final secrets = InMemorySecretStore();
  final storage = SecureTokenStorage(secrets);
  final remote = _FakeAuthRemoteDataSource(onRevoke: onRevoke);
  final logger = RecordingLogger();
  final session = OAuthFlowSession();
  final tokenDs = _FakeTokenDataSource(respond: respondExchange);
  final biometric = _ScriptedBiometricService(
    available: biometricAvailable,
    result: biometricResult,
  );
  final sessionSignalLog = <String>[];
  final sessionSignal = _RecordingSessionSignal(sessionSignalLog);
  final analytics = RecordingAnalyticsService();
  final repo = AuthRepository(
    tokenStorage: storage,
    remote: remote,
    cachedUserDao: db.cachedUserDao,
    biometricSettingsDao: db.biometricSettingsDao,
    biometricService: biometric,
    oauthFlowSession: session,
    oauthTokenDataSource: tokenDs,
    env: _env,
    sessionSignal: sessionSignal,
    analytics: analytics,
    logger: logger,
    crashReporter: LoggingCrashReporter(logger),
  );
  return _Fixture(
    repo: repo,
    storage: storage,
    remote: remote,
    cache: db.cachedUserDao,
    db: db,
    settings: db.biometricSettingsDao,
    biometric: biometric,
    session: session,
    tokenDataSource: tokenDs,
    secrets: secrets,
    sessionSignalLog: sessionSignalLog,
    analytics: analytics,
    logger: logger,
  );
}

Future<void> _seedSession(TokenStorage storage, CachedUserDao cache) async {
  await storage.write(const AuthTokens(
    accessToken: 'at',
    refreshToken: 'rt',
  ));
  await cache.cacheUser(const User(
    id: 'u-1',
    email: 'a@b.co',
    displayName: 'A',
    roles: {'admin'},
  ));
}

// ─────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────

void main() {
  group('AuthRepository.revokeAndWipe — happy path', () {
    test('revokes the refresh token, then clears storage + drift', () async {
      final fx = _build();
      addTearDown(fx.db.close);
      await _seedSession(fx.storage, fx.cache);

      await fx.repo.revokeAndWipe();

      // Server revoke fired with the stored refresh token.
      expect(fx.remote.calls, hasLength(1));
      expect(fx.remote.calls.single.refreshToken, 'rt');

      // Local cleanup complete.
      expect(await fx.storage.read(), isNull);
      expect(await fx.cache.getCurrentUser(), isNull);
      expect(await fx.cache.getPermissions('u-1'), isEmpty);
    });

    test('logs server-side revoke success', () async {
      final fx = _build();
      addTearDown(fx.db.close);
      await _seedSession(fx.storage, fx.cache);

      await fx.repo.revokeAndWipe();

      final infos = fx.logger.at(LogLevel.info).toList();
      expect(
        infos.any((r) => r.message.contains('revoke succeeded')),
        isTrue,
      );
      expect(
        infos.any((r) => r.message.contains('local sign-out completed')),
        isTrue,
      );
    });
  });

  group('AuthRepository.revokeAndWipe — no stored tokens', () {
    test('skips server revoke but still wipes local state', () async {
      final fx = _build();
      addTearDown(fx.db.close);
      // Drift cache present but secure-storage empty (split-brain or
      // boot-time defensive cleanup).
      await fx.cache.cacheUser(const User(
        id: 'u-1',
        email: 'a@b.co',
        displayName: 'A',
      ));

      await fx.repo.revokeAndWipe();

      expect(fx.remote.calls, isEmpty, reason: 'no token → no revoke call');
      expect(await fx.cache.getCurrentUser(), isNull);

      final infos = fx.logger.at(LogLevel.info).toList();
      expect(
        infos.any((r) => r.message.contains('no tokens to revoke')),
        isTrue,
      );
    });
  });

  group('AuthRepository.revokeAndWipe — server failure', () {
    test('DioException from revoke is logged at warning + cleanup proceeds',
        () async {
      final fx = _build(onRevoke: (_) async {
        throw _dioErr(503);
      });
      addTearDown(fx.db.close);
      await _seedSession(fx.storage, fx.cache);

      // Must NOT throw — local sign-out succeeds regardless.
      await fx.repo.revokeAndWipe();

      expect(fx.remote.calls, hasLength(1));
      expect(await fx.storage.read(), isNull);
      expect(await fx.cache.getCurrentUser(), isNull);

      final warnings = fx.logger.at(LogLevel.warning).toList();
      expect(warnings, hasLength(1));
      expect(warnings.single.message, contains('auth.revoke failed'));
    });

    test('non-Dio exception from revoke is also swallowed', () async {
      final fx = _build(onRevoke: (_) async {
        throw StateError('something else broke');
      });
      addTearDown(fx.db.close);
      await _seedSession(fx.storage, fx.cache);

      await fx.repo.revokeAndWipe(); // should not throw

      expect(await fx.storage.read(), isNull);
      expect(await fx.cache.getCurrentUser(), isNull);
    });
  });

  group('AuthRepository.signOut — orchestration', () {
    test('runs revokeAndWipe → session.invalidate → analytics.reset in order',
        () async {
      final fx = _build();
      addTearDown(fx.db.close);
      await _seedSession(fx.storage, fx.cache);

      await fx.repo.signOut();

      // Local cleanup happened first.
      expect(await fx.storage.read(), isNull);
      expect(await fx.cache.getCurrentUser(), isNull);
      // Session signal fired.
      expect(fx.sessionSignalLog, ['session.invalidate']);
      // Analytics reset fired exactly once.
      expect(fx.analytics.calls, hasLength(1));
      expect(fx.analytics.calls.single, isA<Reset>());
    });

    test('signOut on a fully empty session is idempotent', () async {
      // No tokens, no cached user — exercising the "boot-time
      // defensive cleanup" path through the orchestrator.
      final fx = _build();
      addTearDown(fx.db.close);

      await fx.repo.signOut();

      expect(fx.remote.calls, isEmpty);
      expect(fx.sessionSignalLog, ['session.invalidate']);
      expect(fx.analytics.calls, hasLength(1));
      expect(fx.analytics.calls.single, isA<Reset>());
    });
  });

  group('AuthRepository.exchangeAuthorizationCode — happy path', () {
    test('consumes verifier, exchanges code, persists tokens', () async {
      final fx = _build();
      addTearDown(fx.db.close);
      fx.session.begin(challenge: _challenge, state: 'csrf-1');

      final result = await fx.repo.exchangeAuthorizationCode(
        authorizationCode: 'authcode-xyz',
        state: 'csrf-1',
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => fail('expected ok')), unit);

      // Data source called with the right args.
      expect(fx.tokenDataSource.calls, hasLength(1));
      final call = fx.tokenDataSource.calls.single;
      expect(call.code, 'authcode-xyz');
      expect(call.codeVerifier, _challenge.verifier);
      expect(call.redirectUri, _env.oauthRedirectUri);
      expect(call.clientId, _env.oauthClientId);

      // Tokens landed in secure storage.
      final stored = await fx.storage.read();
      expect(stored, isNotNull);
      expect(stored!.accessToken, 'a');
      expect(stored.refreshToken, 'r');

      // Session was wiped.
      expect(fx.session.hasActiveFlow, isFalse);
    });
  });

  group('AuthRepository.exchangeAuthorizationCode — CSRF mismatch', () {
    test('returns UnauthorizedFailure and never calls the data source',
        () async {
      final fx = _build();
      addTearDown(fx.db.close);
      fx.session.begin(challenge: _challenge, state: 'real-nonce');

      final result = await fx.repo.exchangeAuthorizationCode(
        authorizationCode: 'c',
        state: 'forged-nonce',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected error'),
      );
      expect(fx.tokenDataSource.calls, isEmpty,
          reason: 'must not exchange when state mismatched');
      expect(await fx.storage.read(), isNull,
          reason: 'no tokens ever written');

      // Session is wiped even on mismatch (by OAuthFlowSession contract).
      expect(fx.session.hasActiveFlow, isFalse);
    });

    test('no in-flight flow at all returns UnauthorizedFailure', () async {
      final fx = _build();
      addTearDown(fx.db.close);
      // No session.begin() — straight to the callback.

      final result = await fx.repo.exchangeAuthorizationCode(
        authorizationCode: 'c',
        state: 'whatever',
      );

      result.fold(
        (failure) => expect(failure, isA<UnauthorizedFailure>()),
        (_) => fail('expected error'),
      );
      expect(fx.tokenDataSource.calls, isEmpty);
    });
  });

  group('AuthRepository.exchangeAuthorizationCode — server failures', () {
    test('DioException maps through failureFromDioException, no tokens written',
        () async {
      final fx = _build(
        respondExchange: (_) async => throw _dioErr(503, path: '/oauth/token'),
      );
      addTearDown(fx.db.close);
      fx.session.begin(challenge: _challenge, state: 's');

      final result = await fx.repo.exchangeAuthorizationCode(
        authorizationCode: 'c',
        state: 's',
      );

      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected error'),
      );
      expect(await fx.storage.read(), isNull);

      // Session was already wiped by consumeVerifier.
      expect(fx.session.hasActiveFlow, isFalse);
    });

    test('FormatException from token parsing → UnknownFailure', () async {
      final fx = _build(
        respondExchange: (_) async =>
            throw const FormatException('missing access_token'),
      );
      addTearDown(fx.db.close);
      fx.session.begin(challenge: _challenge, state: 's');

      final result = await fx.repo.exchangeAuthorizationCode(
        authorizationCode: 'c',
        state: 's',
      );

      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect((failure as UnknownFailure).message,
              'missing access_token');
        },
        (_) => fail('expected error'),
      );
      expect(await fx.storage.read(), isNull);
    });
  });

  group('AuthRepository.exchangeAuthorizationCode — storage rule (1.2.2)', () {
    test('verifier never reaches the secret store directly', () async {
      final fx = _build();
      addTearDown(fx.db.close);
      fx.session.begin(challenge: _challenge, state: 'csrf-1');
      await fx.repo.exchangeAuthorizationCode(
        authorizationCode: 'authcode',
        state: 'csrf-1',
      );

      // The only key written is the SecureTokenStorage blob — `auth.tokens.v1`.
      expect(fx.secrets.writes, ['auth.tokens.v1']);
      // The verifier text is not in the stored payload.
      final stored = fx.secrets.peek('auth.tokens.v1')!;
      expect(stored.contains(_challenge.verifier), isFalse,
          reason: 'verifier must never reach secure storage');
    });
  });

  group('AuthRepository.unlockWithBiometric — short-circuits', () {
    test('no cached user → unavailable, hardware never queried', () async {
      final fx = _build();
      addTearDown(fx.db.close);

      final result = await fx.repo.unlockWithBiometric(reason: 'Unlock');

      expect(result, BiometricUnlockResult.unavailable);
      expect(fx.biometric.isAvailableCalls, 0);
      expect(fx.biometric.authenticateCalls, 0);
    });

    test('user cached but biometric_on=false → unavailable, no prompt',
        () async {
      final fx = _build();
      addTearDown(fx.db.close);
      await fx.cache.cacheUser(_alice);
      // settings table empty for this user → defaults to false.

      final result = await fx.repo.unlockWithBiometric(reason: 'Unlock');

      expect(result, BiometricUnlockResult.unavailable);
      expect(fx.biometric.isAvailableCalls, 0,
          reason: 'must not query hardware before checking the pref');
      expect(fx.biometric.authenticateCalls, 0);
    });

    test('biometric_on=true but hardware unavailable → unavailable, no prompt',
        () async {
      final fx = _build(biometricAvailable: false);
      addTearDown(fx.db.close);
      await fx.cache.cacheUser(_alice);
      await fx.settings.setEnabledFor('u-1', enabled: true);

      final result = await fx.repo.unlockWithBiometric(reason: 'Unlock');

      expect(result, BiometricUnlockResult.unavailable);
      expect(fx.biometric.isAvailableCalls, 1);
      expect(fx.biometric.authenticateCalls, 0);
    });
  });

  group('AuthRepository.unlockWithBiometric — prompts the user', () {
    test('all preconditions met → forwards reason and returns success',
        () async {
      final fx = _build(biometricResult: BiometricUnlockResult.succeeded);
      addTearDown(fx.db.close);
      await fx.cache.cacheUser(_alice);
      await fx.settings.setEnabledFor('u-1', enabled: true);

      final result = await fx.repo.unlockWithBiometric(
        reason: 'Unlock to view orders',
      );

      expect(result, BiometricUnlockResult.succeeded);
      expect(fx.biometric.authenticateCalls, 1);
      expect(fx.biometric.lastReason, 'Unlock to view orders');
    });

    test('user-cancel result is propagated, not coerced to unavailable',
        () async {
      final fx = _build(biometricResult: BiometricUnlockResult.cancelled);
      addTearDown(fx.db.close);
      await fx.cache.cacheUser(_alice);
      await fx.settings.setEnabledFor('u-1', enabled: true);

      final result = await fx.repo.unlockWithBiometric(reason: 'r');

      expect(result, BiometricUnlockResult.cancelled);
    });

    test('platform-error result is propagated as unavailable', () async {
      final fx = _build(biometricResult: BiometricUnlockResult.unavailable);
      addTearDown(fx.db.close);
      await fx.cache.cacheUser(_alice);
      await fx.settings.setEnabledFor('u-1', enabled: true);

      final result = await fx.repo.unlockWithBiometric(reason: 'r');

      expect(result, BiometricUnlockResult.unavailable);
    });
  });

  group('AuthRepository.unlockWithBiometric — keychain-only contract', () {
    test('the repository never reads or writes any crypto material itself',
        () async {
      // The biometric settings table only holds the bool flag — no
      // crypto material lives in drift. This test exists to catch a
      // future refactor that would smuggle one in.
      final fx = _build();
      addTearDown(fx.db.close);
      await fx.cache.cacheUser(_alice);
      await fx.settings.setEnabledFor('u-1', enabled: true);

      await fx.repo.unlockWithBiometric(reason: 'r');

      // Settings table only stores the bool flag — `enabled` and
      // `enrolledAt`. Verify there's no crypto-looking column we
      // accidentally added.
      final row = await (fx.db.select(fx.db.biometricSettings)
            ..where((r) => r.userId.equals('u-1')))
          .getSingle();
      expect(row.toJson().keys.toSet(), {
        'userId',
        'enabled',
        'enrolledAt',
        'updatedAt',
      });
    });
  });
}
