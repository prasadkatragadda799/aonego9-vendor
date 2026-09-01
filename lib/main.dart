import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_store.dart';
import 'core/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use /#/login style routes — reliable on Vercel static hosting.
  setUrlStrategy(const HashUrlStrategy());
  // Restore before the first frame so the console never flashes the wrong
  // theme on load.
  await ThemeModeStore.restore();
  runApp(const AOneGo9VendorApp());
}

class AOneGo9VendorApp extends StatefulWidget {
  const AOneGo9VendorApp({super.key});

  @override
  State<AOneGo9VendorApp> createState() => _AOneGo9VendorAppState();
}

class _AOneGo9VendorAppState extends State<AOneGo9VendorApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fires when the OS switches appearance. Without this, a vendor on
  /// "follow system" keeps the old palette until the tab reloads.
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeModeStore.mode,
      builder: (context, _, __) {
        final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final brightness = ThemeModeStore.resolve(platform);
        // Colours are static getters, so the palette has to be pointed at the
        // right theme before anything below reads one.
        AppColors.applyBrightness(brightness);

        return MaterialApp.router(
          title: 'AOneGo9 Vendor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.of(brightness),
          routerConfig: appRouter,
        );
      },
    );
  }
}
