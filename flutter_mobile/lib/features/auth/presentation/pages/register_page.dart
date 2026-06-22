import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../core/widgets/loading_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onSimulatedRegister});

  final VoidCallback? onSimulatedRegister;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _showTermsError = false;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final termsValid = _acceptTerms;
    if (!termsValid) {
      setState(() => _showTermsError = true);
    }
    if (!formValid || !termsValid) return;
    if (_submitting) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    setState(() => _submitting = true);
    final result = await GetIt.I<AuthRepository>().register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
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
      (_) => widget.onSimulatedRegister?.call(),
    );
  }

  /// Map a typed [Failure] onto a user-facing string. Same translation
  /// table as the login page — extracted as a private method per screen
  /// rather than a shared helper because future slices may want to
  /// surface field-level [ValidationFailure.fieldErrors] differently
  /// here (e.g. inline on the email field instead of in a snackbar).
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
            // Background Gradient — mirrors login but flipped tones for variety.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                    theme.colorScheme.surface,
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),

            // Decorative Circles
            Positioned(
              top: -120,
              left: -100,
              child: CircleAvatar(
                radius: 160,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
            ).animate().fadeIn(duration: 1200.ms).scale(begin: const Offset(0.5, 0.5)),
            Positioned(
              bottom: -140,
              right: -120,
              child: CircleAvatar(
                radius: 180,
                backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.05),
              ),
            ).animate().fadeIn(duration: 1400.ms).scale(begin: const Offset(0.5, 0.5)),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(18),
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
                            Icons.person_add_alt_1_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ).animate().fadeIn(duration: 600.ms).scale(
                              delay: 100.ms,
                              duration: 700.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 16),

                        AppLabel(
                          text: l10n.registerWelcomeTitle,
                          fontSize: AppFontSize.value24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 8),

                        AppLabel(
                          text: l10n.registerWelcomeSubtitle,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 32),

                        // Glassmorphic Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(28),
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
                                      controller: _fullNameController,
                                      label: l10n.registerFullNameLabel,
                                      icon: Icons.person_outline_rounded,
                                      hintText: l10n.registerFullNameHint,
                                      textCapitalization: TextCapitalization.words,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return l10n.registerValidatorFullNameRequired;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 18),

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

                                    const SizedBox(height: 18),

                                    AppTextField(
                                      controller: _phoneController,
                                      label: l10n.commonPhoneLabel,
                                      icon: Icons.phone_outlined,
                                      hintText: l10n.registerPhoneHint,
                                      keyboardType: TextInputType.phone,
                                      textCapitalization: TextCapitalization.none,
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return l10n.registerValidatorPhoneRequired;
                                        }
                                        // Permissive — anything with at least
                                        // 6 digits passes; the backend is the
                                        // canonical validator (E.164 / locale).
                                        final digitCount =
                                            trimmed.replaceAll(RegExp(r'\D'), '').length;
                                        if (digitCount < 6) {
                                          return l10n.registerValidatorPhoneInvalid;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 18),

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
                                        onPressed: () =>
                                            setState(() => _obscurePassword = !_obscurePassword),
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

                                    const SizedBox(height: 18),

                                    AppTextField(
                                      controller: _confirmPasswordController,
                                      label: l10n.registerConfirmPasswordLabel,
                                      icon: Icons.lock_reset_rounded,
                                      obscureText: _obscureConfirmPassword,
                                      textCapitalization: TextCapitalization.none,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return l10n.loginValidatorPasswordRequired;
                                        }
                                        if (value != _passwordController.text) {
                                          return l10n.registerValidatorPasswordsMismatch;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    InkWell(
                                      borderRadius: BorderRadius.circular(AppRadii.sm),
                                      onTap: () => setState(() {
                                        _acceptTerms = !_acceptTerms;
                                        if (_acceptTerms) _showTermsError = false;
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: Checkbox(
                                                value: _acceptTerms,
                                                onChanged: (v) => setState(() {
                                                  _acceptTerms = v ?? false;
                                                  if (_acceptTerms) _showTermsError = false;
                                                }),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(AppRadii.xs),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: AppLabel(
                                                text: l10n.registerAcceptTermsLabel,
                                                fontSize: AppFontSize.value12,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (_showTermsError && !_acceptTerms) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 38),
                                        child: AppLabel(
                                          text: l10n.registerValidatorAcceptTermsRequired,
                                          fontSize: AppFontSize.value12,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    SizedBox(
                                      height: 54,
                                      child: FilledButton(
                                        // Disables while the
                                        // LoadingScreen overlay (added
                                        // at the end of the Stack) is
                                        // showing — one visual signal
                                        // beats two competing spinners.
                                        onPressed: _submitting ? null : _handleRegister,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadii.md),
                                          ),
                                        ),
                                        child: Text(l10n.registerSubmitAction),
                                      ),
                                    ).animate().shimmer(delay: 2000.ms, duration: 1500.ms),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Already-have-account row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLabel(
                              text: l10n.registerHaveAccountPrompt,
                              fontSize: AppFontSize.value13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: Text(l10n.registerSignInAction),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Back arrow overlay — paints on top of the
            // SingleChildScrollView above. Wrapped in `Align(topLeft)`
            // so the IconButton's hit area is just the corner, not the
            // whole screen — otherwise it would intercept taps meant
            // for the form fields.
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay — last child so it paints on top of
            // EVERYTHING including the back arrow. `AbsorbPointer`
            // swallows taps so the user can't back out mid-register
            // (would leave _submitting stuck) or hammer the disabled
            // submit button. The dim scrim + white-tinted LoadingScreen
            // give a single, branded "we're working" indicator.
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
