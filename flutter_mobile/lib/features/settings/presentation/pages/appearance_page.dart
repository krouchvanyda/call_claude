import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../entities/user_preferences.dart';

/// Slice 9.1.1 — light / dark / system toggle.
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<PreferencesRepository>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.appearancePageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<UserPreferences>(
              stream: repo.watch(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final mode = snap.data!.themeMode;
                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    AppLabel(
                      text: l10n.appearanceChooseThemeHeading,
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    const SizedBox(height: 12),
                    for (final m in AppThemeMode.values) ...[
                      _ThemeCard(
                        mode: m,
                        isSelected: mode == m,
                        onTap: () async => await repo.setThemeMode(m),
                      ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 300.ms),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Miniature Mock UI
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _mockBgColor(theme),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock TopBar
                  Container(
                    height: 8,
                    width: 36,
                    decoration: BoxDecoration(
                      color: _mockPrimaryColor(theme),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Mock Cards
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: _mockCardColor(theme),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 24,
                    decoration: BoxDecoration(
                      color: _mockCardColor(theme),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: _label(l10n, mode),
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 2),
                  AppLabel(
                    text: _subtitle(l10n, mode),
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: theme.colorScheme.onPrimary,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Color _mockBgColor(ThemeData theme) {
    switch (mode) {
      case AppThemeMode.light:
        return Colors.grey.shade50;
      case AppThemeMode.dark:
        return const Color(0xFF121212);
      case AppThemeMode.system:
        return theme.brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.grey.shade50;
    }
  }

  Color _mockPrimaryColor(ThemeData theme) {
    return theme.colorScheme.primary;
  }

  Color _mockCardColor(ThemeData theme) {
    switch (mode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return const Color(0xFF1E1E1E);
      case AppThemeMode.system:
        return theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white;
    }
  }

  String _label(AppLocalizations l10n, AppThemeMode m) {
    switch (m) {
      case AppThemeMode.system:
        return l10n.appearanceModeSystem;
      case AppThemeMode.light:
        return l10n.appearanceModeLight;
      case AppThemeMode.dark:
        return l10n.appearanceModeDark;
    }
  }

  String _subtitle(AppLocalizations l10n, AppThemeMode m) {
    switch (m) {
      case AppThemeMode.system:
        return l10n.appearanceSubtitleSystem;
      case AppThemeMode.light:
        return l10n.appearanceSubtitleLight;
      case AppThemeMode.dark:
        return l10n.appearanceSubtitleDark;
    }
  }
}
