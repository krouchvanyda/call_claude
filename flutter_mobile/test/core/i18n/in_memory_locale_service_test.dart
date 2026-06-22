import 'package:erp_mobile/core/i18n/app_language.dart';
import 'package:erp_mobile/core/i18n/in_memory_locale_service.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryLocaleService', () {
    late InMemoryLocaleService service;

    setUp(() => service = InMemoryLocaleService());
    tearDown(() => service.dispose());

    test('defaults to AppLanguage.fallback', () {
      expect(service.current, AppLanguage.fallback);
    });

    test('honours an explicit initial language', () {
      final s = InMemoryLocaleService(initial: AppLanguage.khmer);
      addTearDown(s.dispose);
      expect(s.current, AppLanguage.khmer);
    });

    test('setLanguage updates current and emits on the changes stream',
        () async {
      final emissions = <AppLanguage>[];
      final sub = service.changes.listen(emissions.add);

      await service.setLanguage(AppLanguage.khmer);
      // Stream is async — let the listener catch up.
      await Future<void>.delayed(Duration.zero);

      expect(service.current, AppLanguage.khmer);
      expect(emissions, [AppLanguage.khmer]);

      await sub.cancel();
    });

    test('setLanguage to the same value is idempotent — no emission', () async {
      final emissions = <AppLanguage>[];
      final sub = service.changes.listen(emissions.add);

      await service.setLanguage(AppLanguage.english); // matches initial
      await Future<void>.delayed(Duration.zero);

      expect(service.current, AppLanguage.english);
      expect(emissions, isEmpty);

      await sub.cancel();
    });

    test('multiple distinct transitions emit in order', () async {
      final emissions = <AppLanguage>[];
      final sub = service.changes.listen(emissions.add);

      await service.setLanguage(AppLanguage.khmer);
      await service.setLanguage(AppLanguage.english);
      await service.setLanguage(AppLanguage.khmer);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [
        AppLanguage.khmer,
        AppLanguage.english,
        AppLanguage.khmer,
      ]);

      await sub.cancel();
    });

    test('changes is a broadcast stream — multiple listeners both receive',
        () async {
      final a = <AppLanguage>[];
      final b = <AppLanguage>[];
      final subA = service.changes.listen(a.add);
      final subB = service.changes.listen(b.add);

      await service.setLanguage(AppLanguage.khmer);
      await Future<void>.delayed(Duration.zero);

      expect(a, [AppLanguage.khmer]);
      expect(b, [AppLanguage.khmer]);

      await subA.cancel();
      await subB.cancel();
    });
  });
}
