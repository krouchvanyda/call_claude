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
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/contacts_repository.dart';
import '../../data/repositories/customers_repository.dart';
import '../../entities/activity_event.dart';
import '../../entities/contact.dart';
import '../../entities/customer.dart';
import 'activity_form_page.dart'
    show ActivityFormPage, activityTypeIcon, activityTypeLabel;
import 'contact_form_page.dart';
import 'customer_form_page.dart';
import 'customer_list_page.dart'
    show
        CustomerStatusBadge,
        customerSegmentLabel,
        customerStatusColor;

/// Customer detail (Slices 6.1.2 + 6.1.3).
class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late Future<_Bundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bundle> _load() async {
    final customer = await getIt<CustomersRepository>()
        .findById(widget.customerId);
    if (customer == null) {
      return const _Bundle(
          customer: null, contacts: [], activities: []);
    }
    final contacts = await getIt<ContactsRepository>()
        .forCustomer(widget.customerId);
    final activities = await getIt<ActivitiesRepository>()
        .forCustomer(widget.customerId);
    return _Bundle(
      customer: customer,
      contacts: contacts,
      activities: activities,
    );
  }

  void _reload() {
    // Block body so the closure returns `void`. The arrow form
    // `setState(() => _future = _load())` evaluates to the assigned
    // Future, which makes the closure async-typed and trips Flutter's
    // "setState callback argument returned a Future" warning.
    setState(() {
      _future = _load();
    });
  }

  Future<void> _deleteContact(String contactId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      // Name the dialog context so the action buttons can pop the
      // dialog (and only the dialog). Reusing the enclosing `context`
      // would pop the customer-detail page itself — `Navigator.of`
      // walks up from page-context to the router's navigator, not the
      // overlay's modal navigator.
      builder: (dialogContext) => AlertDialog(
        title: AppLabel(
          text: l10n.salesContactDeleteTitle,
          fontSize: AppFontSize.value18,
          fontWeight: FontWeight.bold,
        ),
        content: AppLabel(
          text: l10n.salesContactDeleteBody,
          fontSize: AppFontSize.value14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppLabel(
              text: l10n.invoiceActionCancel,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.w600,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppLabel(
              text: l10n.salesContactDeleteConfirm,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await getIt<ContactsRepository>().delete(contactId);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.salesContactDeletedSnack),
        behavior: SnackBarBehavior.floating,
      ));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<_Bundle>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: DynamicAppBar(
              title: l10n.salesCustomerDetailTitle,
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final bundle = snap.data;
        if (bundle == null || bundle.customer == null) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: DynamicAppBar(
              title: l10n.salesCustomerDetailTitle,
              centerTitle: true,
            ),
            body: Center(
              child: AppLabel(
                text: l10n.salesCustomerNotFound(widget.customerId),
                fontSize: AppFontSize.value14,
              ),
            ),
          );
        }
        final c = bundle.customer!;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: DynamicAppBar(
            title: l10n.salesCustomerDetailTitle,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await ConfigRouter.pushPageAnimation(
                    context,
                    CustomerFormPage(initial: c),
                  );
                  _reload();
                },
              ),
            ],
          ),
          body: DynamicStatusBar(
            child: Stack(
              children: [
                // Background Canvas Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
                        theme.colorScheme.surface,
                        theme.colorScheme.secondaryContainer.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
                _Body(
                  bundle: bundle,
                  onAddContact: () async {
                    await ConfigRouter.pushPageAnimation(
                      context,
                      ContactFormPage(customerId: widget.customerId),
                    );
                    if (mounted) _reload();
                  },
                  onEditContact: (c) async {
                    await ConfigRouter.pushPageAnimation(
                      context,
                      ContactFormPage(
                        customerId: widget.customerId,
                        initial: c,
                      ),
                    );
                    if (mounted) _reload();
                  },
                  onDeleteContact: _deleteContact,
                  onLogActivity: () async {
                    await ConfigRouter.pushPageAnimation(
                      context,
                      ActivityFormPage(customerId: widget.customerId),
                    );
                    if (mounted) _reload();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bundle {
  const _Bundle({
    required this.customer,
    required this.contacts,
    required this.activities,
  });
  final Customer? customer;
  final List<CustomerContact> contacts;
  final List<ActivityEvent> activities;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.bundle,
    required this.onAddContact,
    required this.onEditContact,
    required this.onDeleteContact,
    required this.onLogActivity,
  });

  final _Bundle bundle;
  final VoidCallback onAddContact;
  final ValueChanged<CustomerContact> onEditContact;
  final ValueChanged<String> onDeleteContact;
  final VoidCallback onLogActivity;

  static final _date = DateFormat('yyyy-MM-dd');
  static final _stamp = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final c = bundle.customer!;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        left: 16,
        right: 16,
        bottom: 40,
      ),
      children: [
        // ── Header Card ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.business_outlined, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabel(
                            text: c.name,
                            fontSize: AppFontSize.value16,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4),
                          AppLabel(
                            text:
                                '${customerSegmentLabel(l10n, c.segment)}${c.industry == null ? '' : ' · ${c.industry}'}',
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    CustomerStatusBadge(status: c.status),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                _kv(theme, l10n.salesCustomerDetailEmailLabel, c.email, Icons.email_outlined),
                _kv(theme, l10n.salesCustomerDetailPhoneLabel, c.phone, Icons.phone_outlined),
                _kv(theme, l10n.salesCustomerDetailAddressLabel, c.billingAddress, Icons.place_outlined),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetaChip(
                          label: l10n.salesCustomerDetailLifetimeValueLabel,
                          value: c.lifetimeValue,
                          isHighlight: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetaChip(
                          label: l10n.salesCustomerDetailSinceLabel,
                          value: _date.format(c.onboardedAt.toLocal()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
        if (c.notes != null) ...[
          const SizedBox(height: 16),
          // ── Notes Card ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_outlined, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      AppLabel(
                        text: l10n.salesCustomerDetailNotesHeading,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppLabel(
                    text: c.notes!,
                    fontSize: AppFontSize.value14,
                    color: theme.colorScheme.onSurfaceVariant,
                    lineHeight: 1.4,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
        // ── Contacts Card ───────────────────────────────────────
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppLabel(
                        text: l10n.salesCustomerDetailContactsHeading,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onAddContact,
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: AppLabel(
                        text: l10n.salesContactAddAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (bundle.contacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: AppLabel(
                      text: l10n.salesCustomerDetailContactsEmpty,
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bundle.contacts.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                  itemBuilder: (_, index) => _ContactTile(
                    contact: bundle.contacts[index],
                    onEdit: () => onEditContact(bundle.contacts[index]),
                    onDelete: () => onDeleteContact(bundle.contacts[index].id),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        // ── Activity Timeline Card ─────────────────────────────
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off_outlined, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppLabel(
                        text: l10n.salesCustomerDetailTimelineHeading,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onLogActivity,
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: AppLabel(
                        text: l10n.salesActivityLogAction,
                        fontSize: AppFontSize.value14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (bundle.activities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: AppLabel(
                      text: l10n.salesCustomerDetailTimelineEmpty,
                      fontSize: AppFontSize.value12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bundle.activities.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                  itemBuilder: (_, index) => _ActivityTile(
                    activity: bundle.activities[index],
                    stamp: _stamp,
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _kv(ThemeData theme, String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            SizedBox(
              width: 84,
              child: AppLabel(
                text: label,
                fontSize: AppFontSize.value14,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: AppLabel(
                text: value,
                fontSize: AppFontSize.value14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

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
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 2),
        AppLabel(
          text: value,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.bold,
          color: isHighlight
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: contact.isPrimary
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        foregroundColor: contact.isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        child: const Icon(Icons.person_outline, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: AppLabel(
              text: contact.name,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (contact.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: AppLabel(
                text: l10n.salesContactPrimaryBadge,
                fontSize: AppFontSize.value11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: AppLabel(
          text: '${contact.role} · ${contact.email}',
          fontSize: AppFontSize.value12,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: AppLabel(
              text: l10n.salesContactEditAction,
              fontSize: AppFontSize.value14,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: AppLabel(
              text: l10n.salesContactDeleteAction,
              fontSize: AppFontSize.value14,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.stamp});
  final ActivityEvent activity;
  final DateFormat stamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _typeColor(theme, activity.type);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        child: Icon(activityTypeIcon(activity.type), size: 18),
      ),
      title: AppLabel(
        text: activity.summary,
        fontSize: AppFontSize.value14,
        fontWeight: FontWeight.bold,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: AppLabel(
          text:
              '${activityTypeLabel(l10n, activity.type)} · ${stamp.format(activity.occurredAt.toLocal())} · ${activity.actor}${activity.reference == null ? '' : ' · ${activity.reference}'}',
          fontSize: AppFontSize.value12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: activity.amount == null
          ? null
          : AppLabel(
              text: activity.amount!,
              fontSize: AppFontSize.value14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
    );
  }

  Color _typeColor(ThemeData theme, ActivityEventType t) {
    return switch (t) {
      ActivityEventType.note => theme.colorScheme.outline,
      ActivityEventType.call => theme.colorScheme.primary,
      ActivityEventType.meeting => theme.colorScheme.secondary,
      ActivityEventType.email => theme.colorScheme.primary,
      ActivityEventType.quotation => theme.colorScheme.tertiary,
      ActivityEventType.order => customerStatusColor(theme, CustomerStatus.active),
      ActivityEventType.payment => theme.colorScheme.tertiary,
    };
  }
}
