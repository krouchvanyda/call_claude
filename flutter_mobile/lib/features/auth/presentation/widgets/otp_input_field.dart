import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';

/// Multi-box one-time-code input.
///
/// Visually a row of [length] outlined cells, each holding one digit.
/// Under the hood a single off-screen [TextField] captures keystrokes —
/// keeps platform autofill (`AutofillHints.oneTimeCode`, which iOS reads
/// from SMS suggestions and Android pulls from Google's verifier API)
/// working with no per-box focus-juggling.
///
/// Tap-to-focus is handled via [GestureDetector] over the box row.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.length,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = true,
    this.hasError = false,
  });

  final int length;

  /// Fired on every keystroke; receives the entire (possibly partial) code.
  final ValueChanged<String> onChanged;

  /// Fired once exactly [length] digits have been entered. Useful for
  /// auto-submit on the last digit.
  final ValueChanged<String>? onCompleted;

  final bool enabled;
  final bool autofocus;

  /// Tints the cell borders with the theme's error colour. Tied to
  /// `OtpState.hasError` from the bloc.
  final bool hasError;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_handleControllerChange);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleControllerChange() {
    final code = _controller.text;
    setState(() {}); // rebuild boxes
    widget.onChanged(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _handleFocusChange() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          widget.enabled ? () => _focusNode.requestFocus() : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                _OtpDigitBox(
                  digit: i < _controller.text.length
                      ? _controller.text[i]
                      : null,
                  isCurrent: _focusNode.hasFocus &&
                      i == _controller.text.length,
                  hasError: widget.hasError,
                  enabled: widget.enabled,
                ),
              ],
            ],
          ),

          // Invisible capture field — 1×1 px, transparent caret, off-screen
          // visually but still receiving keyboard + autofill events.
          Positioned(
            left: -100,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                autofillHints: const [AutofillHints.oneTimeCode],
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                showCursor: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.digit,
    required this.isCurrent,
    required this.hasError,
    required this.enabled,
  });

  final String? digit;
  final bool isCurrent;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color borderColor;
    if (hasError) {
      borderColor = theme.colorScheme.error;
    } else if (isCurrent) {
      borderColor = theme.colorScheme.primary;
    } else {
      borderColor = theme.colorScheme.outline;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 42,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: borderColor,
          width: (isCurrent || hasError) ? 2 : 1,
        ),
        color: enabled
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerLow,
      ),
      alignment: Alignment.center,
      child: AppLabel(
        text: digit ?? '',
        fontSize: AppFontSize.value24,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
