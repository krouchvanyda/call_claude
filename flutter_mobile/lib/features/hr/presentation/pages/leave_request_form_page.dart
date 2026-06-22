import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/leave_requests_repository.dart';
import '../../entities/leave_request.dart';

/// Slice 7.2.1 — leave request form with calendar pickers.
///
/// **Submit path**: validate via [validateLeaveRequest] (pure-Dart) →
/// hand off to the repo. Field errors come back as
/// [`ValidationFailure.fieldErrors`] so we can attach them per-input
/// rather than dumping a single banner.
class LeaveRequestFormPage extends StatefulWidget {
  const LeaveRequestFormPage({
    super.key,
    this.employeeId = 'emp-001',
    this.employeeName = 'Demo Approver',
  });

  final String employeeId;
  final String employeeName;

  @override
  State<LeaveRequestFormPage> createState() => _LeaveRequestFormPageState();
}

class _LeaveRequestFormPageState extends State<LeaveRequestFormPage> {
  LeaveType _type = LeaveType.annual;
  DateTime? _from;
  DateTime? _to;
  final _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _topError;

  // Modern File Upload / Attachment States
  String? _attachedFileName;
  String? _attachedFileSize;
  bool _isUploadingAttachment = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_from ?? DateTime.now())
        : (_to ?? _from ?? DateTime.now());
    final first = isFrom ? DateTime.now() : (_from ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_to != null && _to!.isBefore(picked)) _to = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  // Trigger Attachment Selection
  void _pickAttachment() {
    setState(() => _isUploadingAttachment = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _attachedFileName = 'medical_certificate_slip.pdf';
        _attachedFileSize = '1.4 MB';
        _isUploadingAttachment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_attachedFileName}" attached successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _removeAttachment() {
    setState(() {
      _attachedFileName = null;
      _attachedFileSize = null;
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _isSubmitting = true;
      _topError = null;
      _fieldErrors = const {};
    });
    try {
      final repo = GetIt.I<LeaveRequestsRepository>();
      final draft = repo.submit(
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        type: _type,
        fromDate: _from ?? DateTime.fromMillisecondsSinceEpoch(0),
        toDate: _to ?? DateTime.fromMillisecondsSinceEpoch(0),
        reason: _reasonCtrl.text,
        now: DateTime.now(),
      );
      await repo.create(draft);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.hrLeaveFormSubmittedSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop();
    } on ValidationFailure catch (f) {
      setState(() => _fieldErrors = f.fieldErrors);
    } catch (e) {
      setState(() => _topError = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _errFor(String key) {
    final list = _fieldErrors[key];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final balanceRepo = GetIt.I<LeaveBalancesRepository>();

    String fmt(DateTime? d) =>
        d == null ? 'Select date' : d.toIso8601String().split('T').first;

    // Calculated Day Duration
    int daysCount = 0;
    if (_from != null && _to != null) {
      final start = DateTime.utc(_from!.year, _from!.month, _from!.day);
      final end = DateTime.utc(_to!.year, _to!.month, _to!.day);
      daysCount = end.difference(start).inDays + 1;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrLeaveFormPageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            ListView(
              padding: EdgeInsets.only(
                top: context.dynamicAppBarPadding + 50,
                left: 16,
                right: 16,
                bottom: 16, // Extra padding to avoid overlapping the floating bottom bar
              ),
              children: [


                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLabel(
                        text: l10n.hrLeaveFormPreferencesSection,
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      const SizedBox(height: 16),

                      // Leave Type Dropdown
                      DropdownButtonFormField<LeaveType>(
                        initialValue: _type,
                        decoration: InputDecoration(
                          labelText: 'Leave Type',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: LeaveType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: AppLabel(
                                    text: t.name.toUpperCase(),
                                    fontSize: AppFontSize.value14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _type = v ?? LeaveType.annual),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 16),

                      // Live Entitlement Balance Stream Row
                      StreamBuilder<List<LeaveBalance>>(
                        stream: balanceRepo.watchForEmployee(widget.employeeId),
                        builder: (context, balanceSnap) {
                          final list = balanceSnap.data ?? const <LeaveBalance>[];
                          final currentBalance = list.isEmpty
                              ? null
                              : list.firstWhere(
                                  (b) => b.type == _type,
                                  orElse: () => list.first,
                                );
                          if (currentBalance == null) return const SizedBox.shrink();

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppLabel(
                                  text:
                                      'Current ${_type.name.toUpperCase()} Balance:',
                                  fontSize: AppFontSize.value12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                AppLabel(
                                  text:
                                      '${currentBalance.remainingDays} days available',
                                  fontSize: AppFontSize.value12,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 50.ms),
                      const Divider(height: 36),

                      AppLabel(
                        text: l10n.hrLeaveFormDurationSection,
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      const SizedBox(height: 12),

                      // Premium Date Pickers - Vertical Split Stacking
                      _CustomDatePickerTile(
                        labelText: 'Start Date',
                        valueText: fmt(_from),
                        isSelected: _from != null,
                        errorText: _errFor('fromDate'),
                        onTap: () => _pickDate(isFrom: true),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _CustomDatePickerTile(
                        labelText: 'End Date',
                        valueText: fmt(_to),
                        isSelected: _to != null,
                        errorText: _errFor('toDate'),
                        onTap: () => _pickDate(isFrom: false),
                      ),

                      if (daysCount > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal,
                                Colors.teal.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppLabel(
                                  text:
                                      'You are requesting $daysCount consecutive working days of leave.',
                                  fontSize: AppFontSize.value14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
                      ],
                      const Divider(height: 36),

                      AppLabel(
                        text: l10n.hrLeaveFormAttachmentsSection,
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      const SizedBox(height: 12),

                      // Premium File Upload Attachment Card
                      _FileAttachmentCard(
                        fileName: _attachedFileName,
                        fileSize: _attachedFileSize,
                        isUploading: _isUploadingAttachment,
                        onAttach: _pickAttachment,
                        onRemove: _removeAttachment,
                      ).animate().fadeIn(delay: 150.ms),

                      const Divider(height: 36),

                      AppLabel(
                        text: l10n.hrLeaveFormJustificationSection,
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      const SizedBox(height: 12),

                      // Reason Input Field
                      TextField(
                        controller: _reasonCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Reason for Leave',
                          alignLabelWithHint: true,
                          errorText: _errFor('reason'),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 56.0),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      if (_topError != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppLabel(
                                  text: _topError!,
                                  fontSize: AppFontSize.value14,
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Sticky, Frosted Glassmorphic Bottom Navigation Bar
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  elevation: 0,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : AppLabel(
                        text: l10n.hrLeaveFormSubmitAction,
                        fontSize: AppFontSize.value16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _CustomDatePickerTile extends StatelessWidget {
  const _CustomDatePickerTile({
    required this.labelText,
    required this.valueText,
    required this.isSelected,
    required this.onTap,
    this.errorText,
  });

  final String labelText;
  final String valueText;
  final bool isSelected;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(
          text: labelText,
          fontSize: AppFontSize.value12,
          color: isError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.03)
                  : theme.colorScheme.surfaceVariant.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isError
                    ? theme.colorScheme.error
                    : isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isError
                      ? theme.colorScheme.error
                      : isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppLabel(
                    text: valueText,
                    fontSize: AppFontSize.value14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isError
                        ? theme.colorScheme.error
                        : isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AppLabel(
              text: errorText!,
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _FileAttachmentCard extends StatelessWidget {
  const _FileAttachmentCard({
    required this.fileName,
    required this.fileSize,
    required this.isUploading,
    required this.onAttach,
    required this.onRemove,
  });

  final String? fileName;
  final String? fileSize;
  final bool isUploading;
  final VoidCallback onAttach;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isAttached = fileName != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isUploading
          ? Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 12),
                  AppLabel(
                    text: l10n.hrLeaveFormUploadingAttachment,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            )
          : isAttached
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppLabel(
                              text: fileName!,
                              fontSize: AppFontSize.value14,
                              fontWeight: FontWeight.bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AppLabel(
                                  text: fileSize!,
                                  fontSize: AppFontSize.value11,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 8),
                                const CircleAvatar(radius: 2, backgroundColor: Colors.green),
                                const SizedBox(width: 4),
                                AppLabel(
                                  text: l10n.hrLeaveFormReadyToUpload,
                                  fontSize: AppFontSize.value11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.hrLeaveFormRemoveAttachmentTooltip,
                        icon: Icon(Icons.cancel_rounded, color: theme.colorScheme.outline),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                )
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAttach,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          AppLabel(
                            text: l10n.hrLeaveFormTapToUploadDocument,
                            fontSize: AppFontSize.value11,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                          const SizedBox(height: 6),
                          AppLabel(
                            text: l10n.hrLeaveFormUploadSupportedFormats,
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.outline,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
