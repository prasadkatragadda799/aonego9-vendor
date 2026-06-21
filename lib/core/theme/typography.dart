import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// EDITORIAL TYPOGRAPHY for the console.
///
/// Brings the AOneGo9 consumer app's Fraunces (serif display) + Syne
/// (sans body) pairing into the vendor console so the three apps read as
/// one product line, while keeping Syne's clean density for data-heavy
/// screens. See ../../../../DESIGN_TOKENS.md (§5 Typography).
/// ─────────────────────────────────────────────────────────────
class AppType {
  AppType._();

  /// Fraunces — serif display for hero numbers, page titles, the wordmark.
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? height,
    double letterSpacing = -0.5,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  /// Syne — sans body for labels, nav, table text.
  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.syne(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Tiny uppercase tracked eyebrow / section label.
  static TextStyle eyebrow({
    Color color = AppColors.textMuted,
    double size = 10,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.syne(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 2,
      );

  /// Full Syne text theme used as the app's base body type.
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.syneTextTheme(base);
}
