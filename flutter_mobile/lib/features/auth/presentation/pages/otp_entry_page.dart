import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/auth_session.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/demo_sign_in.dart';
import '../../data/repositories/otp_repository.dart';
import '../../entities/otp_verification_result.dart';
import '../bloc/otp_bloc.dart';
import '../bloc/otp_event.dart';
import '../bloc/otp_state.dart';
import '../widgets/otp_input_field.dart';

class OtpEntryPage extends StatelessWidget {
  const OtpEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OtpBloc>(
      create: (_) => getIt<OtpBloc>(),
      child: const _OtpEntryView(),
    );
  }
}

class _OtpEntryView extends StatelessWidget {
  const _OtpEntryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<OtpBloc, OtpState>(
      listenWhen: (prev, next) =>
          prev.hasSucceeded == false && next.hasSucceeded,
      listener: (context, state) async {
        // Perform demo sign-in simulation to trigger global auth state
        await getIt<DemoSignInService>().seed();
        final session = getIt<AuthSession>();
        if (session is StubAuthSession) {
          session.simulateSignIn();
        }
        
        if (context.mounted) {
          // OtpEntryPage is pushed onto the root Navigator from
          // LoginPage via ConfigRouter, so go_router's location is
          // still `/login`. `goNamed(dashboardName)` would be a no-op
          // here. Pop instead — the simulateSignIn above already
          // fires the router's refreshListenable, and the auth-redirect
          // policy bounces the revealed `/login` to `/dashboard`.
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: DynamicStatusBar(
            child: Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                      colors: [
                        theme.colorScheme.secondaryContainer.withOpacity(0.8),
                        theme.colorScheme.surface,
                        theme.colorScheme.primaryContainer.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                
                // Decorative Circle
                Positioned(
                  bottom: -100,
                  left: -100,
                  child: CircleAvatar(
                    radius: 150,
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.05),
                  ),
                ).animate().fadeIn(duration: 1200.ms).scale(begin: const Offset(0.5, 0.5)),

                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.canPop() ? context.pop() : context.goNamed(RoutePaths.loginName),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                      
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Icon(
                                    Icons.shield_moon_rounded,
                                    size: 72,
                                    color: theme.colorScheme.primary,
                                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                                  
                                  const SizedBox(height: 24),
                                  
                                  AppLabel(
                                    text: l10n.otpPageTitle,
                                    fontSize: AppFontSize.value22,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(delay: 200.ms),

                                  const SizedBox(height: 12),

                                  AppLabel(
                                    text: l10n.otpSubtitle,
                                    fontSize: AppFontSize.value16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(delay: 300.ms),
                                  
                                  const SizedBox(height: 48),
                                  
                                  // Glassmorphic OTP Card
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 24,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            OtpInputField(
                                              length: state.length,
                                              enabled: !state.isSubmitting,
                                              hasError: state.hasError,
                                              onChanged: (code) => context
                                                  .read<OtpBloc>()
                                                  .add(OtpEvent.codeChanged(code)),
                                              onCompleted: (_) => context
                                                  .read<OtpBloc>()
                                                  .add(const OtpEvent.submitted()),
                                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                                            
                                            const SizedBox(height: 24),
                                            
                                            if (state.hasError)
                                              AppLabel(
                                                text: _errorMessage(l10n, state.rejectionReason!),
                                                fontSize: AppFontSize.value12,
                                                color: theme.colorScheme.error,
                                                fontWeight: FontWeight.bold,
                                                textAlign: TextAlign.center,
                                              ).animate().shake(),
                                            
                                            const SizedBox(height: 24),
                                            
                                            FilledButton(
                                              onPressed: state.canSubmit
                                                  ? () => context
                                                      .read<OtpBloc>()
                                                      .add(const OtpEvent.submitted())
                                                  : null,
                                              child: state.isSubmitting
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Text(l10n.otpVerifyButton),
                                            ).animate().shimmer(delay: 2000.ms, duration: 1500.ms),
                                            
                                            const SizedBox(height: 16),
                                            
                                            TextButton(
                                              onPressed: () {}, // Resend logic
                                              child: Text(l10n.otpResendCodeAction),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                                  
                                  const SizedBox(height: 40),
                                  
                                  AppLabel(
                                    text: l10n.otpDevHint(OtpRepository.devCode),
                                    fontSize: AppFontSize.value12,
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(delay: 800.ms),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _errorMessage(AppLocalizations l10n, OtpRejectionReason reason) {
    return switch (reason) {
      OtpRejectionReason.incorrect => l10n.otpErrorIncorrect,
      OtpRejectionReason.expired => l10n.otpErrorExpired,
      OtpRejectionReason.tooManyAttempts => l10n.otpErrorTooManyAttempts,
      OtpRejectionReason.networkError => l10n.otpErrorNetwork,
    };
  }
}
