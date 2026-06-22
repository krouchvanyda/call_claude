import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../di/injection.dart';
import '../theme/app_font_size.dart';
import '../theme/app_label.dart';
import 'realtime_connection_state.dart';
import 'realtime_service.dart';

/// AppBar-mounted dot + label that surfaces the current
/// [RealtimeConnectionState] from [RealtimeService] (Slice 2.2.4).
///
/// Subscribes to the service's broadcast `connectionState` stream, so
/// the dot turns green / amber / grey live as the connection
/// progresses without the parent widget rebuilding.
///
/// **Test seam**: production callers don't pass [service]; the widget
/// resolves it from `getIt`. Tests pass a fake.
class RealtimeStatusIndicator extends StatelessWidget {
  const RealtimeStatusIndicator({super.key, RealtimeService? service})
      : _serviceOverride = service;

  final RealtimeService? _serviceOverride;

  @override
  Widget build(BuildContext context) {
    final svc = _serviceOverride ?? getIt<RealtimeService>();
    return StreamBuilder<RealtimeConnectionState>(
      stream: svc.connectionState,
      initialData: svc.state,
      builder: (context, snap) {
        final state = snap.data ?? RealtimeConnectionState.disconnected;
        return _Pill(state: state);
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.state});

  final RealtimeConnectionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _colorFor(theme, state);
    final label = _labelFor(l10n, state);
    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            AppLabel(text: label, fontSize: AppFontSize.value11),
          ],
        ),
      ),
    );
  }

  static Color _colorFor(ThemeData theme, RealtimeConnectionState s) {
    return switch (s) {
      RealtimeConnectionState.connected => theme.colorScheme.primary,
      RealtimeConnectionState.connecting => theme.colorScheme.tertiary,
      RealtimeConnectionState.reconnecting => theme.colorScheme.tertiary,
      RealtimeConnectionState.disconnected => theme.colorScheme.outline,
    };
  }

  static String _labelFor(AppLocalizations l10n, RealtimeConnectionState s) {
    return switch (s) {
      RealtimeConnectionState.connected => l10n.realtimeStatusLive,
      RealtimeConnectionState.connecting => l10n.realtimeStatusConnecting,
      RealtimeConnectionState.reconnecting => l10n.realtimeStatusReconnecting,
      RealtimeConnectionState.disconnected => l10n.realtimeStatusOffline,
    };
  }
}
