import 'app_language.dart';

/// Active language surface — read by `MaterialApp.router` to drive the
/// locale, written by Settings → "Change language".
///
/// Stream-based instead of `Listenable` so the interface stays Flutter-free
/// and unit-testable. App shells listen via `StreamBuilder<AppLanguage>`
/// to rebuild when the user picks a different language.
abstract class LocaleService {
  AppLanguage get current;
  Stream<AppLanguage> get changes;
  Future<void> setLanguage(AppLanguage language);
}
