import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// ══════════════════════════════════════════════════════════════
/// APP INPUT FIELD — styled text field with icon support
/// ══════════════════════════════════════════════════════════════
///
///   AppInputField(
///     controller: _emailCtrl,
///     hint: 'Email address',
///     prefixIcon: Icons.mail_outline_rounded,
///     keyboardType: TextInputType.emailAddress,
///   )

class AppInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppInputField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: AppTypography.subtitle.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        counterText: '',
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: Spacing.md,
                  right: Spacing.sm + 4,
                ),
                child: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        // Border & fill inherit from theme's inputDecorationTheme
      ),
      validator: validator,
    );
  }
}
