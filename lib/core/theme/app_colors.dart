import 'package:flutter/material.dart';

/// AOneGo9 brand palette — elegant gold on deep charcoal,
/// matching the marketing site theme colour (#C9A86C).
///
/// Part of the AOneGo9 product line — see ../../../../DESIGN_TOKENS.md for the
/// canonical spec. The gold family is byte-identical with the super-admin and
/// user apps; the neutral ramp is shared with the super-admin console.
class AppColors {
  AppColors._();

  // Brand
  static const Color gold = Color(0xFFC9A86C);
  static const Color goldLight = Color(0xFFE3CFA3);
  static const Color goldDark = Color(0xFFA8884A);

  // Surfaces (dark, premium feel)
  static const Color bg = Color(0xFF14161C);
  static const Color surface = Color(0xFF1C1F27);
  static const Color surfaceAlt = Color(0xFF232730);
  static const Color border = Color(0xFF2E333F);

  // Sidebar
  static const Color sidebar = Color(0xFF101218);

  // Text
  static const Color textPrimary = Color(0xFFF4F5F7);
  static const Color textSecondary = Color(0xFFA5ABB8);
  static const Color textMuted = Color(0xFF6E7585);

  // Status
  static const Color success = Color(0xFF4CAF7D);
  static const Color warning = Color(0xFFE0A93B);
  static const Color danger = Color(0xFFE0534E);
  static const Color info = Color(0xFF4C8AE0);

  // Status soft backgrounds
  static const Color successSoft = Color(0x224CAF7D);
  static const Color warningSoft = Color(0x22E0A93B);
  static const Color dangerSoft = Color(0x22E0534E);
  static const Color infoSoft = Color(0x224C8AE0);

  static const List<Color> chartPalette = [
    gold,
    info,
    success,
    warning,
    Color(0xFF9B6BD8),
    Color(0xFF52C4C0),
  ];
}
