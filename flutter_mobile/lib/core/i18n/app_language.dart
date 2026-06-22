/// Languages the app ships translations for.
///
/// Stored as a plain enum with the BCP-47 [code] (rather than Flutter's
/// `Locale`) so the type stays Flutter-free and unit-testable. The
/// `MaterialApp.router` wiring constructs `Locale(language.code)` at the
/// boundary.
///
/// Adding a language: drop `app_<code>.arb` under `lib/l10n/`, append a
/// variant here, and re-run `flutter gen-l10n`.
enum AppLanguage {
  english('en'),
  khmer('km');

  const AppLanguage(this.code);

  /// ISO 639-1 language code — also the suffix on the matching ARB file
  /// (e.g. `en` ↔ `app_en.arb`).
  final String code;

  /// Default for new installs. Centralised so callers don't pick differently.
  static const AppLanguage fallback = AppLanguage.english;

  /// Resolve a language from a BCP-47 / ISO-639 code. Falls back to
  /// [fallback] when [code] isn't shipped — mirrors how
  /// `LocalizationsDelegate.isSupported` degrades gracefully.
  static AppLanguage fromCode(String? code) {
    if (code == null) return fallback;
    for (final language in values) {
      if (language.code == code) return language;
    }
    return fallback;
  }
}
