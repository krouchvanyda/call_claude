import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
import 'vendor_list_page.dart' show VendorStatusBadge;
import 'vendor_scorecard_page.dart';

class VendorDetailPage extends StatelessWidget {
  const VendorDetailPage({super.key, required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<VendorsRepository>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.vendorDetailTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<Vendor?>(
          future: repo.findById(vendorId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final v = snap.data;
            if (v == null) {
              return _CenteredMessage(text: l10n.vendorDetailNotFound(vendorId), icon: Icons.search_off_rounded);
            }
            return _Body(vendor: v);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vendor});
  final Vendor vendor;
  static final _date = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 100,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.storefront_rounded, color: theme.colorScheme.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: vendor.name,
                          fontSize: AppFontSize.value24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        const SizedBox(height: 4),
                        VendorStatusBadge(status: vendor.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Wrap(
                spacing: 32,
                runSpacing: 20,
                children: [
                  _MetaItem(label: l10n.vendorDetailTaxIdLabel, value: vendor.taxId, icon: Icons.badge_rounded),
                  _MetaItem(label: l10n.vendorDetailOnboardedLabel, value: _date.format(vendor.onboardedAt), icon: Icons.verified_user_rounded),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.vendorDetailContactHeading.toUpperCase(),
          icon: Icons.contact_mail_rounded,
          child: Column(
            children: [
              if (vendor.contactPerson != null)
                _ContactRow(label: l10n.vendorDetailContactPersonLabel, value: vendor.contactPerson!, icon: Icons.person_rounded),
              _ContactRow(label: l10n.vendorDetailEmailLabel, value: vendor.email, icon: Icons.alternate_email_rounded),
              _ContactRow(label: l10n.vendorDetailPhoneLabel, value: vendor.phone, icon: Icons.phone_rounded),
              _ContactRow(label: l10n.vendorDetailAddressLabel, value: vendor.address, icon: Icons.location_on_rounded, isLast: true),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
        
        if (vendor.notes != null) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.vendorDetailNotesHeading.toUpperCase(),
            icon: Icons.speaker_notes_rounded,
            child: AppLabel(
              text: vendor.notes!,
              fontSize: AppFontSize.value14,
              lineHeight: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
        ],
        
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.insights_rounded),
            label: AppLabel(
              text: l10n.vendorDetailScorecardAction.toUpperCase(),
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
            onPressed: () => ConfigRouter.pushPageAnimation(
              context,
              VendorScorecardPage(vendorId: vendor.id),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            AppLabel(
              text: label.toUpperCase(),
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value16,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              AppLabel(
                text: title,
                fontSize: AppFontSize.value11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.value, required this.icon, this.isLast = false});
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: label.toUpperCase(),
                  fontSize: AppFontSize.value8,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                const SizedBox(height: 2),
                AppLabel(
                  text: value,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
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
            Icon(icon ?? Icons.storefront_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value16,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
