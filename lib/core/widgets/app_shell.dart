import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../responsive/responsive.dart';
import '../routing/nav_items.dart';
import '../category/vendor_category.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/vendor_repository.dart';

/// Live counts for the shell — the bell's unread badge. Refreshed on every
/// navigation and once a minute while the console is open, so a new booking
/// request shows up without a reload.
class ShellBadges {
  ShellBadges._();
  static final ValueNotifier<int> unread = ValueNotifier(0);
  static Timer? _timer;
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> refresh({bool force = false}) async {
    // The session ended (sign-out or expiry): stop polling rather than keep
    // calling the API from the sign-in page.
    if (!await ApiClient.isLoggedIn()) {
      stop();
      return;
    }
    final now = DateTime.now();
    if (!force && now.difference(_last) < const Duration(seconds: 20)) return;
    _last = now;
    unread.value = await VendorRepository().unreadNotifications();
  }

  static void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 60), (_) => refresh(force: true));
    refresh(force: true);
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    unread.value = 0;
    _last = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Adaptive vendor shell, themed to the signed-in vendor's category accent:
/// - Desktop : expanded sidebar + top bar
/// - Tablet  : icon rail + top bar
/// - Mobile  : app bar + drawer (full nav) + bottom bar (primary items + More)
class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    ShellBadges.start();
  }


  @override
  void didUpdateWidget(covariant AppShell old) {
    super.didUpdateWidget(old);
    if (old.currentRoute != widget.currentRoute) ShellBadges.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () => openCommandPalette(context),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => openCommandPalette(context),
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<int>(
          // Rebuild the chrome when the profile (name, avatar, category) changes.
          valueListenable: VendorSession.changes,
          builder: (context, _, __) => ResponsiveLayout(
            mobile: (c) => _MobileScaffold(currentRoute: widget.currentRoute, child: widget.child),
            tablet: (c) => _WideScaffold(currentRoute: widget.currentRoute, expanded: false, child: widget.child),
            desktop: (c) => _WideScaffold(currentRoute: widget.currentRoute, expanded: true, child: widget.child),
          ),
        ),
      ),
    );
  }
}

