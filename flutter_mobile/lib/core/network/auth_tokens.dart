import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';

/// Pair of OAuth-style access + refresh tokens persisted by [TokenStorage]
/// and rotated by [TokenRefresher].
///
/// `accessExpiresAt` is optional — populated when the auth server returns an
/// `expires_in`, so future slices can do *proactive* refresh ahead of the
/// 401-driven *reactive* refresh wired in this slice.
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? accessExpiresAt,
  }) = _AuthTokens;
}
