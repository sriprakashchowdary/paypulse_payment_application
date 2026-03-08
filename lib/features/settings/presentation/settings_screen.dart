import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/transactions/services/export_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_preferences_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/biometric_auth_provider.dart';
import '../../../core/services/biometric_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showMessage(BuildContext context, String message) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendResetPassword(
    BuildContext context,
    WidgetRef ref,
    String? email,
  ) async {
    if (email == null) return;
    await ref.read(authControllerProvider.notifier).resetPassword(email: email);
    if (!context.mounted) return;
    await _showMessage(context, 'Password reset email sent');
  }

  Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(exportServiceProvider).export();
    if (!context.mounted) return;
    final message = switch (result.status) {
      ExportStatus.success => 'Exported ${result.count} transactions',
      ExportStatus.empty => 'No transactions to export',
      ExportStatus.failure =>
        'Export failed: ${result.error ?? 'Unknown error'}',
    };
    await _showMessage(context, message);
  }

  Future<void> _toggleTheme(WidgetRef ref) async {
    HapticFeedback.selectionClick();
    await ref.read(themeProvider.notifier).toggleTheme();
  }

  Future<void> _toggleEmergencyLock(WidgetRef ref, bool value) async {
    HapticFeedback.mediumImpact();
    await ref.read(appPreferencesProvider.notifier).setEmergencyLock(value);
  }

  Future<void> _toggleRoundUpSavings(WidgetRef ref, bool value) async {
    HapticFeedback.selectionClick();
    await ref.read(appPreferencesProvider.notifier).setRoundUpSavings(value);
  }

  Future<void> _toggleBiometrics(
      BuildContext context, WidgetRef ref, bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      // Re-evaluate if device supports it before turning it on
      final isAvailable =
          await ref.read(biometricServiceProvider).isBiometricAvailable();
      if (!isAvailable) {
        if (!context.mounted) return;
        await _showMessage(context,
            'Biometric authentication is not set up or not available on this device.');
        return;
      }
    }
    await ref.read(appPreferencesProvider.notifier).setRequireBiometrics(value);
    // Automatically mark as authenticated so they aren't locked out right now
    ref.read(biometricAuthStateProvider.notifier).markAuthenticated();
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;
    final appPrefs = ref.read(appPreferencesProvider);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.selectLanguage,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  title: const Text('English'),
                  trailing: appPrefs.locale == null || appPrefs.locale == 'en'
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(appPreferencesProvider.notifier)
                        .setLocale('en');
                    if (context.mounted) {
                      _showMessage(context, 'Language set to English');
                    }
                  },
                ),
                ListTile(
                  leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                  title: const Text('Hindi (हिन्दी)'),
                  trailing: appPrefs.locale == 'hi'
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(appPreferencesProvider.notifier)
                        .setLocale('hi');
                    if (context.mounted) {
                      _showMessage(context, 'Language set to Hindi');
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(userDocProvider);
    final currentTheme = ref.watch(themeProvider);
    final appPrefs = ref.watch(appPreferencesProvider);
    final l10n = AppLocalizations.of(context)!;

    final user = userAsync.value;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? '—';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: Stack(
          children: [
            const Positioned.fill(child: _SettingsLuxuryBackground()),
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _ProfileCard(
                  initial: initial,
                  userName: userName,
                  userEmail: userEmail,
                  photoUrl: user?.photoUrl,
                ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04),
                const SizedBox(height: 16),
                _Section(
                  title: l10n.account,
                  children: [
                    _ActionTile(
                      icon: Icons.person_outline_rounded,
                      label: l10n.editProfile,
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _ActionTile(
                      icon: Icons.lock_outline_rounded,
                      label: l10n.changePassword,
                      onTap: () =>
                          _sendResetPassword(context, ref, user?.email),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      title: Text(l10n.biometricLogin),
                      subtitle: Text(l10n.biometricSubtitle),
                      value: appPrefs.requireBiometrics,
                      onChanged: (value) =>
                          _toggleBiometrics(context, ref, value),
                      secondary: const Icon(Icons.fingerprint_rounded),
                    ),
                  ],
                ).animate().fadeIn(delay: 70.ms).slideY(begin: 0.04),
                const SizedBox(height: 14),
                _Section(
                  title: l10n.preferences,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      title: Text(l10n.darkMode),
                      subtitle:
                          const Text('Use dark appearance throughout app'),
                      value: currentTheme == ThemeMode.dark,
                      onChanged: (_) => _toggleTheme(ref),
                      secondary: const Icon(Icons.dark_mode_rounded),
                    ),
                    _ActionTile(
                      icon: Icons.notifications_outlined,
                      label: l10n.notifications,
                      onTap: () async => context.push('/notifications'),
                    ),
                    _ActionTile(
                      icon: Icons.language_rounded,
                      label: l10n.language,
                      onTap: () => _showLanguageDialog(context, ref),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      title: Text(l10n.emergencyLock),
                      subtitle: const Text(
                        'Pause all outgoing transfers instantly',
                      ),
                      value: appPrefs.emergencyLock,
                      onChanged: (value) => _toggleEmergencyLock(ref, value),
                      secondary: const Icon(Icons.shield_moon_rounded),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      title: Text(l10n.roundUpAutoSave),
                      subtitle: const Text(
                        'Auto-save spare change from each payment',
                      ),
                      value: appPrefs.roundUpSavings,
                      onChanged: (value) => _toggleRoundUpSavings(ref, value),
                      secondary: const Icon(Icons.savings_rounded),
                    ),
                  ],
                ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.04),
                const SizedBox(height: 14),
                _Section(
                  title: l10n.dataAndLegal,
                  children: [
                    _ActionTile(
                      icon: Icons.ios_share_rounded,
                      label: l10n.exportTransactions,
                      onTap: () => _exportTransactions(context, ref),
                    ),
                    _ActionTile(
                      icon: Icons.help_outline_rounded,
                      label: l10n.helpCenter,
                      onTap: () => context.push('/help-center'),
                    ),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      label: l10n.privacyPolicy,
                      onTap: () => context.push('/privacy-policy'),
                    ),
                    _ActionTile(
                      icon: Icons.description_outlined,
                      label: l10n.termsOfService,
                      onTap: () => context.push('/terms-of-service'),
                    ),
                  ],
                ).animate().fadeIn(delay: 170.ms).slideY(begin: 0.04),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorBg,
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => _logout(context, ref),
                  child: Text(l10n.signOut),
                ).animate().fadeIn(delay: 220.ms),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => _confirmDeleteAccount(context, ref),
                  child: Text(l10n.deleteAccount),
                ).animate().fadeIn(delay: 270.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success =
          await ref.read(authControllerProvider.notifier).deleteAccount();
      if (!context.mounted) return;

      if (success) {
        context.go('/login');
        _showMessage(context, l10n.accountDeletedSuccess);
      } else {
        final authState = ref.read(authControllerProvider);
        _showMessage(context, authState.error ?? l10n.failedToDeleteAccount);
      }
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final String initial;
  final String userName;
  final String userEmail;
  final String? photoUrl;

  const _ProfileCard({
    required this.initial,
    required this.userName,
    required this.userEmail,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withValues(alpha: 0.74),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow:
            Theme.of(context).brightness == Brightness.dark ? [] : Shadows.card,
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto ? null : AppColors.primaryGradient,
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(userEmail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        onTap?.call();
      },
    );
  }
}

class _SettingsLuxuryBackground extends StatelessWidget {
  const _SettingsLuxuryBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            left: -70,
            child: _glow(
              AppColors.secondary.withValues(alpha: isDark ? 0.22 : 0.14),
              250,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _glow(
              AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.12),
              280,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
