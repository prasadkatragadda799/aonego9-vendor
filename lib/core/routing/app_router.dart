import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../widgets/app_shell.dart';
import '../widgets/brand.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../core/category/vendor_category.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/bookings/bookings_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/roster/roster_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/earnings/earnings_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/newsletter/newsletter_screen.dart';
import '../../features/reviews/reviews_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';

bool _vendorSessionReady = false;
Future<void>? _sessionLoading;

/// Loads the signed-in vendor's profile once per session so the shell and
/// every screen know the category, name and approval state.
///
/// Only an auth failure ends the session. A cold backend or a dropped
/// connection used to sign the vendor out here, which looked like the
/// console randomly logging people off.
Future<void> ensureVendorSession() async {
  if (_vendorSessionReady || VendorSession.profileLoaded) {
    _vendorSessionReady = true;
    return;
  }
  if (!await ApiClient.isLoggedIn()) return;
  try {
    VendorSession.setVendorFromProfile(await VendorRepository().myProfile());
    _vendorSessionReady = true;
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      await ApiClient.clearTokens();
      VendorSession.reset();
      _vendorSessionReady = false;
    }
  } catch (_) {
    // Network trouble: keep the session; screens show their own retry.
  }
}

Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: c),
    );

GoRoute _page(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, pageBuilder: (_, s) => _fade(s, build(s)));

/// Central route table. Authenticated pages are wrapped in [AppShell]
/// via a ShellRoute so the navigation persists across pages.
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  // Re-run the redirect the moment a session ends (sign-out, or a token the
  // refresh could not recover), instead of on the vendor's next tap.
  refreshListenable: ApiClient.sessionChanges,
  redirect: (context, state) async {
    final path = state.uri.path;
    final loggedIn = await ApiClient.isLoggedIn();
    final onLogin = path == '/login';

    if (!loggedIn) {
      _vendorSessionReady = false;
      VendorSession.reset();
      if (onLogin) return null;
      // Keep where they were going, so a deep link survives sign-in.
      final from = state.uri.toString();
      return from == '/' || from.isEmpty ? '/login' : '/login?from=${Uri.encodeComponent(from)}';
    }

    // Load the profile in the background. Awaiting it here held every page
    // blank until a cold backend answered (30–60 s on Render); the shell and
    // screens now render at once and pick up the name and category when the
    // profile arrives. A 401 still ends the session via sessionChanges.
    if (!VendorSession.profileLoaded) {
      _sessionLoading ??= ensureVendorSession().whenComplete(() => _sessionLoading = null);
      unawaited(_sessionLoading);
    }
    if (onLogin || path == '/' || path.isEmpty) {
      final from = state.uri.queryParameters['from'];
      return from != null && from.startsWith('/') && !from.startsWith('/login') ? from : '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
    GoRoute(path: '/login', pageBuilder: (_, s) => _fade(s, const LoginScreen())),
    ShellRoute(
      builder: (context, state, child) => AppShell(currentRoute: state.uri.path, child: child),
      routes: [
        _page('/dashboard', (_) => const DashboardScreen()),
        _page('/bookings', (s) => BookingsScreen(initialQuery: s.uri.queryParameters['q'] ?? '')),
        _page('/calendar', (_) => const CalendarScreen()),
        _page('/services', (_) => const ServicesScreen()),
        _page('/roster', (s) => RosterScreen(initialQuery: s.uri.queryParameters['q'] ?? '')),
        _page('/profile', (_) => const ProfileScreen()),
        _page('/earnings', (_) => const EarningsScreen()),
        _page('/subscription', (_) => const SubscriptionScreen()),
        _page('/newsletter', (_) => const VendorNewsletterScreen()),
        _page('/reviews', (_) => const ReviewsScreen()),
        _page('/messages', (_) => const MessagesScreen()),
        _page('/notifications', (_) => const NotificationsScreen()),
        _page('/settings', (_) => const SettingsScreen()),
      ],
    ),
  ],
  errorBuilder: (context, state) => _NotFound(path: state.uri.toString()),
);

class _NotFound extends StatelessWidget {
  final String path;
  const _NotFound({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandLogo(size: 26),
            const SizedBox(height: 28),
            Text('Page not found', style: AppType.display(size: 24)),
            const SizedBox(height: 8),
            Text('There is nothing at $path.',
                textAlign: TextAlign.center, style: AppType.body(size: 13.5, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.dashboard_outlined, size: 18),
              label: const Text('Back to dashboard'),
            ),
          ]),
        ),
      ),
    );
  }
}
