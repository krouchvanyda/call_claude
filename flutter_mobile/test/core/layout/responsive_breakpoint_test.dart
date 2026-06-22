import 'package:erp_mobile/core/layout/responsive_breakpoint.dart';
import 'package:test/test.dart';

void main() {
  group('resolveWindowSizeClass — Material 3 boundaries', () {
    test('zero width is compact (degenerate but defined)', () {
      expect(resolveWindowSizeClass(0), WindowSizeClass.compact);
    });

    test('typical phone portrait (360 dp) is compact', () {
      expect(resolveWindowSizeClass(360), WindowSizeClass.compact);
    });

    test('599 dp — last compact pixel', () {
      expect(resolveWindowSizeClass(599), WindowSizeClass.compact);
    });

    test('600 dp — first medium pixel (boundary)', () {
      expect(resolveWindowSizeClass(600), WindowSizeClass.medium);
    });

    test('typical tablet portrait (720 dp) is medium', () {
      expect(resolveWindowSizeClass(720), WindowSizeClass.medium);
    });

    test('839 dp — last medium pixel', () {
      expect(resolveWindowSizeClass(839), WindowSizeClass.medium);
    });

    test('840 dp — first expanded pixel (boundary)', () {
      expect(resolveWindowSizeClass(840), WindowSizeClass.expanded);
    });

    test('desktop (1440 dp) is expanded', () {
      expect(resolveWindowSizeClass(1440), WindowSizeClass.expanded);
    });

    test('fractional widths are bucketed by truncation, not rounding', () {
      // 599.999 is still < 600, so still compact. Locks the comparison
      // semantics so a future "round to nearest" change shows up in CI.
      expect(resolveWindowSizeClass(599.999), WindowSizeClass.compact);
      expect(resolveWindowSizeClass(839.999), WindowSizeClass.medium);
    });
  });

  group('gridColumnsFor', () {
    test('compact → 2 columns', () {
      expect(gridColumnsFor(WindowSizeClass.compact), 2);
    });

    test('medium → 3 columns', () {
      expect(gridColumnsFor(WindowSizeClass.medium), 3);
    });

    test('expanded → 4 columns', () {
      expect(gridColumnsFor(WindowSizeClass.expanded), 4);
    });

    test('every WindowSizeClass value maps to a positive column count', () {
      // Exhaustiveness sentinel — adding a new enum value without a
      // matching `gridColumnsFor` case is a compile error on the switch.
      // This test guards the *runtime* contract: every value > 0.
      for (final size in WindowSizeClass.values) {
        expect(gridColumnsFor(size), greaterThan(0));
      }
    });
  });
}
