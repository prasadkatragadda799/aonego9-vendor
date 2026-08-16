import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() {
  // Use /#/login style routes — reliable on Vercel static hosting.
  setUrlStrategy(const HashUrlStrategy());
  runApp(const AOneGo9VendorApp());
}

class AOneGo9VendorApp extends StatelessWidget {
  const AOneGo9VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AOneGo9 Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
