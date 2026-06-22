import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_inbox_bloc.dart';
import '../bloc/notification_inbox_event.dart';
import '../bloc/notification_inbox_state.dart';
import '../notification_category_icon.dart';

class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationInboxBloc>(
      create: (_) => getIt<NotificationInboxBloc>()
        ..add(const NotificationInboxEvent.started()),
      child: const _InboxView(),
    );
  }
}

class _InboxView extends StatelessWidget {
  const _InboxView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.notificationInboxTitle,
        backgroundColor: Colors.transparent,
        actions: [
          BlocBuilder<NotificationInboxBloc, NotificationInboxState>(
            buildWhen: (a, b) =>
                a is! NotificationInboxLoaded ||
                b is! NotificationInboxLoaded ||
                a.unreadCount != b.unreadCount,
            builder: (context, state) {
              final hasUnread =
                  state is NotificationInboxLoaded && state.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return IconButton(
                tooltip: l10n.notificationInboxMarkAllRead,
                onPressed: () => context.read<NotificationInboxBloc>().add(
                      const NotificationInboxEvent.markedAllRead(),
                    ),
                icon: const Icon(Icons.done_all_rounded),
              );
            },
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: BlocBuilder<NotificationInboxBloc, NotificationInboxState>(
          builder: (context, state) => switch (state) {
            NotificationInboxInitial() ||
            NotificationInboxLoading() =>
              const Center(child: CircularProgressIndicator()),
            NotificationInboxFailure(:final message) =>
              _CenteredMessage(text: l10n.notificationInboxError(message)),
            NotificationInboxLoaded(:final notifications) =>
              notifications.isEmpty
                  ? _CenteredMessage(text: l10n.notificationInboxEmpty)
                  : _InboxList(notifications: notifications),
          },
        ),
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(
        top: context.dynamicAppBarPadding,
        bottom: 100,
        left: 16,
        right: 16,
      ),
      itemCount: notifications.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _NotificationTile(notification: notifications[i])
            .animate()
            .fadeIn(delay: (i * 40).ms)
            .slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<NotificationInboxBloc>();
    
    final isUnread = notification.isUnread;
    
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        child: Icon(Icons.delete_sweep_rounded,
            color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        bloc.add(NotificationInboxEvent.dismissed(notification.id));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.notificationInboxDismissedSnack),
            behavior: SnackBarBehavior.floating,
          ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnread 
              ? theme.colorScheme.primaryContainer.withOpacity(0.05) 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread 
                ? theme.colorScheme.primary.withOpacity(0.2) 
                : theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            if (isUnread)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleTap(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notificationCategoryIcon(notification.category),
                    size: 20,
                    color: isUnread
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppLabel(
                              text: notification.title,
                              fontSize: AppFontSize.value16,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: isUnread ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppLabel(
                        text: notification.body,
                        fontSize: AppFontSize.value14,
                        color: theme.colorScheme.onSurfaceVariant,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      AppLabel(
                        text: 'Recently',
                        fontSize: AppFontSize.value11,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final bloc = context.read<NotificationInboxBloc>();
    final l10n = AppLocalizations.of(context);
    if (notification.isUnread) {
      bloc.add(NotificationInboxEvent.markedRead(notification.id));
    }
    if (!notification.hasDeepLink) return;
    try {
      context.goNamed(
        notification.routeName!,
        pathParameters: notification.pathParameters,
      );
    } on Object catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.notificationDeepLinkError(e.toString())),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64, 
                color: theme.colorScheme.outline,
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
