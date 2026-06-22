import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/security_repositories.dart';
import '../../entities/app_lock_settings.dart';

/// Slice 9.3.3 — PIN + biometric re-auth on resume.
class AppLockPage extends StatelessWidget {
  const AppLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = GetIt.I<AppLockSettingsRepository>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.appLockPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas
            AppBackgroundGradient(),
            StreamBuilder<AppLockSettings>(
              stream: settingsRepo.watch(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final settings = snap.data!;

                return ListView(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  children: [
                    // Security Shield Header Status Panel
                    _SecurityHeader(isActive: settings.pinEnabled)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1)),
                    const SizedBox(height: 24),
                    AppLabel(
                      text: l10n.appLockDeviceProtectionHeading,
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    const SizedBox(height: 12),
                    // Switches Card Container
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.password, color: theme.colorScheme.primary, size: 20),
                            ),
                            title: AppLabel(
                              text: l10n.appLockPinTitle,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: AppLabel(
                              text: l10n.appLockPinSubtitle,
                              fontSize: AppFontSize.value12,
                            ),
                            value: settings.pinEnabled,
                            onChanged: (v) async {
                              if (v) {
                                final pin = await _promptForNewPin(context);
                                if (pin == null) return;
                                await GetIt.I<InMemoryPinSecretStore>().setPin(pin);
                                await settingsRepo.setPinEnabled(
                                  current: settings,
                                  enabled: true,
                                );
                              } else {
                                await GetIt.I<InMemoryPinSecretStore>().clearPin();
                                await settingsRepo.setPinEnabled(
                                  current: settings,
                                  enabled: false,
                                );
                              }
                            },
                          ),
                          const Divider(height: 1, indent: 64),
                          SwitchListTile(
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (settings.pinEnabled
                                        ? theme.colorScheme.primary
                                        : Colors.grey)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fingerprint,
                                color: settings.pinEnabled ? theme.colorScheme.primary : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: AppLabel(
                              text: l10n.appLockBiometricTitle,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: AppLabel(
                              text: l10n.appLockBiometricSubtitle,
                              fontSize: AppFontSize.value12,
                            ),
                            value: settings.biometricEnabled,
                            onChanged: settings.pinEnabled
                                ? (v) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await settingsRepo.setBiometricEnabled(
                                        current: settings,
                                        enabled: v,
                                      );
                                    } on ConflictFailure catch (f) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(f.message ?? l10n.appLockCannotEnableFallback),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.04, end: 0),
                    const SizedBox(height: 24),
                    AppLabel(
                      text: l10n.appLockTimeoutHeading,
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    const SizedBox(height: 12),
                    // Action List Tiles
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (settings.pinEnabled
                                        ? theme.colorScheme.primary
                                        : Colors.grey)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: settings.pinEnabled ? theme.colorScheme.primary : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: AppLabel(
                              text: l10n.appLockAutoLockDurationTitle,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                              color: settings.pinEnabled
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            subtitle: AppLabel(
                              text: settings.pinEnabled
                                  ? (settings.autoLockMinutes == 0
                                      ? l10n.appLockLockImmediatelySubtitle
                                      : l10n.appLockMinutesAfterBackgroundSubtitle(settings.autoLockMinutes))
                                  : l10n.appLockRequiresPinSubtitle,
                              fontSize: AppFontSize.value12,
                              color: settings.pinEnabled
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: settings.pinEnabled ? theme.colorScheme.primary : Colors.grey,
                            ),
                            onTap: settings.pinEnabled ? () => _pickAutoLock(context, settings) : null,
                          ),
                          if (settings.pinEnabled) ...[
                            const Divider(height: 1, indent: 64),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_reset, color: theme.colorScheme.primary, size: 20),
                              ),
                              title: AppLabel(
                                text: l10n.appLockChangePinTitle,
                                fontSize: AppFontSize.value14,
                                fontWeight: FontWeight.bold,
                              ),
                              subtitle: AppLabel(
                                text: l10n.appLockChangePinSubtitle,
                                fontSize: AppFontSize.value12,
                              ),
                              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final pin = await _promptForNewPin(context);
                                if (pin == null) return;
                                await GetIt.I<InMemoryPinSecretStore>().setPin(pin);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.appLockPinUpdatedSnack),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.04, end: 0),
                    const SizedBox(height: 24),
                    // Footnote Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AppLabel(
                              text: l10n.appLockFootnote,
                              fontSize: AppFontSize.value12,
                              color: theme.colorScheme.onSurfaceVariant,
                              lineHeight: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 280.ms),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAutoLock(BuildContext context, AppLockSettings settings) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = GetIt.I<AppLockSettingsRepository>();
    final theme = Theme.of(context);

    final value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (bottomSheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                AppLabel(
                  text: l10n.appLockAutoLockDurationTitle,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                AppLabel(
                  text: l10n.appLockAutoLockSheetSubtitle,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Divider(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      for (final minutes in [0, 1, 5, 15, 30, 60]) ...[
                        _AutoLockOption(
                          minutes: minutes,
                          isSelected: settings.autoLockMinutes == minutes,
                          onTap: () => Navigator.pop(bottomSheetCtx, minutes),
                        ),
                        if (minutes != 60) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (value == null) return;
    try {
      await repo.setAutoLockMinutes(current: settings, minutes: value);
    } on ValidationFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${f.fieldErrors}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _promptForNewPin(BuildContext context) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => AlertDialog(
          title: AppLabel(
            text: l10n.appLockSetSecurePinAction,
            fontSize: AppFontSize.value18,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: l10n.appLockPinFieldLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: l10n.appLockConfirmPinLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: AppLabel(
                    text: errorMsg!,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: AppLabel(
                text: l10n.commonCancelAction,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w600,
              ),
            ),
            FilledButton(
              onPressed: () {
                try {
                  InMemoryPinSecretStore.validatePinFormat(pinCtrl.text);
                  InMemoryPinSecretStore.ensurePinConfirmationMatches(
                    pin: pinCtrl.text,
                    confirm: confirmCtrl.text,
                  );
                  Navigator.pop(dialogCtx, pinCtrl.text);
                } on ValidationFailure catch (f) {
                  setDialog(() => errorMsg = f.fieldErrors.values.expand((e) => e).join(', '));
                }
              },
              child: AppLabel(
                text: l10n.appLockSavePinAction,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: (isActive ? Colors.green : theme.colorScheme.primary).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shield Graphic Node
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isActive ? Colors.green : theme.colorScheme.primary).withValues(alpha: 0.1),
                  ),
                ),
                Icon(
                  isActive ? Icons.verified_user : Icons.gpp_maybe,
                  color: isActive ? Colors.green : theme.colorScheme.primary,
                  size: 38,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppLabel(
            text: isActive ? l10n.appLockHeaderEnabledTitle : l10n.appLockHeaderDisabledTitle,
            fontSize: AppFontSize.value16,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 6),
          AppLabel(
            text: isActive
                ? l10n.appLockHeaderEnabledSubtitle
                : l10n.appLockHeaderDisabledSubtitle,
            fontSize: AppFontSize.value12,
            textAlign: TextAlign.center,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _AutoLockOption extends StatelessWidget {
  const _AutoLockOption({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final String title = minutes == 0
        ? l10n.appLockOptionImmediately
        : (minutes == 1 ? l10n.appLockOptionMinute(minutes) : l10n.appLockOptionMinutes(minutes));
    final String subtitle = minutes == 0
        ? l10n.appLockOptionImmediatelySubtitle
        : (minutes == 1
            ? l10n.appLockOptionMinuteSubtitle(minutes)
            : l10n.appLockOptionMinutesSubtitle(minutes));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              minutes == 0 ? Icons.bolt_rounded : Icons.timer_outlined,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: title,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 2),
                  AppLabel(
                    text: subtitle,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
