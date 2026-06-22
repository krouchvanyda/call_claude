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
import '../../data/repositories/security_repositories.dart';
import '../../entities/device_session.dart';

/// Slice 9.3.1 — active devices list with revoke actions.
class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GetIt.I<DeviceSessionsRepository>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.sessionsPageTitle,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) async {
              final messenger = ScaffoldMessenger.of(context);
              if (action == 'revoke-others') {
                await repo.revokeAllOthers();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.sessionsSignOutOthersSnack),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'revoke-others',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.sessionsSignOutOthersAction),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas
            AppBackgroundGradient(),
            StreamBuilder<List<DeviceSession>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = snap.data!;
                if (sessions.isEmpty) {
                  return Center(
                    child: AppLabel(
                      text: l10n.sessionsEmpty,
                      fontSize: AppFontSize.value14,
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.only(
                    top: context.dynamicAppBarPadding,
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, idx) => _SessionCard(session: sessions[idx])
                      .animate()
                      .fadeIn(delay: (idx * 100).ms)
                      .slideY(begin: 0.05, end: 0, duration: 350.ms),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final DeviceSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: session.isCurrent
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: session.isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (session.isCurrent ? theme.colorScheme.primary : Colors.grey)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _platformIcon(session.platform),
                  color: session.isCurrent ? theme.colorScheme.primary : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppLabel(
                            text: session.deviceLabel,
                            fontSize: AppFontSize.value14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (session.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: AppLabel(
                              text: l10n.sessionsThisDeviceLabel,
                              fontSize: AppFontSize.value10,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AppLabel(
                      text: session.platform,
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _kv(context, l10n.sessionsLastActiveLabel, _fmt(session.lastActiveAt, withTime: true)),
          _kv(context, l10n.sessionsSignedInLabel, _fmt(session.signedInAt)),
          _kv(context, l10n.sessionsLocationLabel, session.location),
          if (session.ipAddress != null)
            _kv(context, l10n.sessionsIpAddressLabel, session.ipAddress!),
          if (!session.isCurrent) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 16),
                label: AppLabel(
                  text: l10n.sessionsRevokeAccessAction,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () => _revoke(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await GetIt.I<DeviceSessionsRepository>().revokeGuarded(session);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sessionsRevokedSnack(session.deviceLabel)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConflictFailure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(f.message ?? 'Cannot revoke.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _kv(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: AppLabel(
              text: label,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: AppLabel(
              text: value,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.android;
    if (p.contains('ios') || p.contains('ipad')) return Icons.phone_iphone;
    if (p.contains('mac') || p.contains('web')) return Icons.laptop_mac;
    return Icons.devices_other;
  }

  String _fmt(DateTime dt, {bool withTime = false}) {
    final iso = dt.toIso8601String();
    if (!withTime) return iso.split('T').first;
    return iso.split('.').first.replaceFirst('T', ' ');
  }
}
