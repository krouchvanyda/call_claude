import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Read-only auth state surface that the router (and any other observer)
/// can subscribe to without depending on the future Auth BLoC.
///
/// Module 1 (`auth/`) will provide a real implementation backed by
/// `flutter_secure_storage` + token refresh. For now Slice 0.1.3 ships a
/// stub that defaults to *signed-out* so the guard logic is exercised.
abstract class AuthSession implements Listenable {
  bool get isAuthenticated;

  /// Tear down the session — clears tokens (real impl) and notifies the
  /// router so it bounces back to `/login`. Called by the auth interceptor
  /// when a token refresh fails.
  Future<void> signOut();

  /// Flip the session to authenticated WITHOUT going through a login
  /// round-trip. Used by the splash to hydrate from `TokenStorage` on
  /// cold start — the secure-storage entry survives the kill but the
  /// in-process session boots to `false`, so without this call the
  /// router's redirect would bounce a returning user back to `/login`
  /// even though their tokens are valid.
  ///
  /// Safe to call when already authenticated (no-op).
  void markAuthenticated();
}

/// Stub implementation used until Module 1 lands. Mutable so tests can
/// flip it and observe the router reacting.
@LazySingleton(as: AuthSession)
class StubAuthSession extends ChangeNotifier implements AuthSession {
  StubAuthSession();

  bool _isAuthenticated = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<void> signOut() async {
    setAuthenticated(value: false);
  }

  @override
  void markAuthenticated() => setAuthenticated(value: true);

  /// Placeholder API used by the router to flip the stub session to
  /// "signed in" when the demo login button is tapped. The real
  /// `AuthSession` implementation (future slice) will **not** expose
  /// this — sign-in goes through `SignInUseCase` instead.
  void simulateSignIn() => setAuthenticated(value: true);

  @visibleForTesting
  void setAuthenticated({required bool value}) {
    // ignore: avoid_print
    print('🎬 AUTH: setAuthenticated($value) called — was $_isAuthenticated');
    if (_isAuthenticated == value) {
      // ignore: avoid_print
      print('🎬 AUTH: no-op (already $value), notifyListeners NOT fired');
      return;
    }
    _isAuthenticated = value;
    // ignore: avoid_print
    print('🎬 AUTH: notifyListeners() firing — listener count=${_listenerCountForDebug()}');
    notifyListeners();
  }

  /// Cheap debug helper — ChangeNotifier doesn't expose listener
  /// count publicly, so we just return "?" rather than reflect.
  String _listenerCountForDebug() => hasListeners ? '≥1' : '0';
}
