/// Wire-format request DTOs for the Spring `AuthController` endpoints
/// (`/api/v1/auth/*`).
///
/// JSON keys are camelCase to match Spring Boot's default Jackson
/// serialisation of record fields. If the backend ever flips to
/// `PropertyNamingStrategy.SNAKE_CASE`, fix the keys in `toJson` here in
/// one place rather than at every call site.
///
/// Kept as plain Dart classes (no freezed / json_serializable codegen)
/// because these DTOs are tiny and shipping them shouldn't require a
/// `build_runner` step.
library;

/// `POST /auth/login` body.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'password': password,
      };
}

/// `POST /auth/register` body.
///
/// Mirrors the Spring `RegisterRequest` record:
/// `{ email, password, fullName, phone }` — all four fields required.
/// Send order matches the backend example (`email` first) for log
/// readability; Jackson doesn't care about JSON key order on the wire.
class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      };
}

/// `POST /auth/refresh` body.
class RefreshRequest {
  const RefreshRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'refreshToken': refreshToken,
      };
}

/// `POST /auth/logout` body.
///
/// Same shape as [RefreshRequest] today, kept distinct because the
/// backend signature is a separate type and could diverge (e.g. add
/// `everywhere: true` for sign-out-all-sessions).
class LogoutRequest {
  const LogoutRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'refreshToken': refreshToken,
      };
}
