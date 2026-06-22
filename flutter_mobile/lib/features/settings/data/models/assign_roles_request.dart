/// Bulk-assignment modes for the `POST /api/v1/users/assign-roles`
/// endpoint. Mirrors `AssignRolesRequest.Mode` on the Spring side.
///
/// Default is [add] — matches the backend's default when `mode` is
/// omitted from the JSON.
enum AssignRolesMode {
  /// Union the given roles into each user's existing role set.
  add,

  /// Replace each user's role set with exactly the given roles.
  replace,

  /// Subtract the given roles from each user's existing role set.
  remove;

  /// Wire form — Spring's `Set<String>` JSON binding receives the enum
  /// as its uppercase name (`ADD`, `REPLACE`, `REMOVE`).
  String get wireValue => name.toUpperCase();
}

/// `POST /api/v1/users/assign-roles` body — admin bulk-assigns one
/// or more role **codes** to one or more users.
///
/// Mirrors the Spring record:
/// ```java
/// public record AssignRolesRequest(
///     @NotEmpty Set<Long> userIds,
///     @NotNull  Set<String> roles,
///     Mode mode   // null defaults to ADD
/// ) {}
/// ```
///
/// - `userIds` must be non-empty (backend `@NotEmpty`) and contains
///   the numeric primary keys of every target user.
/// - `roles` is a set of role **codes** (`"SUPER_ADMIN"`, `"STAFF"`,
///   …). Empty set is technically valid for [AssignRolesMode.replace]
///   ("strip every role from these users") but the server still
///   requires the field to be present.
/// - `mode` is omitted from the JSON when `null`; backend then
///   defaults to ADD. We always serialise it explicitly so the wire
///   payload is unambiguous.
class AssignRolesRequest {
  const AssignRolesRequest({
    required this.userIds,
    required this.roles,
    this.mode = AssignRolesMode.add,
  });

  final List<int> userIds;
  final List<String> roles;
  final AssignRolesMode mode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userIds': userIds,
        'roles': roles,
        'mode': mode.wireValue,
      };
}
