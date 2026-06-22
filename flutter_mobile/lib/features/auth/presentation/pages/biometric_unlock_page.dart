import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/auth_session.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/demo_sign_in.dart';

class BiometricUnlockPage extends StatefulWidget {
  const BiometricUnlockPage({super.key});

  @override
  State<BiometricUnlockPage> createState() => _BiometricUnlockPageState();
}

class _BiometricUnlockPageState extends State<BiometricUnlockPage> {
  bool _isAuthenticating = false;

  void _simulateAuth() async {
    setState(() => _isAuthenticating = true);
    
    // Simulate a delay for biometric check
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      // Perform demo sign-in simulation to trigger global auth state
      await getIt<DemoSignInService>().seed();
      final session = getIt<AuthSession>();
      if (session is StubAuthSession) {
        session.simulateSignIn();
      }

      // Pop this page (it was pushed via ConfigRouter on top of
      // LoginPage). The simulateSignIn above fires the router's
      // refreshListenable; the auth-redirect policy then bounces
      // the now-revealed `/login` to `/dashboard`. Calling
      // `goNamed(dashboardName)` directly is a no-op here because
      // go_router still thinks the location is `/login`.
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Biometric Icon
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: _isAuthenticating 
                          ? const SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.fingerprint_rounded,
                              size: 100,
                              color: theme.colorScheme.primary,
                            ),
                      )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeInOut)
                          .animate()
                          .fadeIn(duration: 800.ms),
                      
                      const SizedBox(height: 48),
                      
                      AppLabel(
                        text: _isAuthenticating ? l10n.biometricAuthenticatingTitle : l10n.biometricPageTitle,
                        fontSize: AppFontSize.value22,
                        fontWeight: FontWeight.bold,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      AppLabel(
                        text: _isAuthenticating
                          ? l10n.biometricHoldFingerSubtitle
                          : l10n.biometricUseFingerprintSubtitle,
                        fontSize: AppFontSize.value16,
                        color: theme.colorScheme.onSurfaceVariant,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 600.ms),
                      
                      const SizedBox(height: 64),
                      
                      // Action Buttons
                      if (!_isAuthenticating)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: _simulateAuth,
                                child: Text(l10n.biometricUnlockNowAction),
                              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5, end: 0),

                              const SizedBox(height: 16),

                              TextButton(
                                // This page is pushed onto the root
                                // Navigator from LoginPage via
                                // ConfigRouter; go_router's location
                                // is still `/login`, so `goNamed(login)`
                                // is a no-op. Pop instead — reveals
                                // the LoginPage that pushed us here.
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.biometricUsePasswordInsteadAction),
                              ).animate().fadeIn(delay: 1000.ms),
                            ],
                          ),
                        ).animate().fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
