import 'auth_tokens.dart';

/// Read-write surface over the persisted [AuthTokens].
///
/// Module 1 ships a `flutter_secure_storage`-backed implementation. For
/// Slice 0.2.2 the in-memory stub keeps the network layer self-contained
/// and lets unit tests verify the interceptor's behaviour without touching
/// platform channels.
abstract class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// Process-lifetime fallback. Replaced by a secure-storage impl in Module 1.
class InMemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
