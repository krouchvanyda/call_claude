/// Numeric font-size tokens for use with [AppLabel] (and anywhere else
/// you want to reference a size by name instead of typing the number).
///
/// Prefer these over raw literals so a global typography rescale
/// (e.g. for accessibility / larger-text mode) can be done in one place.
///
/// Note: the project's Material 3 text theme in
/// [`app_typography.dart`](app_typography.dart) is the **semantic**
/// system (`titleMedium`, `bodyLarge`, `labelSmall`…). Use it when you
/// want the size to follow Material's role hierarchy. Use [AppFontSize]
/// here when you need a specific pixel size that doesn't map cleanly
/// to a Material role (e.g. badges, custom headings, marketing copy).
abstract final class AppFontSize {
  AppFontSize._();

  static const double value4 = 4;
  static const double value5 = 5;
  static const double value6 = 6;
  static const double value8 = 8;
  static const double value9 = 9;
  static const double value10 = 10;
  static const double value11 = 11;
  static const double value12 = 12;
  static const double value13 = 13;
  static const double value14 = 14;
  static const double value15 = 15;
  static const double value16 = 16;
  static const double value17 = 17;
  static const double value18 = 18;
  static const double value19 = 19;
  static const double value20 = 20;
  static const double value22 = 22;
  static const double value23 = 23;
  static const double value24 = 24;
  static const double value25 = 25;
  static const double value32 = 32;
  static const double value36 = 36;
  static const double value39 = 39;
  static const double value40 = 40;
}
