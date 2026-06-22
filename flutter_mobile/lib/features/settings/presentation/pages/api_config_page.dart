import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/admin_repositories.dart';
import '../../entities/api_environment.dart';

/// Slice 9.2.3 — API environment / tenant switcher.
class ApiConfigPage extends StatelessWidget {
  const ApiConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<ApiEnvironmentsRepository>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.apiConfigPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas
           AppBackgroundGradient(),
            StreamBuilder<List<ApiEnvironment>>(
              stream: repo.watchAll(),
              builder: (context, envSnap) {
                if (!envSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<String>(
                  stream: repo.watchCurrentId(),
                  builder: (context, currentSnap) {
                    final currentId = currentSnap.data ?? '';
                    final envs = envSnap.data!;
                    return ListView(
                      padding: EdgeInsets.only(
                        top: context.dynamicAppBarPadding,
                        left: 16,
                        right: 16,
                        bottom: 100,
                      ),
                      children: [
                        const _Banner()
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: -0.05, end: 0),
                        const SizedBox(height: 16),
                        AppLabel(
                          text: l10n.apiConfigClustersHeading,
                          fontSize: AppFontSize.value11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        const SizedBox(height: 12),
                        for (int idx = 0; idx < envs.length; idx++) ...[
                          _EnvTile(
                            env: envs[idx],
                            currentId: currentId,
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await repo.setCurrent(envs[idx].id);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.apiConfigSwitchedSnack(envs[idx].name)),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(delay: (idx * 60).clamp(0, 300).ms)
                              .slideY(begin: 0.04, end: 0, duration: 300.ms),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: AppLabel(
          text: l10n.apiConfigAddClusterAction,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
        ),
      ).animate().scale(delay: 200.ms),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    Map<String, List<String>> errors = const {};
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppLabel(
                text: l10n.apiConfigAddCustomClusterTitle,
                fontSize: AppFontSize.value16,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.apiConfigClusterNameLabel,
                  hintText: l10n.apiConfigClusterNameHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  errorText: errors['name']?.firstOrNull,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: l10n.apiConfigBaseUrlLabel,
                  hintText: l10n.apiConfigBaseUrlHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  errorText: errors['baseUrl']?.firstOrNull,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      await GetIt.I<ApiEnvironmentsRepository>().createFromInput(
                        name: nameCtrl.text,
                        baseUrl: urlCtrl.text,
                      );
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    } on ValidationFailure catch (f) {
                      setSheet(() => errors = f.fieldErrors);
                    }
                  },
                  child: AppLabel(
                    text: l10n.apiConfigAddClusterAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AppLabel(
              text: l10n.apiConfigBannerWarning,
              fontSize: AppFontSize.value12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvTile extends StatelessWidget {
  const _EnvTile({
    required this.env,
    required this.currentId,
    required this.onTap,
  });

  final ApiEnvironment env;
  final String currentId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSelected = env.id == currentId;

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
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Status Cluster Dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor(env),
                boxShadow: [
                  BoxShadow(
                    color: _dotColor(env).withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppLabel(
                          text: env.name,
                          fontSize: AppFontSize.value14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (env.isBuiltIn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: AppLabel(
                            text: l10n.apiConfigBuiltInBadge,
                            fontSize: AppFontSize.value8,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AppLabel(
                    text: env.baseUrl,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!env.isBuiltIn) ...[
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error.withValues(alpha: 0.8),
                  size: 20,
                ),
                onPressed: () => _deleteEnv(context),
              ),
              const SizedBox(width: 4),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
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

  Color _dotColor(ApiEnvironment e) {
    if (e.isBuiltIn) {
      if (e.name.toLowerCase().contains('prod')) return Colors.green;
      return Colors.blue;
    }
    return Colors.purple;
  }

  Future<void> _deleteEnv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await GetIt.I<ApiEnvironmentsRepository>().deleteGuarded(
        env: env,
        currentEnvironmentId: currentId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.apiConfigDeletedSnack(env.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(f.message ?? l10n.apiConfigCannotDeleteFallback),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
