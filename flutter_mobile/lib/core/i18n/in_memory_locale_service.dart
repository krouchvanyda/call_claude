import 'dart:async';

import 'app_language.dart';
import 'locale_service.dart';

/// Process-lifetime [LocaleService] backed by a broadcast stream.
///
/// Module 9 (Settings & Admin) will swap in a `shared_preferences`-backed
/// implementation that persists the user's choice across app restarts.
/// Until then this default keeps the wiring exercised and the user can
/// flip languages within a single session.
class InMemoryLocaleService implements LocaleService {
  InMemoryLocaleService({AppLanguage initial = AppLanguage.fallback})
      : _current = initial;

  AppLanguage _current;
  final StreamController<AppLanguage> _controller =
      StreamController<AppLanguage>.broadcast();

  @override
  AppLanguage get current => _current;

  @override
  Stream<AppLanguage> get changes => _controller.stream;

  @override
  Future<void> setLanguage(AppLanguage language) async {
    if (_current == language) return; // idempotent — no spurious emissions
    _current = language;
    _controller.add(language);
  }

  /// Releases the underlying stream controller. Tests should call this in
  /// `tearDown` to avoid leaking subscribers between tests.
  Future<void> dispose() => _controller.close();
}
