import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// ══════════════════════════════════════════════════════════════
/// PREMIUM WIDGETS — cinematic UI components
/// ══════════════════════════════════════════════════════════════

class AnimatedBalance extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;

  const AnimatedBalance({
    super.key,
    required this.value,
    this.style,
    this.prefix = '₹',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      tween: Tween<double>(begin: 0.0, end: value),
      builder: (context, val, child) {
        return Text(
          '$prefix${val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}',
          style: style ?? AppTypography.h1,
        );
      },
    );
  }
}

class PremiumShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const PremiumShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withOpacity(0.05)
          : AppColors.border.withOpacity(0.4),
      highlightColor: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BouncyButton({super.key, required this.child, this.onTap});

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class PremiumSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ).animate().fadeIn().slideX(begin: -0.2),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
