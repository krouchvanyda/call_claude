import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_font_size.dart';

/// Reusable text widget that bundles the most common `Text` + `TextStyle`
/// options into one place.
///
/// ## Usage
///
/// ```dart
/// AppLabel(
///   text: 'Welcome back',
///   fontSize: AppFontSize.value18,
///   fontWeight: FontWeight.bold,
/// )
/// ```
///
/// With overflow / multi-line:
///
/// ```dart
/// AppLabel(
///   text: longString,
///   fontSize: AppFontSize.value14,
///   color: theme.colorScheme.onSurfaceVariant,
///   maxLines: 2,
///   overflow: TextOverflow.ellipsis,
/// )
/// ```
///
/// Khmer text is automatically picked up via the `fontFamilyFallback`
/// (NotoSansKhmer), so mixed-script strings render cleanly regardless
/// of which primary font is set.
class AppLabel extends StatelessWidget {
  const AppLabel({
    super.key,
    required this.text,
    required this.fontSize,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.fontStyle,
    this.lineHeight = 1.3,
    this.letterSpacing,
    this.wordSpacing,
    this.textAlign = TextAlign.start,
    this.textDecoration = TextDecoration.none,
    this.decorationColor = const Color(0xff000000),
    this.overflow = TextOverflow.fade,
    this.maxLines,
    this.fontFamily = 'RobotoMono',
    this.fontFamilyFallback = const ['NotoSansKhmer'],
    this.softWrap,
    this.fontFeatures,
  });

  /// Displayed text. Pass an empty string to render nothing.
  final String text;

  /// Required — use [AppFontSize] constants, e.g. [AppFontSize.value18].
  final double fontSize;

  final String fontFamily;
  final List<String> fontFamilyFallback;
  /// Null means "inherit from the nearest `DefaultTextStyle`" — same
  /// behaviour as a bare `Text(...)`. Pass an explicit colour to lock
  /// it (e.g. `theme.colorScheme.primary`).
  final Color? color;
  final FontWeight fontWeight;
  final FontStyle? fontStyle;

  /// `TextStyle.height` — multiplier of [fontSize]. 1.3 gives comfortable
  /// reading-density.
  final double lineHeight;

  final double? letterSpacing;
  final double? wordSpacing;
  final TextAlign textAlign;
  final TextDecoration textDecoration;
  final Color decorationColor;
  final TextOverflow overflow;
  final int? maxLines;
  final bool? softWrap;

  /// e.g. `[FontFeature.tabularFigures()]` for monospace digit columns
  /// in timers / counts. Null leaves the family's defaults.
  final List<FontFeature>? fontFeatures;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: TextStyle(
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        // Resolve the family through google_fonts when it's a known
        // Google Font (RobotoMono / Poppins / PlusJakartaSans). For any
        // other name, fall through to the raw string — that lets you
        // pass a custom asset-registered family without changing the
        // widget. Khmer fallback stays on no matter what.
        fontFamily: _resolveFontFamily(fontFamily),
        fontFamilyFallback: fontFamilyFallback,
        height: lineHeight,
        fontFeatures: fontFeatures,
        decoration: textDecoration,
        decorationColor: decorationColor,
      ),
    );
  }

  static String _resolveFontFamily(String name) {
    switch (name) {
      case 'RobotoMono':
        return GoogleFonts.robotoMono().fontFamily!;
      case 'Poppins':
        return GoogleFonts.poppins().fontFamily!;
      case 'PlusJakartaSans':
        return GoogleFonts.plusJakartaSans().fontFamily!;
      default:
        return name;
    }
  }
}
