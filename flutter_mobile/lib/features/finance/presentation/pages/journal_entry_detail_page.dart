import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/journal_entries_repository.dart';
import '../../entities/journal_entry.dart';

/// Journal entry detail (Slice 3.3.1) — header + line table.
///
/// Shows the debit / credit columns side-by-side with totals at the
/// bottom, matching how accountants read entries on paper.
class JournalEntryDetailPage extends StatelessWidget {
  const JournalEntryDetailPage({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = getIt<JournalEntriesRepository>();
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.journalEntryDetailTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<JournalEntry?>(
        future: repo.findById(entryId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final entry = snap.data;
          if (entry == null) {
            return Center(
              child: AppLabel(
                text: l10n.journalEntryNotFound(entryId),
                fontSize: AppFontSize.value14,
              ),
            );
          }
          return _Body(entry: entry);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.entry});
  final JournalEntry entry;
  static final _date = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: entry.reference,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                AppLabel(
                  text: entry.description,
                  fontSize: AppFontSize.value14,
                ),
                const SizedBox(height: 8),
                AppLabel(
                  text: _date.format(entry.postedAt.toLocal()),
                  fontSize: AppFontSize.value11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppLabel(
                        text: l10n.journalEntryAccountColumn,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: AppLabel(
                        text: l10n.journalEntryDebitColumn,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      child: AppLabel(
                        text: l10n.journalEntryCreditColumn,
                        fontSize: AppFontSize.value12,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              for (final line in entry.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppLabel(
                          text: '${line.accountCode}  ${line.accountName}',
                          fontSize: AppFontSize.value14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Expanded(
                        child: AppLabel(
                          text: line.debit ?? '—',
                          fontSize: AppFontSize.value14,
                          color: line.debit == null
                              ? theme.colorScheme.outline
                              : theme.colorScheme.primary,
                          textAlign: TextAlign.end,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Expanded(
                        child: AppLabel(
                          text: line.credit ?? '—',
                          fontSize: AppFontSize.value14,
                          color: line.credit == null
                              ? theme.colorScheme.outline
                              : theme.colorScheme.tertiary,
                          textAlign: TextAlign.end,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppLabel(
                        text: l10n.journalEntryTotalLabel,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppLabel(
                      text: entry.formattedTotal,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
