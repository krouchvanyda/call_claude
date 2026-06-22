import 'package:flutter/material.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';

/// Animated 3-dot typing indicator. Each dot pulses with a staggered
/// 150ms offset — design-guide rule for the chat conversation page.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    required this.label,
    this.dotColor,
  });

  final String label;
  final Color? dotColor;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.dotColor ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(progress: _ctrl.value, phase: 0, color: color),
                  const SizedBox(width: 4),
                  _Dot(progress: _ctrl.value, phase: 0.16, color: color),
                  const SizedBox(width: 4),
                  _Dot(progress: _ctrl.value, phase: 0.32, color: color),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          AppLabel(
            text: widget.label,
            fontSize: AppFontSize.value12,
            color: color,
            fontStyle: FontStyle.italic,
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.progress,
    required this.phase,
    required this.color,
  });
  final double progress;
  final double phase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Scale 0.5 → 1.0 → 0.5 across the cycle, offset by `phase`.
    final raw = ((progress + phase) % 1.0) * 2 - 1; // -1..1
    final scale = 0.6 + 0.4 * (1 - raw.abs());
    return Container(
      width: 6 * scale,
      height: 6 * scale,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
