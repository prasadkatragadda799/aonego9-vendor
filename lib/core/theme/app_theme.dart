import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  /// The theme for a brightness. [AppColors.applyBrightness] must already
  /// have been called for this frame — the tokens below read from it.
  ///
  /// One builder for both brightnesses. The light theme used to be
  /// `dark.copyWith(...)` over a light base text theme, which silently
  /// dropped the brand typeface in light mode and kept dark-only component
  /// defaults (switch tracks, menus) on paper.
  static ThemeData of(Brightness brightness) => _build(brightness);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);
    final radius10 = BorderRadius.circular(10);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.gold,
        onPrimary: AppColors.onAccent(AppColors.gold),
        secondary: AppColors.goldLight,
        onSecondary: AppColors.onAccent(AppColors.goldLight),
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceAlt,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        error: AppColors.danger,
        onError: AppColors.onAccent(AppColors.danger),
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
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppType.body(size: 13.5, color: AppColors.textMuted),
        labelStyle: AppType.body(size: 13.5, color: AppColors.textSecondary),
        floatingLabelStyle: AppType.body(size: 13, color: AppColors.gold, weight: FontWeight.w600),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        enabledBorder: OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: AppColors.gold, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: AppColors.danger, width: 1.4)),
        border: OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: AppColors.border)),
        errorStyle: AppType.body(size: 11.5, color: AppColors.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onAccent(AppColors.gold),
          disabledBackgroundColor: AppColors.surfaceAlt,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius10),
          textStyle: AppType.body(size: 14, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: radius10),
          textStyle: AppType.body(size: 13.5, weight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppType.body(size: 13.5, weight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: radius10),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textSecondary),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        side: BorderSide(color: AppColors.border),
        labelStyle: AppType.body(size: 12.5, color: AppColors.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.onAccent(AppColors.gold) : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.gold : AppColors.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.gold : AppColors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.gold : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(AppColors.onAccent(AppColors.gold)),
        side: BorderSide(color: AppColors.borderHi, width: 1.4),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold,
        thumbColor: AppColors.gold,
        inactiveTrackColor: AppColors.surfaceAlt,
        overlayColor: AppColors.gold.withValues(alpha: .14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: AppColors.gold.withValues(alpha: .28),
        selectionHandleColor: AppColors.gold,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: AppType.body(size: 11.5, weight: FontWeight.w600, color: AppColors.textPrimary),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppType.display(size: 19, weight: FontWeight.w600),
        contentTextStyle: AppType.body(size: 13.5, color: AppColors.textSecondary, height: 1.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.scrim,
        dragHandleColor: AppColors.borderHi,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        textStyle: AppType.body(size: 13, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.sidebar,
        scrimColor: AppColors.scrim,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.sidebar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withValues(alpha: .18),
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppType.body(
            size: 11.5,
            weight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppType.body(size: 13.5, weight: FontWeight.w600),
        subtitleTextStyle: AppType.body(size: 12, color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppType.display(size: 18, weight: FontWeight.w600),
      ),
      // Without this, Material 3 colours SnackBar text with `onInverseSurface`
      // (a dark tone in a dark scheme) — invisible on our dark surfaces.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: AppType.body(size: 13.5, color: AppColors.textPrimary),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.hovered) ? AppColors.borderHi : AppColors.border,
        ),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(4),
        crossAxisMargin: 2,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: AppType.eyebrow(size: 10.5, color: AppColors.textMuted),
        dataTextStyle: AppType.body(size: 13),
        dividerThickness: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    // Poppins for display/title roles, Inter for body and labels — the same
    // pairing the consumer app uses.
    return AppType.textTheme(base)
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary)
        .copyWith(
          headlineMedium: AppType.display(size: 28, weight: FontWeight.w600, height: 1.2),
          headlineSmall: AppType.display(size: 22, weight: FontWeight.w600),
          titleLarge: AppType.display(size: 18, weight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: AppType.body(size: 15, weight: FontWeight.w700),
          titleSmall: AppType.body(size: 13.5, weight: FontWeight.w700),
          bodyLarge: AppType.body(size: 14.5, color: AppColors.textPrimary, height: 1.5),
          bodyMedium: AppType.body(size: 13.5, color: AppColors.textSecondary, height: 1.45),
          bodySmall: AppType.body(size: 12, color: AppColors.textMuted, height: 1.4),
          labelLarge: AppType.body(weight: FontWeight.w600),
        );
  }
}
