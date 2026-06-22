import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/token_storage.dart';
import '../../../../core/router/auth_session.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Increased delay for better viewing of animations
  static const _probeDelay = Duration(milliseconds: 2000);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_probeDelay, _decide);
  }

  /// Decide where to send the user after the splash animation:
  ///   - tokens present in [TokenStorage]  → straight to the dashboard
  ///                                         (auto-login from prior session)
  ///   - no tokens / read fails            → login page
  ///
  /// Tokens live in `flutter_secure_storage` via `SecureTokenStorage`,
  /// so this survives app kills — the user only re-types credentials
  /// after an explicit logout. If the stored access token has expired
  /// the AuthInterceptor will refresh it on the first authenticated
  /// call (or fall back to /login if the refresh also fails), so we
  /// don't gate the redirect on expiry here.
  Future<void> _decide() async {
    if (!mounted) return;
    final tokens = await GetIt.I<TokenStorage>().read();
    if (!mounted) return;
    final hasTokens = tokens != null && tokens.accessToken.isNotEmpty;
    // ignore: avoid_print
    print('🎬 SPLASH: _decide() — hasTokens=$hasTokens');
    if (hasTokens) {
      // Hydrate the in-process session BEFORE navigating — the router's
      // `redirect` checks `AuthSession.isAuthenticated` and would
      // bounce us back to /login otherwise (the stored tokens alone
      // don't tell the router the user is signed in).
      // ignore: avoid_print
      print('🎬 SPLASH: calling markAuthenticated()');
      GetIt.I<AuthSession>().markAuthenticated();
      context.goNamed(RoutePaths.dashboardName);
    } else {
      // ignore: avoid_print
      print('🎬 SPLASH: no tokens → routing to /login');
      context.goNamed(RoutePaths.loginName);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: DynamicStatusBar(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.9),
                theme.colorScheme.surface,
                theme.colorScheme.secondaryContainer.withOpacity(0.4),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Floating background blobs
              Positioned(
                top: -50,
                left: -50,
                child: _CircularBlob(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  radius: 120,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .moveY(begin: 0, end: 20, duration: 3000.ms, curve: Curves.easeInOut),
              ),
              
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 96,
                      color: theme.colorScheme.primary,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 1000.ms)
                      .scale(
                        delay: 200.ms,
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                      )
                      .shimmer(delay: 1500.ms, duration: 2000.ms)
                      .then()
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .moveY(begin: 0, end: -10, duration: 2000.ms, curve: Curves.easeInOut),
                  
                  const SizedBox(height: 32),
                  
                  // Animated App Name
                  AppLabel(
                    text: l10n.appName,
                    fontSize: AppFontSize.value32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: theme.colorScheme.primary,
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 1000.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 12),

                  // Subtle Tagline
                  AppLabel(
                    text: l10n.splashTagline,
                    fontSize: AppFontSize.value14,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  )
                      .animate()
                      .fadeIn(delay: 1200.ms, duration: 800.ms),
                ],
              ),
              
              const Positioned(
                bottom: 64,
                child: _SplashFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularBlob extends StatelessWidget {
  final Color color;
  final double radius;

  const _CircularBlob({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  const _SplashFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary.withOpacity(0.4),
          ),
        ).animate().fadeIn(delay: 1500.ms),
        const SizedBox(height: 32),
        AppLabel(
          text: 'v1.0.0',
          fontSize: AppFontSize.value12,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
        ).animate().fadeIn(delay: 1800.ms),
      ],
    );
  }
}
