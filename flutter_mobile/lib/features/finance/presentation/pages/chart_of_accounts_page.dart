import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../entities/account_tree_node.dart';
import '../account_type_visual.dart';
import '../bloc/account_tree_bloc.dart';
import '../bloc/account_tree_event.dart';
import '../bloc/account_tree_state.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import 'account_detail_page.dart';
class ChartOfAccountsPage extends StatelessWidget {
  const ChartOfAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountTreeBloc>(
      create: (_) => getIt<AccountTreeBloc>()
        ..add(const AccountTreeEvent.started()),
      child: const _ChartView(),
    );
  }
}

class _ChartView extends StatelessWidget {
  const _ChartView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.chartOfAccountsTitle,
        actions: [
          BlocBuilder<AccountTreeBloc, AccountTreeState>(
            buildWhen: (a, b) =>
                (a is AccountTreeLoaded) != (b is AccountTreeLoaded),
            builder: (context, state) {
              if (state is! AccountTreeLoaded) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.chartOfAccountsExpandAll,
                    icon: const Icon(Icons.unfold_more_rounded),
                    onPressed: () => context
                        .read<AccountTreeBloc>()
                        .add(const AccountTreeEvent.expandedAll()),
                  ),
                  IconButton(
                    tooltip: l10n.chartOfAccountsCollapseAll,
                    icon: const Icon(Icons.unfold_less_rounded),
                    onPressed: () => context
                        .read<AccountTreeBloc>()
                        .add(const AccountTreeEvent.collapsedAll()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            BlocBuilder<AccountTreeBloc, AccountTreeState>(
              builder: (context, state) => switch (state) {
                AccountTreeInitial() ||
                AccountTreeLoading() =>
                  const Center(child: CircularProgressIndicator()),
                AccountTreeFailure(:final message) =>
                  _CenteredMessage(text: l10n.chartOfAccountsError(message)),
                AccountTreeLoaded(:final roots, :final expandedIds) => roots.isEmpty
                    ? _CenteredMessage(text: l10n.chartOfAccountsEmpty)
                    : _AccountTreeList(roots: roots, expandedIds: expandedIds),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTreeList extends StatelessWidget {
  const _AccountTreeList({required this.roots, required this.expandedIds});

  final List<AccountTreeNode> roots;
  final Set<String> expandedIds;

  @override
  Widget build(BuildContext context) {
    final visible = <AccountTreeNode>[];
    void walk(List<AccountTreeNode> nodes) {
      for (final n in nodes) {
        visible.add(n);
        if (expandedIds.contains(n.account.id)) walk(n.children);
      }
    }

    walk(roots);

    return ListView.builder(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        bottom: 100,
        left: 16,
        right: 16,
      ),
      itemCount: visible.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _AccountRow(
          node: visible[i],
          expanded: expandedIds.contains(visible[i].account.id),
        ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.05, end: 0),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.node, required this.expanded});

  final AccountTreeNode node;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = node.account;
    final bloc = context.read<AccountTreeBloc>();
    
    final isLeaf = node.isLeaf;
    
    return Container(
      margin: EdgeInsetsDirectional.only(start: 20.0 * node.depth),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              accountTypeIcon(account.type),
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              AppLabel(
                text: account.code,
                fontSize: AppFontSize.value12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppLabel(
                  text: account.name,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: account.formattedBalance == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AppLabel(
                    text: account.formattedBalance!,
                    fontSize: AppFontSize.value14,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          trailing: isLeaf
              ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline)
              : AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
          onTap: isLeaf
              ? () => ConfigRouter.pushPageAnimation(
                    context,
                    AccountDetailPage(accountId: account.id),
                  )
              : () => bloc.add(AccountTreeEvent.nodeToggled(account.id)),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_outlined,
                size: 64, 
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value16,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
