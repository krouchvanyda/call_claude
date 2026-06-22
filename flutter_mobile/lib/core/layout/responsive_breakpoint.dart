/// Material 3 window-size classes — the canonical breakpoints we use to
/// pick navigation chrome, layout density, and content column counts.
///
/// Pure Dart, no Flutter import: lets the rule set live in unit tests
/// (the `MediaQuery`-aware lookup wrapper lives next to the widget that
/// consumes it).
///
/// Reference: https://m3.material.io/foundations/layout/applying-layout/window-size-classes
enum WindowSizeClass {
  /// `0 ≤ width < 600` dp — phones in portrait. Bottom nav.
  compact,

  /// `600 ≤ width < 840` dp — phones in landscape, small tablets, foldables.
  /// Navigation rail (collapsed).
  medium,

  /// `width ≥ 840` dp — large tablets, desktop, web. Permanent navigation
  /// drawer (or an expanded rail with text labels).
  expanded,
}

/// Resolves the [WindowSizeClass] for a given width in logical pixels.
///
/// Boundaries follow Material 3 *exactly* — change them here and every
/// shell in the app picks up the new policy.
WindowSizeClass resolveWindowSizeClass(double widthDp) {
  if (widthDp < 600) return WindowSizeClass.compact;
  if (widthDp < 840) return WindowSizeClass.medium;
  return WindowSizeClass.expanded;
}

/// Default column count for a card grid at each window size class.
///
/// Centralised here so module shortcut tiles (Slice 2.1.2) and any
/// future grid (KPI tiles, item catalogue, etc.) pick the same density.
int gridColumnsFor(WindowSizeClass size) {
  return switch (size) {
    WindowSizeClass.compact => 2,
    WindowSizeClass.medium => 3,
    WindowSizeClass.expanded => 4,
  };
}
