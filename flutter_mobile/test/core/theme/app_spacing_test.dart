import 'package:erp_mobile/core/theme/app_spacing.dart';
import 'package:test/test.dart';

void main() {
  group('AppSpacing', () {
    test('every token is a positive multiple of the base unit', () {
      const tokens = <String, double>{
        'xs': AppSpacing.xs,
        'sm': AppSpacing.sm,
        'md': AppSpacing.md,
        'lg': AppSpacing.lg,
        'xl': AppSpacing.xl,
        'xxl': AppSpacing.xxl,
        'xxxl': AppSpacing.xxxl,
        'huge': AppSpacing.huge,
      };

      for (final entry in tokens.entries) {
        expect(entry.value, greaterThan(0), reason: '${entry.key} must be > 0');
        expect(
          entry.value % AppSpacing.unit,
          0,
          reason: '${entry.key}=${entry.value} must align to '
              'AppSpacing.unit=${AppSpacing.unit}',
        );
      }
    });

    test('scale is strictly monotonic', () {
      const scale = <double>[
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.huge,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]),
            reason: 'index $i (${scale[i]}) must exceed ${scale[i - 1]}');
      }
    });

    test('readableMaxWidth supports a comfortable text measure', () {
      // Common readability target: 60–80 chars at body sizes ≈ 600–760 dp.
      expect(AppSpacing.readableMaxWidth, inInclusiveRange(600, 900));
    });
  });
}
