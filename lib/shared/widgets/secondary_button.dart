import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'premium_widgets.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double? width;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyButton(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? c.withValues(alpha: 0.14) : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: c.withValues(alpha: 0.26), width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: c, size: 20),
              const SizedBox(width: Spacing.sm),
            ],
            Text(
              label,
              style: AppTypography.button.copyWith(color: c, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
