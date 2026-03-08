import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════
/// PayPulse Design System — Color Tokens
/// ══════════════════════════════════════════════════════════════
///
/// Usage:  AppColors.primary, AppColors.bgLight, etc.
/// All screens must use these tokens — no raw Color() literals.

abstract class AppColors {
  // ── Brand ──────────────────────────────────────
  static const Color primary = Color(0xFF0F62FE);
  static const Color primaryLight = Color(0xFF4F8CFF);
  static const Color primaryDark = Color(0xFF0043CE);
  static const Color secondary = Color(0xFF8A3FFC);
  static const Color secondaryLight = Color(0xFFBE95FF);

  // ── Semantic ───────────────────────────────────
  static const Color success = Color(0xFF24A148);
  static const Color successBg = Color(0xFFD9F7E1);
  static const Color error = Color(0xFFDA1E28);
  static const Color errorBg = Color(0xFFFFE3E3);
  static const Color warning = Color(0xFFF1C21B);
  static const Color warningBg = Color(0xFFFCF4D6);
  static const Color info = Color(0xFF1192E8);
  static const Color infoBg = Color(0xFFD9F1FF);

  // ── Backgrounds ────────────────────────────────
  static const Color bgLight = Color(0xFFF4F7FF);
  static const Color bgDark = Color(0xFF0B1220);
  static const Color surfaceLight = Color(0xFFEFF4FF);

  // ── Cards ──────────────────────────────────────
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF111C2D);

  // ── Text ───────────────────────────────────────
  static const Color textPrimary = Color(0xFF0E1726);
  static const Color textSecondary = Color(0xFF5E6B83);
  static const Color textMuted = Color(0xFF8D99AE);
  static const Color textOnPrimary = Colors.white;

  // ── Borders ────────────────────────────────────
  static const Color border = Color(0xFFDCE5F5);
  static const Color borderDark = Color(0xFF2C3B52);

  // ── Gradients ──────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F62FE), Color(0xFF8A3FFC)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F8CFF), Color(0xFFBE95FF)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF1FF), Color(0xFFF7F9FF)],
  );

  static const LinearGradient bgGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1220), Color(0xFF111C2D)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );
}

/// ══════════════════════════════════════════════════════════════
/// Spacing Grid — multiples of 8px
/// ══════════════════════════════════════════════════════════════

abstract class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 48.0; // 6x
}

/// ══════════════════════════════════════════════════════════════
/// Border Radius — standard card radius: 20px
/// ══════════════════════════════════════════════════════════════

abstract class Radii {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0; // ← Card standard
  static const double xxl = 32.0;
  static const double full = 100.0;
}

/// ══════════════════════════════════════════════════════════════
/// Shadow Presets
/// ══════════════════════════════════════════════════════════════

abstract class Shadows {
  /// Soft card shadow — default for all elevated surfaces.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  /// Primary-tinted soft glow.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.14),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  /// Strong elevated shadow for CTAs and balance cards.
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.24),
          blurRadius: 34,
          offset: const Offset(0, 14),
        ),
      ];
}
