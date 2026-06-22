import 'dart:ui' show Color;

/// Centralised colour tokens.
///
/// Scheme-level colours (`colorScheme.primary`, etc.) are derived from the
/// brand seed via `ColorScheme.fromSeed`. Tokens here are the *raw* palette
/// — use the colour scheme inside widgets whenever possible.
abstract final class AppColors {
  // Brand ────────────────────────────────────────────────────────
  /// Seed for `ColorScheme.fromSeed`. Picked to give an enterprise
  /// trust-blue on Material 3 with sufficient contrast for finance UIs.
  static const Color brandSeed = Color(0xFF6366F1);

  // Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Neutrals ─────────────────────────────────────────────────────
  // Used for surfaces / dividers when the M3 scheme doesn't fit
  // (e.g. data-table zebra rows, audit highlights).
  static const Color neutral0   = Color(0xFFFFFFFF);
  static const Color neutral50  = Color(0xFFF7F8FA);
  static const Color neutral100 = Color(0xFFEEF0F4);
  static const Color neutral200 = Color(0xFFD9DDE3);
  static const Color neutral400 = Color(0xFF8B939E);
  static const Color neutral600 = Color(0xFF4A5260);
  static const Color neutral800 = Color(0xFF20262F);
  static const Color neutral900 = Color(0xFF11151B);
}
