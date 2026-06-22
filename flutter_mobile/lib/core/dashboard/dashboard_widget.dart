import 'package:flutter/widgets.dart';

/// One slot in a [DashboardLayout] (Slice 2.2.2).
///
/// **Why an abstract class, not a freezed union or registry-by-string**:
/// each concrete dashboard widget owns its own typed payload (KPI data,
/// chart series, list query) and its own builder. A registry-by-string
/// would force every payload through a `Map<String, dynamic>` and lose
/// compile-time safety. A sealed union would couple the engine to every
/// new widget kind in a `switch`.
///
/// The trade-off is that *user-customisable layouts persisted to drift /
/// server* (a later slice) will need a (de)serialisation layer on top of
/// this — concrete widget classes will register a `(json) → instance`
/// factory at DI time. For now the layout is built in code by the
/// dashboard page; the engine is the same either way.
abstract class DashboardWidget {
  const DashboardWidget();

  /// Stable identity inside a layout — used as a key for keyed-tree
  /// reconciliation when the layout is rebuilt with re-ordered or
  /// added / removed slots.
  String get id;

  /// How many grid columns this widget occupies. Clamped to the
  /// available column count by [DashboardGrid] so a `colSpan: 4`
  /// widget on a 2-column compact layout still fits (renders as 2).
  int get colSpan;

  /// Fixed height in logical pixels. `null` means "let the child
  /// size itself" — useful for variable-height list widgets. Most
  /// KPI / chart tiles supply a value so rows don't jitter as data
  /// loads.
  double? get heightDp;

  /// Build the slot's content. Wrapped in the cell sizing by the
  /// layout engine, so this method can return the bare card / chart
  /// without worrying about width or padding.
  Widget build(BuildContext context);
}

/// Convenience type — a dashboard layout is just an ordered list of
/// slots. Order is the on-screen reading order; the row packer fills
/// columns left-to-right then wraps.
typedef DashboardLayout = List<DashboardWidget>;
