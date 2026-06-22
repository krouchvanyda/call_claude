import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/app_env.dart';
import '../../../../core/error/crash_reporter.dart';
import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_from_dio.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/session_signal.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/push/device_registrar.dart';
import '../../../../core/utils/logger/app_logger.dart';
import '../../entities/user.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/biometric_service.dart';
import '../datasources/biometric_settings_dao.dart';
import '../datasources/cached_user_dao.dart';
import '../datasources/oauth_flow_session.dart';
import '../datasources/oauth_token_data_source.dart';
import '../models/auth_requests.dart';

/// Concrete auth feature repository.
///
/// **Sign-out ordering** is deliberate:
///   1. **Revoke first** — while tokens are still valid, ask the server to
///      invalidate the refresh chain so a stolen refresh token can't be
///      reused after the user has signed out from this device.
///   2. **Local cleanup second** — clear secure storage *and* drift (the
///      user profile + permissions cache).
///   3. **Server failures don't block local cleanup** — if the revoke
///      throws, log + crash-report at `warning`, then continue with the
///      wipe. A user trying to sign out while offline must still succeed
///      locally; the server's stale refresh chain ages out on its own.
class AuthRepository {
  AuthRepository({
    required TokenStorage tokenStorage,
    required AuthRemoteDataSource remote,
    required CachedUserDao cachedUserDao,
    required BiometricSettingsDao biometricSettingsDao,
    required BiometricService biometricService,
    required OAuthFlowSession oauthFlowSession,
    required OAuthTokenDataSource oauthTokenDataSource,
    required AppEnv env,
    required SessionSignal sessionSignal,
    required AnalyticsService analytics,
    required AppLogger logger,
    required CrashReporter crashReporter,
    required DeviceRegistrar deviceRegistrar,
  })  : _tokenStorage = tokenStorage,
        _remote = remote,
        _cache = cachedUserDao,
        _biometricSettings = biometricSettingsDao,
        _biometric = biometricService,
        _oauthFlowSession = oauthFlowSession,
        _oauthTokenDataSource = oauthTokenDataSource,
        _env = env,
        _sessionSignal = sessionSignal,
        _analytics = analytics,
        _logger = logger.child('auth.repository'),
        _crash = crashReporter,
        _deviceRegistrar = deviceRegistrar;

  final TokenStorage _tokenStorage;
  final AuthRemoteDataSource _remote;
  final CachedUserDao _cache;
  final BiometricSettingsDao _biometricSettings;
  final BiometricService _biometric;
  final OAuthFlowSession _oauthFlowSession;
  final OAuthTokenDataSource _oauthTokenDataSource;
  final AppEnv _env;
  final SessionSignal _sessionSignal;
  final AnalyticsService _analytics;
  final AppLogger _logger;
  final CrashReporter _crash;
  final DeviceRegistrar _deviceRegistrar;

