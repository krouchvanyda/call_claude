import 'package:erp_mobile/core/i18n/app_language.dart';
import 'package:test/test.dart';

void main() {
  group('AppLanguage', () {
    test('every variant exposes a non-empty BCP-47 code', () {
      for (final language in AppLanguage.values) {
        expect(language.code, isNotEmpty);
      }
    });

    test('codes are unique across variants', () {
      final codes = AppLanguage.values.map((l) => l.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('fallback is English (the template ARB locale)', () {
      expect(AppLanguage.fallback, AppLanguage.english);
    });

    group('fromCode', () {
      test('exact-match returns the matching variant', () {
        expect(AppLanguage.fromCode('en'), AppLanguage.english);
        expect(AppLanguage.fromCode('km'), AppLanguage.khmer);
      });

      test('unknown code falls back to AppLanguage.fallback', () {
        expect(AppLanguage.fromCode('zz'), AppLanguage.fallback);
        expect(AppLanguage.fromCode('fr-CA'), AppLanguage.fallback);
      });

      test('null code falls back to AppLanguage.fallback', () {
        expect(AppLanguage.fromCode(null), AppLanguage.fallback);
      });

      test('case sensitivity matches BCP-47 (lowercase only)', () {
        // BCP-47 says language tags are case-insensitive but conventional
        // form is lowercase; AppLanguage codes are stored lowercase, so
        // an uppercase request must NOT match (callers should normalise).
        expect(AppLanguage.fromCode('EN'), AppLanguage.fallback);
      });
    });
  });
}
