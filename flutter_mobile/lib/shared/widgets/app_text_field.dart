import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_radii.dart';

/// Reusable form text field used across every form screen.
///
/// Replaces ~48 hand-rolled `TextFormField + InputDecoration` blocks
/// that all rendered the same outlined / filled / primary-focused look.
/// Centralising it means a single style touch-up here propagates to
/// auth, sales, procurement, inventory, projects, and finance forms.
///
/// ## Usage
///
/// Basic:
/// ```dart
/// AppTextField(
///   controller: _name,
///   label: 'Name',
///   icon: Icons.person_outline,
///   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
/// )
/// ```
///
/// Password / obscured:
/// ```dart
/// AppTextField(
///   controller: _password,
///   label: 'Password',
///   icon: Icons.lock_outline_rounded,
///   obscureText: _hidden,
///   suffixIcon: IconButton(
///     icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
///     onPressed: () => setState(() => _hidden = !_hidden),
///   ),
/// )
/// ```
///
/// Multiline / notes:
/// ```dart
/// AppTextField(
///   controller: _notes,
///   label: 'Notes',
///   icon: Icons.note_outlined,
///   maxLines: 4,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.icon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.initialValue,
    this.onChanged,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
    this.autofocus = false,
    this.helperText,
    this.hintText,
    this.errorText,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool enabled;
  final String? initialValue;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final String? helperText;
  final String? hintText;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadii.md);
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
