import 'package:erp_mobile/shared/widgets/app_background_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/security/app_permissions.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../core/widgets/loading_screen.dart';
import '../../../../features/auth/data/datasources/cached_user_dao.dart';
import '../../../../features/auth/entities/user.dart';
import '../../../../l10n/app_localizations.dart';
import 'api_config_page.dart';
import 'app_lock_page.dart';
import 'appearance_page.dart';
import 'assignments_page.dart';
import 'audit_log_page.dart';
import 'language_page.dart';
import 'my_profile_page.dart';
import 'my_roles_page.dart';
import 'notification_preferences_page.dart';
import 'role_editor_page.dart';
import 'sessions_page.dart';
import 'user_management_page.dart';

/// Module 9 settings hub. Groups every sub-page from Phases 9.1–9.3
/// into three sections so the user can scan the surface at a glance.
class SettingsHomePage extends StatefulWidget {
  const SettingsHomePage({super.key, required this.onSignOut});

  /// Full sign-out orchestrator — wired in `app_router.dart` to
  /// `AuthRepository.signOut()`, which revokes the refresh token,
  /// clears `flutter_secure_storage`, wipes the drift cache, and then
  /// flips the `AuthSession` so the router bounces to `/login`.
  ///
  /// Returns a `Future` so the button can show a spinner during the
  /// network round-trip (~100–500ms typical) and we can `await` to
  /// catch errors from the local-cleanup step.
  final Future<void> Function() onSignOut;

  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  bool _signingOut = false;

