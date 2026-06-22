import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/quotations_repository.dart';
import '../../data/repositories/sales_orders_repository.dart';
import '../../entities/sales_quotation.dart';
import 'quotation_list_page.dart' show QuotationStatusBadge;

/// Quotation detail (Slice 6.2.1 + 6.2.2 convert action).
class QuotationDetailPage extends StatefulWidget {
  const QuotationDetailPage({super.key, required this.quotationId});
  final String quotationId;

  @override
  State<QuotationDetailPage> createState() => _QuotationDetailPageState();
}

class _QuotationDetailPageState extends State<QuotationDetailPage> {
  late Future<SalesQuotation?> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<QuotationsRepository>().findById(widget.quotationId);
  }

  void _reload() {
    setState(() {
      _future = getIt<QuotationsRepository>().findById(widget.quotationId);
    });
  }

  Future<void> _setStatus(SalesQuotation q, QuotationStatus next) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await getIt<QuotationsRepository>().setStatus(q.id, next);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.salesQuotationStatusUpdated)));
      _reload();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesQuotationActionFailed(e.toString())),
        ));
    }
  }

  Future<void> _convert(SalesQuotation q) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome =
        convertQuotationToOrder(q, now: DateTime.now().toUtc());
    if (outcome.result != ConvertQuotationResult.ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(_convertErrorCopy(l10n, outcome.result)),
        ));
      return;
    }
    try {
      await getIt<SalesOrdersRepository>().create(outcome.draftOrder!);
      await getIt<QuotationsRepository>()
          .setStatus(q.id, outcome.updatedQuotation!.status);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.salesQuotationConvertedSnack)));
      _reload();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.salesQuotationActionFailed(e.toString())),
        ));
    }
  }

  static String _convertErrorCopy(
      AppLocalizations l10n, ConvertQuotationResult r) {
    return switch (r) {
      ConvertQuotationResult.notAccepted =>
        l10n.salesQuotationConvertNotAccepted,
      ConvertQuotationResult.alreadyConverted =>
        l10n.salesQuotationConvertAlready,
      ConvertQuotationResult.expired => l10n.salesQuotationConvertExpired,
      ConvertQuotationResult.ok => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLabel(
          text: l10n.salesQuotationDetailTitle,
          fontSize: AppFontSize.value20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<SalesQuotation?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final q = snap.data;
          if (q == null) {
            return Center(
              child: AppLabel(
                text: l10n.salesQuotationNotFound(widget.quotationId),
                fontSize: AppFontSize.value14,
              ),
            );
          }
          return _Body(quotation: q);
        },
      ),
      bottomNavigationBar: FutureBuilder<SalesQuotation?>(
        future: _future,
        builder: (context, snap) {
          final q = snap.data;
          if (q == null) return const SizedBox.shrink();
          return SafeArea(
              child: _ActionBar(
            quotation: q,
            onSetStatus: (s) => _setStatus(q, s),
            onConvert: () => _convert(q),
          ));
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.quotation,
    required this.onSetStatus,
    required this.onConvert,
  });

  final SalesQuotation quotation;
  final ValueChanged<QuotationStatus> onSetStatus;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    switch (quotation.status) {
      case QuotationStatus.draft:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => onSetStatus(QuotationStatus.sent),
            icon: const Icon(Icons.send_outlined),
            label: AppLabel(
              text: l10n.salesQuotationSendAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case QuotationStatus.sent:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onSetStatus(QuotationStatus.rejected),
                  icon: const Icon(Icons.close),
                  label: AppLabel(
                    text: l10n.salesQuotationRejectAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onSetStatus(QuotationStatus.accepted),
                  icon: const Icon(Icons.check),
                  label: AppLabel(
                    text: l10n.salesQuotationAcceptAction,
                    fontSize: AppFontSize.value14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      case QuotationStatus.accepted:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: onConvert,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: AppLabel(
              text: l10n.salesQuotationConvertAction,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case QuotationStatus.rejected:
      case QuotationStatus.expired:
      case QuotationStatus.converted:
        return const SizedBox.shrink();
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.quotation});
  final SalesQuotation quotation;
  static final _date = DateFormat('yyyy-MM-dd');

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
                Row(
                  children: [
                    Expanded(
                      child: AppLabel(
                        text: quotation.number,
                        fontSize: AppFontSize.value22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    QuotationStatusBadge(status: quotation.status),
                  ],
                ),
                const SizedBox(height: 4),
                AppLabel(
                  text: quotation.customerName,
                  fontSize: AppFontSize.value14,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      label: l10n.salesQuotationCreatedLabel,
                      value: _date.format(quotation.createdAt.toLocal()),
                    ),
                    _MetaChip(
                      label: l10n.salesQuotationValidUntilLabel2,
                      value: _date.format(quotation.validUntil.toLocal()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AppLabel(
                  text: l10n.salesQuotationDetailLinesHeading,
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final line in quotation.lineItems)
                ListTile(
                  dense: true,
                  title: AppLabel(
                    text: line.description,
                    fontSize: AppFontSize.value14,
                  ),
                  subtitle: line.sku == null
                      ? null
                      : AppLabel(
                          text: line.sku!,
                          fontSize: AppFontSize.value12,
                        ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLabel(
                        text: '${line.quantity} × ${line.unitPrice}',
                        fontSize: AppFontSize.value11,
                      ),
                      AppLabel(
                        text: line.lineTotal,
                        fontSize: AppFontSize.value14,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ],
                  ),
                ),
              const Divider(height: 0),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    AppLabel(
                      text: l10n.salesQuotationTotalLabel,
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w600,
                    ),
                    const Spacer(),
                    AppLabel(
                      text: quotation.totalAmount,
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
        if (quotation.notes != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(
                    text: l10n.salesQuotationNotesHeading,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  AppLabel(
                    text: quotation.notes!,
                    fontSize: AppFontSize.value14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLabel(
          text: label,
          fontSize: AppFontSize.value11,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value14,
        ),
      ],
    );
  }
}
