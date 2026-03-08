import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ══════════════════════════════════════════════════════════════
/// THEME PROVIDER — manages and persists light/dark mode
///
/// Usage:
///   ref.watch(themeProvider)                        → ThemeMode
///   ref.read(themeProvider.notifier).toggleTheme()  → toggle
///   ref.read(themeProvider.notifier).isDarkMode      → bool
/// ══════════════════════════════════════════════════════════════

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  /// Key exposed so main() can pre-read the value before runApp.
  static const String prefsKey = 'theme_mode';

  /// Optional seed value injected by main() for zero-flash startup.
  final ThemeMode initialTheme;
  ThemeNotifier({this.initialTheme = ThemeMode.light});

  @override
  ThemeMode build() {
    // Immediately return the pre-loaded value; then keep in sync.
    _syncFromPrefs();
    return initialTheme;
  }

  // ── load ────────────────────────────────────────────────────

  /// Reads SharedPreferences and updates state if it differs.
  /// Called once on build() so hot-restarts stay consistent.
  Future<void> _syncFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(prefsKey);
    if (index != null && ThemeMode.values[index] != state) {
      state = ThemeMode.values[index];
    }
  }

  // ── toggle ──────────────────────────────────────────────────

  /// Flip between light and dark, then persist the choice.
  Future<void> toggleTheme() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKey, state.index);
  }

  // ── helpers ─────────────────────────────────────────────────

  bool get isDarkMode => state == ThemeMode.dark;
}
