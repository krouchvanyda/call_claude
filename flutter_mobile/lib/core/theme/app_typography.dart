import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // App-wide font. Driven by `google_fonts` so no manual asset wiring
  // is needed — the family is downloaded on first use and cached.
  // Every `theme.textTheme.X` consumer across the app (Text widgets,
  // AppBar titles, Button labels, ListTile, etc.) picks up this font
  // through the Material 3 theme — that's why a single change here
  // recolours the whole app instead of needing 1k+ widget edits.
  static String get _fontFamily => GoogleFonts.robotoMono().fontFamily!;
  static const String _monoFamily = 'RobotoMono';

  static const double _displayTracking = -0.5;
  static const double _headlineTracking = -0.2;
  static const double _titleTracking = 0.1;
  static const double _bodyTracking = 0.2;
  static const double _labelTracking = 0.5;

  static TextTheme textTheme() => TextTheme(
        displayLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 57, height: 1.12, fontWeight: FontWeight.w800,
          letterSpacing: _displayTracking,
        ),
        displayMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 45, height: 1.15, fontWeight: FontWeight.w800,
          letterSpacing: _displayTracking,
        ),
        displaySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 36, height: 1.22, fontWeight: FontWeight.w800,
          letterSpacing: _displayTracking,
        ),
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32, height: 1.25, fontWeight: FontWeight.w700,
          letterSpacing: _headlineTracking,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28, height: 1.28, fontWeight: FontWeight.w700,
          letterSpacing: _headlineTracking,
        ),
        headlineSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24, height: 1.33, fontWeight: FontWeight.w700,
          letterSpacing: _headlineTracking,
        ),
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20, height: 1.40, fontWeight: FontWeight.w600,
          letterSpacing: _titleTracking,
        ),
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16, height: 1.50, fontWeight: FontWeight.w600,
          letterSpacing: _titleTracking,
        ),
        titleSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14, height: 1.42, fontWeight: FontWeight.w600,
          letterSpacing: _titleTracking,
        ),
        bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16, height: 1.50, fontWeight: FontWeight.w400,
          letterSpacing: _bodyTracking,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14, height: 1.42, fontWeight: FontWeight.w400,
          letterSpacing: _bodyTracking,
        ),
        bodySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12, height: 1.33, fontWeight: FontWeight.w400,
          letterSpacing: _bodyTracking,
        ),
        labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14, height: 1.42, fontWeight: FontWeight.w700,
          letterSpacing: _labelTracking,
        ),
        labelMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12, height: 1.33, fontWeight: FontWeight.w700,
          letterSpacing: _labelTracking,
        ),
        labelSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 10, height: 1.45, fontWeight: FontWeight.w700,
          letterSpacing: _labelTracking,
        ),
      );

  static TextStyle numericMono(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontFamily: _monoFamily,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
  }
}
