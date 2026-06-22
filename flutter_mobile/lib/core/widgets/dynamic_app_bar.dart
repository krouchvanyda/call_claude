import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_font_size.dart';
import '../theme/app_label.dart';

/// A premium, dynamic AppBar that supports transitions and modern ERP aesthetics.
/// 
/// It automatically handles status bar styling when used in conjunction with
/// [DynamicStatusBar] or standard [Scaffold] settings.
class DynamicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const DynamicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: AppLabel(
        text: title,
        fontSize: AppFontSize.value20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: theme.colorScheme.onSurface,
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation,
      // Use a glassmorphic background by default
      backgroundColor: backgroundColor ?? theme.colorScheme.surface.withValues(alpha: 0.8),
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}

/// Provides easy access to layout calculations required when extending body 
/// behind the [DynamicAppBar].
extension DynamicAppBarContext on BuildContext {
  /// The standard top padding for scrollable lists that start behind the
  /// [DynamicAppBar]. Accounts for the system status bar and a standard visual offset.
  double get dynamicAppBarPadding => MediaQuery.paddingOf(this).top + 15;
}