String _titleFor(String route) {
  for (final n in vendorNav) {
    if (n.route == route) return n.label;
  }
  return 'Console';
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
                _TopBar(title: _titleFor(currentRoute)),
                if (!VendorSession.isLive) const _ApprovalBanner(),
                Expanded(child: AmbientBackground(accent: VendorSession.config.accent, child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Primary destinations surfaced on the mobile bottom bar; everything else is
// one tap away under "More" (the drawer).
const _bottomItems = ['/dashboard', '/bookings', '/calendar', '/messages'];

class _MobileScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  const _MobileScaffold({required this.child, required this.currentRoute});

  @override
  State<_MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends State<_MobileScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final accent = VendorSession.config.accent;
    final nav = vendorNav;
    final bottomNav = [
      for (final r in _bottomItems) nav.firstWhere((n) => n.route == r),
    ];
    final idx = _bottomItems.indexOf(widget.currentRoute);
    // Not a tab page → "More" is the honest selection, not Dashboard.
    final selected = idx < 0 ? _bottomItems.length : idx;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 290,
        child: SafeArea(child: _Sidebar(currentRoute: widget.currentRoute, expanded: true, inDrawer: true)),
      ),
      appBar: AppBar(
        titleSpacing: 4,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(children: [
          const BrandMonogram(size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_titleFor(widget.currentRoute),
                overflow: TextOverflow.ellipsis, style: AppType.display(size: 16.5, weight: FontWeight.w600)),
          ),
        ]),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search, size: 22),
            onPressed: () => openCommandPalette(context),
          ),
          const _BellButton(compact: true),
          const Padding(padding: EdgeInsets.only(right: 8), child: _AccountMenu(compact: true)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(children: [
        if (!VendorSession.isLive) const _ApprovalBanner(),
        Expanded(child: AmbientBackground(accent: accent, child: widget.child)),
      ]),
      bottomNavigationBar: NavigationBar(
        indicatorColor: accent.withValues(alpha: 0.20),
        selectedIndex: selected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          if (i == _bottomItems.length) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            context.go(_bottomItems[i]);
          }
        },
        destinations: [
          for (final n in bottomNav)
            NavigationDestination(
              icon: n.route == '/messages' ? const _MessagesIcon() : Icon(n.icon),
              selectedIcon: Icon(n.icon, color: accent),
              label: n.shortLabel,
            ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded, color: accent),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MessagesIcon extends StatelessWidget {
  const _MessagesIcon();
  @override
  Widget build(BuildContext context) => const Icon(Icons.chat_bubble_outline);
}

/// Shown while the marketplace is not listing this vendor yet, so a new
/// vendor knows why no requests are coming in.
class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: VendorSession.changes,
        builder: (context, _, __) => VendorSession.isLive ? const SizedBox.shrink() : _banner(context),
      );

  Widget _banner(BuildContext context) {
    final s = VendorSession.approvalStatus;
    final (msg, color) = switch (s) {
      'pending' => (
          'Your profile is awaiting AOneGo9 approval. Complete your profile and portfolio — you will appear on the marketplace once approved.',
          AppColors.warning
        ),
      'rejected' => (
          'Your listing was not approved. Update your profile and contact the AOneGo9 desk from Settings to request another review.',
          AppColors.danger
        ),
      'suspended' => (
          'Your listing is suspended and hidden from the marketplace. Contact the AOneGo9 desk from Settings.',
          AppColors.danger
        ),
      _ => ('Your listing is not live on the marketplace yet.', AppColors.info),
    };
    return Material(
      color: color.withValues(alpha: .10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color.withValues(alpha: .35)))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(s == 'pending' ? Icons.hourglass_top_rounded : Icons.info_outline, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: color, height: 1.4))),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.go(s == 'pending' ? '/profile' : '/settings'),
            child: Text(s == 'pending' ? 'Complete profile' : 'Contact desk'),
          ),
        ]),
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
    final width = inDrawer ? double.infinity : (expanded ? 256.0 : 78.0);
    String? lastSection;
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarLift, AppColors.sidebar],
        ),
        border: inDrawer ? null : Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0, vertical: 20),
            child: Align(
              alignment: expanded ? Alignment.centerLeft : Alignment.center,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (inDrawer) Navigator.of(context).pop();
                  context.go('/dashboard');
                },
                child: expanded
                    ? const ConsoleLockup(label: 'Vendor Console', size: 21)
                    : const Tooltip(message: 'AOneGo9 Vendor Console', child: BrandMonogram(size: 38)),
              ),
            ),
          ),
          // Category badge — the strongest signal that the console is
          // tailored to this vendor's business type.
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                    Expanded(
                      child: Text(cfg.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body(size: 12.5, weight: FontWeight.w700, color: cfg.accent)),
                    ),
                    if (VendorSession.kycVerified)
                      Tooltip(message: 'KYC verified', child: Icon(Icons.verified_rounded, size: 15, color: AppColors.success)),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                for (final item in vendorNav) ...[
                  if (expanded && item.section != null && item.section != lastSection)
                    _sectionLabel(item.section!, setLast: () => lastSection = item.section),
                  _NavTile(
                    item: item,
                    accent: cfg.accent,
                    expanded: expanded,
                    selected: currentRoute == item.route,
                    badge: item.route == '/notifications' ? ShellBadges.unread : null,
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
          const SizedBox(height: 6),
          _NavTile(
            item: const NavItem('Sign out', Icons.logout, '/login'),
            accent: AppColors.danger,
            expanded: expanded,
            selected: false,
            onTap: () async {
              if (inDrawer) Navigator.of(context).pop();
              await signOutWithConfirm(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {required VoidCallback setLast}) {
    setLast();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 20, 8),
      child: Text(text.toUpperCase(), style: AppType.eyebrow(color: AppColors.textMuted, size: 10)),
    );
  }
}

/// Confirms, signs out, and returns to the sign-in page.
Future<void> signOutWithConfirm(BuildContext context) async {
  final ok = await confirmAction(
    context,
    title: 'Sign out?',
    message: 'You will need your email and password to sign back in to the vendor console.',
    confirmLabel: 'Sign out',
  );
  if (!ok) return;
  ShellBadges.stop();
  await VendorRepository().logout();
  if (context.mounted) context.go('/login');
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final Color accent;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;
  final ValueListenable<int>? badge;
  const _NavTile({
    required this.item,
    required this.accent,
    required this.expanded,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : AppColors.textSecondary;
    final tile = Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: HoverFx(
          onTap: onTap,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.14) : (h ? AppColors.surface : Colors.transparent),
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
                _withBadge(Icon(item.icon, size: 20, color: selected ? accent : (h ? AppColors.textPrimary : color)),
                    dotOnly: !expanded),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body(
                            size: 13.5,
                            weight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected || h ? AppColors.textPrimary : AppColors.textSecondary)),
                  ),
                  if (badge != null)
                    ValueListenableBuilder<int>(
                      valueListenable: badge!,
                      builder: (_, n, __) => n == 0 ? const SizedBox() : _CountBadge(n),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? tile : Tooltip(message: item.label, preferBelow: false, child: tile);
  }

  Widget _withBadge(Widget icon, {required bool dotOnly}) {
    if (badge == null || !dotOnly) return icon;
    return ValueListenableBuilder<int>(
      valueListenable: badge!,
      builder: (_, n, child) => Badge(isLabelVisible: n > 0, backgroundColor: AppColors.gold, smallSize: 8, child: child),
      child: icon,
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int n;
  const _CountBadge(this.n);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
        child: Text(n > 99 ? '99+' : '$n',
            style: AppType.mono(size: 10.5, weight: FontWeight.w700, color: AppColors.onAccent(AppColors.gold))),
      );
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final desktop = Responsive.isDesktop(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis, style: AppType.display(size: 17, weight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          _SearchLauncher(wide: desktop),
          const SizedBox(width: 10),
          const ThemeCycleButton(),
          const _BellButton(),
          const SizedBox(width: 8),
          _AccountMenu(compact: !desktop),
        ],
      ),
    );
  }
}

