import 'package:erp_mobile/core/theme/app_radii.dart';
import 'package:test/test.dart';

void main() {
  group('AppRadii', () {
    test('non-zero tokens are strictly increasing', () {
      const scale = <double>[
        AppRadii.xs,
        AppRadii.sm,
        AppRadii.md,
        AppRadii.lg,
        AppRadii.xl,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('pill is large enough to fully round any sensible button', () {
      // Pill must exceed the largest standard tap target (≥ 48 dp).
      expect(AppRadii.pill, greaterThanOrEqualTo(48));
    });

    test('none is exactly zero', () {
      expect(AppRadii.none, 0);
    });
  });
}
