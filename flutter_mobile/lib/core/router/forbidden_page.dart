import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_font_size.dart';
import '../theme/app_label.dart';
import 'route_paths.dart';

/// Landing page for an authenticated user who lacks the permission
/// required by the route they tried to reach (Slice 1.3.2).
///
/// Distinct from [NotFoundPage] (404): the route exists, the user is
/// signed in — they're just not authorised. The "go home" action returns
/// them to the dashboard, which they always have access to.
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key, this.attemptedLocation});

  /// The path the user tried to reach, surfaced in the body so the bounce
  /// is debuggable. `null` when the page is reached directly.
  final String? attemptedLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.forbiddenTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            AppLabel(
              text: l10n.forbiddenBody(attemptedLocation ?? '?'),
              fontSize: AppFontSize.value14,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.goNamed(RoutePaths.dashboardName),
              child: Text(l10n.goHome),
            ),
          ],
        ),
      ),
    );
  }
}
