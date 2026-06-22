import 'package:flutter/material.dart';

/// Elevation tokens used by [AppCard], modal sheets, and other surfaces.
///
/// Two layers cover the design guide's needs:
/// - [card]  — quiet ambient shadow for resting card surfaces
/// - [modal] — heavier shadow for floating sheets / overlays
abstract final class AppShadow {
  /// Default card resting elevation. Subtle — readability matters more
  /// than depth on a data-dense ERP surface.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Modal / bottom-sheet elevation. Heavier so the floating surface
  /// reads as detached from the page.
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
