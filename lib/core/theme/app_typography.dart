import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ══════════════════════════════════════════════════════════════
/// PayPulse Design System — Typography
/// ══════════════════════════════════════════════════════════════
///
/// Font: Inter (via Google Fonts)
///
/// Scale:
///   H1      — 28px Bold (w700)       Headlines, screen titles
///   H2      — 22px Semi-Bold (w600)  Section headers
///   Body    — 16px Regular (w400)    Body text, descriptions
///   Caption — 12px Light (w300)      Labels, timestamps, hints
///
/// Usage:
///   Text('Hello', style: AppTypography.h1)
///   Text('Subtitle', style: AppTypography.h2.copyWith(color: AppColors.primary))

abstract class AppTypography {
  // ── Headline 1 — 28px Bold ──
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );

  // ── Headline 2 — 22px Semi-Bold ──
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // ── Body — 16px Regular ──
  static TextStyle get body =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  // ── Caption — 12px Light ──
  static TextStyle get caption =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, height: 1.4);

  // ─── Extended Scale (for granular control) ───

  /// 36px Extra-bold — hero numbers (balance, score)
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.2,
  );

  /// 18px Semi-bold — card titles, list headers
  static TextStyle get title =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  /// 15px Medium — form labels, nav items
  static TextStyle get subtitle =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4);

  /// 14px Regular — secondary body text
  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  /// 14px Semi-bold — button text
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.4,
  );

  /// 11px Medium — badge labels, chip text
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  /// White variant helpers
  static TextStyle get h1White => h1.copyWith(color: Colors.white);
  static TextStyle get h2White => h2.copyWith(color: Colors.white);
  static TextStyle get bodyWhite => body.copyWith(color: Colors.white);
  static TextStyle get captionWhite => caption.copyWith(color: Colors.white70);
}
