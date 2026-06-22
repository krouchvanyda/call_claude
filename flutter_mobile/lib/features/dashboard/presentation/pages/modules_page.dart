import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/layout/responsive_breakpoint.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/router/permissions_snapshot.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/shortcuts/module_shortcut.dart';
import '../../../../core/shortcuts/module_shortcut_catalog.dart';
import '../../../../core/shortcuts/permission_filter.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../features/search/presentation/widgets/global_search_anchor.dart';
import '../../../../l10n/app_localizations.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key, PermissionsSnapshot? snapshot})
      : _snapshotOverride = snapshot;

  final PermissionsSnapshot? _snapshotOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final permissions = _snapshotOverride ?? getIt<PermissionsSnapshot>();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.modulesTitle,
        backgroundColor: Colors.transparent,
        actions: const [GlobalSearchAnchor()],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -100,
              right: -100,
              child: CircleAvatar(
                radius: 200,
                backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.05),
              ),
            ),
            
            ListenableBuilder(
              listenable: permissions,
              builder: (context, _) {
                final visible = filterByPermission<ModuleShortcut>(
                  ModuleShortcutCatalog.all,
                  (s) => s.requiredPermission,
                  permissions.permissions,
                ).toList(growable: false);

                if (visible.isEmpty) return _EmptyState(label: l10n.modulesEmpty);

                final size = resolveWindowSizeClass(MediaQuery.sizeOf(context).width);
                final columns = gridColumnsFor(size);
                
                return GridView.builder(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 120,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => _ShortcutTile(shortcut: visible[i], l10n: l10n)
                      .animate()
                      .fadeIn(delay: (i * 50).ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut, required this.l10n});

  final ModuleShortcut shortcut;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          shortcut.builder(),
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shortcut.icon,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              AppLabel(
                text: shortcut.labelOf(l10n),
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppLabel(
              text: label,
              fontSize: AppFontSize.value16,
              color: theme.colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
