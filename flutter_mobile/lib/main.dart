import 'dart:async';

import 'package:erp_mobile/shared/firebase_option/firebase_options.dart';
import 'package:erp_mobile/shared/firebase_services/firebase_notification_provider.dart';
import 'package:erp_mobile/shared/firebase_services/local_notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/error/crash_hooks.dart';
import 'core/error/logging_crash_reporter.dart';
import 'core/network/token_storage.dart';
import 'core/push/device_registrar.dart';
import 'core/push/push_di.dart';
import 'core/push/push_token_storage.dart';
import 'core/router/auth_session.dart';
import 'features/chat/data/callkit_event_handler.dart';
import 'features/chat/data/chat_settings.dart';
import 'features/chat/data/stream_call_engine.dart';
import 'features/chat/data/users_cache.dart';
import 'features/settings/data/datasources/users_remote_data_source.dart';
import 'package:get_it/get_it.dart';
import 'core/sync/sync_engine.dart';
import 'core/utils/logger/console_logger.dart';
import 'features/auth/auth_di.dart';
import 'features/chat/chat_di.dart';
import 'features/finance/finance_di.dart';
import 'features/hr/hr_di.dart';
import 'features/inventory/inventory_di.dart';
import 'features/procurement/procurement_di.dart';
import 'features/projects/projects_di.dart';
import 'features/sales/sales_di.dart';
import 'features/settings/settings_di.dart';
import 'package:firebase_core/firebase_core.dart';

Future <void> main() async {
  // Build the bootstrap reporter outside DI so uncaught errors during
  // `configureDependencies()` are still captured.
  final reporter = LoggingCrashReporter(ConsoleLogger());

  runWithCrashHooks(
    reporter: reporter,
    body: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // FIRST — establish the stream_webrtc_flutter `FlutterWebRTC.Event`
      // subscription (sets the native event sink) before ANY other init.
      // On a VoIP cold-start the killed-app process can be suspended during
      // the awaited Firebase/DI bootstrap below, before the constructor-time
      // prime's async native onListen registers — and then CallKit's audio
      // activation on the first Accept hits the plugin's nil event sink →
      // EXC_BAD_ACCESS at __postEvent_block_invoke (confirmed in the device
      // crash report). Doing it here, before the awaits, gives the native
      // onListen the whole launch window to register. iOS-only, idempotent.
      StreamCallEngine.primeWebRtcAudioEventSinkEarly();

      // ── Firebase + push stack ──────────────────────────────────
      // Order matters here:
      //   1. Firebase.initializeApp before ANY firebase_* SDK call.
      //   2. onBackgroundMessage registered BEFORE runApp so the
      //      background isolate can find the handler when a push
      //      arrives while the app is terminated.
      //   3. Local-notification plugin initialised so the Android
      //      notification channel exists before any push tries to
      //      use it (Android 8+ drops notifications targeting a
      //      non-registered channel).
      //   4. Permission prompt awaited — old code was fire-and-forget,
      //      which let downstream getToken() race the iOS dialog.
      //   5. Token persisted to PushTokenStorage (flutter_secure_storage)
      //      and a refresh listener wired so rotated tokens flow into
      //      the same secure slot. Backend sync of the token still
      //      needs an endpoint (TODO below).
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions().currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await LocalNotificationProvider().initialize();
      await FirebaseNotificationProvider.instance
          .requestNotificationPermissions();
      // Note: foreground / opened / initial-message listeners are
      // attached from `ErpMobileApp.initState` (lib/app.dart) so they
      // can carry the three labelled debug callbacks. Don't duplicate
      // the attach here — the provider's `initOnMessage*` methods are
      // idempotent (cancel prior subscription on re-call) but double-
      // attaching obscures who owns the callback.

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
      configureDependencies(environment: Environment.prod);
      // Hand-rolled DI for the device-registration stack. Must run
      // BEFORE registerAuthModule because AuthRepository consumes
      // DeviceRegistrar in its constructor (see push_di.dart for the
      // codegen-skip rationale).
      registerPushModule(getIt);
      registerAuthModule(getIt);
      registerFinanceModule(getIt);
      registerProcurementModule(getIt);
      registerInventoryModule(getIt);
      registerSalesModule(getIt);
      registerHrModule(getIt);
      registerProjectsModule(getIt);
      registerSettingsModule(getIt);
      registerChatModule(getIt);

      // ── Persist the FCM token to secure storage ───────────────
      // PushTokenStorage is registered by `register_module.dart` as
      // SecretStorePushTokenStorage (flutter_secure_storage). The
      // initial fetch runs after DI is up so the storage handle is
      // available; subsequent rotations flow through the listener
      // below so a refreshed token is persisted without restart.
      //
      // TODO(backend): once a `POST /devices` (or equivalent) endpoint
      // exists, also push the token to the server so the backend can
      // target this device. `deleteFirebaseToken()` should be called
      // from the logout flow to deactivate it.
      unawaited(_persistAndWatchPushToken(
        getIt<PushTokenStorage>(),
        getIt<DeviceRegistrar>(),
        getIt<TokenStorage>(),
      ));

      // Boot the chat wire stack — loads persisted identity / relay
      // URL and opens the WebSocket if one is configured. Errors
      // here must never block app launch (relay may be unreachable).
      unawaited(bootChatTransport(getIt));

      // Stream Video client must connect EAGERLY (not lazily on first
      // call) so its PushNotificationManager.registerDevice runs and
      // associates B's FCM token with B's Stream identity. Without
      // this, Stream's backend has no device id for B → ring=true
      // pushes from A's side silently fail → B's phone never wakes.
      // We listen for auth transitions so the warm-up fires both on
      // fresh login and on auto-login (splash → markAuthenticated).
      _wireStreamWarmUpToAuth(getIt<AuthSession>(), getIt<StreamCallEngine>());

      // Subscribe to flutter_callkit_incoming events (Accept / Reject
      // on the native ringer) so they actually drive the call
      // ceremony. Without this, tapping Accept on the system ring
      // does nothing — the ringer dismisses and the user is stuck on
      // the home screen with no audio. Attached here (pre-runApp) so
      // it catches accept events from a cold-start triggered by the
      // tap itself.
      CallkitEventHandler.instance.attach();
      // Start listening to connectivity transitions so the queue drains
      // automatically when the device comes back online.
      getIt<SyncEngine>().start();
      runApp(const ErpMobileApp());
    },
  );
}

