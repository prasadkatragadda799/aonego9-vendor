import 'package:flutter/material.dart';
import '../category/vendor_category.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final String? section;
  const NavItem(this.label, this.icon, this.route, {this.section});
}

/// Full vendor navigation, adapted to the signed-in vendor's category so
/// the catalogue label/icon match their business (Talent Roster vs Spaces
/// vs Crew & Gear …).
List<NavItem> vendorNavFor(VendorCategory category) {
  final cfg = categoryConfigs[category]!;
  return [
    const NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard', section: 'Overview'),
    const NavItem('Bookings', Icons.event_note_outlined, '/bookings', section: 'Overview'),
    const NavItem('Calendar', Icons.calendar_month_outlined, '/calendar', section: 'Overview'),

    NavItem(cfg.servicesLabel, Icons.layers_outlined, '/services', section: 'Catalogue'),
    NavItem(cfg.rosterLabel, cfg.rosterIcon, '/roster', section: 'Catalogue'),
    const NavItem('Profile & Portfolio', Icons.account_box_outlined, '/profile', section: 'Catalogue'),

    const NavItem('Earnings', Icons.account_balance_wallet_outlined, '/earnings', section: 'Business'),
    const NavItem('Subscription', Icons.workspace_premium_outlined, '/subscription', section: 'Business'),
    const NavItem('Reviews', Icons.star_outline, '/reviews', section: 'Business'),
    const NavItem('Messages', Icons.chat_bubble_outline, '/messages', section: 'Business'),

    const NavItem('Notifications', Icons.notifications_none, '/notifications', section: 'Account'),
    const NavItem('Settings & KYC', Icons.settings_outlined, '/settings', section: 'Account'),
  ];
}

/// Default navigation (talent) for any context without a session.
List<NavItem> get vendorNav => vendorNavFor(VendorSession.category);
