import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/lock_screen.dart';
import '../../features/wallet/presentation/home_screen.dart';
import '../../features/wallet/presentation/add_money_screen.dart';
import '../../features/wallet/presentation/send_money_screen.dart';
import '../../features/wallet/presentation/receive_screen.dart';
import '../../features/wallet/presentation/qr_scanner_screen.dart';
import '../../features/wallet/presentation/split_receipt_screen.dart';
import '../../features/wallet/presentation/cards_screen.dart';
import '../../features/transactions/presentation/history_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/edit_profile_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/terms_of_service_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/wallet/presentation/wallet_activation_screen.dart';
import '../../features/gold/presentation/gold_screen.dart';
import '../../features/help_center/presentation/help_center_screen.dart';
import '../../shared/widgets/shell_screen.dart';
import '../../providers/app_preferences_provider.dart';
import '../../providers/biometric_auth_provider.dart';

CustomTransitionPage<void> _fadeScalePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
          child: pageChild,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _slideFadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: pageChild),
      );
    },
  );
}

/// Listens to multiple Riverpod providers to trigger GoRouter refreshes
class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(appPreferencesProvider, (_, __) => notifyListeners());
    _ref.listen(biometricAuthStateProvider, (_, __) => notifyListeners());
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App-level router with auth + main shell routes.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(firebaseAuthProvider);
      final isLoggedIn = auth.currentUser != null;

      final prefs = ref.read(appPreferencesProvider);
      final hasUnlocked = ref.read(biometricAuthStateProvider);

      final isAuthRoute = state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password' ||
          state.uri.path == '/otp-verification';

      if (isLoggedIn) {
        // Enforce lock screen if biometrics required but not authenticated
        if (prefs.requireBiometrics &&
            !hasUnlocked &&
            state.uri.path != '/lock') {
          return '/lock';
        }

        // Prevent logged-in user from seeing auth routes or returning to lock when unlocked
        if (isAuthRoute ||
            (state.uri.path == '/lock' &&
                (!prefs.requireBiometrics || hasUnlocked))) {
          return '/home';
        }
      } else {
        // Prevent anonymous users from seeing protected routes
        if (!isAuthRoute) {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      // ── Auth routes (no bottom nav) ──
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),

      GoRoute(
        path: '/add-money',
        builder: (context, state) => const AddMoneyScreen(),
      ),
      GoRoute(
        path: '/send-money',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final name = state.uri.queryParameters['name'];
          return SendMoneyScreen(initialEmail: email, recipientName: name);
        },
      ),
      GoRoute(
        path: '/receive',
        builder: (context, state) => const ReceiveScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/split-receipt',
        builder: (context, state) => const SplitBillsScreen(),
      ),
      GoRoute(
        path: '/cards',
        builder: (context, state) => const CardsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/gold',
        builder: (context, state) => const GoldScreen(),
      ),

      // ── Main app (shell with persistent bottom nav) ──
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _fadeScalePage(state: state, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) =>
                _fadeScalePage(state: state, child: const AnalyticsScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                _slideFadePage(state: state, child: const HistoryScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadeScalePage(state: state, child: const SettingsScreen()),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/activate-wallet',
            builder: (context, state) => const WalletActivationScreen(),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: '/terms-of-service',
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
        ],
      ),
    ],
  );
});