  /// Email + password sign-in against the Spring `/auth/login` endpoint.
  ///
  /// Side effects on success:
  ///   1. [AuthTokens] (access + refresh + access expiry) are persisted to
  ///      [TokenStorage] — that's `flutter_secure_storage` in production,
  ///      never drift.
  ///   2. The returned [User] is cached in drift via [CachedUserDao.cacheUser]
  ///      so the splash probe / route guard can answer offline.
  ///   3. [AnalyticsService.identify] tags the session with the user id
  ///      so subsequent events carry their identity.
  ///
  /// On failure, no tokens or user data are persisted — the caller gets
  /// back a typed [Failure] mapped via `failureFromDioException` (the
  /// same translator the rest of the network layer uses).
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.login(
        LoginRequest(email: email, password: password),
      );
      final user = response.user.toDomain();
      await _tokenStorage.write(response.toAuthTokens());
      await _cache.cacheUser(user);
      await _analytics.identify(user.id, traits: <String, Object?>{
        'email': user.email,
      });
      // Ship the device's FCM token to the backend so it can target
      // this device with `call.invite` pushes. Fire-and-forget — a
      // missing device row only means we won't get call notifications
      // when minimized, it must NOT block sign-in.
      unawaited(_deviceRegistrar.register());
      _logger.info('login OK for ${user.id}');
      return ok(user);
    } on ApiEnvelopeException catch (e) {
      return err(Failure.server(message: e.message));
    } on DioException catch (e) {
      return err(failureFromDioException(e));
    } on FormatException catch (e) {
      return err(Failure.unknown(message: e.message));
    }
  }

  /// New-account flow against the Spring `/auth/register` endpoint.
  ///
  /// Same side-effects contract as [login] — the backend returns an
  /// already-issued token pair so the client can drop the user straight
  /// into the authenticated shell without a second round-trip.
  ///
  /// All four fields ([email], [password], [fullName], [phone]) are
  /// required by the backend record.
  Future<Result<User>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _remote.register(
        RegisterRequest(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        ),
      );
      final user = response.user.toDomain();
      await _tokenStorage.write(response.toAuthTokens());
      await _cache.cacheUser(user);
      await _analytics.identify(user.id, traits: <String, Object?>{
        'email': user.email,
      });
      // Same FCM device registration as login — register-account is
      // login's twin, the user is signed in immediately afterward.
      unawaited(_deviceRegistrar.register());
      _logger.info('register OK for ${user.id}');
      return ok(user);
    } on ApiEnvelopeException catch (e) {
      return err(Failure.server(message: e.message));
    } on DioException catch (e) {
      return err(failureFromDioException(e));
    } on FormatException catch (e) {
      return err(Failure.unknown(message: e.message));
    }
  }

  /// Server-revoke the refresh token (best-effort) and wipe every local
  /// trace of the session — secure-storage tokens **and** drift-cached
  /// profile + permissions.
  ///
  /// Returns successfully even if the server-side revoke fails: the
  /// local cleanup must not depend on network reachability or the user
  /// could end up unable to sign out.
  Future<void> revokeAndWipe() async {
    final tokens = await _tokenStorage.read();

    // Step 1 — best-effort server revoke. Skipped when we have no
    // refresh token (e.g. logout button hit twice / boot-time cleanup).
    // Both tokens are forwarded: the refresh token is the payload to
    // invalidate; the access token is required by Spring Security to
    // authorize the `/auth/logout` request.
    if (tokens != null) {
      try {
        await _remote.revokeRefreshToken(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        _logger.info('server-side refresh-token revoke succeeded');
      } catch (e, stack) {
        _crash.report(
          e,
          stack,
          severity: CrashSeverity.warning,
          description: 'auth.revoke failed; continuing local sign-out',
        );
      }
    } else {
      _logger.info('no tokens to revoke — local cleanup only');
    }

    // Step 1b — revoke this device server-side BEFORE wiping tokens.
    // The DELETE /me/devices/{id} call needs the access token to
    // authenticate; if we wiped first, the call would 401 and the
    // backend would keep trying to push call.invites to a phone the
    // user is no longer signed into. Best-effort: failures are
    // logged but don't block the local wipe (the registrar itself
    // already swallows + logs, so this just guarantees ordering).
    if (tokens != null) {
      await _deviceRegistrar.unregister();
    }

    // Step 2 — local cleanup. These two must both run even if one
    // throws, so the user isn't half-signed-out. Each call is itself
    // safe to retry on app restart, but a partial state (storage cleared,
    // drift not, or vice-versa) would confuse the splash probe.
    Object? localError;
    StackTrace? localStack;
    try {
      await _tokenStorage.clear();
    } catch (e, stack) {
      localError = e;
      localStack = stack;
    }
    try {
      await _cache.wipeAll();
    } catch (e, stack) {
      localError ??= e;
      localStack ??= stack;
    }

    if (localError != null) {
      _crash.report(
        localError,
        localStack,
        severity: CrashSeverity.error,
        description: 'auth.signOut local cleanup partially failed',
      );
      // Bubble up so the caller can decide whether to retry on next
      // boot; the user is still being signed out either way.
      Error.throwWithStackTrace(localError, localStack ?? StackTrace.current);
    }

    _logger.info('local sign-out completed');
  }

  /// Sign-out orchestrator — one of the rare "fan-out" operations that
  /// touches multiple cross-cutting collaborators.
  ///
  /// Composes:
  /// 1. [revokeAndWipe] — revoke + wipe (tokens, cached profile,
  ///    permissions).
  /// 2. [SessionSignal.invalidate] — notifies the router (via the bridge
  ///    registered in `register_module.dart`) to bounce to `/login`. Uses
  ///    the Flutter-free `SessionSignal` interface rather than the
  ///    Flutter-bearing `AuthSession` so the call site itself stays in
  ///    pure-Dart territory.
  /// 3. [AnalyticsService.reset] — clears the identified user so the next
  ///    session starts anonymous and previous traits aren't carried over.
  ///
  /// The revoke step **must** run first so the data-layer state is
  /// clean before the router re-renders, otherwise the splash probe
  /// (Slice 1.3.3-equivalent on the next boot) could briefly see a stale
  /// cached user.
  Future<void> signOut() async {
    await revokeAndWipe();
    await _sessionSignal.invalidate();
    await _analytics.reset();
  }

  /// "OAuth callback received → trade the code for tokens" (Slice 1.2.2).
  ///
  /// **Storage rule**: the verifier comes out of the in-memory
  /// [OAuthFlowSession] and is consumed (cleared) on every call regardless
  /// of outcome. The resulting `AuthTokens` are written to the secure
  /// [TokenStorage] — never to drift, `shared_preferences`, or anywhere
  /// else. CLAUDE.md Slice 1.2.2: *"verifier/challenge in memory,
  /// resulting tokens → flutter_secure_storage"*.
  ///
  /// Failure modes mapped to typed [Failure]s:
  /// - **CSRF mismatch / no flow in progress** → [UnauthorizedFailure].
  /// - **Transport / 4xx / 5xx** → propagated through `failureFromDioException`.
  /// - **Malformed token response** → [UnknownFailure] (the body parser
  ///   throws `FormatException`).
  Future<Result<Unit>> exchangeAuthorizationCode({
    required String authorizationCode,
    required String state,
  }) async {
    // Pop the verifier — wipes the session even on mismatch, so a
    // failed attempt can't be replayed with a stolen state nonce.
    final verifier = _oauthFlowSession.consumeVerifier(state: state);
    if (verifier == null) {
      return err(
        const Failure.unauthorized(
          message: 'OAuth state mismatch or no flow in progress',
        ),
      );
    }

    try {
      final tokens = await _oauthTokenDataSource.exchangeAuthorizationCode(
        code: authorizationCode,
        codeVerifier: verifier,
        redirectUri: _env.oauthRedirectUri,
        clientId: _env.oauthClientId,
      );
      // Persist into secure storage — the auth interceptor and
      // refresher will pick up the new tokens automatically on the
      // next outbound call.
      await _tokenStorage.write(tokens);
      return ok(unit);
    } on DioException catch (e) {
      return err(failureFromDioException(e));
    } on FormatException catch (e) {
      return err(Failure.unknown(message: e.message));
    }
  }

  /// "Try to unlock with the biometric the user previously enrolled"
  /// (Slice 1.2.3).
  ///
  /// Composes three checks before prompting the OS:
  /// 1. **A cached user exists** — biometric unlock is a per-user
  ///    preference; with no cached user there's nothing to gate.
  /// 2. **`biometric_on` is `true` for that user** — read straight from
  ///    drift via [BiometricSettingsDao]; the flag is the single source
  ///    of truth (per CLAUDE.md Slice 1.2.3 storage rule).
  /// 3. **The OS reports the hardware is currently usable** — enrolled
  ///    fingerprint/face exists and isn't lockout-blocked.
  ///
  /// Only when all three hold does the call actually invoke
  /// [BiometricService.authenticate]. Otherwise it returns
  /// [BiometricUnlockResult.unavailable] so the caller can fall through
  /// to the PIN / password flow.
  Future<BiometricUnlockResult> unlockWithBiometric({
    required String reason,
  }) async {
    final user = await _cache.getCurrentUser();
    if (user == null) return BiometricUnlockResult.unavailable;

    final enabled = await _biometricSettings.isEnabledFor(user.id);
    if (!enabled) return BiometricUnlockResult.unavailable;

    final hardwareOk = await _biometric.isAvailable();
    if (!hardwareOk) return BiometricUnlockResult.unavailable;

    return _biometric.authenticate(reason: reason);
  }
}
