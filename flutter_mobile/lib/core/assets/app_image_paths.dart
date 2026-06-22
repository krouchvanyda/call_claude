/// Central registry of every static asset path.
///
/// Update this file whenever you add a new asset to `assets/` (and update
/// `pubspec.yaml` to register the folder). Keeping every path in one
/// place means renames are a single edit instead of a project-wide grep.
abstract final class AppImagePaths {
  // Brand ────────────────────────────────────────────────────────
  /// App logo, also used by the splash + login + loading screens.
  static const String logo = 'assets/icons/appLogo.jpg';

  // Fallbacks ────────────────────────────────────────────────────
  // Placeholders below are referenced by `AppImages.imagePlaceholder`
  // / `profileImage`. If the file isn't shipped yet, the helpers fall
  // back to a Material icon — no asset 404 / red error box.
  static const String defaultProfile = 'assets/images/default_profile.png';
  static const String noBanner = 'assets/images/no_banner.png';
}
