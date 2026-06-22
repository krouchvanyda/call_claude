import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_credentials.freezed.dart';

/// Email + password pair submitted to the sign-in use case.
///
/// Domain-layer guards (`isValid`, `validate`) catch the obvious shape
/// errors so the use case can fail fast on `AuthCredentials.empty()`
/// inputs without bouncing through the network. Form-level field-by-field
/// error messages still belong in the presentation layer's validators.
@freezed
class AuthCredentials with _$AuthCredentials {
  const factory AuthCredentials({
    required String email,
    required String password,
  }) = _AuthCredentials;

  const AuthCredentials._();

  /// Empty pair — useful as the initial state in form holders.
  factory AuthCredentials.empty() =>
      const AuthCredentials(email: '', password: '');

  /// Coarse-grained "could plausibly be a credential pair" check. Keeps
  /// the regex permissive on purpose: real validation lives server-side.
  bool get isValid =>
      _isPlausibleEmail(email.trim()) && password.length >= _minPasswordLength;

  /// Returns the first invariant the credentials violate, or null when
  /// they pass. Lets the sign-in use case surface a typed reason without
  /// guessing.
  CredentialIssue? validate() {
    if (email.trim().isEmpty) return CredentialIssue.emailMissing;
    if (!_isPlausibleEmail(email.trim())) return CredentialIssue.emailMalformed;
    if (password.isEmpty) return CredentialIssue.passwordMissing;
    if (password.length < _minPasswordLength) {
      return CredentialIssue.passwordTooShort;
    }
    return null;
  }
}

/// Reason a [AuthCredentials.validate] check failed.
enum CredentialIssue {
  emailMissing,
  emailMalformed,
  passwordMissing,
  passwordTooShort,
}

const int _minPasswordLength = 8;

// Deliberately permissive — anything with `local@domain.tld` shape passes.
// Matches the OWASP recommendation against trying to enforce RFC 5322 in
// regex; the auth server is the canonical validator.
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
bool _isPlausibleEmail(String s) => _emailPattern.hasMatch(s);
