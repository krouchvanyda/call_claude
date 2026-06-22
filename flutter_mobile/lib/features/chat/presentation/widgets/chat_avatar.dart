import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_label.dart';
import '../../data/repositories/presence_repository.dart';
import '../../entities/conversation.dart';

/// Circular avatar with initials fallback. Used for direct chats and
/// participant rows. Group rows use [GroupAvatarCluster] instead.
///
/// When [avatarFilePath] points to a readable local file, the avatar
/// renders the photo (filled by [DecorationImage.cover]) instead of
/// the initials gradient. Slice 10.3.3 uses this for group photos
/// picked via `image_picker`.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    required this.size,
    this.avatarUrl,
    this.avatarFilePath,
    this.presence,
    this.showStatus = true,
    this.userId,
  });

  final String name;
  final double size;
  final String? avatarUrl;
  final String? avatarFilePath;
  final PresenceStatus? presence;
  final bool showStatus;

  /// When set, the dot is driven live from [PresenceRepository] for
  /// this user — overrides the static [presence] field and rebuilds
  /// on every `presence.update` STOMP frame. Leave null for legacy
  /// call sites that pass an explicit [presence] (seed data, etc.).
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initialsFor(name);
    final hue = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = _gradientFor(hue);
    final dotSize = (size * 0.28).clamp(8.0, 18.0);
    final hasPhoto = avatarFilePath != null && avatarFilePath!.isNotEmpty;
    final presenceRepo = (userId != null &&
            GetIt.I.isRegistered<PresenceRepository>())
        ? GetIt.I<PresenceRepository>()
        : null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
              color: hasPhoto ? theme.colorScheme.surface : null,
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(File(avatarFilePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? null
                : AppLabel(
                    text: initials,
                    fontSize: size * 0.38,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
          ),
          if (showStatus)
            Positioned(
              right: -1,
              bottom: -1,
              child: presenceRepo != null
                  ? AnimatedBuilder(
                      animation: presenceRepo.revision,
                      builder: (_, __) {
                        // `effectiveStatus` maps a fresh-OFFLINE
                        // (last-seen < 5 min) to AWAY so dots stay
                        // amber when the peer just minimised, instead
                        // of disappearing instantly.
                        final live =
                            presenceRepo.statusOf(userId!).effectiveStatus;
                        if (live == PresenceStatus.offline) {
                          return const SizedBox.shrink();
                        }
                        return OnlineStatusDot(
                          presence: live,
                          size: dotSize,
                          borderColor: theme.colorScheme.surface,
                        );
                      },
                    )
                  : (presence != null
                      ? OnlineStatusDot(
                          presence: presence!,
                          size: dotSize,
                          borderColor: theme.colorScheme.surface,
                        )
                      : const SizedBox.shrink()),
            ),
        ],
      ),
    );
  }

  static String _initialsFor(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static List<Color> _gradientFor(int hue) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // indigo→violet
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)], // cyan→blue
      [const Color(0xFF10B981), const Color(0xFF059669)], // emerald
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // amber→red
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)], // pink→violet
      [const Color(0xFF14B8A6), const Color(0xFF22D3EE)], // teal→sky
    ];
    return palettes[hue.abs() % palettes.length];
  }
}

/// Small dot used on the bottom-right of avatars to indicate presence.
class OnlineStatusDot extends StatelessWidget {
  const OnlineStatusDot({
    super.key,
    required this.presence,
    required this.size,
    required this.borderColor,
  });

  final PresenceStatus presence;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final color = switch (presence) {
      PresenceStatus.online => const Color(0xFF31A24C), // facebook-green
      PresenceStatus.busy => const Color(0xFFE2A03F),   // amber — in a call
      PresenceStatus.away => Colors.orange.shade500,
      PresenceStatus.offline => Colors.grey.shade400,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }
}

/// 3-avatar cluster used by group conversations in the inbox.
class GroupAvatarCluster extends StatelessWidget {
  const GroupAvatarCluster({
    super.key,
    required this.previews,
    this.size = 52,
  });

  final List<ChatParticipantPreview> previews;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (previews.isEmpty) {
      return ChatAvatar(name: 'Group', size: size, showStatus: false);
    }
    final theme = Theme.of(context);
    final frontSize = size * 0.78;
    final backSize = size * 0.55;
    final visible = previews.take(3).toList();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          if (visible.length >= 3)
            Positioned(
              right: 0,
              top: 0,
              child: _Ringed(
                color: theme.colorScheme.surface,
                child: ChatAvatar(
                  name: visible[2].name,
                  size: backSize,
                  showStatus: false,
                ),
              ),
            ),
          if (visible.length >= 2)
            Positioned(
              right: size * 0.32,
              top: 0,
              child: _Ringed(
                color: theme.colorScheme.surface,
                child: ChatAvatar(
                  name: visible[1].name,
                  size: backSize,
                  showStatus: false,
                ),
              ),
            ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _Ringed(
              color: theme.colorScheme.surface,
              child: ChatAvatar(
                name: visible.first.name,
                size: frontSize,
                showStatus: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ringed extends StatelessWidget {
  const _Ringed({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: child,
    );
  }
}
