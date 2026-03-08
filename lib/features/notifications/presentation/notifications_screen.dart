import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/wallet_provider.dart';
import '../../../shared/widgets/alert_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  AlertType _resolveAlertType(String type) {
    return switch (type.toLowerCase()) {
      'error' => AlertType.error,
      'warning' => AlertType.warning,
      'success' => AlertType.success,
      _ => AlertType.info,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Security Notifications'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background blobs
          if (isDark)
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),

          alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: alerts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final type = _resolveAlertType(alert.alertType);

                  return AlertCard(
                    type: type,
                    title: alert.alertType.toUpperCase(),
                    message: alert.message,
                  )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.05);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load notifications',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'No new security alerts or activity notifications at the moment.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
