import 'package:flutter/material.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';

/// Permission-gated demo destination wired up in Slice 1.3.2 so the
/// `RouteAccess` → `/forbidden` branch can be exercised end-to-end before
/// the real feature modules add their own gated routes.
///
/// `RouteAccess.requirements` declares this route requires `admin`; the
/// route guard reads `PermissionsSnapshot` and bounces unauthorised
/// users to [ForbiddenPage] before this widget ever builds.
class AdminDemoPage extends StatelessWidget {
  const AdminDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.adminDemoTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: AppLabel(
          text: l10n.adminDemoBody,
          fontSize: AppFontSize.value14,
        ),
      ),
    );
  }
}
