import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  /// The theme for a brightness. [AppColors.applyBrightness] must already
  /// have been called for this frame — the tokens below read from it.
  static ThemeData of(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return dark.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: ColorScheme.light(
        surface: AppColors.bg,
        onSurface: AppColors.textPrimary,
        primary: AppColors.gold,
        onPrimary: AppColors.onAccent(AppColors.gold),
        secondary: AppColors.gold,
        onSecondary: AppColors.onAccent(AppColors.gold),
        error: AppColors.danger,
        onError: AppColors.onAccent(AppColors.danger),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.onAccent(AppColors.gold),
        secondary: AppColors.goldLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: _textTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.gold, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onAccent(AppColors.gold),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        side: BorderSide(color: AppColors.border),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      // Without this, Material 3 colours SnackBar text with `onInverseSurface`
      // (a dark tone in a dark scheme) — invisible on our dark surfaces.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    // Syne for body/labels (clean + dense), Fraunces for display headlines —
    // the same editorial pairing the consumer app uses.
    return AppType.textTheme(base)
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary)
        .copyWith(
          headlineMedium: AppType.display(size: 30, weight: FontWeight.w600, height: 1.15),
          headlineSmall: AppType.display(size: 24, weight: FontWeight.w600),
          titleLarge: AppType.display(size: 19, weight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: AppType.body(size: 15, weight: FontWeight.w600),
          bodyMedium: AppType.body(size: 13.5, color: AppColors.textSecondary, height: 1.45),
          labelLarge: AppType.body(weight: FontWeight.w600),
        );
  }
}
