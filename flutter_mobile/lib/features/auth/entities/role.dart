import 'package:freezed_annotation/freezed_annotation.dart';

import 'permission.dart';

part 'role.freezed.dart';

/// A named bundle of permissions — e.g. `accountant`, `warehouse_manager`,
/// `admin`.
///
/// The server is the canonical source of role definitions; the client
/// receives a flattened permission list at sign-in (already
/// role-expanded) and stores it in `user_permissions`. This type exists
/// so the UI can show role badges, group permissions in the Settings
/// page, and reason about role-shaped policies without re-deriving
/// them from scattered string checks.
@freezed
class Role with _$Role {
  const factory Role({
    required String name,
    @Default(<Permission>{}) Set<Permission> permissions,
  }) = _Role;

  const Role._();

  /// `true` when *any* of this role's permissions satisfies [required],
  /// honouring the same wildcard semantics as [Permission.grants].
  bool grants(Permission required) => permissions.grant(required);
}
