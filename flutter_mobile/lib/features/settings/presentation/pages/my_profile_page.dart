import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../../../shared/widgets/avatar_picker_sheet.dart';
import '../../data/repositories/my_profile_repository.dart';
import '../../data/repositories/security_repositories.dart';
import '../../entities/app_lock_settings.dart';
import '../../entities/my_profile.dart';
import 'app_lock_page.dart';

/// Slice 9.1.4 — My Profile Info.
///
/// View-first; the AppBar "Edit" pivots into an in-place edit mode that
/// reveals InputFields with a sticky Save bar at the bottom. Sensitive
/// fields (email / phone) get a "Requires verification" hint when the
/// user mutates them, mirroring the design guide. The Account Security
/// section delegates to existing flows: change password / change PIN /
/// biometric toggle — each is gated by a re-auth confirmation sheet so
/// the user explicitly opts into the change.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _profileRepo = GetIt.I<MyProfileRepository>();

  bool _editing = false;
  bool _saving = false;
  MyProfile? _draft;
  MyProfile? _baseline;

  // Controllers held at state level so they survive rebuilds and keep
  // caret position when the user types.
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _enterEdit(MyProfile current) {
    _baseline = current;
    _draft = current;
    _nameCtrl.text = current.name;
    _emailCtrl.text = current.email;
    _phoneCtrl.text = current.phone;
    _addressCtrl.text = current.address;
    _emergencyNameCtrl.text = current.emergencyContactName;
    _emergencyPhoneCtrl.text = current.emergencyContactPhone;
    setState(() {
      _editing = true;
      _errorMessage = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _saving = false;
      _draft = null;
      _baseline = null;
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    if (_draft == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final next = _draft!.copyWith(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        emergencyContactName: _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      );
      await _profileRepo.update(next);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.myProfileUpdatedSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cancelEdit();
    } on ValidationFailure catch (f) {
      setState(() {
        _saving = false;
        _errorMessage = f.fieldErrors.entries
            .map((e) => '${_humanField(e.key, l10n)}: ${e.value.join(', ')}')
            .join('\n');
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = l10n.myProfileSaveErrorSnack(e.toString());
      });
    }
  }

  String _humanField(String key, AppLocalizations l10n) {
    switch (key) {
      case 'name':
        return l10n.myProfileNameFieldHumanLabel;
      case 'email':
        return l10n.myProfileEmailFieldHumanLabel;
      case 'phone':
        return l10n.myProfilePhoneFieldHumanLabel;
      default:
        return key;
    }
  }

  bool get _emailDirty =>
      _baseline != null && _emailCtrl.text.trim() != _baseline!.email;
  bool get _phoneDirty =>
      _baseline != null && _phoneCtrl.text.trim() != _baseline!.phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.myProfilePageTitle,
        centerTitle: true,
        actions: [
          if (!_editing)
            StreamBuilder<MyProfile>(
              stream: _profileRepo.watch(),
              builder: (context, snap) {
                final enabled = snap.hasData;
                return TextButton(
                  onPressed: enabled ? () => _enterEdit(snap.data!) : null,
                  child: AppLabel(
                    text: l10n.myProfileEditAction,
                    fontSize: AppFontSize.value14,
                    color: enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _cancelEdit,
              child: AppLabel(
                text: l10n.commonCancelAction,
                fontSize: AppFontSize.value14,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            StreamBuilder<MyProfile>(
              stream: _profileRepo.watch(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final live = snap.data!;
                // When not editing, keep _draft in sync with the live
                // record so the view sections always paint the latest.
                final view = _editing ? (_draft ?? live) : live;
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          top: context.dynamicAppBarPadding,
                          left: 16,
                          right: 16,
                          bottom: _editing ? 24 : 100,
                        ),
                        children: [
                          _HeroCard(
                            profile: view,
                            // Avatar picker is always tappable — uploading a
                            // photo shouldn't require entering Edit mode.
                            editable: true,
                            onPickAvatar: _showAvatarSheet,
                          )
                              .animate()
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.04, end: 0, duration: 350.ms),
                          const SizedBox(height: 24),
                          _SectionLabel(text: l10n.myProfileContactSection),
                          const SizedBox(height: 8),
                          _editing
                              ? _ContactEditCard(
                                  nameCtrl: _nameCtrl,
                                  emailCtrl: _emailCtrl,
                                  phoneCtrl: _phoneCtrl,
                                  emailDirty: _emailDirty,
                                  phoneDirty: _phoneDirty,
                                  onAnyChange: () => setState(() {}),
                                  employeeId: view.employeeId,
                                  hiredAt: view.hiredAt,
                                )
                              : _ContactViewCard(profile: view)
                                  .animate()
                                  .fadeIn(delay: 80.ms)
                                  .slideY(
                                    begin: 0.04,
                                    end: 0,
                                    duration: 320.ms,
                                  ),
                          const SizedBox(height: 20),
                          _SectionLabel(text: l10n.myProfilePersonalSection),
                          const SizedBox(height: 8),
                          _editing
                              ? _PersonalEditCard(
                                  birthdate: view.birthdate,
                                  onPickBirthdate: () =>
                                      _pickBirthdate(view.birthdate),
                                  addressCtrl: _addressCtrl,
                                  emergencyNameCtrl: _emergencyNameCtrl,
                                  emergencyPhoneCtrl: _emergencyPhoneCtrl,
                                )
                              : _PersonalViewCard(profile: view)
                                  .animate()
                                  .fadeIn(delay: 160.ms)
                                  .slideY(
                                    begin: 0.04,
                                    end: 0,
                                    duration: 320.ms,
                                  ),
                          if (!_editing) ...[
                            const SizedBox(height: 20),
                            _SectionLabel(text: l10n.myProfileAccountSecuritySection),
                            const SizedBox(height: 8),
                            _SecurityCard(profile: view)
                                .animate()
                                .fadeIn(delay: 240.ms)
                                .slideY(
                                  begin: 0.04,
                                  end: 0,
                                  duration: 320.ms,
                                ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                              ),
                              child: AppLabel(
                                text: _errorMessage!,
                                fontSize: AppFontSize.value14,
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_editing)
                      _SaveBar(
                        saving: _saving,
                        onSave: _save,
                        onCancel: _saving ? null : _cancelEdit,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAvatarSheet() async {
    // Sheet UI lives in the shared `AvatarPickerSheet` widget — every
    // surface that needs a "Take photo / Choose from gallery" picker
    // routes through it so the look is identical to the Chat Info
    // change-photo sheet. Title/subtitle adapt to whether a photo is
    // already set, and the destructive "Remove photo" tile is shown
    // only when there's something to remove — same contextual pattern
    // as the chat sheet (Slice 10.3.5).
    //
    // Read the avatar status from the repo directly, NOT from
    // `_baseline`/`_draft` — those fields are only populated inside
    // Edit mode, and the avatar sheet opens without entering Edit, so
    // checking the local copies would always report "no photo".
    final current = await _profileRepo.get();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    // A photo exists if EITHER the local optimistic file is set OR
    // the server has stored a URL — both cases enable "Remove photo".
    final hasPhoto = (current.avatarFilePath ?? '').isNotEmpty ||
        (current.avatarUrl ?? '').isNotEmpty;
    final choice = await AvatarPickerSheet.show(
      context: context,
      title: hasPhoto ? l10n.myProfileChangePhotoSheetTitle : l10n.myProfileAddPhotoSheetTitle,
      subtitle: l10n.myProfilePhotoLocalSheetSubtitle,
      allowRemove: hasPhoto,
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case AvatarPickChoice.camera:
        await _pickImage(ImageSource.camera);
      case AvatarPickChoice.gallery:
        await _pickImage(ImageSource.gallery);
      case AvatarPickChoice.remove:
        await _profileRepo.clearAvatar();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        // Cap the long edge so we don't haul a 12-megapixel JPEG into
        // memory for a 88×88 avatar.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      // Ensure the file is still readable when the picker callback
      // fires — on some Android devices the OS hands back a path the
      // app no longer has access to once the picker activity closes.
      final file = File(picked.path);
      if (!await file.exists()) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.myProfileImageReadErrorSnack),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await _profileRepo.setAvatarPath(picked.path);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.myProfileImagePickErrorSnack(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickBirthdate(DateTime current) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: l10n.myProfileBirthdateLabel,
    );
    if (picked == null) return;
    setState(() {
      _draft = (_draft ?? _baseline)?.copyWith(birthdate: picked);
    });
  }
}

// ── Hero card ────────────────────────────────────────────────────

/// Modern profile hero card. Three layers:
///   1. Gradient surface clipped to an extra-rounded rect.
///   2. Soft decorative blobs (two off-canvas circles) for depth.
///   3. Foreground column — avatar with double-ring + status dot,
///      name, inline role · department, and a 3-stat footer split
///      by vertical dividers (Employee ID, Tenure, Last login).
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.editable,
    this.onPickAvatar,
  });

  final MyProfile profile;
  final bool editable;
  final VoidCallback? onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              Color.lerp(
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
                0.55,
              )!,
              theme.colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative blobs for visual depth — purely cosmetic.
            Positioned(
              top: -60,
              right: -40,
              child: _Blob(
                size: 180,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -50,
              child: _Blob(
                size: 200,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                children: [
                  _Avatar(
                    profile: profile,
                    editable: editable,
                    onTap: onPickAvatar,
                  ),
                  const SizedBox(height: 14),
                  AppLabel(
                    text: profile.name,
                    fontSize: AppFontSize.value24,
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  // Inline position · department — cleaner than two
                  // chips. `position` is the HR job title; RBAC roles
                  // live on the My Roles page.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      AppLabel(
                        text: profile.position,
                        fontSize: AppFontSize.value14,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      AppLabel(
                        text: profile.department,
                        fontSize: AppFontSize.value14,
                        color: theme.colorScheme.onPrimary
                            .withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Frosted stats strip.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: theme.colorScheme.onPrimary
                            .withValues(alpha: 0.22),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.badge_outlined,
                              label: l10n.myProfileEmployeeRowLabel,
                              value: profile.employeeId,
                            ),
                          ),
                          _StatDivider(),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.workspace_premium_outlined,
                              label: l10n.myProfileTenureRowLabel,
                              value: _tenureFor(profile.hiredAt, l10n),
                            ),
                          ),
                          _StatDivider(),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.schedule_rounded,
                              label: l10n.myProfileLastLoginRowLabel,
                              value: _relativeDay(profile.lastLoginAt, l10n),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _tenureFor(DateTime hiredAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final months = (now.year - hiredAt.year) * 12 + (now.month - hiredAt.month);
    if (months < 1) return l10n.myProfileTenureLessThanMonth;
    if (months < 12) return l10n.myProfileTenureMonths(months);
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (remMonths == 0) {
      return years == 1 ? l10n.myProfileTenureYear(years) : l10n.myProfileTenureYears(years);
    }
    return l10n.myProfileTenureYearsMonths(years, remMonths);
  }

  static String _relativeDay(DateTime when, AppLocalizations l10n) {
    final now = DateTime.now();
    final whenDay = DateTime(when.year, when.month, when.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(whenDay).inDays;
    if (diff <= 0) return l10n.myProfileRelativeToday;
    if (diff == 1) return l10n.myProfileRelativeYesterday;
    if (diff < 7) return l10n.myProfileRelativeDaysAgo(diff);
    if (diff < 30) return l10n.myProfileRelativeWeeksAgo((diff / 7).floor());
    if (diff < 365) return l10n.myProfileRelativeMonthsAgo((diff / 30).floor());
    return l10n.myProfileRelativeYearsAgo((diff / 365).floor());
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.profile,
    required this.editable,
    this.onTap,
  });
  final MyProfile profile;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Local picker file takes priority over the server URL — covers
    // the optimistic-update window after the user picks a photo but
    // before the multipart upload finishes. Network URL is the
    // canonical source once the upload returns.
    final hasLocalPhoto = profile.avatarFilePath != null;
    final hasRemotePhoto =
        !hasLocalPhoto && (profile.avatarUrl ?? '').isNotEmpty;
    final hasPhoto = hasLocalPhoto || hasRemotePhoto;
    final innerGradient = _avatarGradient(theme, profile.avatarTone ?? 0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Outer faint ring — sets the avatar apart from the background.
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
            ),
          ),
          // White ring.
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.30),
              border: Border.all(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ),
          // Photo / initials surface.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto ? null : innerGradient,
              color: hasPhoto ? theme.colorScheme.surface : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              image: hasLocalPhoto
                  ? DecorationImage(
                      image: FileImage(File(profile.avatarFilePath!)),
                      fit: BoxFit.cover,
                    )
                  : hasRemotePhoto
                      ? DecorationImage(
                          // `headers` carries the Bearer token —
                          // Spring's upload route is auth-gated and
                          // `NetworkImage` doesn't attach the dio
                          // interceptor on its own.
                          image: NetworkImage(
                            profile.avatarUrl!,
                            headers: profile.avatarHeaders,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? null
                : AppLabel(
                    text: profile.displayInitials,
                    fontSize: AppFontSize.value32,
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
          ),
          // Online status dot (bottom-right).
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade500,
                border: Border.all(
                  color: theme.colorScheme.onPrimary,
                  width: 2.5,
                ),
              ),
            ),
          ),
          // Camera overlay — always tappable per current contract.
          if (editable)
            Positioned(
              left: 4,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static LinearGradient _avatarGradient(ThemeData theme, int tone) {
    switch (tone % 4) {
      case 1:
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.pink.shade400],
        );
      case 2:
        return LinearGradient(
          colors: [Colors.green.shade500, Colors.teal.shade400],
        );
      case 3:
        return LinearGradient(
          colors: [Colors.indigo.shade400, Colors.purple.shade400],
        );
      default:
        return LinearGradient(
          colors: [
            theme.colorScheme.tertiary,
            theme.colorScheme.primary,
          ],
        );
    }
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.22),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
        ),
        const SizedBox(height: 4),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value14,
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        AppLabel(
          text: label.toUpperCase(),
          fontSize: AppFontSize.value9,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Section header ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: AppLabel(
        text: text.toUpperCase(),
        fontSize: AppFontSize.value11,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Card frame ───────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

// ── View mode ────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: label,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                AppLabel(
                  text: value.isEmpty ? '—' : value,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactViewCard extends StatelessWidget {
  const _ContactViewCard({required this.profile});
  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final df = DateFormat('d MMM yyyy');
    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.mail_outline,
            label: l10n.commonEmailLabel,
            value: profile.email,
            iconColor: Colors.blue,
          ),
          const Divider(height: 1, indent: 52),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: l10n.commonPhoneLabel,
            value: profile.phone,
            iconColor: Colors.green,
          ),
          const Divider(height: 1, indent: 52),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: l10n.myProfileEmployeeIdLabel,
            value: profile.employeeId,
            iconColor: Colors.deepPurple,
          ),
          const Divider(height: 1, indent: 52),
          _InfoRow(
            icon: Icons.event_available_outlined,
            label: l10n.myProfileHireDateLabel,
            value: df.format(profile.hiredAt),
            iconColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}

class _PersonalViewCard extends StatelessWidget {
  const _PersonalViewCard({required this.profile});
  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final df = DateFormat('d MMM yyyy');
    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.cake_outlined,
            label: l10n.myProfileBirthdateLabel,
            value: df.format(profile.birthdate),
            iconColor: Colors.pink,
          ),
          const Divider(height: 1, indent: 52),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: l10n.myProfileAddressLabel,
            value: profile.address,
            iconColor: Colors.orange.shade700,
          ),
          const Divider(height: 1, indent: 52),
          _InfoRow(
            icon: Icons.person_outline,
            label: l10n.myProfileEmergencyContactLabel,
            value: profile.emergencyContactName,
            iconColor: Colors.red,
          ),
          const Divider(height: 1, indent: 52),
          _InfoRow(
            icon: Icons.phone_in_talk_outlined,
            label: l10n.myProfileEmergencyPhoneLabel,
            value: profile.emergencyContactPhone,
            iconColor: Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}

// ── Edit mode ────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.helper,
    this.helperTone = _HelperTone.neutral,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final String? helper;
  final _HelperTone helperTone;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            isDense: true,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                helperTone == _HelperTone.warning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                size: 14,
                color: helperTone == _HelperTone.warning
                    ? Colors.orange.shade800
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppLabel(
                  text: helper!,
                  fontSize: AppFontSize.value12,
                  color: helperTone == _HelperTone.warning
                      ? Colors.orange.shade800
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _HelperTone { neutral, warning }

class _ContactEditCard extends StatelessWidget {
  const _ContactEditCard({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.emailDirty,
    required this.phoneDirty,
    required this.onAnyChange,
    required this.employeeId,
    required this.hiredAt,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool emailDirty;
  final bool phoneDirty;
  final VoidCallback onAnyChange;
  final String employeeId;
  final DateTime hiredAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final df = DateFormat('d MMM yyyy');
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _EditField(
              controller: nameCtrl,
              label: l10n.myProfileFullNameLabel,
              icon: Icons.person_outline,
              onChanged: (_) => onAnyChange(),
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: emailCtrl,
              label: l10n.commonEmailLabel,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              helper: emailDirty ? l10n.myProfileEmailRequiresVerificationHelper : null,
              helperTone: _HelperTone.warning,
              onChanged: (_) => onAnyChange(),
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: phoneCtrl,
              label: l10n.commonPhoneLabel,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              helper: phoneDirty ? l10n.myProfilePhoneRequiresVerificationHelper : null,
              helperTone: _HelperTone.warning,
              onChanged: (_) => onAnyChange(),
            ),
            const SizedBox(height: 12),
            _ReadOnlyField(
              icon: Icons.badge_outlined,
              label: l10n.myProfileEmployeeIdLabel,
              value: employeeId,
              hint: l10n.myProfileManagedByHrBadge,
            ),
            const SizedBox(height: 12),
            _ReadOnlyField(
              icon: Icons.event_available_outlined,
              label: l10n.myProfileHireDateLabel,
              value: df.format(hiredAt),
              hint: l10n.myProfileManagedByHrBadge,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalEditCard extends StatelessWidget {
  const _PersonalEditCard({
    required this.birthdate,
    required this.onPickBirthdate,
    required this.addressCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
  });

  final DateTime birthdate;
  final VoidCallback onPickBirthdate;
  final TextEditingController addressCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final df = DateFormat('d MMM yyyy');
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            InkWell(
              onTap: onPickBirthdate,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabel(
                            text: l10n.myProfileBirthdateLabel,
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          AppLabel(
                            text: df.format(birthdate),
                            fontSize: AppFontSize.value14,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: addressCtrl,
              label: l10n.myProfileAddressLabel,
              icon: Icons.location_on_outlined,
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: emergencyNameCtrl,
              label: l10n.myProfileEmergencyContactLabel,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: emergencyPhoneCtrl,
              label: l10n.myProfileEmergencyPhoneLabel,
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });
  final IconData icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: label,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                AppLabel(
                  text: value,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: AppLabel(
              text: hint,
              fontSize: AppFontSize.value9,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Save bar ─────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final bool saving;
  final VoidCallback onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: AppLabel(
                  text: l10n.commonCancelAction,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : AppLabel(
                        text: l10n.myProfileSaveChangesAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account security card ────────────────────────────────────────

class _SecurityCard extends StatefulWidget {
  const _SecurityCard({required this.profile});
  final MyProfile profile;

  @override
  State<_SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends State<_SecurityCard> {
  final _appLockRepo = GetIt.I<AppLockSettingsRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final df = DateFormat('d MMM yyyy · HH:mm');
    return _Card(
      child: Column(
        children: [
          _SecurityRow(
            icon: Icons.password_rounded,
            iconColor: Colors.blue,
            title: l10n.myProfileChangePasswordTitle,
            subtitle: l10n.myProfileChangePasswordSubtitle,
            onTap: () => _confirmReAuth(
              context,
              title: l10n.myProfileChangePasswordTitle,
              message: l10n.myProfileChangePasswordReAuthMessage,
              onConfirmed: () =>
                  _showStub(context, l10n.myProfilePasswordChangeStubSnack),
            ),
          ),
          const Divider(height: 1, indent: 52),
          _SecurityRow(
            icon: Icons.pin_outlined,
            iconColor: Colors.deepPurple,
            title: l10n.myProfileChangePinTitle,
            subtitle: l10n.myProfileChangePinSubtitle,
            onTap: () => _confirmReAuth(
              context,
              title: l10n.myProfileChangePinTitle,
              message: l10n.myProfileChangePinReAuthMessage,
              onConfirmed: () =>
                  ConfigRouter.pushPageAnimation(context, const AppLockPage()),
            ),
          ),
          const Divider(height: 1, indent: 52),
          StreamBuilder<AppLockSettings>(
            stream: _appLockRepo.watch(),
            builder: (context, snap) {
              final settings = snap.data ?? AppLockSettings.initial;
              return _BiometricSwitchRow(
                enabled: settings.biometricEnabled,
                onChanged: (next) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (next) {
                    final ok = await _confirmReAuth(
                      context,
                      title: l10n.myProfileEnableBiometricTitle,
                      message: l10n.myProfileEnableBiometricReAuthMessage,
                    );
                    if (!ok || !context.mounted) return;
                  }
                  try {
                    await _appLockRepo.setBiometricEnabled(
                      current: settings,
                      enabled: next,
                    );
                  } on ConflictFailure catch (f) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(f.message ?? l10n.myProfileCannotToggleBiometricFallback),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          ),
          const Divider(height: 1, indent: 52),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppLabel(
                    text: l10n.myProfileLastLoginAtLabel(df.format(widget.profile.lastLoginAt)),
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: AppLabel(
                    text: widget.profile.lastLoginDevice,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: title,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w700,
                  ),
                  AppLabel(
                    text: subtitle,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: AppLabel(
                text: l10n.myProfileReAuthBadge,
                fontSize: AppFontSize.value9,
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricSwitchRow extends StatelessWidget {
  const _BiometricSwitchRow({
    required this.enabled,
    required this.onChanged,
  });
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.pink,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: l10n.myProfileBiometricUnlockTitle,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.w700,
                ),
                AppLabel(
                  text: enabled
                      ? l10n.myProfileBiometricEnabledSubtitle
                      : l10n.myProfileBiometricDisabledSubtitle,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Shared re-auth confirmation sheet — returns `true` when the user
/// presses "Confirm" with a non-empty password value. Used for change
/// password / change PIN / enabling biometric, per the design spec.
///
/// The TextEditingController is owned by [_ReAuthSheet] (a private
/// StatefulWidget) so Flutter handles its `dispose()` after the sheet's
/// descendants have finished deactivating. Owning the controller in the
/// outer Future and calling `dispose()` after `await showModalBottomSheet`
/// trips the framework's `_dependents.isEmpty` assertion on InputDecorator.
Future<bool> _confirmReAuth(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onConfirmed,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => _ReAuthSheet(title: title, message: message),
  );
  if (confirmed == true && onConfirmed != null) onConfirmed();
  return confirmed == true;
}

class _ReAuthSheet extends StatefulWidget {
  const _ReAuthSheet({required this.title, required this.message});
  final String title;
  final String message;

  @override
  State<_ReAuthSheet> createState() => _ReAuthSheetState();
}

class _ReAuthSheetState extends State<_ReAuthSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer
                      .withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppLabel(
                  text: widget.title,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppLabel(
            text: widget.message,
            fontSize: AppFontSize.value12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.myProfileCurrentPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: l10n.commonCancelAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    if (_ctrl.text.isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: AppLabel(
                    text: l10n.myProfileConfirmAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
