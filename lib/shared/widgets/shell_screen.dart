import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Persistent bottom-nav shell wrapping all main screens.
class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/analytics')) return 1;
    if (loc.startsWith('/history')) return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/analytics');
      case 2:
        context.go('/history');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark
                    ? AppColors.cardDark.withValues(alpha: 0.96)
                    : Colors.white,
                isDark
                    ? AppColors.bgDark.withValues(alpha: 0.9)
                    : AppColors.surfaceLight.withValues(alpha: 0.52),
              ],
            ),
            borderRadius: BorderRadius.circular(Radii.xxl),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: idx == 0,
                onTap: () => _onTap(context, 0),
              ),
              _NavItem(
                icon: Icons.query_stats_rounded,
                label: 'Stats',
                isActive: idx == 1,
                onTap: () => _onTap(context, 1),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isActive: idx == 2,
                onTap: () => _onTap(context, 2),
              ),
              _NavItem(
                icon: Icons.tune_rounded,
                label: 'Settings',
                isActive: idx == 3,
                onTap: () => _onTap(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.16),
                    AppColors.secondary.withValues(alpha: isDark ? 0.26 : 0.12),
                  ],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: isDark ? 0.32 : 0.24)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryLight : theme.iconTheme.color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primaryLight
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
