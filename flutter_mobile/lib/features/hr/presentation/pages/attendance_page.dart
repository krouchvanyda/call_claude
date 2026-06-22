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
import '../../data/repositories/attendance_repository.dart';
import '../../entities/attendance_entry.dart';

/// Slice 7.3.1 — clock-in / clock-out + recent log.
///
/// The button text + colour follows whatever [resolveClockAction] would
/// do next given the latest entry, so the page truth is the use case,
/// not local UI state.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, this.employeeId = 'emp-001'});
  final String employeeId;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _toggle() async {
    final repo = GetIt.I<AttendanceRepository>();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final latest = await repo.latestFor(widget.employeeId);
      final action = repo.toggleClock(
        latest: latest,
        employeeId: widget.employeeId,
        now: DateTime.now(),
        newId: () => 'att-${DateTime.now().microsecondsSinceEpoch}',
      );
      switch (action) {
        case ClockInAction(:final draft):
          await repo.create(draft);
        case ClockOutAction(:final updated):
          await repo.update(updated);
      }
      if (mounted) setState(() {});
    } on ConflictFailure catch (f) {
      setState(() => _error = f.message ?? 'Conflict');
    } on ValidationFailure catch (f) {
      setState(() => _error =
          f.fieldErrors.values.expand((e) => e).join(', '));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = GetIt.I<AttendanceRepository>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.hrAttendancePageTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            ListView(
              padding: EdgeInsets.only(
                top: context.dynamicAppBarPadding + 60,
                left: 16,
                right: 16,
                bottom: 40,
              ),
              children: [
                FutureBuilder<AttendanceEntry?>(
                  future: repo.latestFor(widget.employeeId),
                  builder: (context, snap) {
                    final latest = snap.data;
                    final isOpen = latest?.isOpen ?? false;
                    final accentColor = isOpen ? Colors.teal : theme.colorScheme.primary;

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Clock Circle Visualisation
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.08),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.2),
                                width: 4,
                              ),
                            ),
                            child: Icon(
                              isOpen
                                  ? Icons.timer_outlined
                                  : Icons.timer_off_outlined,
                              size: 44,
                              color: accentColor,
                            ),
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 16),
                          AppLabel(
                            text: isOpen
                                ? 'YOU ARE CLOCKED IN'
                                : 'YOU ARE CLOCKED OUT',
                            fontSize: AppFontSize.value12,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 1.0,
                          ),
                          if (latest != null) ...[
                            const SizedBox(height: 8),
                            AppLabel(
                              text: isOpen
                                  ? 'Since ${_fmt(latest.clockIn)}'
                                  : 'Last out at ${_fmt(latest.clockOut!)}',
                              fontSize: AppFontSize.value14,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _isSubmitting ? null : _toggle,
                              style: FilledButton.styleFrom(
                                backgroundColor: isOpen ? theme.colorScheme.error : theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                ),
                              ),
                              icon: Icon(
                                isOpen ? Icons.logout_rounded : Icons.login_rounded,
                              ),
                              label: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : AppLabel(
                                      text: isOpen
                                          ? 'Clock Out Now'
                                          : 'Clock In Now',
                                      fontSize: AppFontSize.value16,
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: AppLabel(
                                text: _error!,
                                fontSize: AppFontSize.value12,
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                                textAlign: TextAlign.center,
                              ),
                            ).animate().shake(),
                          ],
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
                  },
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      AppLabel(
                        text: l10n.hrAttendanceRecentEntriesHeading,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<AttendanceEntry>>(
                  stream: repo.watchForEmployee(widget.employeeId),
                  builder: (context, snap) {
                    final entries = snap.data ?? const <AttendanceEntry>[];
                    if (entries.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 40,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              AppLabel(
                                text: l10n.hrAttendanceEmptyMessage,
                                fontSize: AppFontSize.value14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < entries.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EntryCard(entry: entries[i])
                                .animate()
                                .fadeIn(delay: (i * 30).ms)
                                .slideY(begin: 0.05, end: 0, duration: 250.ms),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      dt.toIso8601String().split('.').first.replaceFirst('T', ' ');
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = entry.workedMinutes / 60.0;
    final accentColor = entry.isOpen ? Colors.teal : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                entry.isOpen
                    ? Icons.timer_outlined
                    : Icons.check_circle_outline_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: entry.date.toIso8601String().split('T').first,
                    fontSize: AppFontSize.value16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppLabel(
                    text: entry.isOpen
                        ? 'In ${_fmtTime(entry.clockIn)} (open)'
                        : '${_fmtTime(entry.clockIn)}   ➔   ${_fmtTime(entry.clockOut!)}',
                    fontSize: AppFontSize.value14,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
            if (!entry.isOpen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: AppLabel(
                  text: '${hours.toStringAsFixed(1)} h',
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(DateTime dt) =>
      dt.toIso8601String().split('.').first.split('T').last.substring(0, 5);
}
