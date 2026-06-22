import 'package:flutter/material.dart';

/// Diagonal brand-tinted background used as the bottom layer of most
/// list / detail / form pages.
///
/// Replaces the hand-rolled `Container(decoration: BoxDecoration(gradient: …))`
/// that was duplicated in 18+ files. Keeping it as a single widget means
/// the palette is tweaked in one place.
///
/// Typical use:
/// ```dart
/// body: Stack(
///   children: [
///     const AppBackgroundGradient(),
///     // page content
///   ],
/// ),
/// ```
class AppBackgroundGradient extends StatelessWidget {
  const AppBackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.15),
            scheme.surface,
            scheme.secondaryContainer.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
