import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/purchase_orders_repository.dart';
import '../../data/repositories/purchase_requests_repository.dart';
import '../../data/repositories/vendors_repository.dart';
import '../../entities/purchase_request.dart';
import '../../entities/vendor.dart';
import 'pr_list_page.dart' show PurchaseRequestStatusBadge, prStatusLabel, prStatusColor;

class PurchaseRequestDetailPage extends StatefulWidget {
  const PurchaseRequestDetailPage({super.key, required this.prId});

  final String prId;

  @override
  State<PurchaseRequestDetailPage> createState() => _PurchaseRequestDetailPageState();
}

class _PurchaseRequestDetailPageState extends State<PurchaseRequestDetailPage> {
  late PurchaseRequestsRepository _repo;
  late Future<PurchaseRequest?> _future;

  @override
  void initState() {
    super.initState();
    _repo = getIt<PurchaseRequestsRepository>();
    _future = _repo.findById(widget.prId);
  }

  void _reload() {
    setState(() {
      _future = _repo.findById(widget.prId);
    });
  }

  Future<void> _onApprove(PurchaseRequest pr) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = _repo.approve(pr);
    if (outcome.result == PurchaseRequestApprovalResult.notAllowedFromCurrentStatus) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovalNotAllowed(l10n.prApproveAction.toLowerCase())),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    try {
      await _repo.setStatus(pr.id, outcome.pr.status);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovedSnack(prStatusLabel(l10n, outcome.pr.status))),
          behavior: SnackBarBehavior.floating,
        ));
      _reload();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovalFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<void> _onSubmit(PurchaseRequest pr) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = _repo.submit(pr);
    if (outcome.result != PurchaseRequestApprovalResult.ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovalNotAllowed(l10n.prSubmitAction.toLowerCase())),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    try {
      await _repo.setStatus(pr.id, outcome.pr.status);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.prSubmittedSnack), behavior: SnackBarBehavior.floating));
      _reload();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovalFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<void> _onConvert(PurchaseRequest pr) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final vendors = await getIt<VendorsRepository>().getAll();
    if (!mounted) return;
    final activeVendors = vendors.where((v) => v.status == VendorStatus.active).toList();
    final picked = await showDialog<_ConvertChoice>(
      context: context,
      builder: (_) => _ConvertDialog(vendors: activeVendors),
    );
    if (!mounted || picked == null) return;
    final outcome = convertPurchaseRequestToOrder(
      pr,
      vendorId: picked.vendor.id,
      vendorName: picked.vendor.name,
      expectedAt: picked.expectedAt,
    );
    if (outcome.result != ConvertPurchaseRequestResult.ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovalNotAllowed(l10n.prConvertAction.toLowerCase())),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    try {
      await getIt<PurchaseOrdersRepository>().create(outcome.draftPo!);
      await _repo.setStatus(pr.id, outcome.updatedPr!.status);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.prConvertedSnack), behavior: SnackBarBehavior.floating));
      _reload();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.prApprovalFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<void> _onReject(PurchaseRequest pr) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );
    if (!mounted || reason == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = _repo.reject(pr, reason: reason);
    switch (outcome.result) {
      case PurchaseRequestApprovalResult.reasonRequired:
        return;
      case PurchaseRequestApprovalResult.notAllowedFromCurrentStatus:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.prApprovalNotAllowed(l10n.prRejectAction.toLowerCase())),
            behavior: SnackBarBehavior.floating,
          ));
        return;
      case PurchaseRequestApprovalResult.ok:
        try {
          await _repo.setStatus(pr.id, outcome.pr.status);
          if (!mounted) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.prRejectedSnack), behavior: SnackBarBehavior.floating));
          _reload();
        } catch (e) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(l10n.prApprovalFailed(e.toString())),
              behavior: SnackBarBehavior.floating,
            ));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.prDetailTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<PurchaseRequest?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _CenteredMessage(text: l10n.prDetailError(snap.error.toString()), icon: Icons.error_outline_rounded);
            }
            final pr = snap.data;
            if (pr == null) {
              return _CenteredMessage(text: l10n.prDetailNotFound(widget.prId), icon: Icons.search_off_rounded);
            }
            return _DetailBody(pr: pr);
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<PurchaseRequest?>(
        future: _future,
        builder: (context, snap) {
          final pr = snap.data;
          if (pr == null) return const SizedBox.shrink();
          return _ActionBar(
            pr: pr,
            onApprove: () => _onApprove(pr),
            onReject: () => _onReject(pr),
            onSubmit: () => _onSubmit(pr),
            onConvert: () => _onConvert(pr),
          );
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.pr,
    required this.onApprove,
    required this.onReject,
    required this.onSubmit,
    required this.onConvert,
  });

  final PurchaseRequest pr;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSubmit;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget? action;
    if (pr.status == PurchaseRequestStatus.draft) {
      action = FilledButton.icon(
        onPressed: onSubmit,
        icon: const Icon(Icons.send_rounded),
        label: AppLabel(
          text: l10n.prSubmitAction.toUpperCase(),
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      );
    } else if (pr.status == PurchaseRequestStatus.submitted) {
      action = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded),
              label: AppLabel(
                text: l10n.prRejectAction.toUpperCase(),
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w800,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check_rounded),
              label: AppLabel(
                text: l10n.prApproveAction.toUpperCase(),
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.w800,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
            ),
          ),
        ],
      );
    } else if (pr.status == PurchaseRequestStatus.approved) {
      action = FilledButton.icon(
        onPressed: onConvert,
        icon: const Icon(Icons.shopping_bag_rounded),
        label: AppLabel(
          text: l10n.prConvertAction.toUpperCase(),
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      );
    }

    if (action == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: action,
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
  }
}

