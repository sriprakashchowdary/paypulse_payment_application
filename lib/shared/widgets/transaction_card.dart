import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// ══════════════════════════════════════════════════════════════
/// TRANSACTION CARD — single transaction list tile
/// ══════════════════════════════════════════════════════════════
///
///   TransactionCard(
///     title: 'Swiggy Food Order',
///     amount: 349,
///     date: DateTime.now(),
///     isCredit: false,
///     type: 'SEND',
///     category: 'Dining',
///     onTap: () => showDetails(),
///   )

class TransactionCard extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final bool isCredit;
  final String type;
  final String? category;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.isCredit,
    this.type = 'SEND',
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final color = isCredit ? AppColors.success : AppColors.primary;
    final bgColor = isCredit
        ? (isDark
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.successBg)
        : AppColors.primary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? AppColors.cardDark : Colors.white,
              isDark
                  ? AppColors.cardDark.withValues(alpha: 0.92)
                  : AppColors.surfaceLight.withValues(alpha: 0.45),
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: theme.dividerColor),
          boxShadow: isDark ? [] : Shadows.card,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: Icon(_iconForType, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.subtitle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (category != null) ...[
                        Flexible(
                          child: Text(
                            category!,
                            style: AppTypography.label.copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('•', style: AppTypography.label),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        DateFormat('MMM dd, h:mm a').format(date),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${isCredit ? '+' : '−'}₹${NumberFormat("#,##0").format(amount)}',
              style: AppTypography.title.copyWith(
                color:
                    isCredit ? AppColors.success : theme.colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0);
  }

  IconData get _iconForType {
    switch (type.toUpperCase()) {
      case 'TOPUP':
        return Icons.add_rounded;
      case 'SEND':
        return Icons.arrow_outward_rounded;
      case 'RECEIVE':
        return Icons.south_west_rounded;
      case 'CREDIT':
        return Icons.bolt_rounded;
      case 'SAVINGS':
        return Icons.savings_rounded;
      case 'SPLIT':
        return Icons.group_rounded;
      default:
        return isCredit ? Icons.south_west_rounded : Icons.north_east_rounded;
    }
  }
}
