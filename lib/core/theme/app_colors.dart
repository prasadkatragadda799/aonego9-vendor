import 'package:flutter/material.dart';

/// AOneGo9 brand palette — dual theme.
///
/// Part of the AOneGo9 product line. The gold family is byte-identical with
/// the super-admin and user apps; the neutral ramp is shared with the
/// super-admin console.
///
/// ── How the theme swap works ─────────────────────────────────────
/// Every colour is a static GETTER over one mutable [_light] flag rather than
/// a `const`, which lets the ~290 existing `AppColors.bg` call sites switch
/// theme without being rewritten to take a BuildContext. [applyBrightness] is
/// called at the root before MaterialApp builds, and the whole tree rebuilds
/// on toggle, so nothing can read a stale colour.
///
/// ── Contrast ─────────────────────────────────────────────────────
/// Every text step clears WCAG AA (4.5:1) against bg, surface and surfaceAlt
/// in both themes. Enforced by test/contrast_test.dart.
class AppColors {
  AppColors._();

  static bool _light = false;
  static bool get isLight => _light;
  static void applyBrightness(Brightness b) => _light = b == Brightness.light;
  static Color _p(Color dark, Color light) => _light ? light : dark;

  // Brand — the immutable anchor, shared across all three apps.
  static const Color brandGold = Color(0xFFC9A86C);

  /// Gold as a UI colour. #C9A86C is ~2:1 on light paper, so the light theme
  /// uses a deepened gold of the same hue that clears AA as body text.
  static Color get gold => _p(brandGold, const Color(0xFF7C5E21));
  static Color get goldLight => _p(const Color(0xFFE3CFA3), const Color(0xFF6B501B));
  static Color get goldDark => _p(const Color(0xFFA8884A), const Color(0xFF5A4315));

  // Surfaces — light is warm paper, not clinical white: the gold and the
  // display serif both sit badly on #FFF.
  static Color get bg => _p(const Color(0xFF14161C), const Color(0xFFFAF8F3));
  static Color get surface => _p(const Color(0xFF1C1F27), const Color(0xFFFFFFFF));
  static Color get surfaceAlt => _p(const Color(0xFF232730), const Color(0xFFF2EEE4));
  static Color get border => _p(const Color(0xFF2E333F), const Color(0xFFE3DED1));

  // Sidebar — deliberately a shade off the page ground in both themes so the
  // rail reads as a distinct plane rather than a border.
  static Color get sidebar => _p(const Color(0xFF101218), const Color(0xFFF0EBDF));

  // Text
  static Color get textPrimary => _p(const Color(0xFFF4F5F7), const Color(0xFF1B1913));
  static Color get textSecondary => _p(const Color(0xFFA5ABB8), const Color(0xFF55514A));

  /// Tertiary. Raised on the dark side too: #6E7585 measured 3.6:1 on
  /// `surface`, so labels set in it were failing AA before this change.
  static Color get textMuted => _p(const Color(0xFF8A90A0), const Color(0xFF6A6559));

  // Status
  static Color get success => _p(const Color(0xFF4CAF7D), const Color(0xFF1D6B41));
  static Color get warning => _p(const Color(0xFFE0A93B), const Color(0xFF8A6410));
  static Color get danger => _p(const Color(0xFFE86B66), const Color(0xFFA8291D));
  static Color get info => _p(const Color(0xFF6BA0EA), const Color(0xFF1F5E8C));

  // Soft status backgrounds — a translucent wash of the status colour, so
  // they follow it into the light theme instead of being frozen hexes.
  static Color get successSoft => success.withValues(alpha: .14);
  static Color get warningSoft => warning.withValues(alpha: .14);
  static Color get dangerSoft => danger.withValues(alpha: .14);
  static Color get infoSoft => info.withValues(alpha: .14);

  /// Foreground for text sitting ON a filled surface. Depends only on the
  /// fill's own luminance, so it is correct in both themes; picks whichever
  /// of the two candidates actually measures better rather than trusting a
  /// fixed threshold.
  static Color onAccent(Color fill) {
    const ink = Color(0xFF141209);
    const paper = Color(0xFFF6F2E8);
    return _contrast(ink, fill) >= _contrast(paper, fill) ? ink : paper;
  }

  /// WCAG 2.1 relative contrast ratio.
  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Adapt an accent authored for the dark ground to the active theme.
  ///
  /// The category pastels sit around 2:1 on paper, so the light theme holds
  /// the hue, lifts saturation so it does not go muddy at low lightness, and
  /// drops lightness until it reads as a label. Deriving rather than
  /// hand-listing a second set keeps the two themes from drifting apart.
  static Color forGround(Color pastel) {
    if (!_light) return pastel;
    final h = HSLColor.fromColor(pastel);
    return h
        .withSaturation((h.saturation * 1.45).clamp(0.0, 0.62))
        .withLightness(0.30)
        .toColor();
  }

  static List<Color> get chartPalette => [
        gold,
        info,
        success,
        warning,
        _p(const Color(0xFF9B6BD8), const Color(0xFF6A3FA8)),
        _p(const Color(0xFF52C4C0), const Color(0xFF1F7A76)),
      ];
}