class _ConvertChoice {
  const _ConvertChoice({required this.vendor, required this.expectedAt});
  final Vendor vendor;
  final DateTime expectedAt;
}

class _ConvertDialog extends StatefulWidget {
  const _ConvertDialog({required this.vendors});
  final List<Vendor> vendors;

  @override
  State<_ConvertDialog> createState() => _ConvertDialogState();
}

class _ConvertDialogState extends State<_ConvertDialog> {
  Vendor? _vendor;
  DateTime _expectedAt = DateTime.now().add(const Duration(days: 14));
  String? _vendorError;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expectedAt = picked);
  }

  void _confirm() {
    if (_vendor == null) {
      setState(() => _vendorError = AppLocalizations.of(context).prConvertVendorRequired);
      return;
    }
    Navigator.of(context).pop(_ConvertChoice(vendor: _vendor!, expectedAt: _expectedAt));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat('MMM dd, yyyy');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      title: AppLabel(
        text: l10n.prConvertDialogTitle,
        fontSize: AppFontSize.value18,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<Vendor>(
            decoration: InputDecoration(
              labelText: l10n.prConvertVendorLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              errorText: _vendorError,
            ),
            items: [
              for (final v in widget.vendors)
                DropdownMenuItem(
                  value: v,
                  child: AppLabel(
                    text: v.name,
                    fontSize: AppFontSize.value14,
                  ),
                ),
            ],
            onChanged: (v) => setState(() { _vendor = v; _vendorError = null; }),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.prConvertExpectedLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
              child: AppLabel(
                text: dateFmt.format(_expectedAt),
                fontSize: AppFontSize.value14,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: AppLabel(
            text: l10n.prConvertCancel.toUpperCase(),
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
          ),
        ),
        FilledButton(
          onPressed: _confirm,
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
          child: AppLabel(
            text: l10n.prConvertConfirm.toUpperCase(),
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.pr});
  final PurchaseRequest pr;
  static final _date = DateFormat('MMM dd, yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 120,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLabel(
                          text: pr.number,
                          fontSize: AppFontSize.value24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        const SizedBox(height: 4),
                        AppLabel(
                          text: _date.format(pr.createdAt.toLocal()),
                          fontSize: AppFontSize.value12,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                  PurchaseRequestStatusBadge(status: pr.status),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Wrap(
                spacing: 32,
                runSpacing: 20,
                children: [
                  _MetaItem(label: l10n.prDetailRequesterLabel, value: pr.requesterName, icon: Icons.person_rounded),
                  _MetaItem(label: l10n.prDetailCostCenterLabel, value: pr.costCenter, icon: Icons.account_balance_rounded),
                  _MetaItem(label: l10n.prDetailApproverLabel, value: pr.approverName, icon: Icons.how_to_reg_rounded),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        
        if (pr.justification != null) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.prDetailJustificationHeading.toUpperCase(),
            icon: Icons.subject_rounded,
            child: AppLabel(
              text: pr.justification!,
              fontSize: AppFontSize.value14,
              lineHeight: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
        ],
        
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.prDetailLinesHeading.toUpperCase(),
          icon: Icons.list_alt_rounded,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final line in pr.lineItems) _LineRow(line: line),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg)),
                ),
                child: Row(
                  children: [
                    AppLabel(
                      text: l10n.prDetailTotalLabel.toUpperCase(),
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    AppLabel(
                      text: pr.totalAmount,
                      fontSize: AppFontSize.value22,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            AppLabel(
              text: label.toUpperCase(),
              fontSize: AppFontSize.value11,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value16,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child, this.padding = const EdgeInsets.all(20)});
  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                AppLabel(
                  text: title,
                  fontSize: AppFontSize.value11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final PurchaseRequestLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(
                  text: line.description,
                  fontSize: AppFontSize.value16,
                  fontWeight: FontWeight.bold,
                ),
                if (line.sku != null) ...[
                  const SizedBox(height: 4),
                  AppLabel(
                    text: l10n.commonSkuLabel(line.sku!),
                    fontSize: AppFontSize.value11,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppLabel(
                text: '${line.quantity} × ${line.unitPrice}',
                fontSize: AppFontSize.value11,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 4),
              AppLabel(
                text: line.lineTotal,
                fontSize: AppFontSize.value16,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
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
            Icon(icon ?? Icons.shopping_cart_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            AppLabel(
              text: text,
              fontSize: AppFontSize.value16,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      title: AppLabel(
        text: l10n.prRejectDialogTitle,
        fontSize: AppFontSize.value18,
        fontWeight: FontWeight.bold,
      ),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _controller,
          label: l10n.prRejectReasonLabel,
          hintText: l10n.prRejectReasonHint,
          icon: Icons.subject_rounded,
          autofocus: true,
          maxLines: 3,
          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.prRejectReasonRequired : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: AppLabel(
            text: l10n.prRejectCancel.toUpperCase(),
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: AppLabel(
            text: l10n.prRejectConfirm.toUpperCase(),
            fontSize: AppFontSize.value14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
