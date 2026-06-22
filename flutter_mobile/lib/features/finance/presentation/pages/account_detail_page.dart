import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../entities/account.dart';
import '../../entities/transaction.dart';
import '../account_type_visual.dart';
import '../bloc/account_detail_bloc.dart';
import '../bloc/account_detail_event.dart';
import '../bloc/account_detail_state.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountDetailBloc>(
      create: (_) => getIt<AccountDetailBloc>()
        ..add(AccountDetailEvent.started(accountId)),
      child: _DetailView(accountId: accountId),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.accountDetailTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: BlocBuilder<AccountDetailBloc, AccountDetailState>(
          builder: (context, state) => switch (state) {
            AccountDetailInitial() ||
            AccountDetailLoading() =>
              const Center(child: CircularProgressIndicator()),
            AccountDetailFailure(:final message) =>
              _CenteredMessage(text: l10n.accountDetailError(message)),
            AccountDetailNotFound(:final accountId) =>
              _CenteredMessage(
                icon: Icons.search_off_rounded,
                text: l10n.accountDetailNotFound(accountId),
              ),
            AccountDetailLoaded(:final account, :final transactions) =>
              _LoadedBody(account: account, transactions: transactions),
          },
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.account, required this.transactions});

  final Account account;
  final List<LedgerTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: context.dynamicAppBarPadding,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: _AccountHeaderCard(account: account),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: AppLabel(
              text: AppLocalizations.of(context).accountDetailTransactionsHeading,
              fontSize: AppFontSize.value11,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (transactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _CenteredMessage(
              text: AppLocalizations.of(context).accountDetailNoTransactions,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _TransactionTile(transaction: transactions[i])
                      .animate()
                      .fadeIn(delay: (i * 20).ms)
                      .slideX(begin: 0.05, end: 0),
                ),
                childCount: transactions.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: AppLabel(
                  text: account.code,
                  fontSize: AppFontSize.value12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Icon(accountTypeIcon(account.type), color: Colors.white.withValues(alpha: 0.7), size: 24),
            ],
          ),
          const SizedBox(height: 20),
          AppLabel(
            text: account.name,
            fontSize: AppFontSize.value24,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 4),
          AppLabel(
            text: accountTypeLabel(l10n, account.type).toUpperCase(),
            fontSize: AppFontSize.value11,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: l10n.accountDetailCurrentBalanceLabel,
                    fontSize: AppFontSize.value11,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppLabel(
                    text: account.formattedBalance ?? '—',
                    fontSize: AppFontSize.value36,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final LedgerTransaction transaction;
  static final _dateFormatter = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = transaction;
    final isDebit = t.debit != null;
    final amountText = t.debit ?? t.credit ?? '—';
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDebit
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.tertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDebit ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 20,
                color: isDebit ? theme.colorScheme.primary : theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: t.description,
                    fontSize: AppFontSize.value16,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AppLabel(
                    text:
                        '${_dateFormatter.format(t.postedAt)} ${t.reference != null ? "· ${t.reference}" : ""}',
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppLabel(
                  text: amountText,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w800,
                  color: isDebit ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                AppLabel(
                  text: t.runningBalance,
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.outline,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.icon});

  final String text;
  final IconData? icon;

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
                icon ?? Icons.receipt_long_outlined,
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
