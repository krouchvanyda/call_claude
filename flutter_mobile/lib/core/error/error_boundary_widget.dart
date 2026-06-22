import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_font_size.dart';
import '../theme/app_label.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Friendly replacement for Flutter's red-screen `ErrorWidget`.
///
/// Bound globally by `runWithCrashHooks` via `ErrorWidget.builder`. Renders
/// the exception details in **debug**/**profile** so engineers see what
/// happened, and a generic apology in **release** so users don't see a
/// stack trace.
class ErrorBoundaryWidget extends StatelessWidget {
  const ErrorBoundaryWidget({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDetails = !kReleaseMode;
    // Nullable lookup — ErrorBoundaryWidget can mount in a context that
    // has no Localizations ancestor (e.g. when build() throws before
    // MaterialApp is mounted). Falling back to hardcoded English keeps
    // the error display itself crash-proof.
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final headline = l10n?.errorBoundaryGenericMessage ?? 'Something went wrong';

    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppLabel(
                  text: headline,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              details.exceptionAsString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 6,
            ),
          ],
        ],
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: theme.colorScheme.error),
        ),
        child: body,
      ),
    );
  }
}
