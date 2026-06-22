import 'dart:io' show Platform;

import 'package:erp_callkit/erp_callkit.dart';
import 'package:erp_mobile/shared/firebase_services/firebase_notification_provider.dart';
import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/i18n/locale_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/data/call_signaling_service.dart';
import 'features/chat/data/repositories/conversations_repository.dart';
import 'features/chat/presentation/widgets/incoming_call_overlay.dart';
import 'features/settings/data/repositories/preferences_repository.dart';
import 'features/settings/entities/user_preferences.dart' as pref_entities;
import 'l10n/app_localizations.dart';

/// Root application widget.
///
/// Pulls the resolved [AppRouter] from DI, applies the global [AppTheme]
/// dynamically watching [PreferencesRepository] to switch theme modes (light, dark, system),
/// and rebuilds whenever preferences emit language or theme changes.
class ErpMobileApp extends StatefulWidget {
  const ErpMobileApp({
    super.key,
    AppRouter? router,
    LocaleService? localeService,
  })  : _injectedRouter = router,
        _injectedLocaleService = localeService;

  /// Test seams — production code constructs without these and lets DI
  /// supply both.
  final AppRouter? _injectedRouter;
  final LocaleService? _injectedLocaleService;

  @override
  State<ErpMobileApp> createState() => _ErpMobileAppState();
}

class _ErpMobileAppState extends State<ErpMobileApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Drain any pending native-call launch action: the app may have just
    // been opened by tapping the body / Accept of the native incoming-
    // call notification (see packages/erp_callkit). Reject is handled
    // entirely in native Kotlin, so it never reaches here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeNativeCallLaunch();
    });
    // FirebaseNotificationProvider is now a singleton (private
    // constructor + `.instance`) so subscription state, dedupe
    // counters, and the dispose hook don't fragment across callers.
    //
    // Token fetch + persistence to PushTokenStorage already runs in
    // `main.dart`; this redundant `getFirebaseToken()` call is kept
    // here only for the debug log it produces — drop it once the
    // backend `POST /devices` flow lands.
    FirebaseNotificationProvider.instance.getFirebaseToken();

    // Three labelled callbacks so the console makes the source of
    // each push obvious during development:
    //   - foreground (app open)
    //   - background → tap to open
    //   - terminated → tap to launch
    //
    // The provider's `initOnMessageListener` / `initOnMessageOpenedApp`
    // now cancel any previous subscription on re-call, so a hot
    // reload that re-runs initState won't leak duplicate listeners.
    FirebaseNotificationProvider.instance.initOnMessageListener(
      getData: (message) {
        debugPrint('message ── in app ── $message');
      },
    );
    FirebaseNotificationProvider.instance.initOnMessageOpenedApp(
      getData: (message) {
        debugPrint('message ── out of app (minimised) ── $message');
      },
    );
    FirebaseNotificationProvider.instance.handleInitialMessage(
      getData: (message) {
        debugPrint('message ── killed app ── $message');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // The notification may have been tapped while the app was alive
    // (minimised → singleTask brings MainActivity forward). Drain on
    // every resume too, not just cold start.
    if (state == AppLifecycleState.resumed) {
      _consumeNativeCallLaunch();
    }
  }

  /// Pull a pending native incoming-call tap (body or Accept) and route
  /// it into the existing signalling so the in-app sheet / call page
  /// behaves exactly like the WS / FCM path. No-op when nothing pending.
  Future<void> _consumeNativeCallLaunch() async {
    // iOS has no `erp_callkit` native implementation (it's Android-only —
    // the launch-action / native-Reject mechanism is a Kotlin
    // BroadcastReceiver). Calling it on iOS only throws a
    // `MissingPluginException` that we'd swallow below — and prints
    // confusing noise. The iOS killed/locked accept is driven entirely by
    // the native `CXCallObserver` bridge (AppDelegate.swift →
    // CallkitEventHandler), so short-circuit here.
    if (Platform.isIOS) return;
    try {
      final data = await ErpCallKit.consumeLaunchAction();
      if (data == null) return;

      final accept = data['accept'] == true;
      final callId = data['callId']?.toString() ?? '';
      final callerId = data['callerId']?.toString() ?? '';
      final callerName = data['callerName']?.toString() ?? 'Unknown';
      final isVideo = data['isVideo'] == true;
      final streamCallCid = data['callCid']?.toString() ?? '';
      var conversationId = data['conversationId']?.toString() ?? '';
      if (callId.isEmpty || callerId.isEmpty) return;

      // The app is now handling this call in the foreground (in-app sheet
      // or the in-call page), so the native heads-up notification is
      // redundant — clear it immediately so its header bar disappears.
      await ErpCallKit.dismiss(callId);

      CallSignalingService? signaling;
      ConversationsRepository? conversations;
      try {
        signaling = getIt<CallSignalingService>();
      } catch (_) {
        signaling = null;
      }
      try {
        conversations = getIt<ConversationsRepository>();
      } catch (_) {
        conversations = null;
      }
      if (signaling == null) {
        debugPrint('[NativeCall] signaling not registered yet — skip');
        return;
      }

      // Stream ring pushes carry no local conversationId — resolve the
      // direct conversation with the caller so the call page renders the
      // right name/avatar (mirrors CallkitEventHandler).
      if (conversationId.isEmpty && conversations != null) {
        try {
          final direct = await conversations.findDirectWith(callerId);
          if (direct != null) conversationId = direct.id;
        } catch (_) {/* fall through */}
      }
      if (conversationId.isEmpty) conversationId = streamCallCid;

      final payload = <String, dynamic>{
        'type': 'call.invite',
        'callId': callId,
        'conversationId': conversationId,
        'callerId': callerId,
        'callerName': callerName,
        'callType': isVideo ? 'video' : 'voice',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'streamCallCid': streamCallCid,
      };
      debugPrint('[NativeCall] launch action accept=$accept '
          'callId=$callId conv=$conversationId caller=$callerName');
      await signaling.handleIncomingFromPush(payload);

      if (accept) {
        // Just accept — do NOT push the call page here. The mounted
        // IncomingCallOverlay listens for the connected transition and
        // pushes the in-call page itself (guarded by VoiceCallPage/
        // VideoCallPage.isMounted). Pushing here too stacked the page
        // twice.
        await signaling.acceptIncoming();
      }
    } catch (e) {
      debugPrint('[NativeCall] consume failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = widget._injectedRouter ?? getIt<AppRouter>();
    final prefRepo = getIt<PreferencesRepository>();

    return StreamBuilder<pref_entities.UserPreferences>(
      stream: prefRepo.watch(),
      initialData: pref_entities.UserPreferences.initial,
      builder: (context, snapshot) {
        final prefs = snapshot.data ?? pref_entities.UserPreferences.initial;

        // Map settings AppThemeMode to Flutter's ThemeMode
        final themeMode = _mapThemeMode(prefs.themeMode);

        // Map settings AppLanguage to language code
        final langCode = prefs.language == pref_entities.AppLanguage.en ? 'en' : 'km';

        return MaterialApp.router(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: Locale(langCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router.config,
          // Slice 10.2.3 — wrap every route in [IncomingCallOverlay]
          // so a peer-initiated call invite shows the full-screen
          // accept/reject sheet regardless of which page is on top.
          builder: (context, child) =>
              IncomingCallOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }

  ThemeMode _mapThemeMode(pref_entities.AppThemeMode mode) {
    switch (mode) {
      case pref_entities.AppThemeMode.light:
        return ThemeMode.light;
      case pref_entities.AppThemeMode.dark:
        return ThemeMode.dark;
      case pref_entities.AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
