import 'package:flutter/material.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';

/// Generic landing page used by Slice 2.1.2 module shortcut tiles whose
/// real feature module hasn't shipped yet. Takes the human-readable
/// module name as a path parameter so the catalog stays the only place
/// the label lives.
///
/// Replaced as each feature module lands and gets its own real route.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.moduleLabel});

  final String moduleLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: moduleLabel,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            AppLabel(
              text: l10n.comingSoonBody(moduleLabel),
              fontSize: AppFontSize.value14,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
