import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/vendors_repository.dart';
import '../../entities/vendor.dart';
import 'vendor_detail_page.dart';
import 'vendor_form_page.dart';

class VendorListPage extends StatelessWidget {
  const VendorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<VendorsRepository>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.vendorListTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<List<Vendor>>(
          future: repo.getAll(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final vendors = snap.data ?? const <Vendor>[];
            if (vendors.isEmpty) {
              return _CenteredMessage(text: l10n.vendorListEmpty, icon: Icons.storefront_rounded);
            }
            return ListView.builder(
              padding: EdgeInsets.only(
                top: context.dynamicAppBarPadding,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              itemCount: vendors.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VendorCard(vendor: vendors[i])
                    .animate()
                    .fadeIn(delay: (i * 30).ms)
                    .slideY(begin: 0.05, end: 0),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConfigRouter.pushPageAnimation(context, const VendorFormPage()),
        icon: const Icon(Icons.add_business_rounded),
        label: AppLabel(
          text: l10n.vendorListNewTooltip,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w600,
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = vendorStatusColor(theme, vendor.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ConfigRouter.pushPageAnimation(
          context,
          VendorDetailPage(vendorId: vendor.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront_rounded, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(
                      text: vendor.name,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AppLabel(
                      text: '${vendor.taxId} · ${vendor.email}',
                      fontSize: AppFontSize.value11,
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              VendorStatusBadge(status: vendor.status),
            ],
          ),
        ),
      ),
    );
  }
}

class VendorStatusBadge extends StatelessWidget {
  const VendorStatusBadge({super.key, required this.status});
  final VendorStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = vendorStatusColor(theme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AppLabel(
        text: vendorStatusLabel(l10n, status).toUpperCase(),
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
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), shape: BoxShape.circle),
              child: Icon(icon ?? Icons.storefront_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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

String vendorStatusLabel(AppLocalizations l10n, VendorStatus s) {
  return switch (s) {
    VendorStatus.active => l10n.vendorStatusActive,
    VendorStatus.onHold => l10n.vendorStatusOnHold,
    VendorStatus.archived => l10n.vendorStatusArchived,
  };
}

Color vendorStatusColor(ThemeData theme, VendorStatus s) {
  return switch (s) {
    VendorStatus.active => theme.colorScheme.primary,
    VendorStatus.onHold => theme.colorScheme.error,
    VendorStatus.archived => theme.colorScheme.outline,
  };
}
