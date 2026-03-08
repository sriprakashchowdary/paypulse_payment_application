import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ══════════════════════════════════════════════════════════════
/// PayPulse Design System — Theme
/// ══════════════════════════════════════════════════════════════
///
/// Applies the design tokens to MaterialApp ThemeData.
/// All components inherit these defaults automatically.

abstract class AppTheme {
  // ────────────────────────────────────────────────
  //  LIGHT THEME
  // ────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      primaryColor: AppColors.primary,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        surface: AppColors.cardLight,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        tertiary: AppColors.secondaryLight,
      ),

      // Font
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -1,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0.5,
          shadowColor: AppColors.primary.withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.xl,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.xl,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xxl),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }

  // ────────────────────────────────────────────────
  //  DARK THEME
  // ────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primary,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        surface: AppColors.cardDark,
        onSurface: Colors.white,
        error: AppColors.error,
        tertiary: AppColors.secondaryLight,
      ),

      // Font
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: Colors.white60,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: AppColors.primary.withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.xl,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.cardDark,
          side: const BorderSide(color: AppColors.borderDark, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.xl,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xxl),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF101B2D),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      dividerColor: AppColors.borderDark,
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
