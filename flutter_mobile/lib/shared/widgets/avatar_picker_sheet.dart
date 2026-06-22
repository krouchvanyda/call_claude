import 'package:flutter/material.dart';

import '../../core/theme/app_font_size.dart';
import '../../core/theme/app_label.dart';
import '../../core/theme/app_radii.dart';

/// What the user chose on the [AvatarPickerSheet]. Returned by
/// [AvatarPickerSheet.show] — the caller still owns the actual
/// `image_picker` / file-removal call so the sheet stays UI-only.
enum AvatarPickChoice { camera, gallery, remove }

/// Reusable bottom-sheet for "change avatar / change group photo /
/// change contact photo" flows. Replaces the per-page duplicates that
/// used to live in `my_profile_page.dart` (Slice 9.1.4) and
/// `chat_info_page.dart` (Slices 10.3.3 / 10.3.5 / 10.3.6).
///
/// Two tiles always shown — Take photo (camera) + Choose from gallery.
/// Pass [allowRemove] true to also show the destructive "Remove photo"
/// tile (used when an avatar already exists).
///
/// ## Usage
///
/// ```dart
/// final choice = await AvatarPickerSheet.show(
///   context: context,
///   title: 'Change group photo',
///   allowRemove: hasPhoto,
/// );
/// switch (choice) {
///   case null:                      return; // cancelled
///   case AvatarPickChoice.camera:   await _pickImage(ImageSource.camera);
///   case AvatarPickChoice.gallery:  await _pickImage(ImageSource.gallery);
///   case AvatarPickChoice.remove:   await _clearAvatar();
/// }
/// ```
class AvatarPickerSheet {
  AvatarPickerSheet._();

  /// Show the sheet and resolve with the user's choice. Returns `null`
  /// when dismissed (drag-down, back, scrim tap).
  static Future<AvatarPickChoice?> show({
    required BuildContext context,
    String title = 'Update photo',
    String subtitle = 'Tap an option to change the avatar.',
    String cameraLabel = 'Take photo',
    String cameraSubtitle = 'Open the camera',
    String galleryLabel = 'Choose from gallery',
    String gallerySubtitle = 'Pick an existing image',
    String removeLabel = 'Remove photo',
    String removeSubtitle = 'Go back to initials / fallback',
    bool allowRemove = false,
  }) {
    return showModalBottomSheet<AvatarPickChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _AvatarPickerSheetBody(
        title: title,
        subtitle: subtitle,
        cameraLabel: cameraLabel,
        cameraSubtitle: cameraSubtitle,
        galleryLabel: galleryLabel,
        gallerySubtitle: gallerySubtitle,
        removeLabel: removeLabel,
        removeSubtitle: removeSubtitle,
        allowRemove: allowRemove,
      ),
    );
  }
}

class _AvatarPickerSheetBody extends StatelessWidget {
  const _AvatarPickerSheetBody({
    required this.title,
    required this.subtitle,
    required this.cameraLabel,
    required this.cameraSubtitle,
    required this.galleryLabel,
    required this.gallerySubtitle,
    required this.removeLabel,
    required this.removeSubtitle,
    required this.allowRemove,
  });

  final String title;
  final String subtitle;
  final String cameraLabel;
  final String cameraSubtitle;
  final String galleryLabel;
  final String gallerySubtitle;
  final String removeLabel;
  final String removeSubtitle;
  final bool allowRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppLabel(
              text: title,
              fontSize: AppFontSize.value16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            AppLabel(
              text: subtitle,
              fontSize: AppFontSize.value12,
              color: theme.colorScheme.onSurfaceVariant,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _AvatarSheetTile(
              icon: Icons.camera_alt_outlined,
              label: cameraLabel,
              subtitle: cameraSubtitle,
              accent: Colors.pink,
              onTap: () => Navigator.pop(context, AvatarPickChoice.camera),
            ),
            const SizedBox(height: 8),
            _AvatarSheetTile(
              icon: Icons.photo_library_outlined,
              label: galleryLabel,
              subtitle: gallerySubtitle,
              accent: Colors.green.shade700,
              onTap: () => Navigator.pop(context, AvatarPickChoice.gallery),
            ),
            if (allowRemove) ...[
              const SizedBox(height: 8),
              _AvatarSheetTile(
                icon: Icons.delete_outline,
                label: removeLabel,
                subtitle: removeSubtitle,
                accent: theme.colorScheme.error,
                onTap: () => Navigator.pop(context, AvatarPickChoice.remove),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AvatarSheetTile extends StatelessWidget {
  const _AvatarSheetTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: label,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                  AppLabel(
                    text: subtitle,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
