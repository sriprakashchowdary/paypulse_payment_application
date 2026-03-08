import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'premium_widgets.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = isLoading || onTap == null;

    return BouncyButton(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : (color == null ? AppColors.primaryGradient : null),
          color: disabled
              ? (isDark ? AppColors.cardDark : AppColors.surfaceLight)
              : (color ?? (color == null && !disabled ? null : color)),
          borderRadius: BorderRadius.circular(Radii.xl),
          boxShadow: disabled ? [] : Shadows.soft,
          border: Border.all(
            color: disabled
                ? (isDark ? AppColors.borderDark : AppColors.border)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: disabled ? AppColors.textMuted : Colors.white,
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(
                  icon,
                  color: disabled ? AppColors.textMuted : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: disabled ? AppColors.textMuted : Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