/// One-shot token fetch + lifelong refresh listener. Pulled into a
/// helper so `main()` stays readable. Failures are swallowed in
/// release (kDebugMode logs them) because a push-token error must
/// never block app launch.
Future<void> _persistAndWatchPushToken(
  PushTokenStorage storage,
  DeviceRegistrar registrar,
  TokenStorage authTokenStorage,
) async {
  if (kDebugMode) debugPrint('🔥 FCM: _persistAndWatchPushToken() entered');
  try {
    final token = await FirebaseNotificationProvider.instance.getFirebaseToken();
    if (token != null && token.isNotEmpty) {
      await storage.saveToken(token);
      if (kDebugMode) {
        debugPrint('🔥 FCM: token persisted to secure storage');
      }
      // Cold-start re-register — only meaningful when there's a valid
      // auth token to send with. On a fresh install or after sign-out,
      // there's no session yet → the AuthInterceptor would attach
      // nothing → backend returns 401. The auth login/register paths
      // already call registrar.register() themselves, so skipping here
      // doesn't drop coverage; it just means we wait for the user to
      // sign in instead of POSTing /me/devices anonymously.
      final session = await authTokenStorage.read();
      if (session != null) {
        unawaited(registrar.register(overrideToken: token));
      } else if (kDebugMode) {
        debugPrint('🔥 FCM: no auth session yet — deferring '
            'DeviceRegistrar.register until login fires it');
      }
    } else {
      if (kDebugMode) {
        debugPrint('🔥 FCM: token was null/empty — NOT persisted. Backend cannot push to this device.');
      }
    }
    // FCM rotates tokens occasionally — every rotation must flow into
    // BOTH the local secure cache AND the server-side `devices` row,
    // otherwise the backend keeps pushing to a dead token. Same auth
    // gate as the cold-start path: skip the registrar.register when
    // there's no session, the next login will re-register with the
    // current (rotated) token from the FCM SDK.
    FirebaseNotificationProvider.instance.onTokenRefresh.listen(
      (newToken) async {
        await storage.saveToken(newToken);
        final session = await authTokenStorage.read();
        if (session != null) {
          await registrar.register(overrideToken: newToken);
        }
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('🔥 FCM: token refresh error → $e');
      },
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('🔥 FCM: initial token fetch failed → $e');
      debugPrintStack(stackTrace: st);
    }
  }
}

