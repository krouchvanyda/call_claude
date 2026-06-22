/// Slice 9.1.1 — visual theme preference.
///
/// `system` defers to OS-level light/dark.
enum AppThemeMode { system, light, dark }

/// Slice 9.1.2 — supported app languages. New locales must also be
/// added to the ARB files under [`lib/l10n/`].
enum AppLanguage { en, km }

/// Slice 9.1.3 — channels we surface push / in-app notifications on.
/// Order in the enum is the order in the settings list.
enum NotificationChannel {
  approvals,
  mentions,
  systemAlerts,
  marketing,
}

/// Per-channel preferences. Push and email are independent toggles —
/// users commonly want push for a category but no email digest.
class NotificationChannelPref {
  const NotificationChannelPref({
    required this.channel,
    required this.pushEnabled,
    required this.emailEnabled,
  });

  final NotificationChannel channel;
  final bool pushEnabled;
  final bool emailEnabled;

  NotificationChannelPref copyWith({
    NotificationChannel? channel,
    bool? pushEnabled,
    bool? emailEnabled,
  }) =>
      NotificationChannelPref(
        channel: channel ?? this.channel,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationChannelPref &&
          other.channel == channel &&
          other.pushEnabled == pushEnabled &&
          other.emailEnabled == emailEnabled;

  @override
  int get hashCode => Object.hash(channel, pushEnabled, emailEnabled);
}

/// Aggregate snapshot of all device-local preferences. The settings
/// repo emits one of these on every change so the UI can re-render
/// without subscribing to each axis individually.
class UserPreferences {
  const UserPreferences({
    required this.themeMode,
    required this.language,
    required this.notificationChannels,
  });

  final AppThemeMode themeMode;
  final AppLanguage language;
  final List<NotificationChannelPref> notificationChannels;

  UserPreferences copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    List<NotificationChannelPref>? notificationChannels,
  }) =>
      UserPreferences(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        notificationChannels:
            notificationChannels ?? this.notificationChannels,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserPreferences) return false;
    if (other.themeMode != themeMode || other.language != language) {
      return false;
    }
    if (other.notificationChannels.length != notificationChannels.length) {
      return false;
    }
    for (var i = 0; i < notificationChannels.length; i++) {
      if (other.notificationChannels[i] != notificationChannels[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        language,
        Object.hashAll(notificationChannels),
      );

  /// Default preferences for first-run users. Marketing is OFF by
  /// default to honour opt-in expectations; the rest are ON because
  /// they're operationally important (approvals, mentions, alerts).
  static const initial = UserPreferences(
    themeMode: AppThemeMode.system,
    language: AppLanguage.en,
    notificationChannels: [
      NotificationChannelPref(
        channel: NotificationChannel.approvals,
        pushEnabled: true,
        emailEnabled: true,
      ),
      NotificationChannelPref(
        channel: NotificationChannel.mentions,
        pushEnabled: true,
        emailEnabled: false,
      ),
      NotificationChannelPref(
        channel: NotificationChannel.systemAlerts,
        pushEnabled: true,
        emailEnabled: true,
      ),
      NotificationChannelPref(
        channel: NotificationChannel.marketing,
        pushEnabled: false,
        emailEnabled: false,
      ),
    ],
  );
}
