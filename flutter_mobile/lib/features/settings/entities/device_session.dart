/// Slice 9.3.1 — one row in the "active devices" list.
///
/// `isCurrent` flags the device the user is signed in on right now;
/// the UI shows it pinned to the top with a "this device" chip and the
/// revoke button is hidden (revoking yourself logs you out).
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceLabel,
    required this.platform,
    required this.lastActiveAt,
    required this.signedInAt,
    required this.location,
    required this.isCurrent,
    this.ipAddress,
  });

  final String id;
  final String deviceLabel;
  final String platform;
  final DateTime lastActiveAt;
  final DateTime signedInAt;
  final String location;
  final bool isCurrent;
  final String? ipAddress;

  DeviceSession copyWith({
    String? id,
    String? deviceLabel,
    String? platform,
    DateTime? lastActiveAt,
    DateTime? signedInAt,
    String? location,
    bool? isCurrent,
    String? ipAddress,
  }) =>
      DeviceSession(
        id: id ?? this.id,
        deviceLabel: deviceLabel ?? this.deviceLabel,
        platform: platform ?? this.platform,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        signedInAt: signedInAt ?? this.signedInAt,
        location: location ?? this.location,
        isCurrent: isCurrent ?? this.isCurrent,
        ipAddress: ipAddress ?? this.ipAddress,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSession &&
          other.id == id &&
          other.deviceLabel == deviceLabel &&
          other.platform == platform &&
          other.lastActiveAt == lastActiveAt &&
          other.signedInAt == signedInAt &&
          other.location == location &&
          other.isCurrent == isCurrent &&
          other.ipAddress == ipAddress;

  @override
  int get hashCode => Object.hash(
        id,
        deviceLabel,
        platform,
        lastActiveAt,
        signedInAt,
        location,
        isCurrent,
        ipAddress,
      );
}
