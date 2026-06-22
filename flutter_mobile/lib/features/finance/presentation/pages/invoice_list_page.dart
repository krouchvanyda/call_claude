import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/invoices_repository.dart';
import '../../entities/invoice.dart';
import '../bloc/invoice_list_bloc.dart';
import '../bloc/invoice_list_event.dart';
import '../bloc/invoice_list_state.dart';
import 'invoice_detail_page.dart';
import 'invoice_form_page.dart';

class InvoiceListPage extends StatelessWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceListBloc>(
      create: (_) => getIt<InvoiceListBloc>()
        ..add(const InvoiceListEvent.started()),
      child: const _ListView(),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.invoiceListTitle,
        actions: [
          _SortAction(),
        ],
      ),
      body: DynamicStatusBar(
        child: Column(
          children: [
            _Toolbar(),
            const Expanded(child: _Body()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConfigRouter.pushPageAnimation(context, const InvoiceFormPage()),
        icon: const Icon(Icons.add_rounded),
        label: AppLabel(
          text: l10n.invoiceFormCreateTitle,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w600,
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

class _SortAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      buildWhen: (a, b) => a.sort != b.sort,
      builder: (context, state) => PopupMenuButton<InvoiceSort>(
        tooltip: l10n.invoiceListSortTooltip,
        icon: const Icon(Icons.sort_rounded),
        initialValue: state.sort,
        onSelected: (s) =>
            context.read<InvoiceListBloc>().add(InvoiceListEvent.sortChanged(s)),
        itemBuilder: (_) => [
          for (final s in InvoiceSort.values)
            PopupMenuItem(
              value: s,
              child: AppLabel(
                text: _sortLabel(l10n, s),
                fontSize: AppFontSize.value14,
              ),
            ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<InvoiceListBloc>();
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                hintText: l10n.invoiceListSearchHint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (q) => bloc.add(InvoiceListEvent.searchChanged(q)),
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          BlocBuilder<InvoiceListBloc, InvoiceListState>(
            buildWhen: (a, b) => a.statusFilter != b.statusFilter,
            builder: (context, state) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in InvoiceStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: AppLabel(
                          text: invoiceStatusLabel(l10n, s),
                          fontSize: AppFontSize.value13,
                        ),
                        selected: state.statusFilter.contains(s),
                        onSelected: (_) => bloc.add(
                          InvoiceListEvent.statusToggled(s),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: state.statusFilter.contains(s) 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: state.statusFilter.contains(s) 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      builder: (context, state) {
        if (state.isLoading && state.source.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.source.isEmpty) {
          return _CenteredMessage(
            text: l10n.invoiceListError(state.errorMessage!),
            icon: Icons.error_outline_rounded,
          );
        }
        if (state.visible.isEmpty) {
          return _CenteredMessage(
            text: l10n.invoiceListEmpty,
            icon: Icons.receipt_long_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: state.visible.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InvoiceCard(invoice: state.visible[i])
                .animate()
                .fadeIn(delay: (i * 30).ms)
                .slideY(begin: 0.05, end: 0),
          ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});
  final Invoice invoice;

  static final _date = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = invoiceStatusColor(theme, invoice.status);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          InvoiceDetailPage(invoiceId: invoice.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: invoice.invoiceNumber,
                          fontSize: AppFontSize.value16,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        const SizedBox(height: 2),
                        AppLabel(
                          text: invoice.customerName,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: invoice.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLabel(
                        text: l10n.invoiceListIssuedDateLabel(_date.format(invoice.issuedAt)),
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                      AppLabel(
                        text: l10n.invoiceListDueLabel(_date.format(invoice.dueAt)).toUpperCase(),
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  AppLabel(
                    text: invoice.totalAmount,
                    fontSize: AppFontSize.value24,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = invoiceStatusColor(theme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppLabel(
        text: invoiceStatusLabel(l10n, status).toUpperCase(),
        fontSize: AppFontSize.value9,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
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
                icon ?? Icons.receipt_long_rounded,
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

String invoiceStatusLabel(AppLocalizations l10n, InvoiceStatus s) {
  return switch (s) {
    InvoiceStatus.draft => l10n.invoiceStatusDraft,
    InvoiceStatus.pendingApproval => l10n.invoiceStatusPendingApproval,
    InvoiceStatus.approved => l10n.invoiceStatusApproved,
    InvoiceStatus.rejected => l10n.invoiceStatusRejected,
  };
}

Color invoiceStatusColor(ThemeData theme, InvoiceStatus s) {
  return switch (s) {
    InvoiceStatus.draft => theme.colorScheme.outline,
    InvoiceStatus.pendingApproval => theme.colorScheme.primary,
    InvoiceStatus.approved => theme.colorScheme.tertiary,
    InvoiceStatus.rejected => theme.colorScheme.error,
  };
}

String _sortLabel(AppLocalizations l10n, InvoiceSort s) {
  return switch (s) {
    InvoiceSort.issuedDateDesc => l10n.invoiceSortIssuedDesc,
    InvoiceSort.issuedDateAsc => l10n.invoiceSortIssuedAsc,
    InvoiceSort.dueDateAsc => l10n.invoiceSortDueAsc,
    InvoiceSort.amountDesc => l10n.invoiceSortAmountDesc,
    InvoiceSort.numberAsc => l10n.invoiceSortNumberAsc,
  };
}
