import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'premium_widgets.dart';

/// ══════════════════════════════════════════════════════════════
/// WALLET CARD — gradient balance card with stats and elite animations
/// ══════════════════════════════════════════════════════════════
class WalletCard extends StatelessWidget {
  final double balance;
  final int pulseScore;
  final bool isStealth;
  final String? statusLabel;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.balance,
    this.pulseScore = 750,
    this.isStealth = false,
    this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — label + growth badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: AppColors.success,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '+12.5% this month',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (statusLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .shimmer(duration: 2.seconds, colors: [
                          Colors.white24,
                          Colors.white,
                          Colors.white24
                        ]),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Balance
                  ImageFiltered(
                    imageFilter: isStealth
                        ? ImageFilter.blur(sigmaX: 14, sigmaY: 14)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: AnimatedBalance(
                      value: balance,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const SizedBox(height: 28),

                  // Pulse Score progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pulse Score',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '$pulseScore / 900',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: pulseScore / 900),
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          );
                        }),
                  ),
                ],
              ),
            ),

            // Subtle Continuous Shimmer effect across the card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: const Duration(seconds: 4),
                  blendMode: BlendMode.srcOver,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.0),
                  ]),
            ),

            // Glossy overlay circles for glassmorphism
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
