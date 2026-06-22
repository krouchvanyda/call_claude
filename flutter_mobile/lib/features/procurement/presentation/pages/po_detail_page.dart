import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/purchase_orders_repository.dart';
import '../../entities/goods_receipt.dart';
import '../../entities/purchase_order.dart';
import 'goods_receipt_form_page.dart';
import 'po_list_page.dart' show PurchaseOrderStatusBadge;

class PurchaseOrderDetailPage extends StatefulWidget {
  const PurchaseOrderDetailPage({super.key, required this.poId});

  final String poId;

  @override
  State<PurchaseOrderDetailPage> createState() => _PurchaseOrderDetailPageState();
}

class _PurchaseOrderDetailPageState extends State<PurchaseOrderDetailPage> {
  late PurchaseOrdersRepository _repo;
  late Future<_DetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _repo = getIt<PurchaseOrdersRepository>();
    _future = _load();
  }

  Future<_DetailBundle> _load() async {
    final po = await _repo.findById(widget.poId);
    if (po == null) return _DetailBundle(po: null, receipts: const []);
    final receipts = await _repo.receiptsFor(widget.poId);
    return _DetailBundle(po: po, receipts: receipts);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.poDetailTitle,
        centerTitle: true,
      ),
      body: DynamicStatusBar(
        child: FutureBuilder<_DetailBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final bundle = snap.data;
            if (bundle == null || bundle.po == null) {
              return _CenteredMessage(text: l10n.poDetailNotFound(widget.poId), icon: Icons.search_off_rounded);
            }
            return _Body(bundle: bundle);
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<_DetailBundle>(
        future: _future,
        builder: (context, snap) {
          final po = snap.data?.po;
          if (po == null) return const SizedBox.shrink();
          if (po.status == PurchaseOrderStatus.fullyReceived ||
              po.status == PurchaseOrderStatus.cancelled ||
              po.status == PurchaseOrderStatus.closed) {
            return const SizedBox.shrink();
          }
          return _ActionBar(
            onRecord: () async {
              await ConfigRouter.pushPageAnimation(
                context,
                GoodsReceiptFormPage(purchaseOrderId: po.id),
              );
              if (mounted) _reload();
            },
          );
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onRecord});
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: FilledButton.icon(
        onPressed: onRecord,
        icon: const Icon(Icons.local_shipping_rounded),
        label: AppLabel(
          text: l10n.poDetailRecordReceiptAction.toUpperCase(),
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
  }
}

class _DetailBundle {
  const _DetailBundle({required this.po, required this.receipts});
  final PurchaseOrder? po;
  final List<GoodsReceipt> receipts;
}

class _Body extends StatelessWidget {
  const _Body({required this.bundle});
  final _DetailBundle bundle;
  static final _date = DateFormat('MMM dd, yyyy');
  static final _dt = DateFormat('MMM dd, yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final po = bundle.po!;
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
                          text: po.number,
                          fontSize: AppFontSize.value24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        const SizedBox(height: 4),
                        AppLabel(
                          text: po.vendorName,
                          fontSize: AppFontSize.value14,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                  PurchaseOrderStatusBadge(status: po.status),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Wrap(
                spacing: 32,
                runSpacing: 20,
                children: [
                  _MetaItem(label: l10n.poDetailCreatedLabel, value: _date.format(po.createdAt), icon: Icons.calendar_today_rounded),
                  _MetaItem(label: l10n.poDetailExpectedLabel, value: _date.format(po.expectedAt), icon: Icons.event_rounded),
                  if (po.sourcePurchaseRequestId != null)
                    _MetaItem(label: l10n.poDetailSourcePrLabel, value: po.sourcePurchaseRequestId!, icon: Icons.shopping_cart_rounded),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.poDetailLinesHeading.toUpperCase(),
          icon: Icons.list_alt_rounded,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final line in po.lineItems) _LineRow(line: line),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg)),
                ),
                child: Row(
                  children: [
                    AppLabel(
                      text: l10n.poDetailTotalLabel.toUpperCase(),
                      fontSize: AppFontSize.value14,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                    const Spacer(),
                    AppLabel(
                      text: po.totalAmount,
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
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
        
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.poDetailReceiptsHeading.toUpperCase(),
          icon: Icons.history_rounded,
          padding: EdgeInsets.zero,
          child: bundle.receipts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppLabel(
                    text: l10n.poDetailReceiptsEmpty,
                    fontSize: AppFontSize.value12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Column(
                  children: [
                    for (final r in bundle.receipts)
                      _ReceiptRow(receipt: r),
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
  final PurchaseOrderLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final outstanding = line.outstandingQuantity;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              AppLabel(
                text: line.lineTotal,
                fontSize: AppFontSize.value16,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuantityPill(label: l10n.poLineOrderedLabel(''), value: line.orderedQuantity.toString(), color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              _QuantityPill(label: l10n.poLineReceivedLabel(''), value: line.receivedQuantity.toString(), color: theme.colorScheme.tertiary),
              if (outstanding > 0) ...[
                const SizedBox(width: 8),
                _QuantityPill(label: l10n.poLineOutstandingLabel(''), value: outstanding.toString(), color: theme.colorScheme.error),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLabel(
            text: label.toUpperCase(),
            fontSize: AppFontSize.value8,
            color: color,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(width: 4),
          AppLabel(
            text: value,
            fontSize: AppFontSize.value11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt});
  final GoodsReceipt receipt;
  static final _dt = DateFormat('MMM dd, yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)))),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.local_shipping_rounded, color: theme.colorScheme.tertiary, size: 20),
        ),
        title: AppLabel(
          text: _dt.format(receipt.receivedAt),
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
        ),
        subtitle: AppLabel(
          text: receipt.note == null
              ? receipt.receivedBy
              : '${receipt.receivedBy} · ${receipt.note}',
          fontSize: AppFontSize.value11,
          color: theme.colorScheme.outline,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
          child: AppLabel(
            text: l10n.poDetailReceiptItemsBadge(receipt.lines.length),
            fontSize: AppFontSize.value11,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Icon(icon ?? Icons.inventory_2_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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
