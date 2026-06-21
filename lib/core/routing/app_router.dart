import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/bookings/bookings_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/roster/roster_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/earnings/earnings_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/reviews/reviews_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Central route table. Authenticated pages are wrapped in [AppShell]
/// via a ShellRoute so the navigation persists across pages.
final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
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
        GoRoute(path: '/reviews', builder: (_, __) => const ReviewsScreen()),
        GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
  errorBuilder: (_, __) => const Scaffold(body: Center(child: Text('Page not found'))),
);
