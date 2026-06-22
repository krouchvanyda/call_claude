import 'package:flutter/material.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../entities/invoice.dart';

/// Slice 3.2.4 approve-confirmation bottom sheet.
///
/// Returns `true` when the user taps "Approve", `null`/false otherwise.
class ApproveInvoiceBottomSheet extends StatelessWidget {
  const ApproveInvoiceBottomSheet({super.key, required this.invoice});

  final Invoice invoice;

  static Future<bool?> show(BuildContext context, Invoice invoice) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ApproveInvoiceBottomSheet(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                AppLabel(
                  text: l10n.invoiceApproveSheetTitle,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppLabel(
              text: l10n.invoiceApproveSheetBody(invoice.invoiceNumber),
              fontSize: AppFontSize.value14,
            ),
            const SizedBox(height: 4),
            AppLabel(
              text: '${invoice.customerName} · ${invoice.totalAmount}',
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: AppLabel(
                      text: l10n.invoiceActionCancel,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check),
                    label: AppLabel(
                      text: l10n.invoiceApproveAction,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