/// The top-bar search box. It opens the command palette — jump to any page
/// or search bookings / roster — rather than being a decorative field.
class _SearchLauncher extends StatelessWidget {
  final bool wide;
  const _SearchLauncher({required this.wide});

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return IconButton(
        tooltip: 'Search (Ctrl K)',
        icon: const Icon(Icons.search, size: 21),
        onPressed: () => openCommandPalette(context),
      );
    }
    return HoverFx(
      onTap: () => openCommandPalette(context),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 300,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: h ? AppColors.borderHi : AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.search, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Search bookings, pages…',
                overflow: TextOverflow.ellipsis, style: AppType.body(size: 13, color: AppColors.textMuted)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('Ctrl K', style: AppType.mono(size: 10.5, color: AppColors.textMuted)),
          ),
        ]),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final bool compact;
  const _BellButton({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ShellBadges.unread,
      builder: (context, n, _) => IconButton(
        tooltip: n == 0 ? 'Notifications' : '$n unread notifications',
        onPressed: () => context.go('/notifications'),
        icon: Badge(
          isLabelVisible: n > 0,
          backgroundColor: AppColors.gold,
          textColor: AppColors.onAccent(AppColors.gold),
          label: Text(n > 99 ? '99+' : '$n'),
          child: Icon(Icons.notifications_none, size: compact ? 22 : 21),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  final bool compact;
  const _AccountMenu({this.compact = false});

  @override
  Widget build(BuildContext context) {
    // Listens itself: the phone app bar builds this as a const widget, which
    // a parent rebuild never refreshes, so it kept the placeholder name.
    return ValueListenableBuilder<int>(
      valueListenable: VendorSession.changes,
      builder: (context, _, __) => _menu(context),
    );
  }

  Widget _menu(BuildContext context) {
    final avatar = InitialsAvatar(name: VendorSession.vendorName, size: compact ? 32 : 36, imageUrl: VendorSession.avatarUrl);
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      onSelected: (v) async {
        switch (v) {
          case 'profile':
            context.go('/profile');
          case 'settings':
            context.go('/settings');
          case 'plans':
            context.go('/subscription');
          case 'theme':
            showThemePicker(context);
          case 'logout':
            await signOutWithConfirm(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(VendorSession.vendorName, style: AppType.body(size: 13.5, weight: FontWeight.w700)),
            if (VendorSession.email.isNotEmpty)
              Text(VendorSession.email, style: AppType.body(size: 11.5, color: AppColors.textMuted)),
          ]),
        ),
        const PopupMenuDivider(),
        _item('profile', Icons.account_box_outlined, 'Profile & portfolio'),
        _item('plans', Icons.workspace_premium_outlined, 'Subscription'),
        _item('settings', Icons.settings_outlined, 'Settings & KYC'),
        _item('theme', Icons.contrast, 'Appearance'),
        const PopupMenuDivider(),
        _item('logout', Icons.logout, 'Sign out', color: AppColors.danger),
      ],
      child: compact
          ? Padding(padding: const EdgeInsets.all(4), child: avatar)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              avatar,
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(VendorSession.vendorName,
                        overflow: TextOverflow.ellipsis, style: AppType.body(weight: FontWeight.w600, size: 13)),
                    Text(VendorSession.profileSubtitle,
                        overflow: TextOverflow.ellipsis, style: AppType.body(color: AppColors.textMuted, size: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
            ]),
    );
  }

  PopupMenuItem<String> _item(String v, IconData icon, String label, {Color? color}) => PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: AppType.body(size: 13.5, color: color ?? AppColors.textPrimary)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// COMMAND PALETTE
// ─────────────────────────────────────────────────────────────

/// Jump to any page, or hand a query to the bookings / roster search.
Future<void> openCommandPalette(BuildContext context) async {
  final target = await showDialog<String>(
    context: context,
    builder: (_) => const _CommandPalette(),
  );
  if (target != null && context.mounted) context.go(target);
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette();
  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _q = TextEditingController();
  int _highlight = 0;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<(IconData, String, String, String)> get _results {
    final q = _q.text.trim();
    final lq = q.toLowerCase();
    final cfg = VendorSession.config;
    final out = <(IconData, String, String, String)>[];
    if (q.isNotEmpty) {
      final enc = Uri.encodeQueryComponent(q);
      out.add((Icons.event_note_outlined, 'Search bookings for “$q”', 'Client, service, location or reference', '/bookings?q=$enc'));
      out.add((cfg.rosterIcon, 'Search ${cfg.rosterLabel.toLowerCase()} for “$q”', 'Name, role or city', '/roster?q=$enc'));
    }
    for (final n in vendorNav) {
      if (lq.isEmpty || n.label.toLowerCase().contains(lq) || (n.section ?? '').toLowerCase().contains(lq)) {
        out.add((n.icon, n.label, n.section ?? '', n.route));
      }
    }
    return out;
  }

  void _go(String route) => Navigator.of(context).pop(route);

  @override
  Widget build(BuildContext context) {
    final results = _results;
    if (_highlight >= results.length) _highlight = 0;
    return Dialog(
      alignment: const Alignment(0, -0.55),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    setState(() => _highlight = (_highlight + 1).clamp(0, results.length - 1)),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    setState(() => _highlight = (_highlight - 1).clamp(0, results.length - 1)),
              },
              child: TextField(
                controller: _q,
                autofocus: true,
                onChanged: (_) => setState(() => _highlight = 0),
                onSubmitted: (_) {
                  if (results.isNotEmpty) _go(results[_highlight].$4);
                },
                decoration: const InputDecoration(
                  hintText: 'Type a page, client name or booking reference…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          Flexible(
            child: results.isEmpty
                ? const EmptyView(message: 'No matches', icon: Icons.search_off)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final r = results[i];
                      final hi = i == _highlight;
                      return Material(
                        color: hi ? AppColors.gold.withValues(alpha: .12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: Icon(r.$1, size: 20, color: hi ? AppColors.gold : AppColors.textSecondary),
                          title: Text(r.$2),
                          subtitle: r.$3.isEmpty ? null : Text(r.$3),
                          trailing: hi ? Icon(Icons.keyboard_return, size: 16, color: AppColors.textMuted) : null,
                          onTap: () => _go(r.$4),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
