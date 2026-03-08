import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/biometric_auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Prompt immediately on opening the lock screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final biometricService = ref.read(biometricServiceProvider);

    // Check if available
    final isAvailable = await biometricService.isBiometricAvailable();
    if (!isAvailable) {
      // If hardware isn't available, we fallback to just unlocking
      // (or you could force them to login again via password, but this matches expected local_auth fallback)
      if (mounted) {
        ref.read(biometricAuthStateProvider.notifier).markAuthenticated();
        context.go('/home');
      }
      return;
    }

    final success = await biometricService.authenticate();

    if (success && mounted) {
      ref.read(biometricAuthStateProvider.notifier).markAuthenticated();
      context.go('/home');
    }

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ).animate().scale(
                      delay: 200.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack),
                  const SizedBox(height: 32),
                  Text(
                    'App Locked',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock to access PayPulse',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                  const SizedBox(height: 64),
                  FilledButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.fingerprint_rounded),
                    label: Text(
                      _isAuthenticating ? 'Verifying...' : 'Unlock PayPulse',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
