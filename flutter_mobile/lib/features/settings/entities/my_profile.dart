/// Slice 9.1.4 — signed-in user's own profile record.
///
/// Aggregates fields the user can self-edit (contact + personal) and
/// fields the system maintains (employee id, hire date, position label,
/// last-login metadata). The on-disk source of truth is split across
/// `cached_user` (id/email/displayName) and the HR module's employee
/// record — this entity is the read-model the profile screen joins
/// them into.
///
/// Sensitive identifiers (email, phone) carry no validation flag here;
/// the page surfaces a "Requires verification" hint based on whether
/// the user mutates them in edit mode (see [MyProfileRepository.update]).
class MyProfile {
  const MyProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.position,
    required this.department,
    required this.hiredAt,
    required this.birthdate,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.lastLoginAt,
    required this.lastLoginDevice,
    this.avatarInitials,
    this.avatarTone,
    this.avatarFilePath,
    this.avatarUrl,
    this.avatarHeaders,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  final String position;
  final String department;
  final DateTime hiredAt;
  final DateTime birthdate;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final DateTime lastLoginAt;
  final String lastLoginDevice;

  /// Two-letter initial used by the avatar when no upload is present.
  /// `null` means "derive from [name]". Picking a preset overrides the
  /// derivation so the user can keep their initials short.
  final String? avatarInitials;

  /// Optional tint variant for the avatar (0..3) — lets the avatar
  /// picker stub vary the gradient without needing real photo upload.
  final int? avatarTone;

  /// Absolute path to a locally-stored avatar image (e.g. the file
  /// returned by `image_picker`). When non-null the avatar renders the
  /// photo instead of the initials/gradient fallback. Takes priority
  /// over [avatarUrl] so a freshly-picked image shows immediately
  /// while the multipart upload is still in flight.
  final String? avatarFilePath;

  /// Fully-resolved URL of the server-side avatar (e.g.
  /// `http://api.host/uploads/employees/3/avatar.png`). Used by the
  /// hero card when no local file is available. The repository
  /// resolves relative paths returned by `/employees/me` against the
  /// Dio base URL before populating this field.
  final String? avatarUrl;

  /// HTTP headers (typically `Authorization: Bearer …`) to pass when
  /// fetching [avatarUrl]. Spring's static-upload route is auth-gated;
  /// `NetworkImage` won't send the bearer token on its own, so the
  /// repository pins the current access token into the snapshot and
  /// the hero card threads it through to the image provider.
  final Map<String, String>? avatarHeaders;

  MyProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? employeeId,
    String? position,
    String? department,
    DateTime? hiredAt,
    DateTime? birthdate,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? lastLoginAt,
    String? lastLoginDevice,
    String? avatarInitials,
    int? avatarTone,
    String? avatarFilePath,
    bool clearAvatarFilePath = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    Map<String, String>? avatarHeaders,
    bool clearAvatarHeaders = false,
  }) =>
      MyProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        employeeId: employeeId ?? this.employeeId,
        position: position ?? this.position,
        department: department ?? this.department,
        hiredAt: hiredAt ?? this.hiredAt,
        birthdate: birthdate ?? this.birthdate,
        address: address ?? this.address,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        lastLoginDevice: lastLoginDevice ?? this.lastLoginDevice,
        avatarInitials: avatarInitials ?? this.avatarInitials,
        avatarTone: avatarTone ?? this.avatarTone,
        avatarFilePath:
            clearAvatarFilePath ? null : (avatarFilePath ?? this.avatarFilePath),
        avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
        avatarHeaders: clearAvatarHeaders
            ? null
            : (avatarHeaders ?? this.avatarHeaders),
      );

  /// Initials shown on the avatar. Honours [avatarInitials] when set,
  /// otherwise derives two letters from [name].
  String get displayInitials {
    if (avatarInitials != null && avatarInitials!.trim().isNotEmpty) {
      return avatarInitials!.trim().toUpperCase();
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
