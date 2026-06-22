import '../../../../core/network/auth_tokens.dart';
import '../../entities/user.dart';

/// Wire-format response body returned by `POST /auth/login`,
/// `/auth/register`, and `/auth/refresh`.
///
/// Mirrors the Java `AuthResponse` record exactly — camelCase keys, ISO-8601
/// instants for the two expiry fields. Mapping back into the app's domain
/// types (`AuthTokens` for the network layer, `User` for the cache) lives
/// in [toAuthTokens] and `UserDto.toDomain`, so call sites only ever see
/// pure-domain objects.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final UserDto user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt:
          DateTime.parse(json['accessTokenExpiresAt'] as String),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt:
          DateTime.parse(json['refreshTokenExpiresAt'] as String),
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Map onto the network-layer [AuthTokens] used by the interceptor + the
  /// token refresher. We only propagate the access-token expiry —
  /// `AuthTokens.accessExpiresAt` is what the refresher checks; the refresh
  /// token's own expiry is implicit (the next refresh attempt will fail).
  AuthTokens toAuthTokens() => AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpiresAt: accessTokenExpiresAt,
      );
}

/// Nested user payload returned alongside the tokens.
///
/// Matches the actual Spring `UserDto` wire shape:
///   - `id` arrives as a number (`2`) — toString'd into the domain id.
///   - `fullName` (not `name` / `displayName`) carries the display name.
///   - `roles` and `permissions` arrive as two separate arrays — both
///     get merged into the domain [User.roles] set, which is what the
///     `PermissionGuard` widget + RBAC route guard consult.
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.roles = const <String>[],
    this.permissions = const <String>[],
  });

  final String id;
  final String email;
  final String name;
  final List<String> roles;
  final List<String> permissions;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(String key) {
      final raw = json[key];
      if (raw is! List) return const <String>[];
      return raw.map((e) => e.toString()).toList(growable: false);
    }

    return UserDto(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '') as String,
      // Tolerate older `name` / `displayName` shapes too, in case a
      // legacy fixture surfaces in tests.
      name: (json['fullName'] ?? json['name'] ?? json['displayName'] ?? '')
          as String,
      roles: readStringList('roles'),
      permissions: readStringList('permissions'),
    );
  }

  /// Project onto the domain [User] used by the cache + presentation layer.
  ///
  /// Merges `roles` + `permissions` into a single set — the domain layer
  /// (and the `user_permissions` drift table) treat every authorisation
  /// token uniformly, regardless of whether the server typed it as a
  /// role name or a fine-grained permission.
  User toDomain() => User(
        id: id,
        email: email,
        displayName: name,
        roles: <String>{...roles, ...permissions},
      );
}
