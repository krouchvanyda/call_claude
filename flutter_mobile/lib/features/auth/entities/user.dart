import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// Authenticated user — the domain-layer view of "who is signed in".
///
/// Pure Dart, framework-free. The data layer maps `UserModel` (the
/// API/JSON shape, defined in `data/models/`) onto this entity so the
/// domain never deals with serialisation concerns.
///
/// Roles are an unordered set of opaque permission tokens (e.g.
/// `'finance.invoice.create'`, `'admin'`). Higher-level RBAC checks
/// belong in domain use cases, not here.
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String displayName,
    @Default(<String>{}) Set<String> roles,
  }) = _User;

  const User._();

  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Iterable<String> wanted) => wanted.any(roles.contains);
  bool hasAllRoles(Iterable<String> required) =>
      required.every(roles.contains);
}
