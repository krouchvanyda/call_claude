import 'auth_tokens.dart';

/// Strategy that exchanges a refresh token for a fresh [AuthTokens] pair.
///
/// Module 1 ships the real OAuth2 implementation. Until then,
/// [UnimplementedTokenRefresher] throws so any unexpected production refresh
/// attempt fails loudly instead of silently signing the user out.
abstract class TokenRefresher {
  Future<AuthTokens> refresh(String refreshToken);
}

/// Default registration for the slice — Module 1 swaps it out.
class UnimplementedTokenRefresher implements TokenRefresher {
  @override
  Future<AuthTokens> refresh(String refreshToken) {
    throw UnimplementedError(
      'TokenRefresher is not wired yet — Module 1 (Auth & Identity) supplies '
      'the real implementation. The auth interceptor will treat this as a '
      'refresh failure and invalidate the session.',
    );
  }
}
