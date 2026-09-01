import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appearance preference — system / light / dark.
///
/// A ValueNotifier rather than a provider so the root can rebuild on it
/// without threading a ChangeNotifier through go_router's shell.
class ThemeModeStore {
  ThemeModeStore._();

  static const _key = 'vendor_theme_mode';

  /// 'system' | 'light' | 'dark'. Defaults to following the OS, so a vendor
  /// running their laptop in light mode is not handed a dark console.
  static final ValueNotifier<String> mode = ValueNotifier('system');

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && const ['system', 'light', 'dark'].contains(saved)) {
      mode.value = saved;
    }
  }

  static Future<void> set(String next) async {
    if (mode.value == next) return;
    mode.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next);
  }

  /// Steps system → light → dark → system, which is what the toolbar button
  /// cycles through.
  static void cycle() => set(switch (mode.value) {
        'system' => 'light',
        'light' => 'dark',
        _ => 'system',
      });

  static Brightness resolve(Brightness platform) => switch (mode.value) {
        'light' => Brightness.light,
        'dark' => Brightness.dark,
        _ => platform,
      };
}
