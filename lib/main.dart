import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/app_preferences_provider.dart';
import 'features/notifications/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set the background messaging handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── Pre-load saved theme so there's no flash of wrong theme ──
  final prefs = await SharedPreferences.getInstance();
  final savedThemeIndex = prefs.getInt(ThemeNotifier.prefsKey);
  final initialTheme = savedThemeIndex != null
      ? ThemeMode.values[savedThemeIndex]
      : ThemeMode.light;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Seed the provider with the persisted value before first frame
        themeProvider.overrideWith(
          () => ThemeNotifier(initialTheme: initialTheme),
        ),
      ],
      child: const PayPulseApp(),
    ),
  );
}

class PayPulseApp extends ConsumerWidget {
  const PayPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    final appPrefs = ref.watch(appPreferencesProvider);

    return NotificationBootstrap(
      child: MaterialApp.router(
        title: 'PayPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        themeAnimationDuration: const Duration(milliseconds: 600),
        themeAnimationCurve: Curves.easeInOutExpo,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: appPrefs.locale != null ? Locale(appPrefs.locale!) : null,
      ),
    );
  }
}

class NotificationBootstrap extends ConsumerWidget {
  final Widget child;
  const NotificationBootstrap({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for auth state changes to initialize notifications
    ref.listen(userDocProvider, (previous, next) {
      final user = next.value;
      final prevUser = previous?.value;

      // Only initialize if the user just signed in or switched accounts
      if (user != null && user.uid != prevUser?.uid) {
        ref.read(notificationServiceProvider).initialize(user.uid);
      }
    });

    return child;
  }
}
