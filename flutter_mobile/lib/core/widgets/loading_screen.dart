import 'package:flutter/material.dart';

import 'app_images.dart';

/// Centered logo with a circular progress ring orbiting it.
///
/// Use whenever the app is doing meaningful work that blocks the user
/// (auth check on splash, long sync, large file upload). For inline
/// list loading prefer the per-feature `LoadingShimmer` so the layout
/// doesn't jump when data arrives.
///
/// The spinner colour defaults to the theme's primary tone so the
/// widget paints sensibly without callers having to thread a colour
/// through. Pass [color] to override (e.g. on a dark hero card).
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    this.color,
    this.size = 45,
    this.strokeWidth = 3,
  });

  /// Spinner stroke colour. Defaults to `Theme.of(context).colorScheme.primary`.
  final Color? color;

  /// Logo edge length in logical pixels. Spinner sizes itself to match.
  final double size;

  /// Spinner stroke width.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = color ?? Theme.of(context).colorScheme.primary;
    // Spinner is positioned just outside the logo (8px padding both sides)
    // so it appears to orbit the logo rather than overlap it.
    final spinnerSize = size + 16;

    return Center(
      child: SizedBox(
        width: spinnerSize,
        height: spinnerSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: AppImages.logoImage(width: size, height: size),
            ),
            Positioned.fill(
              child: CircularProgressIndicator(
                color: spinnerColor,
                strokeWidth: strokeWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
