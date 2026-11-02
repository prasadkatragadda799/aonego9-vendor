import 'package:flutter/material.dart';

/// AOneGo9 brand palette — dual theme.
///
/// Part of the AOneGo9 product line. These values are the consumer app's
/// design tokens (`lib/theme/tokens.dart` in aonego9-user-main) mapped onto
/// the console's role names, so a vendor moving between the marketplace and
/// their console sees one product: the same saffron action colour, the same
/// maroon-black night ground and the same warm ivory paper.
///
///   user app        console
///   T.bg         →  bg
///   T.card       →  surface        (raised cards)
///   T.surf       →  surfaceAlt     (sunken bands, inputs) in light
///   T.bdr        →  border
///   T.cream      →  textPrimary
///   T.mut        →  textSecondary
///   T.dim        →  textMuted
///   T.gold       →  gold           (saffron — the one action colour)
///
/// ── How the theme swap works ─────────────────────────────────────
/// Every colour is a static GETTER over one mutable [_light] flag rather than
/// a `const`, which lets the existing `AppColors.bg` call sites switch theme
/// without being rewritten to take a BuildContext. [applyBrightness] is
/// called at the root before MaterialApp builds, and the whole tree rebuilds
/// on toggle, so nothing can read a stale colour.
///
/// ── Contrast ─────────────────────────────────────────────────────
/// Every text step clears WCAG AA (4.5:1) against bg, surface, surfaceAlt and
/// sidebar in both themes. Enforced by test/contrast_test.dart.
class AppColors {
  AppColors._();

  static bool _light = false;
  static bool get isLight => _light;
  static void applyBrightness(Brightness b) => _light = b == Brightness.light;
  static Color _p(Color dark, Color light) => _light ? light : dark;

  // ── Brand anchors — identical in both themes and across all three apps.
  static const Color brandGold = Color(0xFFC9A86C);
  static const Color marigold = Color(0xFFF5A623);
  static const Color maroon = Color(0xFF8C1D2E);

  /// Literal logo colours, sampled from the AOneGo9 master logo.
  static const Color logoAmber = Color(0xFFFFC400);
  static const Color logoCyan = Color(0xFF00BCE0);
  static Color get logoNeutral => _p(const Color(0xFFFFFFFF), const Color(0xFF15161A));

  /// The one action colour — saffron. Bright marigold on the night ground, a
  /// deep saffron on paper (marigold itself is ~2:1 on ivory).
  static Color get gold => _p(marigold, const Color(0xFF9E4500));

  /// Light: maroon, for emphasis beside saffron. Dark: a paler marigold.
  static Color get goldLight => _p(const Color(0xFFFFC766), maroon);
  static Color get goldDark => _p(const Color(0xFFD9821A), const Color(0xFF7A3300));

  // ── Surfaces — warm ivory paper, deep maroon-black night.
  static Color get bg => _p(const Color(0xFF140A0B), const Color(0xFFFBF6EC));
  static Color get surface => _p(const Color(0xFF261518), const Color(0xFFFFFFFF));
  static Color get surfaceAlt => _p(const Color(0xFF2F1B1F), const Color(0xFFF3E8D6));
  static Color get border => _p(const Color(0xFF3D2428), const Color(0xFFE3D2B6));

  /// A stronger hairline for hovered / focused edges.
  static Color get borderHi => _p(const Color(0xFF59363B), const Color(0xFFC9AD86));

  // Sidebar — a shade off the page ground in both themes so the rail reads as
  // a distinct plane rather than a border.
  static Color get sidebar => _p(const Color(0xFF100708), const Color(0xFFF6EEDF));

  // ── Text ramp
  static Color get textPrimary => _p(const Color(0xFFFBF0E4), const Color(0xFF1F1513));
  static Color get textSecondary => _p(const Color(0xFFBCA79D), const Color(0xFF5B4743));
  static Color get textMuted => _p(const Color(0xFFA48F85), const Color(0xFF6A5652));

  // ── Status (as TEXT / icon colours — each clears AA on every surface)
  static Color get success => _p(const Color(0xFF6AAB88), const Color(0xFF17702F));
  static Color get warning => _p(const Color(0xFFE8B04A), const Color(0xFF8A5A00));
  static Color get danger => _p(const Color(0xFFF08C8C), const Color(0xFF9E2A1E));
  static Color get info => _p(const Color(0xFF6BA0EA), const Color(0xFF1F5E8C));

  /// Danger as a FILL (snackbars, destructive buttons). [danger] is tuned for
  /// text and is too light to carry white copy on the night ground.
  static Color get dangerFill => _p(const Color(0xFFBE3B3B), const Color(0xFFB33224));

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
    const ink = Color(0xFF14120E);
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
  /// drops lightness until it reads as a label. Same derivation the user app
  /// uses for its category accents, so a category reads in the same tint in
  /// both products.
  static Color forGround(Color pastel) {
    if (!_light) return pastel;
    final h = HSLColor.fromColor(pastel);
    return h
        .withSaturation((h.saturation * 1.45).clamp(0.0, 0.62))
        .withLightness(0.30)
        .toColor();
  }

  /// Second stop of the card wash — a shade off [surface] so a card reads as
  /// a lifted plane rather than a flat rectangle.
  static Color get surfaceLift => _p(const Color(0xFF1F1114), const Color(0xFFFDF9F2));

  /// Top stop of the sidebar wash.
  static Color get sidebarLift => _p(const Color(0xFF190C0E), const Color(0xFFEFE4D0));

  /// The "premium card" wash used by the subscription and earnings heroes —
  /// a saffron tint bleeding into the raised surface, as in the user app's
  /// gradient grounds.
  static List<Color> get premiumWash => _light
      ? const [Color(0xFFFBEBD3), Color(0xFFFFFFFF)]
      : const [Color(0xFF3A1A06), Color(0xFF261518)];

  /// A ground that stays DARK in both themes, for poster-style media tiles
  /// that carry light copy over imagery.
  static const List<Color> posterWash = [Color(0xFF3A0E16), Color(0xFF140A0B)];
  static const Color posterInk = Color(0xFFF4F1EA);

  /// Scrim over imagery / behind modal sheets.
  static Color get scrim => _p(const Color(0xCC140A0B), const Color(0x991F1513));

  static List<Color> get chartPalette => [
        gold,
        info,
        success,
        warning,
        _p(const Color(0xFFB98AE0), const Color(0xFF6A3FA8)),
        _p(const Color(0xFF52C4C0), const Color(0xFF1F7A76)),
        _p(const Color(0xFFE88AA0), maroon),
      ];
}
