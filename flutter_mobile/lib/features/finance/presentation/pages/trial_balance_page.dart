import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/trial_balance_repository.dart';
import '../../entities/trial_balance_row.dart';
import '../trial_balance_csv_share.dart';

class TrialBalancePage extends StatefulWidget {
  const TrialBalancePage({super.key});

  @override
  State<TrialBalancePage> createState() => _TrialBalancePageState();
}

class _TrialBalancePageState extends State<TrialBalancePage> {
  static const _pageSize = 10;
  int _pageIndex = 0;
  late Future<List<TrialBalanceRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<TrialBalanceRepository>().getReport();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.trialBalanceTitle,
        centerTitle: true,
        actions: [
          FutureBuilder<List<TrialBalanceRow>>(
            future: _future,
            builder: (context, snap) {
              final rows = snap.data ?? const <TrialBalanceRow>[];
              return IconButton(
                tooltip: l10n.trialBalanceExportCsvTooltip,
                icon: const Icon(Icons.file_download_rounded),
                onPressed: rows.isEmpty ? null : () => exportTrialBalanceCsv(context, rows),
              );
            },
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<List<TrialBalanceRow>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data ?? const <TrialBalanceRow>[];
            if (rows.isEmpty) {
              return _CenteredMessage(
                text: l10n.trialBalanceEmpty,
                icon: Icons.table_chart_outlined,
              );
            }
            final pageRows = paginate(
              rows,
              pageIndex: _pageIndex,
              pageSize: _pageSize,
            );
            final totalPages = pageCount(
              totalItems: rows.length,
              pageSize: _pageSize,
            );

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: context.dynamicAppBarPadding,
                      left: 16,
                      right: 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                          headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                          dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          horizontalMargin: 20,
                          columnSpacing: 24,
                          columns: [
                            DataColumn(label: Text(l10n.trialBalanceColumnCode.toUpperCase())),
                            DataColumn(label: Text(l10n.trialBalanceColumnName.toUpperCase())),
                            DataColumn(label: Text(l10n.trialBalanceColumnDebit.toUpperCase()), numeric: true),
                            DataColumn(label: Text(l10n.trialBalanceColumnCredit.toUpperCase()), numeric: true),
                          ],
                          rows: [
                            for (final r in pageRows)
                              DataRow(cells: [
                                DataCell(AppLabel(
                                  text: r.accountCode,
                                  fontSize: AppFontSize.value14,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                )),
                                DataCell(Text(r.accountName)),
                                DataCell(AppLabel(
                                  text: r.debit,
                                  fontSize: AppFontSize.value14,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                )),
                                DataCell(AppLabel(
                                  text: r.credit,
                                  fontSize: AppFontSize.value14,
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                )),
                              ]),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05, end: 0),
                  ),
                ),
                _Pager(
                  pageIndex: _pageIndex,
                  totalPages: totalPages,
                  onPrev: _pageIndex == 0 ? null : () => setState(() => _pageIndex--),
                  onNext: _pageIndex >= totalPages - 1 ? null : () => setState(() => _pageIndex++),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.pageIndex, required this.totalPages, required this.onPrev, required this.onNext});
  final int pageIndex;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppLabel(
            text: l10n.trialBalancePageOf(pageIndex + 1, totalPages).toUpperCase(),
            fontSize: AppFontSize.value11,
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
                style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.table_chart_rounded,
                size: 64, 
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value16,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
