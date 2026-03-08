import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// ══════════════════════════════════════════════════════════════
/// ALERT CARD — contextual notification banner
/// ══════════════════════════════════════════════════════════════
///
/// Variants:  AlertType.info | success | warning | error
///
///   AlertCard(
///     type: AlertType.success,
///     title: 'Payment Successful',
///     message: '₹500 sent to John',
///     showClose: true,
///     onClose: () => dismiss(),
///   )

enum AlertType { info, success, warning, error }

class AlertCard extends StatelessWidget {
  final AlertType type;
  final String title;
  final String? message;
  final bool showClose;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.showClose = false,
    this.onClose,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: _getBgColor(context),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(
            color: _getAccentColor(context).withOpacity(0.20),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getAccentColor(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(_icon, color: _getAccentColor(context), size: 20),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.subtitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!,
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Close / chevron
            if (showClose)
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              )
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor(BuildContext context) {
    switch (type) {
      case AlertType.success:
        return AppColors.success;
      case AlertType.warning:
        return AppColors.warning;
      case AlertType.error:
        return AppColors.error;
      case AlertType.info:
        return AppColors.info;
    }
  }

  Color _getBgColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _getAccentColor(context).withOpacity(0.1);
    }
    switch (type) {
      case AlertType.success:
        return AppColors.successBg;
      case AlertType.warning:
        return AppColors.warningBg;
      case AlertType.error:
        return AppColors.errorBg;
      case AlertType.info:
        return AppColors.infoBg;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_rounded;
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.error:
        return Icons.error_rounded;
      case AlertType.info:
        return Icons.info_rounded;
    }
  }
}
