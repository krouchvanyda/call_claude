import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/permission_guard.dart';
import '../../../auth/entities/permission.dart';
import '../../data/repositories/invoices_repository.dart';
import '../../entities/invoice.dart';
import '../../entities/invoice_detail.dart';
import '../../entities/invoice_line_item.dart';
import '../bloc/invoice_action_bloc.dart';
import '../bloc/invoice_action_event.dart';
import '../bloc/invoice_action_state.dart';
import '../widgets/approve_invoice_bottom_sheet.dart';
import '../widgets/reject_invoice_bottom_sheet.dart';
import 'invoice_list_page.dart' show invoiceStatusColor, invoiceStatusLabel;

class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceActionBloc>(
      create: (_) => getIt<InvoiceActionBloc>(),
      child: _DetailView(invoiceId: invoiceId),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.invoiceId});
  final String invoiceId;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  late InvoicesRepository _repo;
  late Future<InvoiceDetail?> _future;

  @override
  void initState() {
    super.initState();
    _repo = getIt<InvoicesRepository>();
    _future = _repo.findDetailById(widget.invoiceId);
  }

  void _reload() {
    setState(() {
      _future = _repo.findDetailById(widget.invoiceId);
    });
  }

  String _failureMessage(AppLocalizations l10n, Failure f) {
    return switch (f) {
      ForbiddenFailure() => l10n.invoiceActionForbidden,
      NotFoundFailure() => l10n.invoiceActionNotFound,
      ConflictFailure() => l10n.invoiceActionInvalidState,
      UnauthorizedFailure() => l10n.invoiceActionUnauthorized,
      ValidationFailure() => l10n.invoiceRejectReasonRequired,
      _ => l10n.invoiceActionGenericError(f.toString()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<InvoiceActionBloc, InvoiceActionState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        switch (state) {
          case InvoiceActionSuccess(:final invoice):
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(l10n.invoiceActionSuccess(
                  invoiceStatusLabel(l10n, invoice.status),
                )),
                behavior: SnackBarBehavior.floating,
              ));
            _reload();
          case InvoiceActionFailure(:final failure):
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(_failureMessage(l10n, failure)),
                behavior: SnackBarBehavior.floating,
              ));
          default:
            break;
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const DynamicAppBar(
          title: 'Invoice Details',
          centerTitle: true,
        ),
        body: DynamicStatusBar(
          child: FutureBuilder<InvoiceDetail?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _CenteredMessage(
                  text: l10n.invoiceDetailError(snap.error.toString()),
                  icon: Icons.error_outline_rounded,
                );
              }
              final detail = snap.data;
              if (detail == null) {
                return _CenteredMessage(
                  text: l10n.invoiceDetailNotFound(widget.invoiceId),
                  icon: Icons.search_off_rounded,
                );
              }
              return _DetailBody(detail: detail);
            },
          ),
        ),
        bottomNavigationBar: FutureBuilder<InvoiceDetail?>(
          future: _future,
          builder: (context, snap) {
            final header = snap.data?.header;
            if (header == null) return const SizedBox.shrink();
            return _ActionBar(invoice: header);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});
  final InvoiceDetail detail;

  static final _date = DateFormat('MMM dd, yyyy');
  static final _stamp = DateFormat('MMM dd, yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final h = detail.header;

    return ListView(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 32,
      ),
      children: [
        _HeaderCard(h: h, dateFmt: _date).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        if (h.actionedAt != null) ...[
          _AuditCard(invoice: h, stampFmt: _stamp).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
        ],
        _LineItemsCard(detail: detail).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        if (detail.notes != null) ...[
          _NotesCard(notes: detail.notes!).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
        ],
        _PdfPlaceholder().animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.h, required this.dateFmt});
  final Invoice h;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppLabel(
                text: h.invoiceNumber,
                fontSize: AppFontSize.value24,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              _StatusBadge(status: h.status),
            ],
          ),
          const SizedBox(height: 12),
          AppLabel(
            text: h.customerName,
            fontSize: AppFontSize.value16,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetaItem(
                  label: l10n.invoiceDetailIssuedLabel.toUpperCase(),
                  value: dateFmt.format(h.issuedAt),
                ),
              ),
              Expanded(
                child: _MetaItem(
                  label: l10n.invoiceDetailDueLabel.toUpperCase(),
                  value: dateFmt.format(h.dueAt),
                  valueColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineItemsCard extends StatelessWidget {
  const _LineItemsCard({required this.detail});
  final InvoiceDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppLabel(
              text: l10n.invoiceDetailLinesHeading.toUpperCase(),
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          for (final line in detail.lineItems) _LineItemRow(line: line),
          const Divider(height: 1),
          _TotalSection(detail: detail),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.line});
  final InvoiceLineItem line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: line.description,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.w600,
                ),
                if (line.sku != null)
                  AppLabel(
                    text: line.sku!,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.outline,
                  ),
                AppLabel(
                  text: '${line.quantity} × ${line.unitPrice}',
                  fontSize: AppFontSize.value12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AppLabel(
            text: line.lineTotal,
            fontSize: AppFontSize.value16,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ],
      ),
    );
  }
}

