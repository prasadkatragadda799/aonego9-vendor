import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../responsive/responsive.dart';
import '../routing/nav_items.dart';
import '../category/vendor_category.dart';
import '../widgets/common.dart';

/// Adaptive vendor shell, themed to the signed-in vendor's category accent:
/// - Desktop : expanded sidebar
/// - Tablet  : icon rail
/// - Mobile  : app bar + drawer (full nav) + bottom bar (primary items)
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (c) => _MobileScaffold(currentRoute: currentRoute, child: child),
      tablet: (c) => _WideScaffold(currentRoute: currentRoute, expanded: false, child: child),
      desktop: (c) => _WideScaffold(currentRoute: currentRoute, expanded: true, child: child),
    );
  }
}

class _WideScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final bool expanded;
  const _WideScaffold({required this.child, required this.currentRoute, required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentRoute: currentRoute, expanded: expanded),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: AmbientBackground(accent: VendorSession.config.accent, child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Primary destinations surfaced on the mobile bottom bar.
const _bottomItems = ['/dashboard', '/bookings', '/calendar', '/messages'];

class _MobileScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const _MobileScaffold({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final accent = VendorSession.config.accent;
    final bottomNav = _bottomItems
        .map((r) => vendorNav.firstWhere((n) => n.route == r))
        .toList();
    final currentIndex = _bottomItems.indexOf(currentRoute);

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.sidebar,
        child: SafeArea(child: _Sidebar(currentRoute: currentRoute, expanded: true, inDrawer: true)),
      ),
      appBar: AppBar(
        title: const _BrandMark(compact: true),
        actions: [
          IconButton(onPressed: () => context.go('/notifications'), icon: const Icon(Icons.notifications_none, size: 22)),
          const Padding(padding: EdgeInsets.only(right: 12), child: InitialsAvatar(name: 'Spotlight Talent', size: 30)),
        ],
      ),
      body: AmbientBackground(accent: accent, child: child),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.sidebar,
        indicatorColor: accent.withValues(alpha: 0.20),
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_bottomItems[i]),
        destinations: [
          for (final n in bottomNav)
            NavigationDestination(icon: Icon(n.icon), selectedIcon: Icon(n.icon, color: accent), label: n.label.split(' ').first),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  final bool expanded;
  final bool inDrawer;
  const _Sidebar({required this.currentRoute, required this.expanded, this.inDrawer = false});

  @override
  Widget build(BuildContext context) {
    final cfg = VendorSession.config;
    final width = expanded ? 254.0 : 76.0;
    String? lastSection;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13151B), AppColors.sidebar],
        ),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0, vertical: 22),
            child: Align(
              alignment: expanded ? Alignment.centerLeft : Alignment.center,
              child: _BrandMark(compact: !expanded),
            ),
          ),
          // Category badge — the strongest signal that the console is
          // tailored to this vendor's business type.
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: cfg.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cfg.accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(cfg.icon, size: 16, color: cfg.accent),
                    const SizedBox(width: 9),
                    Expanded(child: Text(cfg.label, style: AppType.body(size: 12.5, weight: FontWeight.w700, color: cfg.accent))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                for (final item in vendorNav) ...[
                  if (expanded && item.section != null && item.section != lastSection)
                    _sectionLabel(item.section!, setLast: () => lastSection = item.section),
                  _NavTile(
                    item: item,
                    accent: cfg.accent,
                    expanded: expanded,
                    selected: currentRoute == item.route,
                    onTap: () {
                      if (inDrawer) Navigator.of(context).pop();
                      context.go(item.route);
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          _NavTile(
            item: const NavItem('Logout', Icons.logout, '/login'),
            accent: cfg.accent,
            expanded: expanded,
            selected: false,
            onTap: () => context.go('/login'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {required VoidCallback setLast}) {
    setLast();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 20, 9),
      child: Text(text.toUpperCase(), style: AppType.eyebrow(color: AppColors.textMuted, size: 10)),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final Color accent;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.accent, required this.expanded, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : AppColors.textSecondary;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 2),
      child: HoverFx(
        onTap: onTap,
        builder: (h) => AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : (h ? AppColors.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? accent.withValues(alpha: 0.32) : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (expanded)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              if (expanded) const SizedBox(width: 11),
              Icon(item.icon, size: 20, color: selected ? accent : (h ? AppColors.textPrimary : color)),
              if (expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label,
                      style: AppType.body(
                          size: 13.5,
                          weight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.textPrimary : (h ? AppColors.textPrimary : AppColors.textSecondary))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Spacer(),
          Container(
            width: 280,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.search, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text('Search bookings, clients…', style: AppType.body(size: 13, color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(width: 16),
          _iconBtn(Icons.notifications_none, badge: true),
          const SizedBox(width: 16),
          const InitialsAvatar(name: 'Spotlight Talent', size: 36),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Spotlight Talent Co.', style: AppType.body(weight: FontWeight.w600, size: 13)),
              Text(VendorSession.config.profileType, style: AppType.body(color: AppColors.textMuted, size: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {bool badge = false}) {
    return Stack(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Icon(icon, size: 19, color: AppColors.textSecondary),
      ),
      if (badge) Positioned(right: 9, top: 9, child: CircleAvatar(radius: 4, backgroundColor: VendorSession.config.accent)),
    ]);
  }
}

class _BrandMark extends StatelessWidget {
  final bool compact;
  const _BrandMark({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 36, height: 36, alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Text('A9', style: AppType.display(color: const Color(0xFF1A1407), weight: FontWeight.w700, size: 15)),
    );
    if (compact) return logo;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      logo,
      const SizedBox(width: 11),
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(
            style: AppType.display(size: 18, weight: FontWeight.w600),
            children: [
              const TextSpan(text: 'AOne'),
              TextSpan(text: 'Go9', style: AppType.display(size: 18, weight: FontWeight.w600, color: AppColors.gold)),
            ],
          ),
        ),
        Text('VENDOR CONSOLE', style: AppType.eyebrow(color: AppColors.gold.withValues(alpha: 0.9), size: 9)),
      ]),
    ]);
  }
}
