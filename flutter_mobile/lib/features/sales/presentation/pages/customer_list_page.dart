import 'dart:ui';
import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
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
import '../../entities/customer.dart';
import '../bloc/customer_list_bloc.dart';
import '../bloc/customer_list_event.dart';
import '../bloc/customer_list_state.dart';
import 'customer_detail_page.dart';
import 'customer_form_page.dart';
import 'sales_analytics_page.dart';

/// Customer list (Slice 6.1.1).
class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerListBloc>(
      create: (_) =>
          getIt<CustomerListBloc>()..add(const CustomerListStarted()),
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
        title: l10n.salesCustomersTitle,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.salesAnalyticsTooltip,
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () =>
                ConfigRouter.pushPageAnimation(context, const SalesAnalyticsPage()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConfigRouter.pushPageAnimation(
          context,
          const CustomerFormPage(),
        ),
        icon: const Icon(Icons.add),
        label: AppLabel(
          text: l10n.customerListNewCustomerAction,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas Gradient
            AppBackgroundGradient(),
            Column(
              children: [
                SizedBox(height: context.dynamicAppBarPadding + 45),
                const _Toolbar(),
                const Expanded(child: _Body()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<CustomerListBloc>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                hintText: l10n.salesCustomersSearchHint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (q) => bloc.add(CustomerListSearchChanged(q)),
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<CustomerListBloc, CustomerListState>(
            buildWhen: (a, b) =>
                a.statusFilter != b.statusFilter ||
                a.segmentFilter != b.segmentFilter ||
                a.sort != b.sort,
            builder: (context, state) => Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final s in CustomerStatus.values) ...[
                          FilterChip(
                            label: AppLabel(
                              text: customerStatusLabel(l10n, s),
                              fontSize: AppFontSize.value13,
                            ),
                            selected: state.statusFilter.contains(s),
                            onSelected: (_) =>
                                bloc.add(CustomerListStatusToggled(s)),
                            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            checkmarkColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        for (final s in CustomerSegment.values) ...[
                          FilterChip(
                            label: AppLabel(
                              text: customerSegmentLabel(l10n, s),
                              fontSize: AppFontSize.value13,
                            ),
                            selected: state.segmentFilter.contains(s),
                            onSelected: (_) =>
                                bloc.add(CustomerListSegmentToggled(s)),
                            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            checkmarkColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: _SortMenu(current: state.sort),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.02, end: 0);
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current});
  final CustomerSort current;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<CustomerSort>(
      tooltip: l10n.salesCustomersSortTooltip,
      icon: const Icon(Icons.sort),
      initialValue: current,
      onSelected: (s) =>
          context.read<CustomerListBloc>().add(CustomerListSortChanged(s)),
      itemBuilder: (_) => [
        for (final s in CustomerSort.values)
          PopupMenuItem(
            value: s,
            child: AppLabel(
              text: _sortLabel(l10n, s),
              fontSize: AppFontSize.value14,
            ),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CustomerListBloc, CustomerListState>(
      builder: (context, state) {
        if (state.isLoading && state.source.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.source.isEmpty) {
          return _CenteredMessage(
              text: l10n.salesCustomersError(state.errorMessage!));
        }
        if (state.visible.isEmpty) {
          return _CenteredMessage(text: l10n.salesCustomersEmpty);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          physics: const BouncingScrollPhysics(),
          itemCount: state.visible.length,
          itemBuilder: (_, i) => _Tile(customer: state.visible[i]),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.customer});
  final Customer customer;
  static final _date = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = customerStatusColor(theme, customer.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business_outlined, color: color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: AppLabel(
                  text: customer.name,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomerStatusBadge(status: customer.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: AppLabel(
              text:
                  '${customerSegmentLabel(l10n, customer.segment)} • ${l10n.salesCustomersOnboardedLabel(_date.format(customer.onboardedAt.toLocal()))}',
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLabel(
                text: customer.lifetimeValue,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
          onTap: () => ConfigRouter.pushPageAnimation(
            context,
            CustomerDetailPage(customerId: customer.id),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.02, end: 0);
  }
}

class CustomerStatusBadge extends StatelessWidget {
  const CustomerStatusBadge({super.key, required this.status});
  final CustomerStatus status;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = customerStatusColor(theme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: AppLabel(
        text: customerStatusLabel(l10n, status),
        fontSize: AppFontSize.value11,
        color: color,
        fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business_outlined,
                  size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value14,
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

String customerStatusLabel(AppLocalizations l10n, CustomerStatus s) {
  return switch (s) {
    CustomerStatus.prospect => l10n.salesStatusProspect,
    CustomerStatus.active => l10n.salesStatusActive,
    CustomerStatus.onHold => l10n.salesStatusOnHold,
    CustomerStatus.churned => l10n.salesStatusChurned,
  };
}

Color customerStatusColor(ThemeData theme, CustomerStatus s) {
  return switch (s) {
    CustomerStatus.prospect => theme.colorScheme.secondary,
    CustomerStatus.active => theme.colorScheme.tertiary,
    CustomerStatus.onHold => theme.colorScheme.error,
    CustomerStatus.churned => theme.colorScheme.outline,
  };
}

String customerSegmentLabel(AppLocalizations l10n, CustomerSegment s) {
  return switch (s) {
    CustomerSegment.smb => l10n.salesSegmentSmb,
    CustomerSegment.midMarket => l10n.salesSegmentMidMarket,
    CustomerSegment.enterprise => l10n.salesSegmentEnterprise,
  };
}

String _sortLabel(AppLocalizations l10n, CustomerSort s) {
  return switch (s) {
    CustomerSort.nameAsc => l10n.salesCustomersSortName,
    CustomerSort.lifetimeValueDesc => l10n.salesCustomersSortLtv,
    CustomerSort.recentlyAdded => l10n.salesCustomersSortRecent,
  };
}
