import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that dynamically updates the system status bar style.
/// 
/// Use this to wrap screens where you want a specific status bar look
/// (e.g., transparent on splash/login, or matching a specific theme color).
class DynamicStatusBar extends StatelessWidget {
  final Widget child;
  final Brightness? brightness;
  final Color? statusBarColor;

  const DynamicStatusBar({
    super.key,
    required this.child,
    this.brightness,
    this.statusBarColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // If brightness is not provided, we derive it from the theme's brightness
    // to ensure icons are always visible.
    final effectiveBrightness = brightness ?? 
        (theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: effectiveBrightness,
        statusBarBrightness: theme.brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
      ),
      child: child,
    );
  }
}
