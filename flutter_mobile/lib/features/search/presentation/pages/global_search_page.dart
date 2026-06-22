import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/router/permissions_snapshot.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/shortcuts/module_shortcut_catalog.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/providers/module_shortcut_search_provider.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/federated_search.dart';
import '../bloc/global_search_bloc.dart';
import '../bloc/global_search_event.dart';
import '../bloc/global_search_state.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = getIt<PermissionsSnapshot>();
    final theme = Theme.of(context);

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
      child: BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
        builder: (context, state) {
          final bloc = context.read<GlobalSearchBloc>();

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: DynamicAppBar(
              title: '',
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: l10n.globalSearchHint,
                        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  bloc.add(const GlobalSearchEvent.cleared());
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onChanged: (q) {
                        bloc.add(GlobalSearchEvent.queryChanged(q));
                        setState(() {});
                      },
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                ),
              ),
            ),
            body: DynamicStatusBar(
              child: _SuggestionsBody(
                state: state,
                onTapResult: (result) {
                  bloc.add(const GlobalSearchEvent.cleared());
                  if (result.providerId == 'modules') {
                    for (final s in ModuleShortcutCatalog.all) {
                      if (s.id == result.id) {
                        ConfigRouter.pushPageAnimation(context, s.builder());
                        break;
                      }
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionsBody extends StatelessWidget {
  const _SuggestionsBody({required this.state, required this.onTapResult});

  final GlobalSearchState state;
  final ValueChanged<SearchResult> onTapResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
      ),
      child: switch (state) {
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
      },
    );
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        for (var gIdx = 0; gIdx < groups.length; gIdx++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
            child: Row(
              children: [
                AppLabel(
                  text: _providerHeader(context, groups[gIdx].providerId).toUpperCase(),
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (gIdx * 100).ms),
          for (var rIdx = 0; rIdx < groups[gIdx].results.length; rIdx++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ResultTile(
                result: groups[gIdx].results[rIdx],
                onTap: () => onTap(groups[gIdx].results[rIdx]),
              ).animate().fadeIn(delay: (gIdx * 100 + rIdx * 30).ms).slideX(begin: 0.05, end: 0),
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
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
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
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    if (result.subtitle != null)
                      AppLabel(
                        text: result.subtitle!,
                        fontSize: AppFontSize.value12,
                        color: theme.colorScheme.onSurfaceVariant,
                        lineHeight: 1.4,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline, size: 22),
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
        padding: const EdgeInsets.all(40),
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
              const SizedBox(height: 24),
            ],
            DefaultTextStyle(
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
