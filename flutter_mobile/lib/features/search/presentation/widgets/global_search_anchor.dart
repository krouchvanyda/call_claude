import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/router/permissions_snapshot.dart';
import '../../../../core/shortcuts/module_shortcut_catalog.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/providers/module_shortcut_search_provider.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/federated_search.dart';
import '../bloc/global_search_bloc.dart';
import '../bloc/global_search_event.dart';
import '../bloc/global_search_state.dart';

class GlobalSearchAnchor extends StatelessWidget {
  const GlobalSearchAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = getIt<PermissionsSnapshot>();

    return BlocProvider<GlobalSearchBloc>(
      create: (_) => GlobalSearchBloc(
        federatedSearch: FederatedSearchUseCase(
          providers: [
            ModuleShortcutSearchProvider(
              labelOf: (s) => s.labelOf(l10n),
              shortcutHeld: permissions.holds,
            ),
          ],
          holds: permissions.holds,
        ),
      ),
      child: const _GlobalSearchAnchorView(),
    );
  }
}

class _GlobalSearchAnchorView extends StatelessWidget {
  const _GlobalSearchAnchorView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<GlobalSearchBloc>();
    final theme = Theme.of(context);

    return SearchAnchor(
      isFullScreen: true,
      builder: (context, controller) => IconButton(
        tooltip: l10n.globalSearchTooltip,
        icon: const Icon(Icons.search_rounded),
        onPressed: controller.openView,
      ),
      viewHintText: l10n.globalSearchHint,
      viewLeading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      viewOnChanged: (q) => bloc.add(GlobalSearchEvent.queryChanged(q)),
      viewOnSubmitted: (q) => bloc.add(GlobalSearchEvent.queryChanged(q)),
      suggestionsBuilder: (context, controller) {
        return [
          BlocProvider<GlobalSearchBloc>.value(
            value: bloc,
            child: BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
              builder: (context, state) => _SuggestionsBody(
                state: state,
                onTapResult: (result) {
                  controller.closeView(result.title);
                  bloc.add(const GlobalSearchEvent.cleared());
                  final page = _pageForResult(result);
                  if (page != null) {
                    ConfigRouter.pushPageAnimation(context, page);
                  }
                },
              ),
            ),
          ),
        ];
      },
    );
  }
}

/// Resolves a [SearchResult] to the page widget it should push.
///
/// `SearchResult` deliberately carries no `Widget Function()` field
/// (keeps the entity Flutter-free for pure-Dart tests). Dispatch happens
/// here on `(providerId, id)`: the modules provider's results map 1:1
/// to [ModuleShortcutCatalog] entries by `id`. Returns `null` when no
/// match is found so the caller can no-op.
Widget? _pageForResult(SearchResult result) {
  if (result.providerId == 'modules') {
    for (final s in ModuleShortcutCatalog.all) {
      if (s.id == result.id) return s.builder();
    }
  }
  return null;
}

class _SuggestionsBody extends StatelessWidget {
  const _SuggestionsBody({required this.state, required this.onTapResult});

  final GlobalSearchState state;
  final ValueChanged<SearchResult> onTapResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (state) {
      GlobalSearchIdle() => _Centered(
          icon: Icons.manage_search_rounded,
          child: Text(l10n.globalSearchPrompt),
        ),
      GlobalSearchLoading() => const _Centered(
          child: CircularProgressIndicator(),
        ),
      GlobalSearchFailure(:final message) => _Centered(
          icon: Icons.error_outline_rounded,
          child: Text(l10n.globalSearchError(message)),
        ),
      GlobalSearchSuccess(:final query, :final groups) => groups.isEmpty
          ? _Centered(
              icon: Icons.search_off_rounded,
              child: Text(l10n.globalSearchNoResults(query)),
            )
          : _GroupedResultsList(groups: groups, onTap: onTapResult),
    };
  }
}

class _GroupedResultsList extends StatelessWidget {
  const _GroupedResultsList({required this.groups, required this.onTap});

  final List<SearchResultGroup> groups;
  final ValueChanged<SearchResult> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (var gIdx = 0; gIdx < groups.length; gIdx++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Row(
              children: [
                AppLabel(
                  text: _providerHeader(context, groups[gIdx].providerId).toUpperCase(),
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                const SizedBox(width: 8),
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
              ],
            ),
          ),
          for (var rIdx = 0; rIdx < groups[gIdx].results.length; rIdx++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ResultTile(
                result: groups[gIdx].results[rIdx],
                onTap: () => onTap(groups[gIdx].results[rIdx]),
              ),
            ),
        ],
      ],
    );
  }

  String _providerHeader(BuildContext context, String providerId) {
    final l10n = AppLocalizations.of(context);
    return switch (providerId) {
      'modules' => l10n.shellModules,
      _ => providerId,
    };
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(result), color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(
                      text: result.title,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w600,
                    ),
                    if (result.subtitle != null)
                      AppLabel(
                        text: result.subtitle!,
                        fontSize: AppFontSize.value12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SearchResult r) {
    if (r.providerId != 'modules') return Icons.description_outlined;
    for (final s in ModuleShortcutCatalog.all) {
      if (s.id == r.id) return s.icon;
    }
    return Icons.search_rounded;
  }
}

class _Centered extends StatelessWidget {
  const _Centered({this.icon, required this.child});
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: theme.colorScheme.outline.withOpacity(0.4)),
              ),
              const SizedBox(height: 16),
            ],
            DefaultTextStyle(
              style: theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
