import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../entities/invoice.dart';
import '../bloc/reject_reason_form_bloc.dart';

/// Slice 3.2.4 reject bottom sheet with FormBLoC-driven validation.
///
/// Returns the trimmed reason on confirm; `null` on dismiss / cancel.
class RejectInvoiceBottomSheet extends StatelessWidget {
  const RejectInvoiceBottomSheet({super.key, required this.invoice});

  final Invoice invoice;

  static Future<String?> show(BuildContext context, Invoice invoice) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RejectInvoiceBottomSheet(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RejectReasonFormBloc(),
      child: _RejectBody(invoice: invoice),
    );
  }
}

class _RejectBody extends StatelessWidget {
  const _RejectBody({required this.invoice});
  final Invoice invoice;

  String _resolveError(AppLocalizations l10n, String? code) {
    return switch (code) {
      'required' => l10n.invoiceRejectReasonRequired,
      _ => '',
    };
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
        child: BlocBuilder<RejectReasonFormBloc, RejectReasonFormState>(
          builder: (context, state) {
            final bloc = context.read<RejectReasonFormBloc>();
            final errorText = state.error == null
                ? null
                : _resolveError(l10n, state.error);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    AppLabel(
                      text: l10n.invoiceRejectSheetTitle,
                      fontSize: AppFontSize.value16,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppLabel(
                  text: l10n.invoiceRejectSheetBody(invoice.invoiceNumber),
                  fontSize: AppFontSize.value14,
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (v) => bloc.add(RejectReasonChanged(v)),
                  decoration: InputDecoration(
                    labelText: l10n.invoiceRejectReasonLabel,
                    hintText: l10n.invoiceRejectReasonHint,
                    border: const OutlineInputBorder(),
                    errorText:
                        (errorText?.isEmpty ?? true) ? null : errorText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () {
                          bloc.add(const RejectReasonSubmitted());
                          final next = bloc.state;
                          if (next.isValid) {
                            Navigator.of(context).pop(next.reason.trim());
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: AppLabel(
                          text: l10n.invoiceRejectAction,
                          fontSize: AppFontSize.value14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
