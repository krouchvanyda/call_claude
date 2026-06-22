import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/export/csv_writer.dart';
import '../../../l10n/app_localizations.dart';
import '../entities/trial_balance_row.dart';

/// Writes the trial balance to a CSV file in the app's documents
/// directory (Slice 3.3.3).
///
/// **Why local file, not share-sheet**: `share_plus` would be the
/// natural next step but it's a new dependency + native plumbing.
/// Writing to documents + showing the path in a Snackbar is enough to
/// demo the export pipeline; a follow-up slice can add the share
/// intent (or `printing` for direct print).
///
/// **BOM prefix** (`﻿`): Excel-on-Windows treats files without
/// a BOM as the system codepage rather than UTF-8, mangling the `$`
/// in formatted amounts on some locales. The BOM forces UTF-8.
Future<void> exportTrialBalanceCsv(
  BuildContext context,
  List<TrialBalanceRow> rows,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final csv = CsvWriter.encode(
      header: const [
        'Code',
        'Account',
        'Type',
        'Debit',
        'Credit',
      ],
      rows: [
        for (final r in rows)
          [
            r.accountCode,
            r.accountName,
            r.accountType.name,
            r.debit,
            r.credit,
          ],
      ],
    );
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'trial-balance-$stamp.csv'));
    await file.writeAsBytes(
      utf8.encode('﻿$csv'),
      flush: true,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.trialBalanceExportSuccess(file.path)),
        duration: const Duration(seconds: 5),
      ));
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.trialBalanceExportError(e.toString())),
      ));
  }
}
