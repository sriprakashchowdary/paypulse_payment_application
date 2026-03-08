import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must override in main.dart');
});

class AppPreferences {
  final bool emergencyLock;
  final bool roundUpSavings;
  final bool requireBiometrics;
  final String? locale;

  const AppPreferences({
    required this.emergencyLock,
    required this.roundUpSavings,
    required this.requireBiometrics,
    this.locale,
  });

  AppPreferences copyWith({
    bool? emergencyLock,
    bool? roundUpSavings,
    bool? requireBiometrics,
    String? locale,
  }) {
    return AppPreferences(
      emergencyLock: emergencyLock ?? this.emergencyLock,
      roundUpSavings: roundUpSavings ?? this.roundUpSavings,
      requireBiometrics: requireBiometrics ?? this.requireBiometrics,
      locale: locale ?? this.locale,
    );
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferences>(
  AppPreferencesNotifier.new,
);

class AppPreferencesNotifier extends Notifier<AppPreferences> {
  static const String emergencyLockKey = 'pref_emergency_lock';
  static const String roundUpSavingsKey = 'pref_roundup_savings';
  static const String requireBiometricsKey = 'pref_require_biometrics';
  static const String localeKey = 'pref_locale';

  @override
  AppPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppPreferences(
      emergencyLock: prefs.getBool(emergencyLockKey) ?? false,
      roundUpSavings: prefs.getBool(roundUpSavingsKey) ?? false,
      requireBiometrics: prefs.getBool(requireBiometricsKey) ?? false,
      locale: prefs.getString(localeKey),
    );
  }

  Future<void> setEmergencyLock(bool value) async {
    state = state.copyWith(emergencyLock: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(emergencyLockKey, value);
  }

  Future<void> setRoundUpSavings(bool value) async {
    state = state.copyWith(roundUpSavings: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(roundUpSavingsKey, value);
  }

  Future<void> setRequireBiometrics(bool value) async {
    state = state.copyWith(requireBiometrics: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(requireBiometricsKey, value);
  }

  Future<void> setLocale(String? value) async {
    state = state.copyWith(locale: value);
    final prefs = ref.read(sharedPreferencesProvider);
    if (value == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, value);
    }
  }
}