  /// Two-step: confirm → execute. The confirm dialog blocks accidental
  /// taps; the loading state on the button prevents double-fire while
  /// the round-trip is in flight.
  Future<void> _handleSignOut() async {
    if (_signingOut) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: AppLabel(
          text: l10n.settingsHomeSignOutConfirmTitle,
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.bold,
        ),
        content: AppLabel(
          text: l10n.settingsHomeSignOutConfirmMessage,
          fontSize: AppFontSize.value14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: AppLabel(
              text: l10n.commonCancelAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: AppLabel(
              text: l10n.settingsHomeSignOutAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
      // Note: no need to flip _signingOut back — by the time the
      // AuthRepository.signOut() completes, the router has already
      // bounced this page off-stack via the SessionSignal/AuthSession
      // notification. The setState below only runs on the unhappy path.
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.settingsHomeSignOutErrorSnack),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(title: l10n.settingsHomePageTitle, centerTitle: true),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            // Background Canvas
            AppBackgroundGradient(),
            ListView(
              padding: EdgeInsets.only(
                top: context.dynamicAppBarPadding + 60,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              children: [

                // Account Group — Slices 9.1.4 / 9.1.5.
                _Section(
                  title: l10n.settingsHomeAccountSection,
                  children: [
                    _Tile(
                      icon: Icons.person_outline,
                      title: l10n.settingsHomeMyProfileTitle,
                      subtitle: l10n.settingsHomeMyProfileSubtitle,
                      page: const MyProfilePage(),
                      color: Colors.deepPurple,
                    ),
                    const Divider(height: 1, indent: 56),
                    _Tile(
                      icon: Icons.shield_outlined,
                      title: l10n.settingsHomeMyRolesTitle,
                      subtitle: l10n.settingsHomeMyRolesSubtitle,
                      page: const MyRolesPage(),
                      color: Colors.cyan.shade700,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 80.ms)
                    .slideY(begin: 0.05, end: 0, duration: 300.ms),

                const SizedBox(height: 20),

                // Preferences Group
                _Section(
                      title: l10n.settingsHomePreferencesSection,
                      children: [
                        _Tile(
                          icon: Icons.brightness_6_outlined,
                          title: l10n.settingsHomeAppearanceTitle,
                          subtitle: l10n.settingsHomeAppearanceSubtitle,
                          page: const AppearancePage(),
                          color: Colors.blue,
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.language_outlined,
                          title: l10n.settingsHomeLanguageTitle,
                          subtitle: l10n.settingsHomeLanguageSubtitle,
                          page: const LanguagePage(),
                          color: Colors.indigo,
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.notifications_outlined,
                          title: l10n.settingsHomeNotificationsTitle,
                          subtitle: l10n.settingsHomeNotificationsSubtitle,
                          page: const NotificationPreferencesPage(),
                          color: Colors.amber.shade800,
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.05, end: 0, duration: 300.ms),

                const SizedBox(height: 20),

                // Security Group
                _Section(
                      title: l10n.settingsHomeSecuritySection,
                      children: [
                        _Tile(
                          icon: Icons.devices_other_outlined,
                          title: l10n.settingsHomeActiveDevicesTitle,
                          subtitle: l10n.settingsHomeActiveDevicesSubtitle,
                          page: const SessionsPage(),
                          color: Colors.teal,
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.history_edu_outlined,
                          title: l10n.settingsHomeAuditLogTitle,
                          subtitle: l10n.settingsHomeAuditLogSubtitle,
                          page: const AuditLogPage(),
                          color: Colors.deepPurple,
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.lock_outline,
                          title: l10n.settingsHomeAppLockTitle,
                          subtitle: l10n.settingsHomeAppLockSubtitle,
                          page: const AppLockPage(),
                          color: Colors.pink,
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 300.ms),

                const SizedBox(height: 20),

                // Administration Group — super-admin only. Hidden
                // entirely from regular admins / staff so the surface
                // matches the policy. Stream comes from the cached
                // user (populated by AuthRepository.login) — no
                // extra network call on every Settings open.
                StreamBuilder<User?>(
                  stream: GetIt.I<CachedUserDao>().watchCurrentUser(),
                  builder: (context, snap) {
                    final user = snap.data;
                    // TEMP DEBUG — remove once the gate is confirmed
                    // working. Prints exactly what's in the cached
                    // user's `roles` set so we can see why the
                    // isSuperAdmin check is matching/missing.
                    debugPrint(
                      '[SettingsHome] cached user=${user?.id} '
                      'roles=${user?.roles} '
                      'isSuperAdmin=${isSuperAdmin(user?.roles ?? const <String>{})}',
                    );
                    final isAdmin =
                        isSuperAdmin(user?.roles ?? const <String>{});
                    if (!isAdmin) return const SizedBox.shrink();
                    return _Section(
                      title: l10n.settingsHomeAdminSection,
                      children: [
                        _Tile(
                          icon: Icons.people_alt_outlined,
                          title: l10n.settingsHomeUserMgmtTitle,
                          subtitle: l10n.settingsHomeUserMgmtSubtitle,
                          page: const UserManagementPage(),
                          color: Colors.orange.shade700,
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.shield_outlined,
                          title: l10n.settingsHomeRolesPermsTitle,
                          subtitle: l10n.settingsHomeRolesPermsSubtitle,
                          page: const RoleEditorPage(),
                          color: Colors.cyan.shade700,
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.tune_rounded,
                          title: l10n.assignmentsPageTitle,
                          subtitle: l10n.assignmentsRolesTab,
                          page: const AssignmentsPage(),
                          color: Colors.deepPurple,
                          // Assignments page pops with `true` after a
                          // successful bulk save so the snackbar can be
                          // shown HERE — using the settings page's own
                          // ScaffoldMessenger, which is still alive
                          // after the pop. Showing it from inside the
                          // assignments route would flash and vanish
                          // because that route's messenger is gone.
                          onResult: (result) {
                            if (result == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.assignmentsSavedSnack),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        _Tile(
                          icon: Icons.cloud_outlined,
                          title: l10n.settingsHomeApiConfigTitle,
                          subtitle: l10n.settingsHomeApiConfigSubtitle,
                          page: const ApiConfigPage(),
                          color: Colors.blueGrey,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.05, end: 0, duration: 300.ms);
                  },
                ),

                Container(
                  margin: EdgeInsets.only(bottom: 16, top: 16),
                  child: Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      // Disables while the LoadingScreen overlay
                      // (added at the end of the Stack) is showing.
                      // Icon stays static so the button doesn't jitter
                      // — the overlay is the single source of "we're
                      // working".
                      onPressed: _signingOut ? null : _handleSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: AppLabel(
                        text: l10n.settingsHomeSignOutAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),
              ],
            ),

            // Loading overlay — last child so it paints on top of the
            // ListView + AppBackgroundGradient. `AbsorbPointer` blocks
            // every tap during sign-out so the user can't drill into a
            // sub-page (My Profile, etc.) while tokens are being wiped
            // and the router is about to bounce to /login.
            if (_signingOut)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const LoadingScreen(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: AppLabel(
            text: title.toUpperCase(),
            fontSize: AppFontSize.value11,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
    required this.color,
    this.onResult,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
  final Color color;

  /// Optional callback fired with the pushed page's pop result. Lets
  /// callers react to success/cancel signals from sub-pages without
  /// the sub-page having to reach into a global state holder. Pages
  /// that don't need a result (the vast majority) leave this null.
  final ValueChanged<Object?>? onResult;

  Future<void> _open(BuildContext context) async {
    final result = await ConfigRouter.pushPageAnimation(context, page);
    if (!context.mounted) return;
    onResult?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: AppLabel(
        text: title,
        fontSize: AppFontSize.value14,
        fontWeight: FontWeight.bold,
      ),
      subtitle: AppLabel(
        text: subtitle,
        fontSize: AppFontSize.value12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        size: 16,
      ),
      onTap: () => _open(context),
    );
  }
}
