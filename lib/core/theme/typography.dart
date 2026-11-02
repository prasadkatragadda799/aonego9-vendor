import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// TYPOGRAPHY for the console — the user app's type stack.
///
/// The marketplace draws its display role in Poppins and its body and
/// metadata roles in Inter (see `F` in aonego9-user-main/lib/theme/tokens.dart).
/// The console uses the same faces so the three apps read as one product
/// line. Role names (`display`, `body`, `eyebrow`) are kept so no call site
/// changes.
/// ─────────────────────────────────────────────────────────────
class AppType {
  AppType._();

  /// Poppins — display for hero numbers, page titles, card titles.
  ///
  /// Call sites were tuned for a compact serif. Poppins has tall ascenders,
  /// so tight line-heights and negative tracking would make wrapped headings
  /// collide — floor and soften them here, exactly as the user app does.
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double letterSpacing = -0.5,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height == null ? null : (height < 1.2 ? 1.2 : height),
        letterSpacing: letterSpacing < 0 ? letterSpacing * .35 : letterSpacing,
        fontStyle: fontStyle,
      );

  /// Inter — body for labels, nav, table text.
  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Tabular Inter for amounts, IDs and timestamps, so columns of figures
  /// line up.
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textMuted,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Tiny uppercase tracked eyebrow / section label.
  static TextStyle eyebrow({
    Color? color,
    double size = 10,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textMuted,
        letterSpacing: 1.8,
      );

  /// Full Inter text theme used as the app's base body type.
  static TextTheme textTheme(TextTheme base) => GoogleFonts.interTextTheme(base);
}