class _TotalSection extends StatelessWidget {
  const _TotalSection({required this.detail});
  final InvoiceDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Column(
        children: [
          _SummaryRow(label: l10n.invoiceDetailSubtotalLabel, value: detail.subtotal),
          const SizedBox(height: 4),
          _SummaryRow(label: l10n.invoiceDetailTaxLabel, value: detail.tax),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppLabel(
                text: l10n.invoiceDetailTotalLabel.toUpperCase(),
                fontSize: AppFontSize.value16,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
              AppLabel(
                text: detail.header.totalAmount,
                fontSize: AppFontSize.value24,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.invoice});
  final Invoice invoice;

  Future<void> _onApprove(BuildContext context) async {
    final ok = await ApproveInvoiceBottomSheet.show(context, invoice);
    if (ok != true || !context.mounted) return;
    context.read<InvoiceActionBloc>().add(InvoiceActionApprove(invoice.id));
  }

  Future<void> _onReject(BuildContext context) async {
    final reason = await RejectInvoiceBottomSheet.show(context, invoice);
    if (reason == null || !context.mounted) return;
    context.read<InvoiceActionBloc>().add(InvoiceActionReject(invoiceId: invoice.id, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: BlocBuilder<InvoiceActionBloc, InvoiceActionState>(
        builder: (context, actionState) {
          final isLoading = actionState is InvoiceActionLoading;
          
          return PermissionGuard.builder(
            required: const Permission(token: kFinanceApprovePermission),
            builder: (context, allowed) {
              final canAction = allowed && (invoice.status == InvoiceStatus.pendingApproval);
              
              if (invoice.status == InvoiceStatus.draft) {
                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : () => context.read<InvoiceActionBloc>().add(InvoiceActionSubmit(invoice.id)),
                    icon: const Icon(Icons.send_rounded),
                    label: AppLabel(
                      text: l10n.invoiceSubmitAction.toUpperCase(),
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w800,
                    ),
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
                  ),
                );
              }

              return Row(
                children: [
                  if (invoice.status == InvoiceStatus.rejected)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : () => context.read<InvoiceActionBloc>().add(InvoiceActionReopen(invoice.id)),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.invoiceReopenAction.toUpperCase()),
                        ),
                      ),
                    ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (canAction && !isLoading) ? () => _onReject(context) : null,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n.invoiceRejectAction.toUpperCase()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: canAction ? theme.colorScheme.error : theme.colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (canAction && !isLoading) ? () => _onApprove(context) : null,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.invoiceApproveAction.toUpperCase()),
                      style: FilledButton.styleFrom(
                        backgroundColor: canAction ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.invoice, required this.stampFmt});
  final Invoice invoice;
  final DateFormat stampFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isReject = invoice.status == InvoiceStatus.rejected;
    final actorId = invoice.approvedBy ?? invoice.rejectedBy;
    final statusColor = invoiceStatusColor(theme, invoice.status);

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isReject ? Icons.cancel_rounded : Icons.verified_rounded, size: 20, color: statusColor),
              const SizedBox(width: 8),
              AppLabel(
                text: (isReject ? l10n.invoiceAuditRejectedHeading : l10n.invoiceAuditApprovedHeading).toUpperCase(),
                fontSize: AppFontSize.value11,
                color: statusColor,
                fontWeight: FontWeight.w900,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (actorId != null)
            _AuditLine(icon: Icons.person_outline_rounded, text: l10n.invoiceAuditActorLine(actorId)),
          _AuditLine(icon: Icons.access_time_rounded, text: l10n.invoiceAuditWhenLine(stampFmt.format(invoice.actionedAt!))),
          if (isReject && invoice.rejectedReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppLabel(
                text: l10n.invoiceDetailRejectionReasonLabel(invoice.rejectedReason!),
                fontSize: AppFontSize.value12,
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _AuditLine extends StatelessWidget {
  const _AuditLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: AppLabel(
              text: text,
              fontSize: AppFontSize.value12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLabel(
            text: l10n.invoiceDetailNotesHeading.toUpperCase(),
            fontSize: AppFontSize.value11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          AppLabel(
            text: notes,
            fontSize: AppFontSize.value14,
          ),
        ],
      ),
    );
  }
}

class _PdfPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.picture_as_pdf_rounded, color: theme.colorScheme.error),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: l10n.invoiceDetailPdfHeading,
                  fontSize: AppFontSize.value14,
                  fontWeight: FontWeight.bold,
                ),
                AppLabel(
                  text: l10n.invoiceDetailPdfPlaceholder,
                  fontSize: AppFontSize.value12,
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.open_in_new_rounded)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppLabel(
          text: label,
          fontSize: AppFontSize.value14,
          color: theme.colorScheme.outline,
        ),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(
          text: label,
          fontSize: AppFontSize.value11,
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 2),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value16,
          fontWeight: FontWeight.bold,
          color: valueColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = invoiceStatusColor(theme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadii.pill), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: AppLabel(
        text: invoiceStatusLabel(l10n, status).toUpperCase(),
        fontSize: AppFontSize.value9,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
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
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), shape: BoxShape.circle), child: Icon(icon ?? Icons.receipt_long_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5))),
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
