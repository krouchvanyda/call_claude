import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../core/widgets/loading_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';
import 'biometric_unlock_page.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSimulatedLogin});

  final VoidCallback? onSimulatedLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitting) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    setState(() => _submitting = true);
    final result = await GetIt.I<AuthRepository>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(
          content: Text(_failureMessage(failure, l10n)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
      (_) => widget.onSimulatedLogin?.call(),
    );
  }

  /// Map a typed [Failure] onto a user-facing string. Prefer the message
  /// the backend / interceptor put on the failure; fall back to a
  /// localized generic when it's null (and a network-specific one for
  /// connectivity issues so the user knows to retry instead of fixing
  /// their password).
  String _failureMessage(Failure failure, AppLocalizations l10n) {
    return switch (failure) {
      NetworkFailure(:final message) ||
      TimeoutFailure(:final message) =>
        message ?? l10n.authNetworkErrorFallback,
      UnauthorizedFailure(:final message) ||
      ValidationFailure(:final message) ||
      ServerFailure(:final message) ||
      ForbiddenFailure(:final message) ||
      NotFoundFailure(:final message) ||
      ConflictFailure(:final message) ||
      RateLimitFailure(:final message) ||
      UnknownFailure(:final message) =>
        message ?? l10n.authGenericErrorFallback,
      CancelledFailure() => l10n.authGenericErrorFallback,
    };
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
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                    theme.colorScheme.surface,
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),

            // Decorative Circles — paired for compositional balance
            Positioned(
              top: -100,
              right: -100,
              child: CircleAvatar(
                radius: 150,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
            ).animate().fadeIn(duration: 1200.ms).scale(begin: const Offset(0.5, 0.5)),
            Positioned(
              bottom: -120,
              left: -120,
              child: CircleAvatar(
                radius: 170,
                backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.04),
              ),
            ).animate().fadeIn(duration: 1400.ms).scale(begin: const Offset(0.5, 0.5)),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Welcome Text
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.business_center_rounded,
                            size: 56,
                            color: theme.colorScheme.primary,
                          ),
                        ).animate().fadeIn(duration: 600.ms).scale(
                          delay: 100.ms,
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        AppLabel(
                          text: l10n.appName,
                          fontSize: AppFontSize.value24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 8),

                        AppLabel(
                          text: l10n.loginWelcomeSubtitle,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),
                        
                        const SizedBox(height: 48),
                        
                        // Glassmorphic Login Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      controller: _emailController,
                                      label: l10n.commonEmailLabel,
                                      icon: Icons.email_outlined,
                                      hintText: 'name@company.com',
                                      keyboardType: TextInputType.emailAddress,
                                      textCapitalization: TextCapitalization.none,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return l10n.loginValidatorEmailRequired;
                                        }
                                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                        if (!emailRegex.hasMatch(value)) {
                                          return l10n.loginValidatorEmailInvalid;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    AppTextField(
                                      controller: _passwordController,
                                      label: l10n.loginPasswordLabel,
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      textCapitalization: TextCapitalization.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return l10n.loginValidatorPasswordRequired;
                                        }
                                        if (value.length < 6) {
                                          return l10n.loginValidatorPasswordTooShort;
                                        }
                                        return null;
                                      },
                                    ),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => ConfigRouter.pushPageAnimation(context, const ForgotPasswordPage()),
                                        child: Text(l10n.loginForgotPasswordAction),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    SizedBox(
                                      height: 54,
                                      child: FilledButton(
                                        // Button disables while the
                                        // LoadingScreen overlay (added
                                        // at the end of the Stack) is
                                        // showing — keeps a single
                                        // source of "we're working" so
                                        // the UI doesn't have two
                                        // competing spinners.
                                        onPressed: _submitting ? null : _handleLogin,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadii.md),
                                          ),
                                        ),
                                        child: Text(l10n.loginSignInAction),
                                      ),
                                    ).animate().shimmer(delay: 2000.ms, duration: 1500.ms),

                                    const SizedBox(height: 20),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: AppLabel(
                                            text: l10n.loginOrSecureWith,
                                            fontSize: AppFontSize.value11,
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    SizedBox(
                                      height: 54,
                                      child: OutlinedButton.icon(
                                        onPressed: () => ConfigRouter.pushPageAnimation(context, const BiometricUnlockPage()),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadii.md),
                                          ),
                                          side: BorderSide(
                                            color: theme.colorScheme.outlineVariant,
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.fingerprint_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                        label: Text(l10n.loginUseBiometricsAction),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Don't have an account? → Register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLabel(
                              text: l10n.loginNoAccountPrompt,
                              fontSize: AppFontSize.value13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            TextButton(
                              onPressed: () => ConfigRouter.pushPageAnimation(
                                context,
                                RegisterPage(onSimulatedRegister: widget.onSimulatedLogin),
                              ),
                              child: Text(l10n.loginCreateAccountAction),
                            ),
                          ],
                        ).animate().fadeIn(delay: 700.ms),

                        // Demo Link
                        // TextButton(
                        //   onPressed: () => ConfigRouter.pushPageAnimation(context, const OtpEntryPage()),
                        //   child: Text(l10n.loginOtpDemoLink),
                        // ).animate().fadeIn(delay: 800.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay — last child so it paints on top of the
            // whole screen. `AbsorbPointer` swallows taps so the user
            // can't double-submit by hammering the disabled button or
            // tap the "Forgot password" / "Create one" links during
            // the in-flight call. Semi-opaque scrim dims everything
            // underneath so the centred LoadingScreen reads cleanly.
            if (_submitting)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const LoadingScreen(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
