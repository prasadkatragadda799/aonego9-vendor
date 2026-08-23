import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_shell.dart';
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

Future<void> ensureVendorSession() async {
  if (_vendorSessionReady || VendorSession.profileLoaded) {
    _vendorSessionReady = true;
    return;
  }
  if (!await ApiClient.isLoggedIn()) return;
  try {
    VendorSession.setVendorFromProfile(await VendorRepository().myProfile());
    _vendorSessionReady = true;
  } catch (_) {
    await ApiClient.clearTokens();
    VendorSession.reset();
    _vendorSessionReady = false;
  }
}

/// Central route table. Authenticated pages are wrapped in [AppShell]
/// via a ShellRoute so the navigation persists across pages.
final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final path = state.uri.path;
    if (path == '/' || path.isEmpty) {
      final loggedIn = await ApiClient.isLoggedIn();
      return loggedIn ? '/dashboard' : '/login';
    }

    final loggedIn = await ApiClient.isLoggedIn();
    final onLogin = path == '/login';

    if (onLogin) {
      if (loggedIn) {
        await ensureVendorSession();
        if (!await ApiClient.isLoggedIn()) return '/login';
        return '/dashboard';
      }
      return null;
    }

    if (!loggedIn) {
      _vendorSessionReady = false;
      VendorSession.reset();
      return '/login';
    }

    await ensureVendorSession();
    if (!await ApiClient.isLoggedIn()) {
      _vendorSessionReady = false;
      VendorSession.reset();
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) async {
        final loggedIn = await ApiClient.isLoggedIn();
        return loggedIn ? '/dashboard' : '/login';
      },
    ),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(currentRoute: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/services', builder: (_, __) => const ServicesScreen()),
        GoRoute(path: '/roster', builder: (_, __) => const RosterScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
        GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
        GoRoute(path: '/newsletter', builder: (_, __) => const VendorNewsletterScreen()),
        GoRoute(path: '/reviews', builder: (_, __) => const ReviewsScreen()),
        GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Page not found'),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Go to login')),
        ],
      ),
    ),
  ),
);