/// Wires [StreamCallEngine.warmUp] to fire whenever the auth session
/// transitions to `isAuthenticated == true`.
///
/// Covers two cases with one listener:
///   1. **Cold-start auto-login** — splash reads tokens from secure
///      storage and calls `session.markAuthenticated()`. AuthSession
///      starts at `false` in-process, so this is a true transition →
///      our listener catches it.
///   2. **Fresh login** — login page calls `session.markAuthenticated()`
///      after `AuthRepository.login()` succeeds. Same transition.
///
/// Why eager and not lazy: `_ensureClient()` is currently triggered
/// from `StreamCallEngine.join()` (when this user PLACES a call). For
/// a callee who has only logged in, the client never gets built, so
/// `StreamVideoPushNotificationManager.registerDevice()` never runs,
/// and Stream's backend has no FCM target for this user — `ring=true`
/// from the caller side silently drops.
/// Re-runs `bootChatTransport` on a sign-in transition so STOMP gets a
/// real `userId` after the user authenticates. Without this, the
/// presence channel never broadcasts this user's `presence.update`,
/// so every peer sees them as Offline.
///
/// Why this is necessary: `bootChatTransport` runs once at app start
/// (in `main()` below) — well before any login. Its `users.me()` call
/// fails with 401 and is swallowed; `ChatSettings.setIdentity` is
/// never reached, so STOMP connects (if at all) with `userId = ''`.
/// Re-running on sign-in retries `me()` with the now-valid token,
/// fires `setIdentity`, and the existing `settings.watch()` listener
/// reconfigures STOMP with the real identity → presence works.
///
/// `bootChatTransport` IS NOT fully idempotent (the trailing
/// `settings.watch().listen(...)` would double-attach), so we don't
/// re-run the whole thing — we just fetch `users.me()` and call
/// `setIdentity` directly. The existing watch listener catches it.
Future<void> _rehydrateChatIdentityOnAuth(GetIt getIt) async {
  // ignore: avoid_print
  print('🎬 CHAT: rehydrating identity after sign-in');
  try {
    final users = getIt<UsersRemoteDataSource>();
    // Hard timeout — earlier symptom was rehydrate hanging silently
    // (no error log, no success log, just dead). Hung `users.me()`
    // blocked the entire downstream chain. 8s is generous for a
    // healthy backend and not painful when offline.
    final me = await users.me().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException(
          'users.me() did not return within 8s'),
    );
    final displayName = me.fullName.trim().isEmpty ? me.email : me.fullName;
    await getIt<ChatSettings>().setIdentity(
      userId: me.id,
      userName: displayName,
    );
    UsersCache.instance.put(userId: me.id, name: displayName);
    // ignore: avoid_print
    print('🎬 CHAT: setIdentity(userId=${me.id}, name=$displayName) OK '
        '— STOMP will reconnect with this identity, presence will flow');
  } catch (e) {
    // ignore: avoid_print
    print('🎬 CHAT: rehydrate failed → $e (presence may stay Offline)');
  }
}

void _wireStreamWarmUpToAuth(AuthSession session, StreamCallEngine engine) {
  // Unconditionally print (no kDebugMode guard) so the diagnostic
  // also fires in release builds — needed while we triangulate why
  // the ring isn't reaching B. Re-gate once the flow is confirmed.
  // ignore: avoid_print
  print('🎬 STREAM: _wireStreamWarmUpToAuth() called — '
      'session.isAuthenticated=${session.isAuthenticated}');
  if (session.isAuthenticated) {
    // ignore: avoid_print
    print('🎬 STREAM: already authenticated → warmUp() now');
    unawaited(engine.warmUp());
  }
  bool wasAuthed = session.isAuthenticated;
  session.addListener(() {
    final nowAuthed = session.isAuthenticated;
    // ignore: avoid_print
    print('🎬 STREAM: AuthSession changed → '
        'wasAuthed=$wasAuthed nowAuthed=$nowAuthed');
    if (!wasAuthed && nowAuthed) {
      // ignore: avoid_print
      print('🎬 STREAM: transition false→true → rehydrate + warmUp (parallel)');
      // Parallel — NOT chained. Chaining was an attempt to populate
      // UsersCache before Stream's client construction so the VoIP
      // ringer shows "Mr A" instead of "10", but it blocked the entire
      // ring path: if `users.me()` hung (network blip, slow backend)
      // warmUp never fired and no ring went out at all. The race is
      // acceptable — StreamCallEngine reads UsersCache lazily AND
      // refreshes on every Call via getOrCreate. First call may show
      // the bare id; subsequent ones land on the cached name.
      unawaited(_rehydrateChatIdentityOnAuth(GetIt.instance));
      unawaited(engine.warmUp());
    }
    wasAuthed = nowAuthed;
  });
}
