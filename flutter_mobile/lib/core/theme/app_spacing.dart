/// 4-pt baseline grid.
///
/// Every padding, gap, inset, and stack offset across the app must come from
/// this scale — no raw `EdgeInsets.all(13)` in widgets. The scale is geometric
/// (4, 8, 12, 16, 24, 32, 48, 64) so density tweaks compound predictably.
abstract final class AppSpacing {
  /// Base unit. All other tokens are integer multiples of this.
  static const double unit = 4;

  static const double xs = unit;        //  4
  static const double sm = unit * 2;    //  8
  static const double md = unit * 3;    // 12
  static const double lg = unit * 4;    // 16
  static const double xl = unit * 6;    // 24
  static const double xxl = unit * 8;   // 32
  static const double xxxl = unit * 12; // 48
  static const double huge = unit * 16; // 64

  /// Default page-level horizontal gutter on phones (≤ 600 dp).
  static const double phoneGutter = lg;

  /// Default page-level horizontal gutter on tablets / desktop (> 600 dp).
  static const double tabletGutter = xl;

  /// Maximum readable content width (used by responsive constraints).
  static const double readableMaxWidth = 720;
}
